# Building a Clean Sari-sari Store Sales Dataset Using SQL and Medallion Architecture

## 📌 Project Overview

This project demonstrates a Medallion Architecture approach to data quality management using SQL in Databricks.

The workflow is divided into two stages:

- Bronze Layer: Data ingestion, profiling, and quality assessment
- Silver Layer: Data cleaning, standardization, and validation

The objective is to identify quality issues in a raw sales dataset and transform it into a reliable dataset for reporting and analytics.

---

## 🎯 Objectives

### Bronze Layer

Assess the quality of the raw dataset by identifying:

- Missing values
- Invalid values
- Duplicate records
- Inconsistent formats
- Data type issues
- Business rule violations

### Silver Layer

Transform the raw dataset into a clean and analysis-ready table by:

- Correcting recoverable data quality issues
- Standardizing formats and text values
- Applying business validation rules
- Converting columns to appropriate data types
- Producing a trusted analytical dataset

---

## ✅ Expected Outcome

A clean and reliable dataset suitable for reporting, analytics, and downstream data processing.

---

# Project Workflow

## Data Architecture

```text
workspace.d4_indiv.bronze_sarisari
                ↓
workspace.sari_sari_pipeline.sari_sari_transactions_raw
                ↓
Data Profiling & Quality Assessment
                ↓
Data Cleaning & Standardization
                ↓
workspace.sari_sari_pipeline.sari_sari_transactions_clean
```

```text
Bronze Layer
│
├── Raw Data Ingestion
├── Data Profiling
├── Data Quality Assessment
└── Issue Identification
            ↓
Silver Layer
│
├── Data Cleaning
├── Data Standardization
├── Business Validation
└── Final Clean Dataset
```

---

# 1. Bronze Layer: Data Quality Assessment

## Goal

Explore the raw dataset and identify data quality issues before any transformations are applied.

### Input Table

`workspace.sari_sari_pipeline.sari_sari_transactions_raw`

### Dataset Overview

| Dataset | Description |
|----------|-------------|
| Sari-sari Store Sales | Transaction-level sales records containing item purchases, quantities, prices, payment methods, and customer information |

---

## Data Profiling Results

### Duplicate Records

| Finding | Result |
|----------|---------|
| Duplicate Transaction_ID values detected | Yes |
| Exact duplicate rows identified | Yes |

A review of duplicate Transaction_ID values showed that many duplicated rows were exact copies across all columns.

---

### Date

| Finding | Result |
|----------|---------|
| Mixed date formats | No |
| Invalid dates detected | No |

| Metric | Value |
|----------|----------|
| Earliest Transaction Date | 2022-08-21 |
| Latest Transaction Date | 2026-04-03 |

---

### Item

| Finding | Count |
|----------|------:|
| Missing Item values | 250 |

Missing Item values frequently occurred alongside missing Quantity, Unit_Price, Payment_Method, and Customer_Type values.

No reliable pattern was found for imputation.

---

### Quantity

| Finding | Count |
|----------|------:|
| Missing values | 242 |
| Invalid value (`353`) | 50 |
| Text value (`two`) | 100 |

The repeated value `353` appeared inconsistent with expected transaction behavior and was investigated further.

---

### Unit_Price

| Finding | Count |
|----------|------:|
| Missing values | 242 |
| Negative values | 50 |
| Placeholder values detected | 47 |

A repeated Unit_Price value of:

```text
895.74346145472623
```

appeared across multiple unrelated products and was treated as a placeholder value.

---

### Total_Amount

| Finding | Count |
|----------|------:|
| Negative values | 46 |
| Amount mismatches | 79 |

Validation using:

```text
Total_Amount = Quantity × Unit_Price
```

identified records where transaction totals did not match expected amounts.

---

### Payment_Method

| Finding | Result |
|----------|---------|
| Typographical errors detected | Yes |

Example:

```text
cashh
```

---

### Customer_Type

| Finding | Result |
|----------|---------|
| Invalid category values detected | Yes |

Invalid values identified:

```text
123
```

Observed categories:

- Walk-in
- Regular
- Neighbor
- 123
- NULL

---

## Bronze Layer Summary

The data quality assessment identified several issues requiring remediation:

- Exact duplicate records
- Missing values
- Invalid quantity values
- Placeholder prices
- Negative transaction values
- Calculation inconsistencies
- Typographical errors
- Invalid category values

These findings informed the cleaning rules implemented in the Silver Layer.

---

# 2. Silver Layer: Data Cleaning and Standardization

## Goal

