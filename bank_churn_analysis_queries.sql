-- Create database as BankChurnDB
CREATE DATABASE BankChurnDB1;
GO
USE BankChurnDB;

--1- Create tables
DROP TABLE IF EXISTS Customers
CREATE TABLE Customers(
    CustomerID INT PRIMARY KEY, 
    FullName nVARCHAR(100), 
    Age INT, 
    Gender NVARCHAR(10),
    JoinDate DATE, 
    AccountType NVARCHAR(50), 
    BranchID INT);
CREATE TABLE Transactions(
    TransactionID INT PRIMARY KEY, 
    CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID),
    TransactionDate DATE, 
    Amount DECIMAL(10,2),
    TransactionType NVARCHAR(50), 
    Channel VARCHAR(50));
DROP TABLE IF EXISTS CHURN
CREATE TABLE CHURN(
              CustomerID INT PRIMARY KEY FOREIGN KEY REFERENCES Customers(CustomerID), 
			  ChurnFlag BIT,
			  ChurnDate DATE);

--Inserting records
--Customers_insert.SQL
--transactions_insert.SQL
--churn_insert.SQL

select * from Customers
select * from Transactions
select *  from churn

--Initial Exploration
--COUNT()
--total count per table
SELECT COUNT(*) AS TotalCustomers FROM Customers;
SELECT COUNT(*) AS TotalTransactions FROM Transactions;
SELECT COUNT(*) AS TotalChurnRecords FROM Churn;
--TotalCustomers      TotalTransactions       TotalChurnRecords
--  10000                50000                     10000

-- unique counts
SELECT COUNT(DISTINCT CustomerID) AS UNIQUE_CNT
FROM Customers
--UNIQUE_CNT
--10000

SELECT COUNT(DISTINCT CustomerID) AS UNIQUE_CNT, COUNT(TransactionID) AS Tranxcnt
FROM Transactions
--UNIQUE    Tranxcnt
--9924      50000
SELECT COUNT(DISTINCT CustomerID) AS UNIQUE_CNT, SUM(CAST(Churnflag as int)) AS Total_churned
FROM Churn
--UNIQUE_CNT    total_churn
----10000       1962

-- count per Account type
SELECT AccountType, COUNT(*) AS TotalCustomers
FROM Customers
GROUP BY AccountType;
--Savings     Current
--4974        5026

-- TransactionType
--Count Transactions per Type 
SELECT 
    TransactionType,
    COUNT(*) AS TotalTransactions
FROM Transactions
GROUP BY TransactionType;
--paymnet   Transfer    Withdrawal     Deposit
--- 12440   12487        12514           12559

--Total Amount per Transaction Type
SELECT 
    TransactionType,
    COUNT(*) AS TotalTransactions,
    SUM(Amount) AS TotalAmount,
    AVG(Amount) AS AverageAmount
FROM Transactions
GROUP BY TransactionType;

--Percentage Distribution
SELECT 
    TransactionType,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS Percentage
FROM Transactions
GROUP BY TransactionType;

--Age Distribution
SELECT 
    MIN(Age) AS MinAge,
    MAX(Age) AS MaxAge,
    AVG(Age) AS AverageAge
FROM Customers;
--MinAge    MaxAge     AverageAge
--- 18        79          48

--- Transaction Distribution
SELECT 
    MIN(Amount) AS MinTranAmount,
    MAX(Amount) AS MaxTranAmount,
    AVG(Amount) AS AvgTranAmount
FROM Transactions;
--MinTranAmount      MaxTransAmount      AvgTranAmount
--- 5.04                4999.96             2503.30

--Check Date Range
SELECT 
    MIN(JoinDate) AS EarliestJoin,
    MAX(JoinDate) AS LatestJoin
FROM Customers;

SELECT 
    MIN(TransactionDate) AS EarliestTransaction,
    MAX(TransactionDate) AS LatestTransaction
FROM Transactions;
-- EarliestJoin     LatestJoin       EarliestTransaction    LatestTransaction
----Feb 17,2016     Feb 15,2025      Feb 16,2021               Feb 16,2026

--Gender Distribution
SELECT Gender, COUNT(*) AS TotalCustomers
FROM Customers
GROUP BY Gender;
--Male          Female
--501          4986

-- Data Cleaning & Validation

