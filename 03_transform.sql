-- Transform raw public health tables into clean typed tables and analytical views.
-- Co-authored with CoCo
/*=============================================================================
  Ontario Public Health Intelligence Agent
  Step 3 - Standardize & Transform

  Demonstrates the "T" in ETL:
  - Type casting (VARCHAR dates → DATE)
  - String standardization
  - Null handling
  - Analytical views for outbreak trends, geographic risk, LTC vulnerability,
    and healthcare capacity pressure
=============================================================================*/

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE OPS_HOL_WH;
USE SCHEMA OPS_HACKATHON.PUBLIC_HEALTH;

-- ==========================================================================
-- STEP 3A: Clean & type-cast raw tables
-- ==========================================================================

-- 1. Outbreak Cases (what is spreading?)
CREATE OR REPLACE TABLE OUTBREAK_CASES AS
SELECT
    TRY_TO_DATE(DATE, 'YYYY-MM-DD')    AS REPORT_DATE,
    TRIM(CATEGORY_GROUPED)              AS OUTBREAK_CATEGORY,
    TRIM(OUTBREAK_SUBGROUP)             AS OUTBREAK_SETTING,
    COALESCE(TOTAL_CASES, 0)            AS TOTAL_CASES
FROM OUTBREAK_CASES_RAW
WHERE TRY_TO_DATE(DATE, 'YYYY-MM-DD') IS NOT NULL;

SELECT COUNT(*) AS OUTBREAK_CASES_CLEANED FROM OUTBREAK_CASES;

-- 2. Outbreaks by PHU (where is it spreading?)
CREATE OR REPLACE TABLE OUTBREAKS_BY_PHU AS
SELECT
    TRY_TO_DATE(DATE, 'YYYY-MM-DD')    AS REPORT_DATE,
    TRIM(PHU_NAME)                      AS PHU_NAME,
    PHU_NUM,
    TRIM(OUTBREAK_GROUP)                AS OUTBREAK_GROUP,
    COALESCE(NUMBER_ONGOING_OUTBREAKS, 0) AS ONGOING_OUTBREAKS
FROM OUTBREAKS_BY_PHU_RAW
WHERE TRY_TO_DATE(DATE, 'YYYY-MM-DD') IS NOT NULL;

SELECT COUNT(*) AS OUTBREAKS_BY_PHU_CLEANED FROM OUTBREAKS_BY_PHU;

-- 3. LTC Summary by PHU (how are seniors affected?)
CREATE OR REPLACE TABLE LTC_SUMMARY_PHU AS
SELECT
    TRY_TO_DATE(REPORT_DATA_EXTRACTED, 'YYYY-MM-DD') AS REPORT_DATE,
    PHU_NUM,
    TRIM(PHU)                                        AS PHU_NAME,
    COALESCE(LTC_HOMES_WITH_ACTIVE_OUTBREAK, 0)      AS ACTIVE_OUTBREAK_HOMES,
    COALESCE(LTC_HOMES_WITH_RESOLVED_OUTBREAK, 0)    AS RESOLVED_OUTBREAK_HOMES,
    COALESCE(CONFIRMED_ACTIVE_LTC_RESIDENT_CASES, 0) AS RESIDENT_CASES,
    COALESCE(CONFIRMED_ACTIVE_LTC_HCW_CASES, 0)     AS HCW_CASES,
    COALESCE(TOTAL_LTC_RESIDENT_DEATHS, 0)           AS RESIDENT_DEATHS,
    COALESCE(TOTAL_LTC_HCW_DEATHS, 0)               AS HCW_DEATHS
FROM LTC_SUMMARY_PHU_RAW
WHERE TRY_TO_DATE(REPORT_DATA_EXTRACTED, 'YYYY-MM-DD') IS NOT NULL;

SELECT COUNT(*) AS LTC_SUMMARY_CLEANED FROM LTC_SUMMARY_PHU;

