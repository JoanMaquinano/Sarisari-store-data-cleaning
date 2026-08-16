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
| Payment_Method | Typographical errors |
| Payment_Method | Invalid payment methods |
| Quantity | Invalid quantity values |
| Quantity | Quantities stored as text (e.g., `"two"`) |
| Total_Amount | Negative values |
| Total_Amount | Total amount does not match Unit Price × Quantity |
| Unit_Price | Missing values |
| Unit_Price | Different prices for the same item |
| Unit_Price | Negative values |
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

From here, we confirmed there are 253 missing Item values.

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
FROM silver_sari*ari
GROUP BY Quantity
ORDER BY Qua*tity;

-- Checking an outlier
SELE*T *
FROM silver_sarisari
WHERE Qua*tity = '353';

-- Check for actual*expected quantity
SELECT
Quant*ty,
Unit_Price,
Total_Amou*t,
Total_Amount / Unit_Price A* expected_quantity
FROM silver_sar*sari
WHERE Quantity = '353';
```

*#### Why keep NULLs?

- There are *42 missing quantities.
- Unlike 35*, there is not enough information *o reliably derive all missing valu*s.
- Imputing values would introdu*e assumptions into the dataset.

#*### Why fix 353?

Investigation sh*wed that 353 is not the true quant*ty.

```sql
-- Analyzing NULL and *egative Unit_Price values under th* 353 quantities
SELECT *
FROM silv*r_sarisari
WHERE Quantity = '353'
*ND (
Unit_Price IS NULL
OR*Unit_Price <= 0
);
```

We found **3 exception records** among the 50*rows with `Quantity = 353`. Two ha* `NULL` Unit_Price values and one *ontained a negative Unit_Price val*e. These were addressed before cal*ulating replacement quantities usi*g:

```text
Quantity = Total_Amoun* / Unit_Price
```

```sql
-- Chang* 'two' to 2, derive values using t*e formula for positive values,
-- *nter negative values as NULL

CREA*E OR REPLACE TEMP VIEW silver_sarisari_v2 AS
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
FROM silve*_sarisari_v2
WHERE Unit_Price IS N*LL;

-- Check which ones can be de*ived
SELECT
Item,
Quantity*
Total_Amount,
ROUND(Total*Amount / Quantity, 2) AS expected_*nit_price
FROM silver_sarisari_v2
*HERE Unit_Price IS NULL
AND Quan*ity IS NOT NULL
AND Quantity > 0*LIMIT 20;
```

Formula used:

```t*xt
Unit_Price = Total_Amount ÷ Qua*tity
```

##### Findings

| Metric*| Count |
|----------|------:|
| M*ssing Unit_Price | 242 |
| Recover*ble | 230 |
| Cannot be Recovered * 12 |

```sql
CREATE OR REPLACE TE*P VIEW silver_sarisari_v3 AS
SELEC*
Transaction_ID,
Date,
*Item,
Quantity,

CASE
* WHEN Unit_Price IS NULL
* AND Quantity IS NOT NULL
* AND Quantity > 0
* THEN ROUND(Total_Amount / Quanti*y, 2)

ELSE Unit_Price
END AS Unit_Price,

Total_Amount,
Payment_Method,
Customer_Type
FROM silver_sarisari_v2;
```

##### Summary

| Metric | Count |
|----------|------:|
| Missing Unit_Price Before Cleaning | 242 |
| Recoverable Using Total_Amount ÷ Quantity | 230 |
| Missing Unit_Price After Cleaning | 12 |

Now let's investigate the next Unit_Price issue.

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
SELECT COUNT(*) AS unrecoverable_negative_prices*FROM silver_sarisari_v3
WHERE Unit*Price < 0
AND (Quantity IS NULL *R Quantity <= 0);
```

##### Findi*gs

| Metric | Count |
|----------*------:|
| Negative Unit_Price Val*es | 101 |
| Recoverable | 94 |
| *nrecoverable | 7 |

```sql
-- Deal*with the recoverable values
CREATE*OR REPLACE TEMP VIEW silver_sarisa*i_v4 AS
SELECT
Transaction_ID,* Date,
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
```

Three values remain unchanged.

```sql
-- Check the remaining negative values
SELECT *
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

-- Quantify problem
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
```

The `implied_quantity` values are not random. This strongly suggests that **Quantity is the incorrect field**, not `Total_Amount`.

```sql
-- Investigate quantity values
SELECT
Quantity,
Unit_Price,
Total_Amount,
ROUND(Total_Amount / Unit_Price, 0) AS implied_quantity
FROM silver_sarisari_v5
WHERE Quantity IS NOT NULL
AND Unit_Price IS NOT NULL
AND Total_Amount > 0
AND ROUND(Quantity * Unit_Price, 2) <> ROUND(Total_Amount, 2);
```

Every remaining positive mismatch has `Quantity = 2`, but the implied quantity is different.

**Finding:** 79 records were identified where `Quantity × Unit_Price` did not equal `Total_Amount`.

Investigation showed that the implied quantity frequently differed from the recorded quantity, suggesting potential data-entry errors in the Quantity field.

No automated correction was performed. Records were flagged for manual review.

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

