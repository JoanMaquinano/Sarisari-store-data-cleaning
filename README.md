# Build the Clean Layer with SQL

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
| Item | Inconsistent item descriptions |
| Item | Missing values |
| Quantity | Invalid quantity values |
| Quantity | Quantities stored as text (e.g., `"two"`) |
| Unit_Price | Different prices for the same item |
| Unit_Price | Negative values |
| Unit_Price | Missing values |
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
CREATE OR REPLACE TEMP VIEW silver_sarisari AS
SELECT *
FROM workspace.d4_indiv.bronze_sarisari;
```

#### Transaction_ID

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

```sql
-- Before cleaning
SELECT COUNT(*) AS before_count
FROM workspace.d4_indiv.bronze_sarisari;

-- Remove duplicate records using DISTINCT
CREATE OR REPLACE TEMP VIEW silver_sarisari AS
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
- Repeated Transaction_ID values associated with transaction reversals or adjustments were retained.

#### Date

```sql
SELECT DISTINCT Date
FROM silver_sarisari
ORDER BY Date;
```

```sql
SELECT Date
FROM silver_sarisari
WHERE Date LIKE '%/%';
```

Through this, it was confirmed that all dates were stored in the `YYYY-MM-DD` format, no inconsistent date formats were identified, and no invalid date values were observed.

#### Item

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

-- Checking if they have a common Unit_Price
SELECT
Unit_Price,
COUNT(*) AS record_count
FROM silver_sarisari
WHERE Item IS NULL
GROUP BY Unit_Price
ORDER BY record_count DESC;

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

Observations:

- Missing items occur across many different Unit_Price values.
- Some missing items even have a NULL Unit_Price.
- There is no obvious one-to-one relationship between a missing Item and a specific Unit_Price.
- Missing Item values cannot be reliably inferred using Unit_Price.

Decision: Keep missing Item values as NULL.

Reason:

- The missing values cannot be accurately derived.
- Imputing values would introduce assumptions and potentially reduce data quality.
- The affected records represent less than 5% of the dataset and can be retained for analysis.


#### Quantity

```sql
-- Checking for unexpected values
SELECT
Quantity,
COUNT(*) AS record_count
FROM silver_sarisari
GROUP BY Quantity
ORDER BY Quantity;

-- Checking an outlier
SELECT *
FROM silver_sarisari
WHERE Quantity = '353';

-- Check for actual expected quantity
SELECT
Quantity,
Unit_Price,
Total_Amount,
Total_Amount / Unit_Price AS expected_quantity
FROM silver_sarisari
WHERE Quantity = '353';
```

##### Why keep NULLs?

- There are 242 missing quantities.
- Unlike with value 353, there is not enough information to reliably derive all missing values.
- Imputing values would introduce assumptions into the dataset.

##### Why fix 353?

Investigation showed that 353 is not the true quantity.

```sql
-- Analyzing NULL and negative Unit_Price values under the 353 quantities
SELECT *
FROM silver_sarisari
WHERE Quantity = '353'
AND (
Unit_Price IS NULL
OR Unit_Price <= 0
);
```

We found **3 exception records** among the 50 rows with `Quantity = 353`. Two has `NULL` Unit_Price values and one contained a negative Unit_Price value. These were addressed before calculating replacement quantities using:

Quantity = Total_Amount / Unit_Price

```sql
-- Change 'two' to 2, derive values using the formula for positive values,
-- Enter negative values as NULL

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
```

| Quantity | Record Count |
|----------|------------:|
| NULL | 245 |
| 1 | 905 |
| 2 | 1082 |
| 3 | 932 |
| 4 | 937 |
| 5 | 905 |

##### Analysis

- The text value `two` was successfully converted to `2`.
- The invalid quantity value `353` was successfully replaced using the calculated quantity (`Total_Amount / Unit_Price`) where possible.
- Three records with `Quantity = 353` could not be corrected because `Unit_Price` was either NULL or negative. These records were set to NULL.
- As a result, the number of missing quantities increased from **242** to **245**.
- The dataset now contains only valid quantity values (1 to 5) and NULL.

---

#### Unit_Price