-- 4. LTC Resolved - Facility Level (which homes are impacted?)
CREATE OR REPLACE TABLE LTC_RESOLVED AS
SELECT
    TRY_TO_DATE(REPORT_DATA_EXTRACTED, 'YYYY-MM-DD') AS REPORT_DATE,
    PHU_NUM,
    TRIM(PHU)                                        AS PHU_NAME,
    TRIM(LTC_HOME)                                   AS LTC_HOME_NAME,
    TRIM(CITY)                                       AS CITY,
    COALESCE(BEDS, 0)                                AS BED_CAPACITY,
    COALESCE(TOTAL_LTC_RESIDENT_DEATHS, 0)           AS RESIDENT_DEATHS
FROM LTC_RESOLVED_RAW
WHERE TRY_TO_DATE(REPORT_DATA_EXTRACTED, 'YYYY-MM-DD') IS NOT NULL;

SELECT COUNT(*) AS LTC_RESOLVED_CLEANED FROM LTC_RESOLVED;

-- 5. Hospital & ICU (healthcare system burden)
CREATE OR REPLACE TABLE HOSPITAL_ICU AS
SELECT
    TRY_TO_DATE(DATE, 'YYYY-MM-DD')    AS REPORT_DATE,
    TRIM(OH_REGION)                     AS REGION,
    COALESCE(ICU_CURRENT_COVID, 0)      AS ICU_COVID_PATIENTS,
    COALESCE(ICU_CURRENT_COVID_VENTED, 0) AS ICU_COVID_VENTILATED,
    COALESCE(HOSPITALIZATIONS, 0)       AS HOSPITALIZATIONS,
    COALESCE(ICU_CRCI_TOTAL, 0)         AS ICU_TOTAL,
    COALESCE(ICU_CRCI_TOTAL_VENTED, 0)  AS ICU_TOTAL_VENTILATED,
    COALESCE(ICU_FORMER_COVID, 0)       AS ICU_FORMER_COVID,
    COALESCE(ICU_FORMER_COVID_VENTED, 0) AS ICU_FORMER_COVID_VENTILATED
FROM HOSPITAL_ICU_RAW
WHERE TRY_TO_DATE(DATE, 'YYYY-MM-DD') IS NOT NULL;

SELECT COUNT(*) AS HOSPITAL_ICU_CLEANED FROM HOSPITAL_ICU;

-- ==========================================================================
-- STEP 3B: Outbreak Trends by Category (weekly aggregation)
-- ==========================================================================
CREATE OR REPLACE VIEW WEEKLY_OUTBREAK_TREND AS
SELECT
    DATE_TRUNC('WEEK', REPORT_DATE)::DATE   AS WEEK_START,
    OUTBREAK_CATEGORY,
    SUM(TOTAL_CASES)                        AS WEEKLY_CASES,
    LAG(SUM(TOTAL_CASES)) OVER (
        PARTITION BY OUTBREAK_CATEGORY ORDER BY DATE_TRUNC('WEEK', REPORT_DATE)
    )                                       AS PREV_WEEK_CASES,
    ROUND(DIV0(
        SUM(TOTAL_CASES) - LAG(SUM(TOTAL_CASES)) OVER (
            PARTITION BY OUTBREAK_CATEGORY ORDER BY DATE_TRUNC('WEEK', REPORT_DATE)
        ),
        NULLIF(LAG(SUM(TOTAL_CASES)) OVER (
            PARTITION BY OUTBREAK_CATEGORY ORDER BY DATE_TRUNC('WEEK', REPORT_DATE)
        ), 0)
    ) * 100, 1)                             AS WOW_CHANGE_PCT
FROM OUTBREAK_CASES
GROUP BY DATE_TRUNC('WEEK', REPORT_DATE), OUTBREAK_CATEGORY;

-- ==========================================================================
-- STEP 3C: Geographic Risk - PHU Outbreak Burden
-- ==========================================================================
CREATE OR REPLACE VIEW PHU_OUTBREAK_SUMMARY AS
SELECT
    REPORT_DATE,
    PHU_NAME,
    PHU_NUM,
    SUM(ONGOING_OUTBREAKS)                  AS TOTAL_ONGOING_OUTBREAKS,
    COUNT(DISTINCT OUTBREAK_GROUP)          AS OUTBREAK_CATEGORIES_AFFECTED
