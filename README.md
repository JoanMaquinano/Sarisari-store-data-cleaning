# SQL Data Clean-up: Building the Silver Layer of Medallion Architecture on a Dirty Sari-sari store Dataset Using SQL

## 📌 Project Overview

This project focuses on transforming raw sales data into a clean, reliable, and analysis-ready dataset using SQL in Databricks.

The workflow follows common data engineering practices used in the Silver Layer of a medallion architecture, where raw data is cleaned, standardized, validated, and prepared for downstream reporting and analytics.

## 🎯 Objective

Create a clean and consistent table called:

`silver.sarisari_sales`

The final table should contain high-quality data that can be trusted for business analysis and reporting.

## ✅ Expected Outcome

A dataset that is:

- Complete and reliable
- Free of major data quality issues
- Consistent in formatting
- Stored using proper data types
- Free of unnecessary duplicates
- Ready for analysis and reporting

---

# Project Workflow

## 1. Inspect the Raw Data for Quality Problems

### Goal

Identify data quality issues that may affect reporting, analysis, and downstream transformations through manual checking in Excel.

### Findings

| Field | Issue |
|---------|---------|
| Transaction_ID | No issues detected |
| Date | No issues detected |
| Item | Missing values |
| Quantity | Invalid quantity values |
| Quantity | Quantities stored as text (e.g., `"two"`) |
| Unit_Price | Missing values |
| Unit_Price | Negative values |
| Unit_Price | Different prices for the same item |
| Total_Amount | Negative values |
| Total_Amount | Total amount does not match Unit Price × Quantity |
| Payment_Method | Typographical errors |
| Payment_Method | Invalid payment methods |
| Customer_Type | Missing values |
| Customer_Type | Invalid customer type values (`123`) |
| Customer_Type | Unapproved customer category (`Neighbor`) |

## 2. Fix Values by Column

### Goal

Correct incomplete, invalid, and inaccurate data identified during the data profiling phase to improve overall data quality and reliability.

#### Create Silver Layer

Created a temporary Silver-layer view from the Bronze table. This view serves as the working dataset for all subsequent cleaning and validation activities while preserving the original Bronze data.

```sql
-- Creating temporary silver layer
CREATE TEMP TABLE silver_sarisari AS
SELECT *
FROM workspace.d4_indiv.bronze_sarisari;
```

#### Transaction_ID

| Field | Issue |
|---------|---------|
| Transaction_ID | No issues detected |

##### Checking

```sql
-- Checking for duplicate entries
SELECT
Transaction_ID,
COUNT(*) AS record_count
FROM silver_sarisari
GROUP BY Transaction_ID
HAVING COUNT(*) > 1;
```

Identified 100 repeated `Transaction_ID` values. Review of sample records showed that many of the duplicated rows were exact copies across all columns and could be removed through deduplication.

##### Cleaning (Removing duplicates)
```sql
-- Before cleaning
SELECT COUNT(*) AS before_count
FROM workspace.d4_indiv.bronze_sarisari;

-- Remove duplicate records using DISTINCT
CREATE OR REPLACE TEMPORARY TABLE silver_sarisari AS
SELECT DISTINCT *
FROM workspace.d4_indiv.bronze_sarisari;

-- After cleaning
SELECT COUNT(*) AS after_count
FROM silver_sarisari;
```

##### Results

| Metric | Count |
|---------|------:|
| Before Cleaning | 5,100 |
| After Cleaning | 5,006 |

- Removed 94 exact duplicate records.
- Retained one copy of each duplicated record.
- Repeated Transaction_ID values with different values associated with transaction reversals or adjustments were retained.

#### Date
| Field | Issue |
|---------|---------|
| Date | No issues detected |
##### Checking
```sql
-- Ordering by date
SELECT DISTINCT Date
FROM silver_sarisari
ORDER BY Date;
-- Checking for differently formatted dates
SELECT Date
FROM silver_sarisari
WHERE Date LIKE '%/%';
-- Optional analysis to check scope of transactions
SELECT 
    MIN(Date) AS earliest_date,
    MAX(Date) AS latest_date
FROM silver_sarisari;
```

