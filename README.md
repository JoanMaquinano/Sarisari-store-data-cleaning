# Exercise: Build the Silver Layer with SQL

## Introduction

As part of the Bronze-to-Silver data transformation process, the raw sales dataset (`bronze.sarisari_sales`) was assessed and cleaned using SQL. The objective was to identify and resolve data quality issues that could impact reporting, analytics, and business decision-making.

The cleaning process focused on improving data completeness, consistency, accuracy, and reliability before storing the transformed dataset in the Silver layer. The final result is a structured and analysis-ready dataset that can be confidently used for reporting and downstream analytical tasks.

---

## Business Problem (BP)

The raw sales dataset may contain data quality issues that can affect reporting accuracy and business insights. Common problems include:

- Missing values in critical fields
- Invalid or unrealistic values
- Inconsistent text formatting
- Incorrect data types
- Duplicate transaction records

If these issues are not addressed, sales reports and analytical outputs may become unreliable and lead to incorrect business decisions.

---

## Analytical Problem (AP)

How can the raw sales dataset be transformed into a clean, consistent, and trustworthy dataset using SQL while preserving the original data stored in the Bronze layer?

To address this problem, the following data quality tasks were performed:

- Inspection of raw data for quality issues
- Handling of missing and invalid values
- Standardization of inconsistent text values
- Conversion of columns to appropriate data types
- Removal of duplicate records
- Creation of a cleaned Silver-layer table

---

## Objectives

The objectives of this exercise were to:

- Assess the quality of the raw sales data
- Identify and resolve missing or invalid values
- Standardize inconsistent text entries
- Ensure all columns use appropriate data types
- Remove duplicate records
- Create the `silver.sarisari_sales` table
- Produce a clean and analysis-ready dataset

---

# Step 1: Data Inspection and Quality Assessment

The raw dataset was first inspected to understand its structure and identify potential data quality concerns.

The review focused on the following areas:

- Presence of null or missing values
- Invalid numerical values
- Inconsistent categorical values
- Incorrect data types
- Duplicate records

Key business columns such as `Transaction_ID`, `Date`, `Quantity`, `Unit_Price`, `Total_Amount`, and `Payment_Method` were examined to determine whether the stored values aligned with expected business rules.

The inspection revealed several quality issues requiring further cleaning, including incomplete fields, inconsistent formatting, and potential duplication. These findings provided the basis for subsequent transformation steps.

---

# Step 2: Handling Missing and Invalid Values

After identifying problematic records, missing and invalid values were evaluated and corrected using appropriate business rules.

Where sufficient information was available, missing values were derived from related columns to maintain data completeness and accuracy.

The dataset was also reviewed for invalid records, including:

- Missing transaction details
- Invalid quantity values
- Invalid pricing values
- Invalid transaction amounts
- Other values that violated expected business logic

Corrections were applied where possible to ensure consistency between sales quantities, prices, and transaction totals.

This step improved the overall integrity and usability of the dataset.

---

# Step 3: Standardizing Text Values

Categorical columns were reviewed for inconsistencies caused by variations in formatting, capitalization, spelling, and abbreviations.

Examples included:

- Multiple representations of the same payment method
- Variations in product naming conventions
- Mixed usage of uppercase and lowercase text

All identified categories were standardized to a consistent format to ensure that equivalent values were treated as a single category during reporting and aggregation.

This standardization improved data consistency and reduced the likelihood of fragmented analytical results.

---

# Step 4: Converting Columns to Appropriate Data Types

Each column was evaluated to ensure that its stored data type matched its intended business purpose.

The following data structure was implemented:

| Column | Data Type |
|----------|----------|
| Transaction_ID | Integer |
| Date | Date |
| Item | String |
| Quantity | Integer |
| Unit_Price | Decimal |
| Total_Amount | Decimal |
| Payment_Method | String |

Applying the correct data types improves data quality, supports accurate calculations, and enables efficient querying and analysis.

---

# Step 5: Removing Duplicate Records

The dataset was reviewed for duplicate transactions that could potentially distort sales metrics and analytical results.

Duplicate detection was performed at the transaction level by comparing identifiers and associated transaction details.

Where duplicate records were identified, only a single valid occurrence was retained while redundant records were removed.

This process ensured that each transaction was represented once within the cleaned dataset and prevented double counting during analysis.

---

# Step 6: Creating the Silver Layer Table

After all cleaning and validation activities were completed, the transformed dataset was stored in the Silver layer as:

`silver.sarisari_sales`

The final table contains:

- Cleaned and validated records
- Standardized text values
- Appropriate data types
- Removed duplicate entries
- Reliable transactional information

The Silver table now serves as the trusted source for reporting, dashboard creation, exploratory analysis, and future data transformations.

---

# Result

The Bronze-layer sales dataset was successfully transformed into a clean and structured Silver-layer table.

The resulting dataset is:

- Complete and consistent
- Free from major data quality issues
- Suitable for analytical processing
- Ready for business reporting and decision-making

## Data Flow

```text
bronze.sarisari_sales
        │
        ▼
Data Quality Assessment
        │
        ▼
Missing & Invalid Value Handling
        │
        ▼
Text Standardization
        │
        ▼
Data Type Conversion
        │
        ▼
Duplicate Removal
        │
        ▼
silver.sarisari_sales
```

**Output:** A clean, consistent, and analysis-ready sales dataset stored in `silver.sarisari_sales`.