--Check for NULLS
--Customer Table
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN FullName IS NULL THEN 1 ELSE 0 END) AS Null_FullName,
    SUM(CASE WHEN Age IS NULL THEN 1 ELSE 0 END) AS Null_Age,
    SUM(CASE WHEN Gender IS NULL THEN 1 ELSE 0 END) AS Null_Gender,
    SUM(CASE WHEN JoinDate IS NULL THEN 1 ELSE 0 END) AS Null_JoinDate,
    SUM(CASE WHEN AccountType IS NULL THEN 1 ELSE 0 END) AS Null_AccountType,
    SUM(CASE WHEN BranchID IS NULL THEN 1 ELSE 0 END) AS Null_BranchID
FROM Customers;
--No missing Value in all rows

--Transaction Table
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS Null_CustomerID,
    SUM(CASE WHEN TransactionDate IS NULL THEN 1 ELSE 0 END) AS Null_TransactionDate,
    SUM(CASE WHEN Amount IS NULL THEN 1 ELSE 0 END) AS Null_Amount,
    SUM(CASE WHEN TransactionType IS NULL THEN 1 ELSE 0 END) AS Null_TransactionType,
    SUM(CASE WHEN Channel IS NULL THEN 1 ELSE 0 END) AS Null_Channel
FROM Transactions;
--No Missing value in all rows

--Churn Table
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN ChurnFlag IS NULL THEN 1 ELSE 0 END) AS Null_ChurnFlag,
    SUM(CASE WHEN ChurnDate IS NULL THEN 1 ELSE 0 END) AS Null_ChurnDate
FROM Churn;
--Null_ChurnFalg           Null_ChurnDate
-----   0                     8038

--Remove Duplicates

--Customer Table
WITH CTE_Customers AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY FullName, Age, Gender, JoinDate, AccountType, BranchID
               ORDER BY CustomerID
           ) AS rn
    FROM Customers
)
DELETE FROM CTE_Customers
WHERE rn > 1;

--Transaction Table
WITH CTE_Transactions AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY CustomerID, TransactionDate, Amount, TransactionType, Channel
               ORDER BY TransactionID
           ) AS rn
    FROM Transactions
)
DELETE FROM CTE_Transactions
WHERE rn > 1;

--Validate Ranges

-- Age range check 
SELECT *
FROM Customers
WHERE Age < 18 OR Age > 80;
--All ages are bn the range

-- Amount should not be negative
SELECT *
FROM Transactions
WHERE Amount < 0;
--No negative value

-- Gender only Male/Female (after trimming)
SELECT DISTINCT Gender
FROM Customers
WHERE LTRIM(RTRIM(Gender)) NOT IN ('Male', 'Female');

----Transactions before join
SELECT t.*
FROM Transactions t
JOIN Customers c ON c.CustomerID = t.CustomerID
WHERE t.TransactionDate < c.JoinDate;
---There are observation which have a transaction before join date 

--Update transaction date that are greater than today
UPDATE Transactions
SET TransactionDate = GETDATE()
WHERE TransactionDate > GETDATE();

--Validate Churn
-- churned=1 but missing date
SELECT CustomerID
FROM Churn
WHERE ChurnFlag = 1 AND ChurnDate IS NULL;

-- churned=0 but has date
SELECT CustomerID
FROM Churn
WHERE ChurnFlag = 0 AND ChurnDate IS NOT NULL;

--Churn date before join date
SELECT ch.*
FROM Churn ch
JOIN Customers c ON c.CustomerID = ch.CustomerID
WHERE ch.ChurnFlag = 1
  AND ch.ChurnDate < c.JoinDate;
  ----129 observations

  --Transaction after churn
SELECT t.*
FROM Transactions_Cleaned t
JOIN Churn_Cleaned ch 
    ON ch.CustomerID = t.CustomerID
WHERE ch.ChurnFlag = 1
  AND t.TransactionDate > ch.ChurnDate;

---Standardize Data
UPDATE Customers
SET Gender = UPPER(LEFT(LTRIM(RTRIM(Gender)),1)) + LOWER(SUBSTRING(LTRIM(RTRIM(Gender)),2,50))
WHERE Gender IS NOT NULL;