##### Results
Through this, it was confirmed that all dates were stored in the `YYYY-MM-DD` format, no inconsistent date formats were identified, and no invalid date values were observed.

The following are the observed earliest and latest date on the transactions.
| earliest_date | latest_date |
|----------------|------------:|
| 2022-08-21	| 2026-04-03 |

#### Item
| Field | Issue |
|---------|---------|
| Item | Missing values |
##### Checking
```sql
-- Checking for missing items
SELECT COUNT(*) AS missing_items
FROM silver_sarisari
WHERE Item IS NULL
OR TRIM(Item) = '';
```

From here, we confirmed there are 250 missing Item values.

```sql
-- Checking for patterns in null values
SELECT *
FROM silver_sarisari
WHERE Item IS NULL
OR TRIM(Item) = '';

-- Checking if Unit_Price uniquely identifies an item
SELECT
Unit_Price,
COUNT(DISTINCT Item) AS distinct_items
FROM silver_sarisari
WHERE Item IS NOT NULL
GROUP BY Unit_Price
HAVING COUNT(DISTINCT Item) > 1
ORDER BY distinct_items DESC;
```

After checking the identified 250 missing values, it was observed that null Item frequently overlaps with other data quality issues like missing values in columns quantity, unit price, payment method, and customer type. This is a strong sign that null Item is part of broader incomplete records rather than an isolated issue. There is no found pattern from these values so far. Null records also occur across years.


##### Results
As the missing values cannot be accurately derived, imputing values would introduce assumptions and potentially reduce data quality. 

Since the affected records also represent less than 5% of the dataset and can be retained for analysis, ** the missing Item values were retained as NULL.
**

#### Quantity
| Field | Issue |
|---------|---------|
| Quantity | Invalid quantity values |
| Quantity | Quantities stored as text (e.g., `"two"`) |
##### Checking
```sql
-- Checking for unexpected values
SELECT
Quantity,
COUNT(*) AS record_count
FROM silver_sarisari
GROUP BY Quantity
ORDER BY Quantity;
```

This query yields the following values:
| Quantity | record_count |
|----------|--------------|
| null     | 242          |
| 1        | 899          |
| 2        | 975          |
| 3        | 919          |
| 353      | 50           |
| 4        | 925          |
| 5        | 896          |
| two      | 100          |

##### Cleaning erroneous values
```sql
-- Checking the 353 values
SELECT *
FROM silver_sarisari
WHERE Quantity = '353';
-- Analyzing NULL and negative Unit_Price values under the 353 quantities
SELECT *
FROM silver_sarisari
WHERE Quantity = '353'
AND (
Unit_Price IS NULL
OR Unit_Price <= 0
);
```
Based on the resulting tables, we can assume that 353 is not a correctly encoded value. We can derive the correct quantity of the "353" data.

We also found **3 exception records** among the 50 rows with `Quantity = 353`. Two has `NULL` Unit_Price values and one contained a negative Unit_Price values: 

| Transaction_ID | Date       | Item             | Quantity | Unit_Price | Total_Amount | Payment_Method | Customer_Type |
|---------------:|------------|------------------|----------|------------|-------------:|---------------|--------------|
| 3747 | 2023-11-30 | Candies | 353 | NULL | 175.35 | Cash | Regular |
| 1251 | 2023-01-27 | Canned Sardines | 353 | NULL | 76.83 | Cash | Walk-in |
| 159 | 2025-01-17 | Soy Sauce | 353 | -50.00 | 170.88 | GCash | Regular |

Because the true unit price could not be determined with confidence, Quantity was set to NULL at this stage and the records were retained for transparency.

The rest of the values with Quantity = 343 was recalculated using:

Quantity = Total_Amount / Unit_Price

