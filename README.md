Build the Clean Layer with SQL
Project Overview

This project focuses on building a clean data layer from a raw sales dataset using SQL in Databricks. The objective is to identify and resolve data quality issues, standardize values, enforce proper data types, remove duplicates, and create a clean table ready for analysis.

Objective

Create a clean and consistent silver.sarisari_sales table that can be used reliably for reporting and analytics.

Expected Output
Clean dataset
Consistent formatting across records
Correct data types
No unnecessary duplicates
Analysis-ready silver table
Step 1: Inspect the Raw Data for Quality Problems
Goal

Understand the current state of the raw dataset before making any changes.

Substeps
1.1 Review Table Structure
Identify all columns.
Review existing data types.
Check for columns that appear to have incorrect data types.
1.2 Check Row Volume
Count total records.
Identify unusually small or large datasets.
1.3 Look for Missing Values
Check each column for null values.
Identify columns with a high percentage of missing data.
1.4 Look for Invalid Values
Search for blank strings.
Search for placeholder values such as:
N/A
Unknown
Null
Check for impossible values (negative sales, invalid dates, etc.).
1.5 Identify Inconsistent Formats
Review text fields.
Check for inconsistent capitalization.
Check for leading or trailing spaces.
Check for spelling variations.
1.6 Check for Duplicates
Determine whether duplicate rows exist.
Identify possible duplicate business records.
Deliverable

A summary of all data quality issues discovered.

Step 2: Fix Missing or Invalid Values
Goal

Improve data completeness and accuracy.

Substeps
2.1 Define Missing Data Rules
Determine which fields are required.
Determine which fields can remain null.
2.2 Handle Null Values
Replace nulls where appropriate.
Retain nulls when no valid replacement exists.
2.3 Handle Blank Values
Convert empty strings into a consistent format.
Ensure blanks are treated correctly.
2.4 Correct Invalid Values
Fix impossible values.
Replace placeholder values with valid values or nulls.
2.5 Validate Results
Recheck columns after corrections.
Confirm missing-value counts have improved.
Deliverable

Dataset with missing and invalid values addressed.

Step 3: Standardize Inconsistent Text
Goal

Ensure text values follow a consistent format.

Substeps
3.1 Standardize Capitalization
Apply a consistent text format.
Ensure values do not differ only by case.
3.2 Remove Unwanted Spaces
Remove leading spaces.
Remove trailing spaces.
Remove unnecessary extra spaces.
3.3 Standardize Categories
Identify category variations.
Consolidate equivalent values.
3.4 Validate Consistency
Review unique values.
Confirm duplicate categories no longer exist.
Deliverable

Consistent text values across all categorical columns.

Step 4: Cast Columns to the Correct Data Types
Goal

Ensure each column uses the appropriate data type.

Substeps
4.1 Review Business Meaning
Determine the expected data type for each column.
4.2 Convert Numeric Fields
Convert sales, quantity, and similar columns to numeric types.
Verify conversion success.
4.3 Convert Date Fields
Convert date columns to date format.
Check for invalid date records.
4.4 Convert Text Fields
Ensure descriptive attributes remain text.
4.5 Validate Schema
Review the updated schema.
Confirm all columns have appropriate data types.
Deliverable

Dataset with an analysis-ready schema.

Step 5: Remove Unwanted Duplicates
Goal

Ensure every record is unique and trustworthy.

Substeps
5.1 Define Duplicate Criteria
Determine what constitutes a duplicate record.
Identify key columns for comparison.
5.2 Detect Duplicates
Count duplicate records.
Review duplicate patterns.
5.3 Remove Duplicate Records
Retain only the correct version of each record.
Remove redundant records.
5.4 Validate Results
Recheck row counts.
Confirm duplicates have been removed.
Deliverable

Dataset containing only unique records.

Step 6: Create silver.sarisari_sales
Goal

Store the cleaned dataset in the silver layer.

Substeps
6.1 Verify Final Dataset
Review row counts.
Review schema.
Review sample records.
6.2 Create Silver Table
Save the cleaned data as silver.sarisari_sales.
6.3 Perform Final Validation
Confirm table creation succeeded.
Confirm record counts match expectations.
Confirm all cleaning rules were applied.
Deliverable

silver.sarisari_sales table ready for business analysis.

Success Criteria

The project is successful when:

Missing values are handled appropriately.
Invalid values are corrected or removed.
Text values are standardized.
Data types are accurate.
Duplicate records are removed.
silver.sarisari_sales is created successfully.
The final table is clean, consistent, and analysis-ready.