UPDATE Transactions
SET TransactionType = UPPER(LTRIM(RTRIM(TransactionType)))
WHERE TransactionType IS NOT NULL;

UPDATE Transactions
SET Channel = UPPER(LTRIM(RTRIM(Channel)))
WHERE Channel IS NOT NULL;


----Cleaned Tables
USE BankChurnDB;

-- Drop cleaned tables if they already exist
IF OBJECT_ID('Customers_Cleaned', 'U') IS NOT NULL DROP TABLE Customers_Cleaned;
IF OBJECT_ID('Transactions_Cleaned', 'U') IS NOT NULL DROP TABLE Transactions_Cleaned;
IF OBJECT_ID('Churn_Cleaned', 'U') IS NOT NULL DROP TABLE Churn_Cleaned;

-- Customers_Cleaned
SELECT *
INTO Customers_Cleaned
FROM Customers
WHERE Age BETWEEN 18 AND 80
  AND LTRIM(RTRIM(Gender)) IN ('Male','Female')
  AND FullName IS NOT NULL
  AND JoinDate IS NOT NULL
  AND AccountType IS NOT NULL
  AND BranchID IS NOT NULL;

-- Transactions_Cleaned (exclude negative + nulls + before JoinDate)
SELECT t.*
INTO Transactions_Cleaned
FROM Transactions t
JOIN Customers_Cleaned c 
    ON c.CustomerID = t.CustomerID
WHERE t.Amount >= 0
  AND t.TransactionDate IS NOT NULL
  AND t.TransactionType IS NOT NULL
  AND t.Channel IS NOT NULL
  AND t.TransactionDate >= c.JoinDate;

-- Churn_Cleaned (exclude invalid churn logic + before JoinDate)
SELECT ch.*
INTO Churn_Cleaned
FROM Churn ch
JOIN Customers_Cleaned c 
    ON c.CustomerID = ch.CustomerID
WHERE ch.ChurnFlag IN (0,1)
  AND NOT (ch.ChurnFlag = 1 AND ch.ChurnDate IS NULL)
  AND NOT (ch.ChurnFlag = 1 AND ch.ChurnDate < c.JoinDate);

--- Descriptive Analysis and Diagbostic Analysis

--- UNIVARIATE ANALYSIS
--Target Variable(ChurnFlag)
SELECT 
    ChurnFlag,
    COUNT(*) AS Frequency,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS Percentage
FROM Churn
GROUP BY ChurnFlag;
---0          1
--8038       1962
-- Age Distribution
WITH AgeStats AS (
    SELECT
        Age,
        MIN(Age) OVER() AS Minimum,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Age) OVER() AS Q1,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Age) OVER() AS Median,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Age) OVER() AS Q3,
        MAX(Age) OVER() AS Maximum
    FROM Customers_Cleaned
)SELECT DISTINCT Minimum, Q1, Median, Q3, Maximum
FROM AgeStats;
---MIN       Q1    Median     Q3     MAX
--- 18      34      49       64      79
---Transaction Amount
WITH AmountStats AS (
    SELECT
        Amount,
        MIN(Amount) OVER() AS Minimum,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Amount) OVER() AS Q1,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Amount) OVER() AS Median,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Amount) OVER() AS Q3,
        MAX(Amount) OVER() AS Maximum
    FROM Transactions_Cleaned
)SELECT DISTINCT Minimum, Q1, Median, Q3, Maximum
FROM AmountStats;
---MIN       Q1        Median     Q3        MAX
---5.04    1254.55   2511.29   3764.87     4999.96

---Gender
SELECT 
    Gender,
    COUNT(*) AS Frequency,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS Percentage
FROM Customers_Cleaned
GROUP BY Gender;
--Male          Female
--5014          4986

----Account Type
SELECT 
    AccountType,
    COUNT(*) AS Frequency,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS Percentage
FROM Customers_Cleaned
GROUP BY AccountType;
----Savings              Current
----4974                  5026

---Transaction Type
SELECT 
    TransactionType,
    COUNT(*) AS Frequency,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS Percentage
FROM Transactions_Cleaned
GROUP BY TransactionType;

---Channel
SELECT 
    t.Channel,
    COUNT(*) AS TotalTransactions
FROM Transactions_Cleaned t
GROUP BY t.Channel;

