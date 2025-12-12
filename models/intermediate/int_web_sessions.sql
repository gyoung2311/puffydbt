
with 

filled_web_events as (

    select * from {{ ref('int_web_events') }}

),

client_sessions as (

    select
        client_id,
        session_number,
        MIN(event_timestamp) AS session_start_at,
        MAX(event_timestamp) AS session_end_at,

        session_first_utm_source,
        session_first_utm_medium,

        session_last_utm_source,       
        session_last_utm_medium,

    from filled_web_events
    group by all

)

select * from client_sessions