```sql
-- Change 'two' to 2, derive values using the formula for positive values, enter negative values as NULL, and recalculate those that can be derived
CREATE OR REPLACE TEMP VIEW silver_sarisari_v2 AS
SELECT
Transaction_ID,
Date,
Item,

CASE
WHEN Quantity = 'two' THEN 2
WHEN Quantity = '353' AND Unit_Price > 0
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
FROM silver_sarisari;

SELECT
Quantity,
COUNT(*) AS record_count
FROM silver_sarisari_v2
GROUP BY Quantity
ORDER BY Quantity;

-- Validating results
SELECT
Quantity,
COUNT(*) AS record_count
FROM silver_sarisari_v2
GROUP BY Quantity
ORDER BY Quantity;
```

##### Results
The text value 'two' was successfully converted to 2, and the invalid quantity value 353 was replaced using the calculated quantity (Total_Amount / Unit_Price) where possible. Three records with Quantity = 353 could not be corrected because Unit_Price was either NULL or negative, so these were set to NULL. As a result, the number of missing quantities increased slightly from 242 to 245. The dataset now contains only valid quantity values ranging from 1 to 5, along with NULL where correction was not possible.

| Quantity | Record Count |
|----------|------------:|
| NULL | 245 |
| 1 | 905 |
| 2 | 1082 |
| 3 | 932 |
| 4 | 937 |
| 5 | 905 |

#### Unit_Price
| Field | Issue |
|---------|---------|
| Unit_Price | Missing values |
| Unit_Price | Negative values |
| Unit_Price | Different prices for the same item |
##### Checking for null values
```sql
-- Check number of null values
SELECT COUNT(*) AS missing_unit_price
FROM silver_sarisari_v2
WHERE Unit_Price IS NULL;

-- Check for recoverable missing Unit_Price
SELECT COUNT(*) AS recoverable
FROM silver_sarisari_v2
WHERE Unit_Price IS NULL
  AND Quantity IS NOT NULL
  AND Quantity > 0;
```
There are 242 starting null values, 230 of which can be recovered.

##### Cleaning by correcting recoverable prices
```sql
-- Correct recoverable prices
CREATE OR REPLACE TEMP VIEW silver_sarisari_v3 AS
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
FROM silver_sarisari_v2;

-- Validate remaining missing Unit_Price values
SELECT COUNT(*) AS missing_unit_price_after_cleaning
FROM silver_sarisari_v3
WHERE Unit_Price IS NULL;
```

##### Results
We were able to correct the 230 null values that had unit prices that can be derived by using the formula:
Unit_Price = Total_Amount ÷ Quantity

Twelve null values remain which does not contain enough data to be corrected.

##### Checking negative values
```sql
-- Check negative values
SELECT *
FROM silver_sarisari_v3
WHERE Unit_Price < 0;
```

There are 50 negative values under unit price.

##### Cleaning negative values
```sql
-- Deal with the recoverable values
CREATE OR REPLACE TEMP VIEW silver_sarisari_v4 AS
SELECT
Transaction_ID, Date,
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
FROM silver_sarisari_v3;

-- Check results
SELECT COUNT(*) AS negative_unit_price
FROM silver_sarisari_v4
WHERE Unit_Price < 0;
```

Three values remain unchanged.

```sql
-- Check the remaining negative values
SELECT
    Quantity,
    Unit_Price,
    Total_Amount,
    ROUND(Total_Amount / Quantity, 2) AS expected_unit_price
FROM silver_sarisari_v4
WHERE Unit_Price < 0;
```

Formula used to derive unit prices:

Unit_Price = Total_Amount ÷ Quantity


##### Results
We were able to correct the 50 negative values that had unit prices that can be derived. Three records remain with negative values. These have calculations that are mathematically correct. They were therefore left unchanged.

##### Checking inconsistent prices
```sql
-- Initial check for inconsistent prices
SELECT
    Item,
    COUNT(DISTINCT ROUND(Unit_Price, 2)) AS unique_prices,
    MIN(Unit_Price) AS min_price,
    MAX(Unit_Price) AS max_price
FROM silver_sarisari_v4
WHERE Unit_Price IS NOT NULL
GROUP BY Item
ORDER BY unique_prices DESC;
```

