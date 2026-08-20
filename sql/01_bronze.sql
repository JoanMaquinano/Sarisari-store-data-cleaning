-- ============================================================
-- BRONZE LAYER
-- Raw Data Ingestion and Data Quality Assessment
-- ============================================================

USE CATALOG workspace;
USE SCHEMA sari_sari_pipeline;

-- ============================================================
-- CREATE RAW TABLE
-- ============================================================

CREATE OR REPLACE TABLE sari_sari_transactions_raw AS
SELECT *
FROM workspace.d4_indiv.bronze_sarisari;

-- ============================================================
-- DATA PROFILING
-- ============================================================

SELECT COUNT(*) AS total_records
FROM sari_sari_transactions_raw;

-- ============================================================
-- TRANSACTION_ID
-- ============================================================

SELECT
    Transaction_ID,
    COUNT(*) AS record_count
FROM sari_sari_transactions_raw
GROUP BY Transaction_ID
HAVING COUNT(*) > 1;

-- ============================================================
-- DATE
-- ============================================================

SELECT DISTINCT Date
FROM sari_sari_transactions_raw
ORDER BY Date;

SELECT Date
FROM sari_sari_transactions_raw
WHERE Date LIKE '%/%';

SELECT
    MIN(Date) AS earliest_date,
    MAX(Date) AS latest_date
FROM sari_sari_transactions_raw;

-- ============================================================
-- ITEM
-- ============================================================

SELECT COUNT(*) AS missing_items
FROM sari_sari_transactions_raw
WHERE Item IS NULL
   OR TRIM(Item) = '';

SELECT *
FROM sari_sari_transactions_raw
WHERE Item IS NULL
   OR TRIM(Item) = '';

SELECT
    Unit_Price,
    COUNT(DISTINCT Item) AS distinct_items
FROM sari_sari_transactions_raw
WHERE Item IS NOT NULL
GROUP BY Unit_Price
HAVING COUNT(DISTINCT Item) > 1
ORDER BY distinct_items DESC;

-- ============================================================
-- QUANTITY
-- ============================================================

SELECT
    Quantity,
    COUNT(*) AS record_count
FROM sari_sari_transactions_raw
GROUP BY Quantity
ORDER BY Quantity;

SELECT *
FROM sari_sari_transactions_raw
WHERE Quantity = '353';

SELECT *
FROM sari_sari_transactions_raw
WHERE Quantity = '353'
  AND (
        Unit_Price IS NULL
        OR Unit_Price <= 0
      );

-- ============================================================
-- UNIT PRICE
-- ============================================================

SELECT COUNT(*) AS missing_unit_price
FROM sari_sari_transactions_raw
WHERE Unit_Price IS NULL;

SELECT *
FROM sari_sari_transactions_raw
WHERE Unit_Price < 0;

SELECT
    Item,
    COUNT(DISTINCT ROUND(Unit_Price,2)) AS unique_prices,
    MIN(Unit_Price) AS min_price,
    MAX(Unit_Price) AS max_price
FROM sari_sari_transactions_raw
WHERE Unit_Price IS NOT NULL
GROUP BY Item
ORDER BY unique_prices DESC;

SELECT *
FROM sari_sari_transactions_raw
WHERE Unit_Price < 0
   OR Unit_Price = 895.74346145472623;

-- ============================================================
-- TOTAL AMOUNT
-- ============================================================

SELECT
    Transaction_ID,
    Quantity,
    Unit_Price,
    Total_Amount
FROM sari_sari_transactions_raw
WHERE Total_Amount < 0;

SELECT
    Transaction_ID,
    Quantity,
    Unit_Price,
    Total_Amount
FROM sari_sari_transactions_raw
WHERE Quantity IS NOT NULL
  AND Unit_Price IS NOT NULL
  AND Total_Amount IS NOT NULL
  AND TRY_CAST(Quantity AS DOUBLE) IS NOT NULL
  AND ROUND(
        TRY_CAST(Quantity AS DOUBLE) * Unit_Price,
        2
      ) <> ROUND(Total_Amount, 2);

-- ============================================================
-- PAYMENT METHOD
-- ============================================================

SELECT
    Payment_Method,
    COUNT(*) AS record_count
FROM sari_sari_transactions_raw
GROUP BY Payment_Method
ORDER BY Payment_Method;

-- ============================================================
-- CUSTOMER TYPE
-- ============================================================

SELECT
    Customer_Type,
    COUNT(*) AS record_count
FROM sari_sari_transactions_raw
GROUP BY Customer_Type
ORDER BY Customer_Type;
