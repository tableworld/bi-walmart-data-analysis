{{
    config(
        materialized='incremental',
        unique_key='Date_id',
        incremental_strategy='merge',
        merge_exclude_columns=['Insert_date']
    )
}}

WITH raw_dates AS (
    SELECT DISTINCT
        DATE AS Store_Date,
        CASE WHEN ISHOLIDAY THEN 'True' ELSE 'False' END AS Isholiday
    FROM {{ source('walmart_raw', 'RAW_DEPARTMENT') }}
    WHERE DATE IS NOT NULL

    UNION

    SELECT DISTINCT
        DATE AS Store_Date,
        CASE WHEN ISHOLIDAY THEN 'True' ELSE 'False' END AS Isholiday
    FROM {{ source('walmart_raw', 'RAW_FACT') }}
    WHERE DATE IS NOT NULL
),

deduped_dates AS (
    SELECT
        TO_NUMBER(TO_CHAR(Store_Date, 'YYYYMMDD')) AS Date_id,
        Store_Date,
        MAX(Isholiday) AS Isholiday
    FROM raw_dates
    GROUP BY Store_Date
)

SELECT
    Date_id,
    Store_Date,
    Isholiday,
    CURRENT_TIMESTAMP() AS Insert_date,
    CURRENT_TIMESTAMP() AS Update_date
FROM deduped_dates