All products exhibited hundreds of unique prices, suggesting that price variation is an expected characteristic of the dataset rather than a data quality issue.

However, invalid values were identified, including negative prices and the repeated outlier value 895.74346145472623 across multiple unrelated items. The repeated Unit_Price value of 895.74346145472623 was identified across multiple unrelated items, including Bread, Rice, Soft Drinks, Candies, Soy Sauce

```sql
-- Checking repeated value
SELECT *
FROM silver_sarisari_v4
WHERE Unit_Price < 0
   OR Unit_Price = 895.74346145472623;
---Counting affected records
SELECT
    COUNT(*) AS records
FROM silver_sarisari_v4
WHERE Unit_Price = 895.74346145472623;
-- Counting recoverable values
SELECT
    COUNT(*) AS recoverable
FROM silver_sarisari_v4
WHERE Unit_Price = 895.74346145472623
  AND Quantity IS NOT NULL
  AND Quantity > 0;
```

##### Cleaning repeated unit_price
```sql
-- Fixing placeholder Unit_Price values
CREATE OR REPLACE TEMP VIEW silver_sarisari_v5 AS
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
FROM silver_sarisari_v4;

-- Validation
SELECT
    COUNT(*) AS records
FROM silver_sarisari_v5
WHERE Unit_Price = 895.74346145472623;

-- Validating all fixes for this column
SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN Unit_Price IS NULL THEN 1 ELSE 0 END) AS null_unit_price,
    SUM(CASE WHEN Unit_Price < 0 THEN 1 ELSE 0 END) AS negative_unit_price,
    SUM(CASE WHEN Unit_Price = 895.74346145472623 THEN 1 ELSE 0 END) AS placeholder_value,
    SUM(CASE WHEN Unit_Price = 0 THEN 1 ELSE 0 END) AS zero_unit_price
FROM silver_sarisari_v5;
```

##### Results
| Metric | Count |
|----------|------:|
| Total Records | 5,006 |
| Null Unit_Price | 22 |
| Negative Unit_Price | 4 |
| Placeholder Value (895.74346145472623) | 0 |
| Zero Unit_Price | 0 |

Four records contain negative Unit_Price values. Since the negative values are mathematically consistent with their corresponding Total_Amount values, there is insufficient evidence to determine whether they represent data-entry errors or legitimate reversal/refund transactions. The records were retained and flagged for business review rather than automatically corrected. 

The remaining 22 null values also have insufficient data for us to assume the true value.

---

#### Total_Amount
| Field | Issue |
|---------|---------|
| Total_Amount | Negative values |
| Total_Amount | Total amount does not match Unit Price × Quantity |

##### Checking negative values
```sql
-- Check records where Total_Amount is negative
SELECT Transaction_ID, Quantity, Unit_Price, Total_Amount
FROM silver_sarisari_v5
WHERE Total_Amount < 0
LIMIT 50;
```

Below are the observations from the query result:
- 49 records have negative Total amount values.
- Most rows have positive Quantity and Unit_Price, but the Total_Amount is negative.
- Three rows have negative Unit_Price as well (e.g., Transaction_ID 4645, 4739, and 25).
- Some records have missing `Quantity` values, making validation difficult.
- One record (Transaction_ID 2314) has both missing `Quantity` and `Unit_Price`, making it unrecoverable.
- The negative values are mathematically consistent with the transaction details, suggesting possible refunds, returns, reversals, or sign errors.

This tells us there are two root causes for negative totals. First it sign errors (the math is correct but the total is stored as negative). Second is bad inputs (negative or invalid Unit_Price, or missing values).

