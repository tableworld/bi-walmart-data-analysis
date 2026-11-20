from snowflake.snowpark.context import get_active_session
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

session = get_active_session()

query = """
SELECT
    f.Store_id,
    f.Dept_id,
    f.Date_id,
    d.Store_Date,
    d.Isholiday,
    s.Store_type,
    f.Store_size,
    f.Store_weekly_sales,
    f.Fuel_price,
    f.Store_temperature,
    f.Unemployment,
    f.CPI,
    COALESCE(f.Markdown1, 0) + COALESCE(f.Markdown2, 0) +
    COALESCE(f.Markdown3, 0) + COALESCE(f.Markdown4, 0) +
    COALESCE(f.Markdown5, 0) AS Total_Markdown
FROM WALMART_DB.DBT_DEV.WALMART_FACT_TABLE f
JOIN WALMART_DB.DBT_DEV.WALMART_DATE_DIM d
    ON f.Date_id = d.Date_id
JOIN WALMART_DB.DBT_DEV.WALMART_STORE_DIM s
    ON f.Store_id = s.Store_id
   AND f.Dept_id = s.Dept_id
WHERE f.vrsn_end_date IS NULL
"""

df = session.sql(query).to_pandas()
df["STORE_DATE"] = pd.to_datetime(df["STORE_DATE"])
sns.set_theme(style="whitegrid")

# Chart 1: Weekly Sales Trend Over Time (Holiday vs. Non-Holiday)
weekly_trend = df.groupby(["STORE_DATE", "ISHOLIDAY"], as_index=False)["STORE_WEEKLY_SALES"].sum()
plt.figure(figsize=(12, 5))
sns.lineplot(data=weekly_trend, x="STORE_DATE", y="STORE_WEEKLY_SALES", label="Total Weekly Sales")
holidays = weekly_trend[weekly_trend["ISHOLIDAY"] == "True"]
plt.scatter(holidays["STORE_DATE"], holidays["STORE_WEEKLY_SALES"], color="red", zorder=5, label="Holiday Week")
plt.title("Total Weekly Sales Over Time (Holiday vs. Non-Holiday)")
plt.xlabel("Date")
plt.ylabel("Weekly Sales ($)")
plt.legend()
plt.tight_layout()
plt.show()

# Chart 2: Total Sales by Store Type
plt.figure(figsize=(8, 5))
store_type_sales = df.groupby("STORE_TYPE", as_index=False)["STORE_WEEKLY_SALES"].sum()
sns.barplot(data=store_type_sales, x="STORE_TYPE", y="STORE_WEEKLY_SALES", hue="STORE_TYPE", palette="viridis", legend=False,)
plt.title("Total Sales by Store Type")
plt.xlabel("Store Type")
plt.ylabel("Total Sales ($)")
plt.tight_layout()
plt.show()

# Chart 3: Top 10 Stores by Total Sales
top_stores = (
    df.groupby("STORE_ID", as_index=False)["STORE_WEEKLY_SALES"]
    .sum()
    .sort_values("STORE_WEEKLY_SALES", ascending=False)
    .head(10)
)
plt.figure(figsize=(10, 5))
sns.barplot(data=top_stores, x="STORE_ID", y="STORE_WEEKLY_SALES", hue="STORE_ID", order=top_stores["STORE_ID"], palette="Blues_d", legend=False,)
plt.title("Top 10 Stores by Total Sales")
plt.xlabel("Store ID")
plt.ylabel("Total Sales ($)")
plt.tight_layout()
plt.show()

# Chart 4: Correlation Heatmap (Sales vs. Macro Factors & Markdowns)
corr_cols = ["STORE_WEEKLY_SALES", "STORE_SIZE", "FUEL_PRICE", "STORE_TEMPERATURE", "UNEMPLOYMENT", "CPI", "TOTAL_MARKDOWN"]
plt.figure(figsize=(9, 7))
sns.heatmap(df[corr_cols].corr(), annot=True, fmt=".2f", cmap="coolwarm", center=0)
plt.title("Correlation: Weekly Sales vs. Store Size, Macro Factors & Markdowns")
plt.tight_layout()
plt.show()