```sql
-- Check number of null values
SELECT COUNT(*) AS missing_unit_price
FROM silver_sarisari_v2
WHERE Unit_Price IS NULL;

-- Check which ones can be derived
SELECT
Item,
Quantity,
Total_Amount,
ROUND(Total_Amount / Quantity, 2) AS expected_unit_price
FROM silver_sarisari_v2
WHERE Unit_Price IS NULL
AND Quantity IS NOT NULL
AND Quantity > 0 LIMIT 20;

-- Recoverable missing Unit_Price
SELECT COUNT(*) AS recoverable
FROM silver_sarisari_v2
WHERE Unit_Price IS NULL
  AND Quantity IS NOT NULL
  AND Quantity > 0;

-- Unrecoverable missing Unit_Price
SELECT COUNT(*) AS cannot_be_recovered
FROM silver_sarisari_v2
WHERE Unit_Price IS NULL
  AND (Quantity IS NULL OR Quantity <= 0);
```

Formula used to derive unit prices:

Unit_Price = Total_Amount ÷ Quantity


##### Findings

| Metric | Count |
|----------|------:|
| Missing Unit_Price | 242 |
| Recoverable | 230 |
| Cannot be Recovered | 12 |

```sql
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

##### Summary

| Metric | Count |
|----------|------:|
| Missing Unit_Price Before Cleaning | 242 |
| Recoverable Using Total_Amount ÷ Quantity | 230 |
| Missing Unit_Price After Cleaning | 12 |

Investigating the next Unit_Price issue:

```sql
-- Check negative values
SELECT *
FROM silver_sarisari_v3
WHERE Unit_Price < 0;

-- Check recoverable
SELECT COUNT(*) AS recoverable_negative_prices
FROM silver_sarisari_v3
WHERE Unit_Price < 0
AND Quantity IS NOT NULL
AND Quantity > 0;

-- Check unrecoverable
SELECT COUNT(*) AS unrecoverable_negative_prices
FROM silver_sarisari_v3
WHERE Unit_Price < 0
AND (Quantity IS NULL OR Quantity <= 0);
```

##### Findings

| Metric | Count |
|------------------:|
| Negative Unit_Price Values | 101 |
| Recoverable | 94 |
| Unrecoverable | 7 |

```sql
-- Deal with the recoverable values
CREATE OR REPLACE TEMP VIEW silver_sarisari_v4 AS
SELECT
Transaction_ID, Date,
Item,
Quantity,

CASE
WHEN Unit_Price IS NULL
AND Quantity IS NOT NULL
AND Quantity > 0
THEN ROUND(Total_Amount / Quantity, 2)

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

-- Validate remaining missing Unit_Price values
SELECT COUNT(*) AS missing_unit_price_after_negative_cleanup
FROM silver_sarisari_v4
WHERE Unit_Price IS NULL;
```

Three values remain unchanged.

```sql
-- Check the remaining negative values
SELECT COUNT(*) AS remaining_negative_unit_price
FROM silver_sarisari_v4
WHERE Unit_Price < 0;
-- Check for count
SELECT *
FROM silver_sarisari_v4
WHERE Unit_Price < 0;

SELECT
    Quantity,
    Unit_Price,
    Total_Amount,
    ROUND(Total_Amount / Quantity, 2) AS expected_unit_price
FROM silver_sarisari_v4
WHERE Unit_Price < 0;

```

Upon checking, these three records have calculations that are mathematically correct. They were therefore left unchanged.

---

#### Total_Amount

```sql
-- Check mismatched records
SELECT *
FROM silver_sarisari_v4
WHERE Quantity IS NOT NULL
AND Unit_Price IS NOT NULL
AND ROUND(Quantity * Unit_Price, 2) <> ROUND(Total_Amount, 2);

-- Measure the number of affected records
SELECT COUNT(*) AS mismatched_records
FROM silver_sarisari_v4
WHERE Quantity IS NOT NULL
AND Unit_Price IS NOT NULL
AND ROUND(Quantity * Unit_Price, 2) <> ROUND(Total_Amount, 2);

-- Break the mismatches into categories
SELECT
CASE
WHEN Total_Amount < 0 THEN 'Negative Total Amount'
WHEN Unit_Price = 895.7434614547262 THEN 'Invalid Unit Price'
ELSE 'Other Mismatch'
END AS issue_type,
COUNT(*) AS record_count
FROM silver_sarisari_v4
WHERE Quantity IS NOT NULL
AND Unit_Price IS NOT NULL
AND ROUND(Quantity * Unit_Price, 2) <> ROUND(Total_Amount, 2)
GROUP BY issue_type;

