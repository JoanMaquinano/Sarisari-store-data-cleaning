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

Understand the current condition of the dataset before applying any transformations.

### Tasks

#### Review the table structure

- Identify all available columns
- Review current column data types
- Look for suspicious or incorrect data types

#### Analyze record volume

- Determine the total number of records
- Verify that the dataset loaded correctly

#### Identify missing values

- Check for `NULL` values
- Check for blank values
- Compare missing-value counts across columns

#### Identify invalid values

- Look for placeholder values such as:
  - N/A
  - Unknown
  - Null
  - -
- Look for impossible values such as:
  - Negative quantities
  - Negative sales amounts
  - Invalid dates

#### Check text consistency

- Review capitalization differences
- Review spelling variations
- Review extra spaces

#### Check for duplicates

- Search for duplicate rows
- Identify duplicate business records

### Deliverable

A complete inventory of all identified data quality issues.

---

## 2. Fix Missing or Invalid Values

### Goal

Improve the completeness and accuracy of the dataset.

### Tasks

#### Define handling rules

- Identify required fields
- Identify optional fields
- Determine acceptable missing-value treatments

#### Handle missing values

- Replace missing values where appropriate
- Retain values as `NULL` when no valid replacement exists

#### Handle blank values

- Convert empty strings into a consistent format
- Ensure blanks are treated consistently across columns

#### Correct invalid values

- Fix incorrect entries
- Replace placeholder values
- Remove impossible values when necessary

#### Validate results

- Recheck missing-value counts
- Confirm corrections were applied successfully

### Deliverable

A dataset with missing and invalid values addressed.

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