-- Join date
SELECT 
    MIN(JoinDate) AS EarliestJoin,
    MAX(JoinDate) AS LatestJoin
FROM Customers_Cleaned;

--Distribution by year
SELECT 
    YEAR(JoinDate) AS JoinYear,
    COUNT(*) AS TotalCustomers
FROM Customers_Cleaned
GROUP BY YEAR(JoinDate)
ORDER BY JoinYear;

---Bivariate Analysis
---Churn vs Gender
SELECT 
    c.Gender,
    ch.ChurnFlag,
    COUNT(*) AS Frequency
FROM Customers_Cleaned c
JOIN Churn_Cleaned ch 
    ON c.CustomerID = ch.CustomerID
GROUP BY c.Gender, ch.ChurnFlag
ORDER BY c.Gender;

--Churn rate by Gender
SELECT 
    c.Gender,
    COUNT(*) AS Total,
    SUM(CAST(ch.ChurnFlag AS INT)) AS TotalChurned,
    ROUND(SUM(CAST(ch.ChurnFlag AS FLOAT)) * 100 / COUNT(*), 2) AS ChurnRate
FROM Customers_Cleaned c
JOIN Churn_Cleaned ch 
    ON c.CustomerID = ch.CustomerID
GROUP BY c.Gender;
----Male        Female
---- 18.16       18.98

---Churn by Account type
SELECT 
    c.AccountType,
    ch.ChurnFlag,
    COUNT(*) AS Frequency
FROM Customers_Cleaned c
JOIN Churn_Cleaned ch 
    ON c.CustomerID = ch.CustomerID
GROUP BY c.AccountType, ch.ChurnFlag;

--Churn rate by account type
SELECT 
    c.AccountType,
    COUNT(*) AS TotalCustomers,
    SUM(CAST(ch.ChurnFlag AS INT)) AS TotalChurned,
    ROUND(
        SUM(CAST(ch.ChurnFlag AS FLOAT)) * 100.0 
        / COUNT(*),
        2
    ) AS ChurnRate_Percentage
FROM Customers_Cleaned c
JOIN Churn_Cleaned ch 
    ON c.CustomerID = ch.CustomerID
GROUP BY c.AccountType
ORDER BY ChurnRate_Percentage DESC;
-----Savings             Current
----    18.96            18.19

----Churn by Age
SELECT 
    ch.ChurnFlag,
    AVG(c.Age) AS AvgAge,
    STDEV(c.Age) AS StdDevAge,
    COUNT(*) AS SampleSize
FROM Customers_Cleaned c
JOIN Churn_Cleaned ch 
    ON c.CustomerID = ch.CustomerID
GROUP BY ch.ChurnFlag;

---Churn by Transaction Amount 
SELECT 
    ch.ChurnFlag,
    AVG(t.Amount) AS AvgTransactionAmount,
    STDEV(t.Amount) AS StdDevAmount,
    COUNT(*) AS SampleSize
FROM Transactions_Cleaned t
JOIN Churn_Cleaned ch 
    ON t.CustomerID = ch.CustomerID
GROUP BY ch.ChurnFlag;

-- Overall Churn Rate
SELECT 
    COUNT(*) AS TotalCustomers,
    SUM(CAST(ChurnFlag AS INT)) AS ChurnedCustomers,
    ROUND(100.0 * SUM(CAST(ChurnFlag AS INT)) / COUNT(*),2) AS ChurnRatePercent
FROM Churn;
-- TotalCustomers	ChurnedCustomers	ChurnRatePercent
-- 10000	         1962	            19.62

---Explorotary Analysis and Aggregation
--1 High risk Customers
WITH LastTransaction AS (
    SELECT 
        CustomerID,
        MAX(TransactionDate) AS LastTransactionDate
    FROM Transactions_Cleaned
    GROUP BY CustomerID
)
SELECT 
    c.CustomerID,
    lt.LastTransactionDate,
    DATEDIFF(DAY, lt.LastTransactionDate, GETDATE()) AS DaysSinceLastTransaction,
    ch.ChurnFlag
FROM Customers_Cleaned c
LEFT JOIN LastTransaction lt 
    ON c.CustomerID = lt.CustomerID
JOIN Churn_Cleaned ch 
    ON c.CustomerID = ch.CustomerID