FROM OUTBREAKS_BY_PHU
GROUP BY REPORT_DATE, PHU_NAME, PHU_NUM;

-- ==========================================================================
-- STEP 3D: LTC Vulnerability Score by PHU
-- ==========================================================================
CREATE OR REPLACE VIEW LTC_VULNERABILITY AS
SELECT
    REPORT_DATE,
    PHU_NAME,
    PHU_NUM,
    ACTIVE_OUTBREAK_HOMES,
    RESIDENT_CASES,
    HCW_CASES,
    RESIDENT_DEATHS,
    ACTIVE_OUTBREAK_HOMES + RESOLVED_OUTBREAK_HOMES AS TOTAL_AFFECTED_HOMES,
    ROUND(DIV0(RESIDENT_DEATHS, NULLIF(RESIDENT_CASES, 0)) * 100, 1) AS CASE_FATALITY_RATE_PCT
FROM LTC_SUMMARY_PHU;

-- ==========================================================================
-- STEP 3E: Healthcare Capacity - Daily Provincial Summary
-- ==========================================================================
CREATE OR REPLACE VIEW DAILY_HEALTHCARE_PRESSURE AS
SELECT
    REPORT_DATE,
    SUM(HOSPITALIZATIONS)           AS TOTAL_HOSPITALIZATIONS,
    SUM(ICU_COVID_PATIENTS)         AS TOTAL_ICU_COVID,
    SUM(ICU_COVID_VENTILATED)       AS TOTAL_ICU_VENTILATED,
    SUM(ICU_TOTAL)                  AS TOTAL_ICU_ALL_CAUSES,
    ROUND(DIV0(
        SUM(ICU_COVID_VENTILATED),
        NULLIF(SUM(ICU_COVID_PATIENTS), 0)
    ) * 100, 1)                     AS VENTILATION_RATE_PCT,
    LAG(SUM(HOSPITALIZATIONS), 7) OVER (ORDER BY REPORT_DATE) AS HOSPITALIZATIONS_7D_AGO,
    ROUND(DIV0(
        SUM(HOSPITALIZATIONS) - LAG(SUM(HOSPITALIZATIONS), 7) OVER (ORDER BY REPORT_DATE),
        NULLIF(LAG(SUM(HOSPITALIZATIONS), 7) OVER (ORDER BY REPORT_DATE), 0)
    ) * 100, 1)                     AS HOSPITALIZATION_7D_CHANGE_PCT
FROM HOSPITAL_ICU
GROUP BY REPORT_DATE;

-- ==========================================================================
-- STEP 3F: Regional Healthcare Breakdown
-- ==========================================================================
CREATE OR REPLACE VIEW REGIONAL_HEALTHCARE_PRESSURE AS
SELECT
    REPORT_DATE,
    REGION,
    HOSPITALIZATIONS,
    ICU_COVID_PATIENTS,
    ICU_COVID_VENTILATED,
    ICU_TOTAL,
    LAG(HOSPITALIZATIONS, 7) OVER (
        PARTITION BY REGION ORDER BY REPORT_DATE
    )                               AS HOSPITALIZATIONS_7D_AGO,
    HOSPITALIZATIONS - LAG(HOSPITALIZATIONS, 7) OVER (
        PARTITION BY REGION ORDER BY REPORT_DATE
    )                               AS HOSPITALIZATION_7D_CHANGE
FROM HOSPITAL_ICU;

-- ==========================================================================
-- VERIFY: Preview analytical views
-- ==========================================================================
SELECT * FROM WEEKLY_OUTBREAK_TREND ORDER BY WEEK_START DESC LIMIT 10;
SELECT * FROM PHU_OUTBREAK_SUMMARY ORDER BY REPORT_DATE DESC, TOTAL_ONGOING_OUTBREAKS DESC LIMIT 10;
SELECT * FROM DAILY_HEALTHCARE_PRESSURE ORDER BY REPORT_DATE DESC LIMIT 10;
