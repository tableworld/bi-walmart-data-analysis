SELECT
    Store_id,
    Dept_id,
    Date_id,
    Store_size,
    Store_weekly_sales,
    Fuel_price,
    Store_temperature,
    Unemployment,
    CPI,
    Markdown1,
    Markdown2,
    Markdown3,
    Markdown4,
    Markdown5,
    dbt_valid_from AS vrsn_start_date,
    dbt_valid_to AS vrsn_end_date
FROM {{ ref('walmart_fact_snapshot') }}