Apply cleaning rules and standardization logic to create a trusted dataset for analytics.

### Output Table

`workspace.sari_sari_pipeline.sari_sari_transactions_clean`

---

## Cleaning Actions Performed

### Duplicate Records

- Removed exact duplicate records using `DISTINCT`
- Retained valid repeated Transaction_ID values

**Result:** 94 duplicate records removed.

---

### Quantity

Applied the following corrections:

- Converted `two` to `2`
- Corrected invalid `353` values when recoverable
- Attempted to recover missing quantities using:

```text
Quantity = Total_Amount ÷ Unit_Price
```

**Results**

| Metric | Count |
|----------|------:|
| Remaining Missing Quantities | 245 |

Many Quantity values could not be reliably recovered because supporting Unit_Price values were missing, invalid, or unavailable.

As a result, these records were retained as NULL to preserve data integrity.

---

### Unit_Price

Applied the following corrections:

- Recovered missing values
- Corrected recoverable negative values
- Removed placeholder prices
- Retained unrecoverable records

**Results**

| Metric | Count |
|----------|------:|
| Remaining NULL Unit_Price | 22 |
| Remaining Negative Unit_Price | 4 |
| Placeholder Values Remaining | 0 |

---

### Payment_Method

Standardized:

```text
cashh → Cash
```

**Result:** All valid payment methods were standardized.

---

### Customer_Type

Converted invalid values:

```text
123 → NULL
```

Valid categories were retained.

**Results**

| Metric | Count |
|----------|------:|
| Invalid Customer_Type Values Converted to NULL | 104 |
| Remaining NULL Customer_Type | 344 |

---

### Data Type Standardization

To improve consistency and support downstream analytics, key columns were converted to appropriate data types.

| Column | Data Type |
|----------|-----------|
| Transaction_ID | INT |
| Date | DATE |
| Quantity | INT |
| Unit_Price | DECIMAL(10,2) |
| Total_Amount | DECIMAL(10,2) |

This ensures calculations, aggregations, filtering, and reporting can be performed reliably.

---

## Silver Layer Summary

### Cleaning Results

| Check | Result |
|---------|------:|
| Duplicate Records Removed | 94 |
| Quantity Mismatches Corrected | 79 |
| Placeholder Unit Prices Removed | 47 |
| Invalid Customer Types Converted to NULL | 104 |
| Remaining Missing Quantities | 245 |
| Remaining Missing Unit Prices | 22 |
| Remaining Negative Unit Prices | 4 |

### Final Outcome

The Silver-layer dataset:

- Contains deduplicated records
- Uses standardized categorical values
- Corrects recoverable data quality issues
- Retains unresolved records where insufficient evidence exists
- Preserves data lineage by avoiding unsupported assumptions
- Is ready for reporting and downstream analytics

---

# 3. Silver Layer Validation

## Goal

Verify that all cleaning rules were applied successfully and confirm that the resulting dataset is suitable for reporting and analysis.

### Validation Checks

The final validation process focused on:

- Record counts
- Schema and data type validation
- Remaining missing values
- Remaining negative values
- Sample record review

### Validation Results

| Metric | Value |
|----------|------:|
| Total Records | 5,006 |
| Missing Items | 250 |
| Missing Quantities | 245 |
| Missing Unit Prices | 22 |
| Missing Payment Methods | 246 |
| Missing Customer Types | 344 |
| Remaining Placeholder Prices | 0 |
| Remaining Negative Unit Prices | 4 |

### Data Quality Review

The majority of critical data quality issues identified during profiling were successfully resolved.

Remaining missing values were retained only when there was insufficient evidence to derive a reliable replacement value.

No unsupported assumptions were used during the cleaning process.

### Final Output

The validated dataset was published as:

`workspace.sari_sari_pipeline.sari_sari_transactions_clean`

This table serves as the trusted Silver-layer dataset for reporting, analytics, and downstream data processing.

---

## Final Output

| Attribute | Value |
|-----------|--------|
| Source | `workspace.d4_indiv.bronze_sarisari` |
| Output Table | `workspace.sari_sari_pipeline.sari_sari_transactions_clean` |
| Layer | Silver |
| Final Record Count | 5,006 |
| Purpose | Cleaned and analysis-ready sales dataset |

---

## Skills Demonstrated

- SQL
- Databricks
- Data Profiling
- Data Quality Assessment
- Data Cleaning
- Data Standardization
- Business Rule Validation
- Data Quality Management
- Medallion Architecture
- Data Documentation
- Data Engineering Best Practices
