# Build the Clean Layer with SQL

## 📌 Project Overview

This project focuses on transforming raw sales data into a clean, reliable, and analysis-ready dataset using SQL in Databricks.

The workflow follows common data engineering practices used in the Silver Layer of a medallion architecture, where raw data is cleaned, standardized, validated, and prepared for downstream reporting and analytics.

## 🎯 Objective

Create a clean and consistent table called:

`silver.sarisari_sales`

The final table should contain high-quality data that can be trusted for business analysis and reporting.

---

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

Perform data profiling to identify quality issues that may impact reporting, analysis, and downstream transformations.

### Findings

#### Customer_Type

##### Missing Values
- Blank customer type records were identified.
- Customer type is a required field and should not be null or blank.

##### Inaccurate Customer Categories
- Some customer types do not match the expected categories.
- Existing values must be reviewed against business-defined customer segments.

##### Unnecessary Categories
- Customer type values should be limited to:
  - Walk-In
  - Regular
- Records outside these categories require validation.

##### Inconsistent Naming
- Variations such as:
  - "123"
  - "Customer"
- These values are not valid customer types and need standardization.

---

#### Date

##### Invalid Date Format
- Dates use inconsistent formats.
- Example:
  - 01/21/2026
  - 21-01-2026
- A single standard date format is required.

##### Out-of-Sequence Dates
- Dates must follow a valid chronological order.
- Future, incorrect, or malformed dates require validation.

---

#### Item

##### Inconsistent Item Names
- Similar items have different descriptions.
- Item naming must be standardized to avoid duplicate categories.

##### Missing Item Values
- Some records contain blank item names.

##### Missing Item Category
- Items are not grouped into categories.
- A category classification system is required.

##### Single-Use Item Labels
- Certain item names appear only once.
- These require validation to determine whether they are valid products or data-entry errors.

---

#### Payment_Method

##### Typographical Errors
- Payment methods contain spelling mistakes.
- Example:
  - "Cahs"
  - "Cash"

##### Invalid Payment Methods
- Some payment methods do not correspond to approved payment options.

##### Inconsistent Naming
- Multiple spellings and formats exist for the same payment method.
- Payment methods require standardization.

---

#### Quantity

##### Invalid Quantity Values
- Quantities contain text rather than numbers.
- Example:
  - "two"

##### Mixed Numeric Formats
- Quantities contain both numeric and text-based representations.
- Example:
  - "2"
  - "two"

##### Data Type Issues
- Quantity should be stored as a numeric field.

---

#### Total_Amount

##### Negative Values
- Negative sales amounts were identified.
- Sales values should be reviewed and validated.

##### Calculation Errors
- Total amount does not always match:
  - Unit Price × Quantity
- Recalculation and validation are required.

---

#### Transaction_ID

##### Duplicate Records
- Duplicate transaction IDs were identified.
- Duplicate transactions require investigation and resolution.

##### Inconsistent Numbering
- Transaction IDs do not follow a consistent format.
- Standard transaction numbering rules are required.

---

#### Unit_Price

##### Missing Values
- Some records contain missing unit prices.

##### Multiple Prices for the Same Item
- The same item appears with different unit prices.
- Price consistency must be validated against business rules.

##### Negative Values
- Negative unit prices were identified.
- These values are considered invalid and require correction.

---

### Summary of Identified Data Quality Issues

| Category | Issues Found |
|-----------|-------------|
| Completeness | Missing Customer Type, Missing Item, Missing Unit Price |
| Accuracy | Invalid Customer Types, Invalid Payment Methods, Negative Amounts, Incorrect Total Amount Calculations |
| Consistency | Inconsistent Item Names, Payment Method Variations, Mixed Date Formats, Inconsistent Transaction IDs |
| Validity | Invalid Quantities, Text-Based Quantities, Invalid Dates, Negative Unit Prices |
| Uniqueness | Duplicate Transaction IDs |

### Deliverable

A documented list of data quality issues that will be addressed during the data cleaning and transformation process.

---

## 3. Standardize Inconsistent Text

### Goal

Ensure text-based fields follow a consistent format.

### Tasks

#### Standardize capitalization

- Apply a consistent text format
- Eliminate case-sensitive variations

#### Remove unnecessary spaces

- Remove leading spaces
- Remove trailing spaces
- Remove extra spaces between words

#### Standardize categories

- Consolidate equivalent category values
- Correct text inconsistencies

#### Verify unique values

- Review distinct category values
- Confirm duplicate variations have been removed

### Deliverable

A dataset with consistent and standardized text fields.

---

## 4. Cast Columns to the Correct Data Types

### Goal

Ensure every column uses the most appropriate data type.

### Tasks

#### Review business requirements

- Identify expected data type for every column

#### Convert numeric fields

- Convert quantity fields to numeric types
- Convert sales-related fields to numeric types

#### Convert date fields

- Convert date columns into proper date formats
- Identify invalid date records

#### Validate text fields

- Ensure descriptive fields remain text-based

#### Validate schema

- Review the final schema
- Confirm all data types are correct

### Deliverable

A dataset with an analysis-ready schema.

---

## 5. Remove Unwanted Duplicates

### Goal

Ensure every record is unique and trustworthy.

### Tasks

#### Define duplicate criteria

- Determine which columns define uniqueness
- Establish duplicate-identification rules

#### Analyze duplicate records

- Count duplicates
- Understand duplicate patterns

#### Remove duplicate records

- Keep only valid records
- Remove redundant duplicates

#### Validate results

- Compare row counts before and after removal
- Confirm duplicate issues have been resolved

### Deliverable

A dataset with duplicate records removed.

---

## 6. Create `silver.sarisari_sales`

### Goal

Persist the cleaned dataset in the Silver Layer.

### Tasks

#### Perform final validation

- Review row counts
- Review schema
- Review sample records

#### Create the silver table

- Save the cleaned dataset as:
  - `silver.sarisari_sales`

#### Verify output

- Confirm table creation succeeded
- Confirm data quality improvements are present
- Confirm the table is ready for analysis

### Deliverable

A production-ready Silver Layer table.

---

# Success Criteria

The project is considered successful when:

- All major data quality issues are identified
- Missing values are handled appropriately
- Invalid values are corrected or removed
- Text fields are standardized
- Columns use appropriate data types
- Duplicate records are removed
- `silver.sarisari_sales` is created successfully
- The final dataset is clean, consistent, and analysis-ready

---

## Final Output

**Table Name:** `silver.sarisari_sales`

**Layer:** Silver

**Purpose:** Clean, standardized, and analysis-ready sales dataset for reporting and business insights.
