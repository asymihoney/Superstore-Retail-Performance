import streamlit as st
import pandas as pd
import sqlite3

st.set_page_config(page_title="Superstore Performance", layout="wide")
conn = sqlite3.connect("superstore.db", check_same_thread=False)

st.title("📊 Superstore Retail Performance")

# --- Sidebar filters ---
regions = pd.read_sql("SELECT DISTINCT region FROM orders", conn)["region"].tolist()
selected_region = st.sidebar.multiselect("Region", regions, default=regions)

region_filter = "', '".join(selected_region)

# --- KPI row ---
kpi_query = f"""
SELECT SUM(sales) AS total_sales, SUM(profit) AS total_profit,
       COUNT(DISTINCT order_id) AS n_orders
FROM orders WHERE region IN ('{region_filter}')
"""
kpis = pd.read_sql(kpi_query, conn).iloc[0]

col1, col2, col3 = st.columns(3)
col1.metric("Total Sales", f"${kpis['total_sales']:,.0f}")
col2.metric("Total Profit", f"${kpis['total_profit']:,.0f}")
col3.metric("Orders", f"{kpis['n_orders']:,}")

# --- Tabs for each business question ---
tab1, tab2, tab3 = st.tabs(["Sales Trend", "Profitability", "Raw SQL"])

with tab1:
    q1 = f"""
    SELECT strftime('%Y-%m', order_date) AS month, region, SUM(sales) AS total_sales
    FROM orders WHERE region IN ('{region_filter}')
    GROUP BY 1, 2 ORDER BY 1
    """
    df1 = pd.read_sql(q1, conn)
    st.line_chart(df1.pivot(index="month", columns="region", values="total_sales"))

with tab2:
    q2 = f"""
    SELECT p.sub_category, SUM(o.profit) AS profit
    FROM orders o JOIN products p ON o.product_id = p.product_id
    WHERE o.region IN ('{region_filter}')
    GROUP BY 1 ORDER BY profit
    """
    df2 = pd.read_sql(q2, conn)
    st.bar_chart(df2.set_index("sub_category"))

with tab3:
    st.code(open("queries.sql").read(), language="sql")