WHERE DATEDIFF(DAY, lt.LastTransactionDate, GETDATE()) > 180
   OR ch.ChurnFlag = 1
ORDER BY DaysSinceLastTransaction DESC;

-- 2-Churn rate by Branch
SELECT 
    c.BranchID,
    COUNT(*) AS TotalCustomers,
    SUM(CAST(ch.ChurnFlag AS INT)) AS TotalChurned,
    ROUND(
        SUM(CAST(ch.ChurnFlag AS FLOAT)) * 100.0 
        / COUNT(*),
        2
    ) AS ChurnRate_Percentage
FROM Customers_Cleaned c
JOIN Churn_Cleaned ch 
    ON c.CustomerID = ch.CustomerID
GROUP BY c.BranchID
ORDER BY ChurnRate_Percentage DESC;

---3-Age Segmentation
---Add Age Group Column
ALTER TABLE Customers ADD AgeGroup VARCHAR(20);
UPDATE Customers
SET AgeGroup =
    CASE 
        WHEN Age < 30 THEN 'Young'
        WHEN Age BETWEEN 30 AND 50 THEN 'Middle'
        ELSE 'Senior'
    END;

--- Churn by Age Group
SELECT c.AgeGroup,
       COUNT(*) AS Total,
       SUM(CAST(ch.ChurnFlag AS INT)) AS Churned,
	   CAST(100.0 * SUM(CAST(ch.ChurnFlag AS INT)) / COUNT(*)
	         AS DECIMAL(5,2))
			 AS ChurnRate
FROM Customers c
JOIN Churn ch ON c.CustomerID = ch.CustomerID
GROUP BY c.AgeGroup;

---AgeGroup	Total	Churned     rate
---Senior	4719	968        20.51
---Young	1857	332        17.88
---Middle	3424	662        19.33

---4- Deposit Vs Withdrawal
SELECT 
    ch.CustomerID,
    SUM(CASE WHEN t.TransactionType = 'DEPOSIT' THEN t.Amount ELSE 0 END) AS TotalDeposits,
    SUM(CASE WHEN t.TransactionType = 'WITHDRAWAL' THEN t.Amount ELSE 0 END) AS TotalWithdrawals,
    SUM(CASE 
            WHEN t.TransactionType = 'DEPOSIT' THEN t.Amount
            WHEN t.TransactionType = 'WITHDRAWAL' THEN -t.Amount
            ELSE 0
        END) AS NetFlow,
    ch.ChurnFlag
FROM Transactions_Cleaned t
INNER JOIN Churn_Cleaned ch 
    ON t.CustomerID = ch.CustomerID
GROUP BY ch.CustomerID, ch.ChurnFlag;

---5- Top 3 Transactions per Customer
WITH RankedTransactions AS (
    SELECT 
        CustomerID,
        Amount,
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID
            ORDER BY Amount DESC
        ) AS rn
    FROM Transactions_Cleaned
)
SELECT *
FROM RankedTransactions
WHERE rn <= 3
ORDER BY CustomerID, Amount DESC;


-- 6 Cumulative Transaction Amount per Customer

SELECT
    CustomerID,
    YEAR(TransactionDate)  AS TranYear,
    MONTH(TransactionDate) AS TranMonth,
    TransactionDate,
    Amount,
    SUM(Amount) OVER (
        PARTITION BY CustomerID
        ORDER BY TransactionDate
    ) AS CumulativeAmount
FROM Transactions_Cleaned
ORDER BY CustomerID, TransactionDate;


-- 7) Churn Customers with Above-Average Deposits

WITH AvgDeposit AS (
    SELECT AVG(CAST(Amount AS FLOAT)) AS AvgDepositAmount
    FROM Transactions_Cleaned
    WHERE TransactionType = 'DEPOSIT'
)
SELECT
    t.CustomerID,
    SUM(t.Amount) AS TotalDeposits
FROM Transactions_Cleaned t
INNER JOIN Churn_Cleaned ch
    ON ch.CustomerID = t.CustomerID
CROSS JOIN AvgDeposit a
WHERE t.TransactionType = 'DEPOSIT'
  AND ch.ChurnFlag = 1
GROUP BY t.CustomerID, a.AvgDepositAmount
HAVING SUM(t.Amount) > a.AvgDepositAmount
ORDER BY TotalDeposits DESC;


