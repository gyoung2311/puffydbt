{% test revenue_matches_item_sum(model, order_details_model, transaction_id_column='transaction_id', revenue_column='revenue', item_revenue_column='item_revenue') %}

WITH order_details_agg AS (
    SELECT
        {{ transaction_id_column }},
        SUM({{ item_revenue_column }}) AS total_item_revenue
    FROM {{ ref(order_details_model) }}
    GROUP BY {{ transaction_id_column }}
),

attribution_revenue AS (
    SELECT
        {{ transaction_id_column }},
        {{ revenue_column }} AS revenue
    FROM {{ model }}
    WHERE {{ transaction_id_column }} IS NOT NULL
)

SELECT
    COALESCE(order_details_agg.{{ transaction_id_column }}, attribution_revenue.{{ transaction_id_column }}) AS {{ transaction_id_column }},
    order_details_agg.total_item_revenue,
    attribution_revenue.revenue,
    ABS(COALESCE(order_details_agg.total_item_revenue, 0) - COALESCE(attribution_revenue.revenue, 0)) AS revenue_difference
FROM order_details_agg
FULL OUTER JOIN attribution_revenue
    ON order_details_agg.{{ transaction_id_column }} = attribution_revenue.{{ transaction_id_column }}
WHERE ABS(COALESCE(order_details_agg.total_item_revenue, 0) - COALESCE(attribution_revenue.revenue, 0)) > 0.01

{% endtest %}

