WITH base_events AS (

    SELECT * FROM {{ ref('stg_web_events') }}

),

ordered_events as (

    SELECT
        base_events.*,

        LAG(event_timestamp) OVER (
            PARTITION BY client_id
            ORDER BY event_timestamp
        ) AS prev_ts
  FROM base_events
),

session_flags AS (
  SELECT
    ordered_events.*,
    CASE
      WHEN prev_ts IS NULL THEN 1
      WHEN DATEDIFF('minute', prev_ts, event_timestamp) > 30 THEN 1
      ELSE 0
    END AS is_new_session
  FROM ordered_events
),

sessionized AS (
  SELECT
    session_flags.*,
    SUM(is_new_session) OVER (
      PARTITION BY client_id
      ORDER BY event_timestamp
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS session_number
  FROM session_flags
),

-- fill in missing utm parameters within same session
-- identify first utm parameters within a session
-- identify last utm parameters within a session
with_session_utm AS (
  SELECT
    sessionized.*,

    LAST_VALUE(utm_source) IGNORE NULLS
        OVER (
            PARTITION BY client_id, session_number
            ORDER BY event_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS filled_utm_source,

    LAST_VALUE(utm_medium) IGNORE NULLS
        OVER (
            PARTITION BY client_id, session_number
            ORDER BY event_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS filled_utm_medium,

    FIRST_VALUE(utm_source) IGNORE NULLS 
        OVER (
            PARTITION BY client_id, session_number
            ORDER BY event_timestamp
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS session_first_utm_source,

    FIRST_VALUE(utm_medium) IGNORE NULLS 
        OVER (
            PARTITION BY client_id, session_number
            ORDER BY event_timestamp
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS session_first_utm_medium,

    FIRST_VALUE(utm_source) IGNORE NULLS 
        OVER (
            PARTITION BY client_id, session_number
            ORDER BY event_timestamp desc
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS session_last_utm_source,

    FIRST_VALUE(utm_medium) IGNORE NULLS 
        OVER (
            PARTITION BY client_id, session_number
            ORDER BY event_timestamp desc
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS session_last_utm_medium

  FROM sessionized
)


select * from with_session_utm
--where client_id = '1741367456-uz2V75aLolvU'
--order by 4
--where event_name = 'checkout_completed' and session_number > 1
--where client_id = '1740490652-u8qNtnGdfQWY'
--order by event_timestamp