--8- Churn Customers with < 3 Transactions in Last 6 Months
SELECT
    t.CustomerID,
    COUNT(*) AS TransCount
FROM Transactions_Cleaned t
INNER JOIN Churn_Cleaned ch
    ON ch.CustomerID = t.CustomerID
WHERE ch.ChurnFlag = 1
  AND t.TransactionDate >= DATEADD(MONTH, -6, CAST(GETDATE() AS DATE))
GROUP BY t.CustomerID
HAVING COUNT(*) < 3
ORDER BY TransCount ASC, t.CustomerID;

-- 9- Branches with Highest Churn and Average Transactions

WITH BranchStats AS (
    SELECT
        c.BranchID,
        COUNT(*) AS TotalCustomers,
        SUM(CAST(ch.ChurnFlag AS INT)) AS TotalChurned,
        ROUND(SUM(CAST(ch.ChurnFlag AS FLOAT)) * 100.0 / COUNT(*), 2) AS ChurnRatePercentage
    FROM Customers_Cleaned c
    INNER JOIN Churn_Cleaned ch
        ON ch.CustomerID = c.CustomerID
    GROUP BY c.BranchID
),
BranchTransactions AS (
    SELECT
        c.BranchID,
        AVG(CAST(x.TransCount AS FLOAT)) AS AvgTransactionsPerCustomer
    FROM Customers_Cleaned c
    LEFT JOIN (
        SELECT CustomerID, COUNT(*) AS TransCount
        FROM Transactions_Cleaned
        GROUP BY CustomerID
    ) x
        ON x.CustomerID = c.CustomerID
    GROUP BY c.BranchID
)
SELECT
    bs.BranchID,
    bs.TotalCustomers,
    bs.TotalChurned,
    bs.ChurnRatePercentage,
    bt.AvgTransactionsPerCustomer
FROM BranchStats bs
INNER JOIN BranchTransactions bt
    ON bt.BranchID = bs.BranchID
ORDER BY bs.ChurnRatePercentage DESC;

USE BankChurnDB;
GO

 ----CUSTOMER BEHAVIOR METRICS

  -----1. TOTAL SPEND PER CUSTOMER
DROP TABLE IF EXISTS ##CustomerSpend;

SELECT 
    CustomerID,
    SUM(Amount) AS TotalSpend
INTO ##CustomerSpend
FROM Transactions
GROUP BY CustomerID;

 ----2. TRANSACTION FREQUENCY
DROP TABLE IF EXISTS ##CustomerFrequency;

SELECT 
    CustomerID,
    COUNT(*) AS TransactionCount
INTO ##CustomerFrequency
FROM Transactions
GROUP BY CustomerID;

 ---3. COMBINE BEHAVIORAL FEATURES
DROP TABLE IF EXISTS ##CustomerFeatures;

SELECT 
    c.CustomerID,
    cs.TotalSpend,
    cf.TransactionCount,
    ch.ChurnFlag
INTO ##CustomerFeatures
FROM Customers_Cleaned c
LEFT JOIN ##CustomerSpend cs 
    ON c.CustomerID = cs.CustomerID
LEFT JOIN ##CustomerFrequency cf 
    ON c.CustomerID = cf.CustomerID
LEFT JOIN Churn ch 
    ON c.CustomerID = ch.CustomerID;

----4. HIGH RISK SEGMENT
SELECT *
FROM ##CustomerFeatures
WHERE TotalSpend < 1000
  AND TransactionCount < 5
  AND ChurnFlag = 1;


 ----5.EXECUTIVE SUMMARY (AgeGroup + AccountType)
SELECT 
    c.AgeGroup,
    c.AccountType,
    COUNT(*) AS TotalCustomers,
    SUM(CAST(ch.ChurnFlag AS INT)) AS ChurnedCustomers,
    ROUND(100.0 * SUM(CAST(ch.ChurnFlag AS INT)) / COUNT(*),2) AS ChurnRate
FROM Customers_Cleaned c
JOIN Churn ch 
    ON c.CustomerID = ch.CustomerID
GROUP BY c.AgeGroup, c.AccountType
ORDER BY ChurnRate DESC;


---- 6. RFM ANALYSIS
DROP TABLE IF EXISTS RFM_Table;

