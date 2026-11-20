{{
    config(
        materialized='incremental',
        unique_key=['Store_id', 'Dept_id', 'Date_id', 'vrsn_start_date'],
        incremental_strategy='merge',
        merge_exclude_columns=['insert_date']
    )
}}

WITH source_data AS (
    SELECT
        d.STORE AS Store_id,
        d.DEPT AS Dept_id,
        TO_NUMBER(TO_CHAR(d.DATE, 'YYYYMMDD')) AS Date_id,
        st.Store_size AS Store_size,
        CAST(d.WEEKLY_SALES AS DECIMAL(18, 2)) AS Store_weekly_sales,
        CAST(f.FUEL_PRICE AS DECIMAL(10, 4)) AS Fuel_price,
        CAST(f.TEMPERATURE AS DECIMAL(10, 2)) AS Store_temperature,
        CAST(NULLIF(TRIM(f.UNEMPLOYMENT), '') AS DECIMAL(10, 3)) AS Unemployment,
        CAST(NULLIF(TRIM(f.CPI), '') AS DECIMAL(12, 4)) AS CPI,
        CAST(NULLIF(TRIM(f.MARKDOWN1), '') AS DECIMAL(18, 2)) AS Markdown1,
        CAST(NULLIF(TRIM(f.MARKDOWN2), '') AS DECIMAL(18, 2)) AS Markdown2,
        CAST(NULLIF(TRIM(f.MARKDOWN3), '') AS DECIMAL(18, 2)) AS Markdown3,
        CAST(NULLIF(TRIM(f.MARKDOWN4), '') AS DECIMAL(18, 2)) AS Markdown4,
        CAST(NULLIF(TRIM(f.MARKDOWN5), '') AS DECIMAL(18, 2)) AS Markdown5,
        HASH(
            st.Store_size,
            CAST(d.WEEKLY_SALES AS DECIMAL(18, 2)),
            CAST(f.FUEL_PRICE AS DECIMAL(10, 4)),
            CAST(f.TEMPERATURE AS DECIMAL(10, 2)),
            CAST(NULLIF(TRIM(f.UNEMPLOYMENT), '') AS DECIMAL(10, 3)),
            CAST(NULLIF(TRIM(f.CPI), '') AS DECIMAL(12, 4)),
            CAST(NULLIF(TRIM(f.MARKDOWN1), '') AS DECIMAL(18, 2)),
            CAST(NULLIF(TRIM(f.MARKDOWN2), '') AS DECIMAL(18, 2)),
            CAST(NULLIF(TRIM(f.MARKDOWN3), '') AS DECIMAL(18, 2)),
            CAST(NULLIF(TRIM(f.MARKDOWN4), '') AS DECIMAL(18, 2)),
            CAST(NULLIF(TRIM(f.MARKDOWN5), '') AS DECIMAL(18, 2))
        ) AS row_hash
    FROM {{ source('walmart_raw', 'RAW_DEPARTMENT') }} d
    LEFT JOIN {{ source('walmart_raw', 'RAW_FACT') }} f
        ON d.STORE = f.STORE
       AND d.DATE = f.DATE
    LEFT JOIN {{ ref('walmart_store_dim') }} st
        ON d.STORE = st.Store_id
       AND d.DEPT = st.Dept_id
    WHERE d.STORE IS NOT NULL
      AND d.DEPT IS NOT NULL
      AND d.DATE IS NOT NULL
)

{% if is_incremental() %}
,
current_active AS (
    SELECT
        *,
        HASH(
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
            Markdown5
        ) AS existing_hash
    FROM {{ this }}
    WHERE vrsn_end_date IS NULL
),

-- 1. Close out active records whose attributes changed
records_to_expire AS (
    SELECT
        c.Store_id,
        c.Dept_id,
        c.Date_id,
        c.Store_size,
        c.Store_weekly_sales,
        c.Fuel_price,
        c.Store_temperature,
        c.Unemployment,
        c.CPI,
        c.Markdown1,
        c.Markdown2,
        c.Markdown3,
        c.Markdown4,
        c.Markdown5,
        c.vrsn_start_date,
        CURRENT_TIMESTAMP() AS vrsn_end_date,
        c.insert_date,
        CURRENT_TIMESTAMP() AS update_date
    FROM current_active c
    INNER JOIN source_data s
        ON c.Store_id = s.Store_id
       AND c.Dept_id = s.Dept_id
       AND c.Date_id = s.Date_id
    WHERE c.existing_hash != s.row_hash
),

-- 2. Insert brand-new keys or new versions of changed records
records_to_insert AS (
    SELECT
        s.Store_id,
        s.Dept_id,
        s.Date_id,
        s.Store_size,
        s.Store_weekly_sales,
        s.Fuel_price,
        s.Store_temperature,
        s.Unemployment,
        s.CPI,
        s.Markdown1,
        s.Markdown2,
        s.Markdown3,
        s.Markdown4,
        s.Markdown5,
        CURRENT_TIMESTAMP() AS vrsn_start_date,
        CAST(NULL AS TIMESTAMP_NTZ) AS vrsn_end_date,
        CURRENT_TIMESTAMP() AS insert_date,
        CURRENT_TIMESTAMP() AS update_date
    FROM source_data s
    LEFT JOIN current_active c
        ON s.Store_id = c.Store_id
       AND s.Dept_id = c.Dept_id
       AND s.Date_id = c.Date_id
    WHERE c.Store_id IS NULL
       OR c.existing_hash != s.row_hash
)

SELECT * FROM records_to_expire
UNION ALL
SELECT * FROM records_to_insert

{% else %}

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
    CURRENT_TIMESTAMP() AS vrsn_start_date,
    CAST(NULL AS TIMESTAMP_NTZ) AS vrsn_end_date,
    CURRENT_TIMESTAMP() AS insert_date,
    CURRENT_TIMESTAMP() AS update_date
FROM source_data

{% endif %}