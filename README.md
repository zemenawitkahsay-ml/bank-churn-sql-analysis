# Bank Customer Churn Analysis Using SQL

## Project Overview

This project analyzes bank customer churn using SQL by integrating three datasets: **Customers, Transactions, and Churn**. The goal is to identify behavioral patterns and key factors that influence customer churn.

The analysis includes **data cleaning, exploratory analysis, feature engineering, and customer segmentation**.

---

## Database Structure

The database contains three main tables:

- **Customers** – customer demographics and account details  
- **Transactions** – transaction history and financial activity  
- **Churn** – churn status for each customer  

These tables are connected using **CustomerID**.

---

## SQL Skills Demonstrated

This project demonstrates:

- Data cleaning and validation
- Table joins across multiple datasets
- Aggregations and grouping
- Window functions
- Common Table Expressions (CTEs)
- Feature engineering
- Customer segmentation (RFM analysis)
- Churn risk analysis

---

## Key Analysis Performed

Key analytical tasks include:

- Customer demographic and transaction analysis
- Churn rate calculation and segmentation
- Identification of high-risk customers
- Branch-level churn comparison
- RFM customer segmentation
- Customer lifetime value estimation
- Creation of a master analytical dataset

---

## Key Insight

The dataset contains **10,000 customers and 50,000 transactions**, with an overall churn rate of **19.62%**. Behavioral features such as **recency, transaction frequency, and total spend** were strong indicators of customer churn risk.

---

## Project Structure

```
bank-churn-sql-analysis
│
├── data
│   ├── customers_insert.sql
│   ├── transactions_insert.sql
│   └── churn_insert.sql
│
├── queries
│   └── bank_churn_analysis_queries.sql
│
├── README.md
├── LICENSE

```

---

## Author

Zemenawit Kahsay  
Advanced Diploma in Data Science  
Toronto, Canada