WITH RFM AS (
    SELECT 
        t.CustomerID,
        DATEDIFF(DAY, MAX(t.TransactionDate),
            (SELECT MAX(TransactionDate) FROM Transactions_Cleaned)
        ) AS Recency,
        COUNT(t.TransactionID) AS Frequency,
        SUM(t.Amount) AS Monetary
    FROM Transactions t
    GROUP BY t.CustomerID
)
SELECT * INTO RFM_Table FROM RFM;

select * from RFM_Table

---7️. ASSIGN RFM SCORES
DROP TABLE IF EXISTS ##RFM_Scored;

SELECT *,
       NTILE(5) OVER (ORDER BY Recency DESC) AS R_Score,
       NTILE(5) OVER (ORDER BY Frequency) AS F_Score,
       NTILE(5) OVER (ORDER BY Monetary) AS M_Score
INTO ##RFM_Scored
FROM RFM_Table;

select * from  ##RFM_Scored
  ---8️. CREATE RFM SEGMENT LABEL

ALTER TABLE ##RFM_Scored ADD RFM_Segment VARCHAR(20);

UPDATE ##RFM_Scored
SET RFM_Segment =
    CASE 
        WHEN R_Score >=4 AND F_Score >=4 AND M_Score >=4 THEN 'Champions'
        WHEN R_Score >=3 AND F_Score >=3 THEN 'Loyal'
        WHEN R_Score =1 AND F_Score <=2 THEN 'At Risk'
        ELSE 'Regular'
    END;

 ----9️. RFM SEGMENT DISTRIBUTION

SELECT 
    RFM_Segment,
    COUNT(*) AS CustomerCount
FROM ##RFM_Scored
GROUP BY RFM_Segment
ORDER BY CustomerCount DESC;


 ----10. CHURN RISK SCORING
--------------------------------------------------------- */
DROP TABLE IF EXISTS ##CustomerRisk;

SELECT 
    r.CustomerID,
    r.Recency,
    r.Frequency,
    r.Monetary,
    ch.ChurnFlag,
    CASE 
        WHEN r.Recency > 180 AND r.Frequency < 5 THEN 'High Risk'
        WHEN r.Recency BETWEEN 90 AND 180 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS RiskLevel
INTO ##CustomerRisk
FROM RFM_Table r
JOIN Churn ch 
    ON r.CustomerID = ch.CustomerID;


 ---11. EVALUATE RISK MODEL
SELECT 
    RiskLevel,
    COUNT(*) AS Customers,
    SUM(CAST(ChurnFlag AS INT)) AS ActualChurned
FROM ##CustomerRisk
GROUP BY RiskLevel;

--- Customer Lifetime Value (CLV)
SELECT 
    c.CustomerID,
    SUM(t.Amount) AS LifetimeValue,
    DATEDIFF(MONTH, MIN(c.JoinDate), GETDATE()) AS TenureMonths,
    SUM(t.Amount) / 
        NULLIF(DATEDIFF(MONTH, MIN(c.JoinDate), GETDATE()),0) AS AvgMonthlyValue
FROM Customers c
JOIN Transactions t
    ON c.CustomerID = t.CustomerID
GROUP BY c.CustomerID;

USE BankChurnDB;
GO

/*===========================================================
  FEATURE ENGINEERING + MASTER TABLE (
===========================================================*/

-- 1) CUSTOMER TRANSACTION SUMMARY 

IF OBJECT_ID('Customer_Transaction_Summary', 'U') IS NOT NULL
    DROP TABLE Customer_Transaction_Summary;
GO

SELECT 
    t.CustomerID,

    COUNT(*) AS TotalTransactions,
    SUM(t.Amount) AS TotalSpend,
    AVG(t.Amount) AS AvgTransactionAmount,

    MAX(t.TransactionDate) AS LastTransactionDate,
    MIN(t.TransactionDate) AS FirstTransactionDate,

    -- Recencey
    DATEDIFF(DAY, MAX(t.TransactionDate),
        (SELECT MAX(TransactionDate) FROM Transactions_Cleaned)
    ) AS RecencyDays,

	---Active Month
    DATEDIFF(MONTH, MIN(t.TransactionDate), MAX(t.TransactionDate)) + 1 AS ActiveMonths,

	----Avg Monthly Frequency
    COUNT(*) * 1.0 /
        NULLIF(DATEDIFF(MONTH, MIN(t.TransactionDate), MAX(t.TransactionDate)) + 1, 0)
        AS AvgMonthlyFrequency