##### Cleaning negative values
```sql
-- Create v6 with cleaned Total_Amount (fix sign errors, nullify invalid cases)
-- Create v6 with cleaned Total_Amount (overwrite original, rounded to 2 decimals)
CREATE OR REPLACE TABLE silver_sarisari_v6 AS
SELECT 
    Transaction_ID,
    Date,
    Item,
    Quantity,
    Unit_Price,
    Payment_Method,
    Customer_Type,
    CASE
        -- Flip sign if math matches but total is negative
        WHEN Quantity IS NOT NULL 
             AND Unit_Price IS NOT NULL 
             AND ROUND(Quantity * Unit_Price, 2) = ABS(ROUND(Total_Amount, 2))
             AND Total_Amount < 0
        THEN ROUND(ABS(Total_Amount), 2)

        -- Nullify invalid cases
        WHEN Unit_Price < 0 THEN NULL
        WHEN Quantity IS NULL OR Unit_Price IS NULL THEN NULL
        WHEN Unit_Price = 895.7434614547262 THEN NULL

        -- Keep valid totals
        ELSE ROUND(Total_Amount, 2)
    END AS Total_Amount
FROM silver_sarisari_v5;

-- Validation query (check for remaining negatives or invalid unit prices)
SELECT *
FROM silver_sarisari_v6
WHERE Total_Amount < 0
   OR Unit_Price < 0;
```

##### Results

Four remaining records contain both negative `Unit_Price` and negative `Total_Amount`. However, all records remain mathematically consistent based on the relationship:

  Total_Amount = Quantity × Unit_Price

Because the dataset does not provide sufficient business context, it was not possible to determine whether these records represent refunds, returns, reversal transactions, or data-entry sign errors.

These records were retained and flagged for review rather than automatically corrected.

---
#### Payment_Method
| Field | Issue |
|---------|---------|
| Payment_Method | Typographical errors |
| Payment_Method | Invalid payment methods |

##### Checking for typos and erroneous values
```sql
SELECT
Payment_Method,
COUNT(*) AS record_count
FROM silver_sarisari_v6
GROUP BY Payment_Method
ORDER BY Payment_Method;
```
##### Cleaning typos and erroneous values
```sql
-- Cleaning typos
CREATE OR REPLACE TEMP VIEW silver_sarisari_v7 AS
SELECT
Transaction_ID,
Date,
Item,
Quantity,
Unit_Price,
Total_Amount,

CASE
WHEN Payment_Method = 'cashh' THEN 'Cash'
ELSE Payment_Method
END AS Payment_Method,

Customer_Type
FROM silver_sarisari_v5;

-- Validation
SELECT
Payment_Method,
COUNT(*) AS record_count
FROM silver_sarisari_v6
GROUP BY Payment_Method
ORDER BY Payment_Method;
```

| Payment_Method | Record Count |
|----------------|------------:|
| NULL | 246 |
| Cash | 1635 |
| GCash | 1534 |
| PayMaya | 1591 |

##### Results
We have corrected 100 records containing the value `cashh`, standardized all payment method names, and retained missing values as NULL. Payment_Method now contains only valid payment methods.

---

#### Customer_Type
| Field | Issue |
|---------|---------|
| Customer_Type | Invalid customer type values (`123`) |
| Customer_Type | Unapproved customer category (`Neighbor`) |

##### Checking values

```sql
SELECT
Customer_Type,
COUNT(*)
FROM workspace.d4_indiv.bronze_sarisari
GROUP BY Customer_Type
ORDER BY Customer_Type;
```

The `Customer_Type` column contains five unique values:

- `Walk-in`
- `Regular`
- `Neighbor`
- `123`
- `NULL`

`Walk-in` (1,620 records) and `Regular` (1,547 records) were identified as valid customer types.

`Neighbor` (1,582 records) and `123` (104 records) were identified as invalid values.

Additionally, 247 records contained missing (`NULL`) customer type values.

##### Cleaning

