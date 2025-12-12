
with

checkout_completed_web_events as (
    select * from {{ ref('int_web_events') }}
    where event_name = 'checkout_completed'
),

purchased_items as (

    select
        checkout_completed_web_events.client_id,
        checkout_completed_web_events.event_timestamp,
        checkout_completed_web_events.transaction_id,
        checkout_completed_web_events.event_data,

        -- item details
        item.value:item_id::string  AS item_id,
        item.value:item_name::string AS item_name,
        item.value:item_price::number AS item_price,
        item.value:item_variant::string AS item_variant,
        item.value:quantity::number AS quantity,

        -- per-line item revenue
        (item.value:item_price::number * item.value:quantity::number) as item_revenue

    from checkout_completed_web_events,
     LATERAL FLATTEN(
       INPUT => checkout_completed_web_events.event_data:items
     ) item
)

select * from purchased_items