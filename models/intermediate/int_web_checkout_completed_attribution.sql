-- revenue_matches_item_sum_int_web_checkout_completed_attribution_item_revenue__int_web_checkout_completed_order_details__revenue__transaction_id":
-- depends_on: {{ ref('int_web_checkout_completed_order_details') }}

with 

checkout_completed_events as (

    select * from {{ ref('int_web_events') }}
    where event_name = 'checkout_completed'

),

client_sessions as (

    select * from {{ ref('int_web_sessions') }}

),

-- identify sessions within 7 day lookback window
eligible_sessions as(

    select
        checkout_completed_events.client_id,
        checkout_completed_events.event_timestamp as checkout_completed_at,
        checkout_completed_events.revenue,
        checkout_completed_events.transaction_id,
    

        client_sessions.session_number,
        client_sessions.session_start_at,
        client_sessions.session_first_utm_source,
        client_sessions.session_first_utm_medium,
        client_sessions.session_last_utm_source,
        client_sessions.session_last_utm_medium


    from checkout_completed_events
        JOIN client_sessions
        ON client_sessions.client_id = checkout_completed_events.client_id
        AND client_sessions.session_start_at >= DATEADD('day', -7, checkout_completed_events.event_timestamp)
        AND client_sessions.session_start_at <= checkout_completed_events.event_timestamp

),

first_touch as (

    select distinct
        client_id,
        checkout_completed_at,

        -- first-touch within lookback: earliest session_start_at with non-null first UTMs
        FIRST_VALUE(session_first_utm_source) OVER (
            PARTITION BY client_id, checkout_completed_at
            ORDER BY session_start_at
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS first_touch_utm_source,

        FIRST_VALUE(session_first_utm_medium) OVER (
            PARTITION BY client_id, checkout_completed_at
            ORDER BY session_start_at
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS first_touch_utm_medium

    from eligible_sessions

),

last_touch as (

    select distinct
        client_id,
        checkout_completed_at,

        -- first-touch within lookback: earliest session_start_at with non-null first UTMs
        LAST_VALUE(session_last_utm_source) OVER (
            PARTITION BY client_id, checkout_completed_at
            ORDER BY session_start_at desc
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS last_touch_utm_source,

        LAST_VALUE(session_last_utm_medium) OVER (
            PARTITION BY client_id, checkout_completed_at
            ORDER BY session_start_at desc
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS last_touch_utm_medium

    from eligible_sessions

),

final as (

    select
        checkout_completed_events.client_id,
        checkout_completed_events.event_timestamp as checkout_completed_at,
        checkout_completed_events.revenue,
        checkout_completed_events.session_number,
        checkout_completed_events.transaction_id,

        row_number() over (
            PARTITION by checkout_completed_events.client_id
            ORDER BY event_timestamp
        ) as client_purchase_sequence,

        first_touch_utm_source,
        first_touch_utm_medium,
        last_touch_utm_source,
        last_touch_utm_medium

    from checkout_completed_events

        left join first_touch on
        checkout_completed_events.client_id = first_touch.client_id
        and checkout_completed_events.event_timestamp = first_touch.checkout_completed_at 

        left join last_touch on
        checkout_completed_events.client_id = last_touch.client_id
        and checkout_completed_events.event_timestamp = last_touch.checkout_completed_at 

)

select * from final