```sql
CREATE OR REPLACE TEMP VIEW silver_sarisari_v6 AS
SELECT
CASE
WHEN Customer_Type IN ('123', 'Neighbor')
THEN NULL
ELSE Customer_Type
END AS Customer_Type,
Date,
Item,
Payment_Method,
Quantity,
Total_Amount,
Transaction_ID,
Unit_Price
FROM workspace.d4_indiv.bronze_sarisari;

-- Validation
SELECT
Customer_Type,
COUNT(*)
FROM silver_sarisari
GROUP BY Customer_Type
ORDER BY Customer_Type;
```

A `CASE` statement was used to replace the invalid customer types `123` and `Neighbor` with `NULL`, while keeping valid values unchanged.

##### Results
After cleaning, the `Customer_Type` column contains only three values:

- `Regular` remains unchanged with **1,547 records**.
- `Walk-in` remains unchanged with **1,620 records**.
- `NULL` values increased from **247** to **1,933** records.

The increase in NULL values is expected because the invalid customer types `123` (104 records) and `Neighbor` (1,582 records) were converted to NULL.

As a result, all invalid customer type values were successfully removed, leaving only the approved customer categories (`Regular` and `Walk-in`) and records with missing customer type information.

---

# 3. Final Validation and Output Creation

### Goal

Perform final quality checks on the cleaned dataset and create the final Silver Layer table for reporting and analysis.

#### Final Validation

Before publishing the dataset, a series of validation checks were performed to ensure that the cleaning process was successfully applied and that the dataset was suitable for downstream use.

##### Validate Row Count

```sql
SELECT COUNT(*) AS final_row_count
FROM silver_sarisari_final;
```

This confirms the final number of records remaining after all cleaning activities.
##### Validate Schema

```sql
DESCRIBE silver_sarisari_final;
```

This confirms that all columns are present and stored using the expected data types.

##### Review Final Data Quality

```sql
SELECT
    COUNT(*) AS total_records,
    COUNT(CASE WHEN Item IS NULL THEN 1 END) AS missing_items,
    COUNT(CASE WHEN Quantity IS NULL THEN 1 END) AS missing_quantities,
    COUNT(CASE WHEN Unit_Price IS NULL THEN 1 END) AS missing_unit_prices,
    COUNT(CASE WHEN Payment_Method IS NULL THEN 1 END) AS missing_payment_methods,
    COUNT(CASE WHEN Customer_Type IS NULL THEN 1 END) AS missing_customer_types
FROM silver_sarisari_final;
```

This provides a final summary of remaining missing values that could not be reliably corrected.

##### Review Sample Records

```sql
SELECT *
FROM silver_sarisari_v6
LIMIT 20;
```

A sample review was conducted to verify that cleaning rules were applied correctly and that values appeared reasonable.

---

### Create the Final Silver Table

After validation was completed, the cleaned dataset was persisted to the Silver Layer.

```sql
CREATE OR REPLACE TABLE d4_indiv.silver_sarisari_final AS
SELECT *
FROM silver_sarisari_v6;
```

---

### Verify Table Creation

```sql
SELECT COUNT(*) AS final_record_count
FROM silver_sarisari_final;
```

```sql
SELECT *
FROM silver_sarisari_final
LIMIT 20;
```

These checks confirm that:

- The table was successfully created.
- The expected records were loaded.
- The final dataset is available for analysis and reporting.

---

## Final Outcome

The Silver Layer dataset was successfully created and contains:

- Duplicate records removed
- Invalid quantity valuee corrected where recoverable
- Missing Unit_Price values recovered where possible
- Invalid payment meth*ds standardized
- Invalid customer*type values removed
- Data quality issues investigated and documented
- Remaining unresolved records retained for manual review rather than modified through assumptions

The resulting dataset is cleaner, more consistent, and better suited for reporting, dashboarding, and further analytical work.

---

## Final Output

| Attribute | Value |
|-----------|--------|
| Table Name | `workspace.d4_indiv.silver_sarisari_final` |
| Layer | Silver |
| Purpose | Cleaned and analysis-ready sales dataset |
| Source | `workspace.d4_indiv.bronze_sarisari` |
| Final Record Count | 5,005 |
