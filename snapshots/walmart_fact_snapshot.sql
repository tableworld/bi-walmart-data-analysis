{% snapshot walmart_fact_snapshot %}

{{
    config(
      target_schema='DBT_DEV',
      unique_key="Store_id || '-' || Dept_id || '-' || Date_id",
      strategy='check',
      check_cols=[
        'Store_size',
        'Store_weekly_sales',
        'Fuel_price',
        'Store_temperature',
        'Unemployment',
        'CPI',
        'Markdown1',
        'Markdown2',
        'Markdown3',
        'Markdown4',
        'Markdown5'
      ],
      invalidate_hard_deletes=True
    )
}}

SELECT
    s.Store_id,
    s.Dept_id,
    d.Date_id,
    s.Store_size,
    dept.Weekly_Sales AS Store_weekly_sales,
    f.Fuel_Price AS Fuel_price,
    f.Temperature AS Store_temperature,
    f.Unemployment,
    f.CPI,
    f.MarkDown1 AS Markdown1,
    f.MarkDown2 AS Markdown2,
    f.MarkDown3 AS Markdown3,
    f.MarkDown4 AS Markdown4,
    f.MarkDown5 AS Markdown5
FROM {{ ref('walmart_store_dim') }} s
JOIN {{ source('walmart_raw', 'RAW_DEPARTMENT') }} dept
    ON s.Store_id = dept.Store
   AND s.Dept_id = dept.Dept
JOIN {{ ref('walmart_date_dim') }} d
    ON dept.Date = d.Store_Date
JOIN {{ source('walmart_raw', 'RAW_FACT') }} f
    ON dept.Store = f.Store
   AND dept.Date = f.Date

{% endsnapshot %}