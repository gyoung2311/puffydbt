{% test not_null_for_entire_day(model, column_name, date_column='event_timestamp') %}

    SELECT
        DATE({{ date_column }}) AS date_day,
        COUNT(*) AS total_records,
        COUNT({{ column_name }}) AS non_null_records
    FROM {{ model }}
    GROUP BY DATE({{ date_column }})
    HAVING COUNT({{ column_name }}) = 0

{% endtest %}