INTO Customer_Transaction_Summary
FROM Transactions t
GROUP BY t.CustomerID;
GO

-- 2) DAYS INACTIVE 

IF OBJECT_ID('Customer_DaysInactive', 'U') IS NOT NULL
    DROP TABLE Customer_DaysInactive;
GO
WITH RefDate AS (
    SELECT
        c.CustomerID,
        CASE 
            WHEN ch.ChurnFlag = 1 AND ch.ChurnDate IS NOT NULL THEN CAST(ch.ChurnDate AS DATE)
            ELSE (SELECT MAX(TransactionDate) FROM Transactions)
        END AS ReferenceDate
    FROM Customers c
    LEFT JOIN Churn ch
        ON ch.CustomerID = c.CustomerID
),
LastTxn AS (
    SELECT
        r.CustomerID,
        MAX(t.TransactionDate) AS LastTxnUpToRef
    FROM RefDate r
    LEFT JOIN Transactions t
        ON t.CustomerID = r.CustomerID
       AND t.TransactionDate <= r.ReferenceDate
    GROUP BY r.CustomerID
)
SELECT
    r.CustomerID,
    CASE 
        WHEN l.LastTxnUpToRef IS NULL THEN NULL
        ELSE DATEDIFF(DAY, l.LastTxnUpToRef, r.ReferenceDate)
    END AS DaysInactive
INTO Customer_DaysInactive
FROM RefDate r
LEFT JOIN LastTxn l
    ON l.CustomerID = r.CustomerID;
GO

-- 3) MASTER TABLE 
IF OBJECT_ID('Customer_Churn_Master', 'U') IS NOT NULL
    DROP TABLE Customer_Churn_Master;
GO

SELECT 
    c.CustomerID,
    c.Age,
    c.Gender,
    c.AccountType,
    c.AgeGroup,
	c.BranchID,
    c.JoinDate,

    -- TenureMonths 
    DATEDIFF(MONTH, c.JoinDate,
        (SELECT MAX(TransactionDate) FROM Transactions)
    ) AS TenureMonths,

    ts.TotalTransactions,
    ts.TotalSpend,
    ts.AvgTransactionAmount,
    ts.RecencyDays,
    ts.ActiveMonths,
    ts.AvgMonthlyFrequency,

    di.DaysInactive,

    ch.ChurnFlag,
    ch.ChurnDate

INTO Customer_Churn_Master
FROM Customers c
LEFT JOIN Customer_Transaction_Summary ts
    ON c.CustomerID = ts.CustomerID
LEFT JOIN Customer_DaysInactive di
    ON c.CustomerID = di.CustomerID
LEFT JOIN Churn ch
    ON c.CustomerID = ch.CustomerID;
GO


-- 4) HANDLE NULLS 
UPDATE Customer_Churn_Master
SET 
    TotalTransactions   = ISNULL(TotalTransactions, 0),
    TotalSpend          = ISNULL(TotalSpend, 0),
    AvgTransactionAmount= ISNULL(AvgTransactionAmount, 0),
    RecencyDays         = ISNULL(RecencyDays, 9999),
    ActiveMonths        = ISNULL(ActiveMonths, 0),
    AvgMonthlyFrequency = ISNULL(AvgMonthlyFrequency, 0),
    -- if DaysInactive is missing, use TenureMonths as a fallback 
    DaysInactive        = ISNULL(DaysInactive, TenureMonths);
GO


-- 5) QUICK VALIDATION
SELECT COUNT(*) AS MasterRows FROM Customer_Churn_Master;

SELECT 
    SUM(CASE WHEN ChurnFlag IS NULL THEN 1 ELSE 0 END) AS MissingChurnFlag,
    SUM(CASE WHEN TotalTransactions = 0 THEN 1 ELSE 0 END) AS ZeroTxnCustomers,
    SUM(CASE WHEN DaysInactive < 0 THEN 1 ELSE 0 END) AS NegativeDaysInactive
FROM Customer_Churn_Master;
GO 

SELECT *
FROM Customer_Churn_Master
ORDER BY CustomerID




