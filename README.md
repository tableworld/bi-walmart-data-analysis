# Walmart BI Data Analysis (Snowflake + dbt + Python)

End-to-end Business Intelligence pipeline analyzing Walmart retail store and department sales across macroeconomic indicators, store types, and holiday periods.

## Architecture & Tech Stack

- **Data Warehouse:** Snowflake (`WALMART_DB.RAW` -> `WALMART_DB.DBT_DEV`)
- **Transformation & Modeling:** dbt Cloud / dbt Studio (Star Schema with SCD Type 1 dimensions and SCD Type 2 snapshot history)
- **Reporting & Visualization:** Python (Snowpark, pandas, Matplotlib, Seaborn)

## Data Model (`WALMART_DB.DBT_DEV`)

- *walmart_date_dim* *(SCD Type 1):* Date dimension tracking `Date_id`, `Store_Date`, `Isholiday`, and audit timestamps.
- *walmart_store_dim* *(SCD Type 1):* Store dimension tracking `Store_id`, `Dept_id`, `Store_type`, `Store_size`, and audit timestamps.
- *walmart_fact_snapshot* *(dbt Snapshot — SCD Type 2):* Captures historical changes (`dbt_valid_from`, `dbt_valid_to`) across weekly sales, fuel price, temperature, unemployment, CPI, and markdown metrics (`Markdown1`–`Markdown5`).
- *walmart_fact_table* *(SCD Type 2):* Reads from `walmart_fact_snapshot` and maps `dbt_valid_from` and `dbt_valid_to` to `vrsn_start_date` and `vrsn_end_date` alongside core fact columns (`Store_id`, `Dept_id`, `Date_id`, `Store_size`, `Store_weekly_sales`, `Fuel_price`, `Store_temperature`, `Unemployment`, `CPI`, `Markdown1`–`Markdown5`).

## Visual Reports (`walmart_analysis_reports.py`)

### 1. Weekly Sales Trend Over Time
![Weekly Sales Trend Over Time](charts/weekly_sales_trend.png)

### 2. Total Weekly Sales by Store Type (A, B, C)
![Total Weekly Sales by Store Type](charts/sales_by_store_type.png)

### 3. Top 10 Stores by Weekly Sales
![Top 10 Stores by Weekly Sales](charts/top_10_stores.png)

### 4. Correlation Heatmap
![Correlation Heatmap](charts/correlation_heatmap.png)