-- Validate whether the invalid Unit_Price value still exists
SELECT COUNT(*) AS invalid_unit_price_records
FROM silver_sarisari_v4
WHERE Unit_Price = 895.7434614547262;
```

##### Findings

| Issue Type | Record Count |
|------------|------------:|
| Other Mismatch | 79 |
| Negative Total Amount | 42 |
| Invalid Unit Price | 46 |

```sql
-- Categorize mismatches
SELECT
Transaction_ID,
Quantity,
Unit_Price,
Total_Amount,
ROUND(Quantity * Unit_Price, 2) AS expected_total_amount
FROM silver_sarisari_v5
WHERE Quantity IS NOT NULL
AND Unit_Price IS NOT NULL
AND ROUND(Quantity * Unit_Price, 2) <> ROUND(Total_Amount, 2)
LIMIT 50;
```

I observed three types of mismatches:

- Negative Total Amount
- Total Amount Equals Unit Price
- Total Amount is a Multiple of Unit Price

```sql
-- Check if error comes from Quantity or Total_Amount
SELECT
Quantity,
Unit_Price,
Total_Amount,
ROUND(Total_Amount / Unit_Price, 2) AS implied_quantity
FROM silver_sarisari_v5
WHERE Quantity IS NOT NULL
AND Unit_Price IS NOT NULL
AND ROUND(Quantity * Unit_Price, 2) <> ROUND(Total_Amount, 2);

-- Count records where implied quantity differs from recorded quantity
SELECT COUNT(*) AS quantity_mismatch_records
FROM silver_sarisari_v5
WHERE Quantity IS NOT NULL
  AND Unit_Price IS NOT NULL
  AND Total_Amount > 0
  AND ROUND(Quantity * Unit_Price, 2) <> ROUND(Total_Amount, 2)
  AND Quantity <> ROUND(Total_Amount / Unit_Price, 0);
```

The `implied_quantity` values are not random. This strongly suggests that **Quantity is the incorrect field**, not `Total_Amount`.

```sql
-- Count positive mismatch records
SELECT COUNT(*) AS positive_mismatch_records
FROM silver_sarisari_v5
WHERE Quantity IS NOT NULL
AND Unit_Price IS NOT NULL
AND Total_Amount > 0
AND ROUND(Quantity * Unit_Price, 2) <> ROUND(Total_Amount, 2);

-- Count records where implied quantity differs from recorded quantity
SELECT COUNT(*) AS quantity_mismatch_records
FROM silver_sarisari_v5
WHERE Quantity IS NOT NULL
AND Unit_Price IS NOT NULL
AND Total_Amount > 0
AND ROUND(Quantity * Unit_Price, 2) <> ROUND(Total_Amount, 2)
AND Quantity <> ROUND(Total_Amount / Unit_Price, 0);
```

Every remaining positive mismatch has `Quantity = 2`, but the implied quantity is different.

**Finding:** 79 records classified as Other Mismatch were further investigated.
Analysis of the implied quantity values suggested that the Quantity field may contain data-entry errors, as the calculated quantity frequently differed from the recorded quantity.

---

#### Payment_Method

```sql
SELECT
Payment_Method,
COUNT(*) AS record_count
FROM silver_sarisari_v5
GROUP BY Payment_Method
ORDER BY Payment_Method;
```

```sql
CREATE OR REPLACE TEMP VIEW silver_sarisari_v6 AS
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
```

```sql
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

- Corrected 100 records containing the value `cashh`.
- Standardized all payment method names.
- Retained missing values as NULL.
- Payment_Method now contains only valid payment methods.

---

#### Customer_Type

##### Issue

- Missing values
- Invalid customer types
- Unapproved customer categories

##### Before Cleaning

###### Validation Query

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

###### Transformation Query

```sql
CREATE OR REPLACE TEMP VIEW silver_sarisari AS
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
```

A temporary view named `silver_sarisari` was created from the Bronze table.

A `CASE` statement was used to replace the invalid customer types `123` and `Neighbor` with `NULL`, while keeping valid values unchanged.

The remaining columns were carried over without changes.

##### After Cleaning

###### Validation Query

```sql
SELECT
Customer_Type,
COUNT(*)
FROM silver_sarisari
GROUP BY Customer_Type
ORDER BY Customer_Type;
```

After cleaning, the `Customer_Type` column contains only three values:

- `Regular`
- `Walk-in`
- `NULL`

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

This confirms the final number of records remai*ing after all cleaning activities.
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
