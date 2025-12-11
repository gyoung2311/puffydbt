
with raw_events as (

    select * from {{ source('csv', 'events') }}

),

final as (
    select 
        client_id,
        page_url,
        referrer,
        timestamp as event_timestamp,
        event_name,
        event_data,

        --base url
         SPLIT_PART(page_url, '?', 1) AS base_url,

         --referrer base url
         SPLIT_PART(referrer, '?', 1) AS referrer_base_url,

        -- UTM Source
        REGEXP_SUBSTR(page_url, 'utm_source=([^&]*)', 1, 1, 'e') AS utm_source,
        
        -- UTM Medium
        REGEXP_SUBSTR(page_url, 'utm_medium=([^&]*)', 1, 1, 'e') AS utm_medium,
        
        -- UTM Campaign
        REGEXP_SUBSTR(page_url, 'utm_campaign=([^&]*)', 1, 1, 'e') AS utm_campaign,
        
        -- UTM Term
        REGEXP_SUBSTR(page_url, 'utm_term=([^&]*)', 1, 1, 'e') AS utm_term,
        
        -- UTM Content
        REGEXP_SUBSTR(page_url, 'utm_content=([^&]*)', 1, 1, 'e') AS utm_content,

        -- Impact.com ir click id
        REGEXP_SUBSTR(page_url, 'irclickid=([^&]*)', 1, 1, 'e') AS ir_click_id,

        -- Impact.com ir click id
        REGEXP_SUBSTR(page_url, 'gclid=([^&]*)', 1, 1, 'e') AS google_click_id,

        -- Completed Order fields
        parse_json(event_data):revenue::number AS revenue,
        parse_json(event_data):transaction_id::string AS transaction_id,
        parse_json(event_data):user_email::string AS user_email,

        CASE
            -- Detect mobile devices
            WHEN LOWER(user_agent) LIKE '%mobile%' 
                OR LOWER(user_agent) LIKE '%android%'
                OR LOWER(user_agent) LIKE '%iphone%'
                OR LOWER(user_agent) LIKE '%ipad%'
                OR LOWER(user_agent) LIKE '%ipod%'
                OR LOWER(user_agent) LIKE '%blackberry%'
                OR LOWER(user_agent) LIKE '%windows phone%'
            THEN 'mobile'
            -- Detect desktop
            WHEN LOWER(user_agent) LIKE '%windows%'
                OR LOWER(user_agent) LIKE '%macintosh%'
                OR LOWER(user_agent) LIKE '%linux%'
                OR LOWER(user_agent) LIKE '%x11%'
            THEN 'desktop'
            ELSE 'unknown'
        END AS device_type,

        row_number() over(
            PARTITION by client_id
            order by event_timestamp
        ) as client_id_event_sequence
        
    from raw_events
    
)

select * from final