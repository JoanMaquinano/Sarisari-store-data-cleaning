-- ============================================================
-- SILVER LAYER
-- Clean, Standardize, and Validate Data
-- Output: sari_sari_transactions_clean
-- ============================================================

USE CATALOG workspace;
USE SCHEMA sari_sari_pipeline;

-- ============================================================
-- STEP 1: REMOVE EXACT DUPLICATES
-- ============================================================

CREATE OR REPLACE TEMP VIEW deduplicated_sales AS
SELECT DISTINCT *
FROM sari_sari_transactions_raw;

-- ============================================================
-- STEP 2: CLEAN QUANTITY
-- - Convert text values
-- - Correct invalid placeholder values
-- ============================================================

CREATE OR REPLACE TEMP VIEW quantity_cleaned AS
SELECT
    Transaction_ID,
    Date,
    Item,

    CASE
        WHEN Quantity = 'two'
            THEN 2

        WHEN Quantity = '353'
             AND Unit_Price > 0
            THEN ROUND(Total_Amount / Unit_Price)

        WHEN Quantity = '353'
             AND (Unit_Price IS NULL OR Unit_Price <= 0)
            THEN NULL

        ELSE Quantity
    END AS Quantity,

    Unit_Price,
    Total_Amount,
    Payment_Method,
    Customer_Type

FROM deduplicated_sales;

-- ============================================================
-- STEP 3: RECOVER MISSING UNIT PRICES
-- Unit_Price = Total_Amount / Quantity
-- ============================================================

CREATE OR REPLACE TEMP VIEW unit_price_recovered AS
SELECT
    Transaction_ID,
    Date,
    Item,
    Quantity,

    CASE
        WHEN Unit_Price IS NULL
             AND Quantity IS NOT NULL
             AND Quantity > 0
            THEN ROUND(Total_Amount / Quantity, 2)

        ELSE Unit_Price
    END AS Unit_Price,

    Total_Amount,
    Payment_Method,
    Customer_Type

FROM quantity_cleaned;

-- ============================================================
-- STEP 4: FIX RECOVERABLE NEGATIVE UNIT PRICES
-- ============================================================

CREATE OR REPLACE TEMP VIEW unit_price_corrected AS
SELECT
    Transaction_ID,
    Date,
    Item,
    Quantity,

    CASE
        WHEN Unit_Price < 0
             AND Quantity IS NOT NULL
             AND Quantity > 0
            THEN ROUND(Total_Amount / Quantity, 2)

        WHEN Unit_Price < 0
             AND (Quantity IS NULL OR Quantity <= 0)
            THEN NULL

        ELSE Unit_Price
    END AS Unit_Price,

    Total_Amount,
    Payment_Method,
    Customer_Type

FROM unit_price_recovered;

-- ============================================================
-- STEP 5: REMOVE PLACEHOLDER UNIT PRICE VALUES
-- Placeholder Value: 895.74346145472623
-- ============================================================

CREATE OR REPLACE TEMP VIEW placeholder_price_fixed AS
SELECT
    Transaction_ID,
    Date,
    Item,
    Quantity,

    CASE
        WHEN Unit_Price = 895.74346145472623
             AND Quantity IS NOT NULL
             AND Quantity > 0
            THEN ROUND(Total_Amount / Quantity, 2)

        WHEN Unit_Price = 895.74346145472623
             AND (Quantity IS NULL OR Quantity <= 0)
            THEN NULL

        ELSE Unit_Price
    END AS Unit_Price,

    Total_Amount,
    Payment_Method,
    Customer_Type

FROM unit_price_corrected;

-- ============================================================
-- STEP 6: CORRECT QUANTITY MISMATCHES
-- Total_Amount = Quantity × Unit_Price
-- ============================================================

CREATE OR REPLACE TEMP VIEW quantity_mismatch_corrected AS
SELECT
    Transaction_ID,
    Date,
    Item,

    CASE
        WHEN Quantity IS NOT NULL
             AND Unit_Price IS NOT NULL
             AND Total_Amount IS NOT NULL
             AND Total_Amount > 0
             AND Unit_Price > 0
             AND ROUND(Quantity * Unit_Price, 2)
                 <> ROUND(Total_Amount, 2)
            THEN CAST(ROUND(Total_Amount / Unit_Price, 0) AS INT)

        ELSE Quantity
    END AS Quantity,

    Unit_Price,
    Total_Amount,
    Payment_Method,
    Customer_Type

