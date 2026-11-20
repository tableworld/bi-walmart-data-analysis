{{
    config(
        materialized='incremental',
        unique_key=['Store_id', 'Dept_id'],
        incremental_strategy='merge',
        merge_exclude_columns=['Insert_date']
    )
}}

WITH store_depts AS (
    SELECT DISTINCT
        d.STORE AS Store_id,
        d.DEPT AS Dept_id,
        s.TYPE AS Store_type,
        s.SIZE AS Store_size
    FROM {{ source('walmart_raw', 'RAW_DEPARTMENT') }} d
    LEFT JOIN {{ source('walmart_raw', 'RAW_STORES') }} s
        ON d.STORE = s.STORE
    WHERE d.STORE IS NOT NULL
      AND d.DEPT IS NOT NULL
)

SELECT
    Store_id,
    Dept_id,
    Store_type,
    Store_size,
    CURRENT_TIMESTAMP() AS Insert_date,
    CURRENT_TIMESTAMP() AS Update_date
FROM store_depts