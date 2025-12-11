
with 

client as (
    select * from {{ ref('dim_clients') }}
),

client_journey as (
    select * from {{ ref('fct_client_journey') }}
),

client_metrics as (
    select * from {{ ref('fct_client_metrics') }}
),

final as (
    select
        client.*,

        client_metrics.total_events,
        client_metrics.total_sessions,
        client_metrics.total_revenue,
        client_metrics.days_active,

        page_viewed_at,
        product_added_to_cart_at,
        checkout_started_at,
        checkout_completed_at

    from client
        left join client_metrics 
            on client.client_id = client_metrics.client_id

        left join client_journey
            on client.client_id = client_journey.client_id
)

select * from final