FROM placeholder_price_fixed;

-- ============================================================
-- STEP 7: RECOVER MISSING QUANTITIES
-- Quantity = Total_Amount / Unit_Price
-- ============================================================

CREATE OR REPLACE TEMP VIEW quantity_recovered AS
SELECT
    Transaction_ID,
    Date,
    Item,

    CASE
        WHEN Quantity IS NULL
             AND Unit_Price IS NOT NULL
             AND Total_Amount IS NOT NULL
             AND Unit_Price > 0
             AND ROUND(Total_Amount / Unit_Price, 0)
                 = Total_Amount / Unit_Price
            THEN CAST(ROUND(Total_Amount / Unit_Price, 0) AS INT)

        ELSE Quantity
    END AS Quantity,

    Unit_Price,
    Total_Amount,
    Payment_Method,
    Customer_Type

FROM quantity_mismatch_corrected;

-- ============================================================
-- STEP 8: STANDARDIZE PAYMENT METHOD
-- ============================================================

CREATE OR REPLACE TEMP VIEW payment_method_cleaned AS
SELECT
    Transaction_ID,
    Date,
    Item,
    Quantity,
    Unit_Price,
    Total_Amount,

    CASE
        WHEN LOWER(Payment_Method) = 'cashh'
            THEN 'Cash'
        ELSE Payment_Method
    END AS Payment_Method,

    Customer_Type

FROM quantity_recovered;

-- ============================================================
-- STEP 9: CLEAN CUSTOMER TYPE
-- ============================================================

CREATE OR REPLACE TEMP VIEW customer_type_cleaned AS
SELECT
    Transaction_ID,
    Date,
    Item,
    Quantity,
    Unit_Price,
    Total_Amount,
    Payment_Method,

    CASE
        WHEN Customer_Type = '123'
            THEN NULL
        ELSE Customer_Type
    END AS Customer_Type

FROM payment_method_cleaned;

-- ============================================================
-- STEP 10: CREATE FINAL SILVER TABLE
-- ============================================================

CREATE OR REPLACE TABLE sari_sari_transactions_clean AS
SELECT
    CAST(Transaction_ID AS INT) AS Transaction_ID,
    CAST(Date AS DATE) AS Date,
    Item,
    CAST(Quantity AS INT) AS Quantity,
    CAST(Unit_Price AS DECIMAL(10,2)) AS Unit_Price,
    CAST(Total_Amount AS DECIMAL(10,2)) AS Total_Amount,
    Payment_Method,
    Customer_Type
FROM customer_type_cleaned;

-- ============================================================
-- STEP 11: VALIDATE FINAL OUTPUT
-- ============================================================

-- Validate row count

SELECT
    COUNT(*) AS final_row_count
FROM sari_sari_transactions_clean;

-- Validate schema and data types

DESCRIBE sari_sari_transactions_clean;

-- Review remaining missing values

SELECT
    COUNT(*) AS total_records,
    COUNT(CASE WHEN Item IS NULL THEN 1 END) AS missing_items,
    COUNT(CASE WHEN Quantity IS NULL THEN 1 END) AS missing_quantities,
    COUNT(CASE WHEN Unit_Price IS NULL THEN 1 END) AS missing_unit_prices,
    COUNT(CASE WHEN Payment_Method IS NULL THEN 1 END) AS missing_payment_methods,
    COUNT(CASE WHEN Customer_Type IS NULL THEN 1 END) AS missing_customer_types
FROM sari_sari_transactions_clean;

-- Review remaining negative values retained for business review

SELECT
    SUM(CASE WHEN Unit_Price < 0 THEN 1 ELSE 0 END) AS negative_unit_price,
    SUM(CASE WHEN Total_Amount < 0 THEN 1 ELSE 0 END) AS negative_total_amount
FROM sari_sari_transactions_clean;

-- Review sample records

SELECT *
FROM sari_sari_transactions_clean
LIMIT 20;