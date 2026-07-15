-- Load 5 Ontario public health CSV files into raw landing tables from internal stage.
-- Co-authored with CoCo
/*=============================================================================
  Ontario Public Health Intelligence Agent
  Step 2 - Load CSV into Snowflake
  
  This script loads 5 public health CSV files from the internal stage into
  raw landing tables:
    1. outbreak_cases     - Outbreak case counts by setting/category
    2. outbreaks_by_phu   - Active outbreaks by Public Health Unit
    3. ltc_summary_phu    - LTC outbreak summary by PHU
    4. ltc_resolved       - Facility-level LTC details
    5. hospital_icu       - Hospital/ICU burden by region
=============================================================================*/

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE OPS_HOL_WH;
USE SCHEMA OPS_HACKATHON.PUBLIC_HEALTH;

-- ==========================================================================
-- TABLE 1: Outbreak Cases (what is spreading?)
-- ==========================================================================
CREATE OR REPLACE TABLE OUTBREAK_CASES_RAW (
    DATE                VARCHAR,
    CATEGORY_GROUPED    VARCHAR,
    OUTBREAK_SUBGROUP   VARCHAR,
    TOTAL_CASES         NUMBER
);

COPY INTO OUTBREAK_CASES_RAW
FROM @DATA_LOAD/outbreak_cases.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

SELECT COUNT(*) AS OUTBREAK_CASES_ROWS FROM OUTBREAK_CASES_RAW;

-- ==========================================================================
-- TABLE 2: Outbreaks by PHU (where is it spreading?)
-- ==========================================================================
CREATE OR REPLACE TABLE OUTBREAKS_BY_PHU_RAW (
    DATE                        VARCHAR,
    PHU_NAME                    VARCHAR,
    PHU_NUM                     NUMBER,
    OUTBREAK_GROUP              VARCHAR,
    NUMBER_ONGOING_OUTBREAKS    NUMBER
);

COPY INTO OUTBREAKS_BY_PHU_RAW
FROM @DATA_LOAD/outbreaks_by_phu.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

SELECT COUNT(*) AS OUTBREAKS_BY_PHU_ROWS FROM OUTBREAKS_BY_PHU_RAW;

-- ==========================================================================
-- TABLE 3: LTC Summary by PHU (how are vulnerable seniors affected?)
-- ==========================================================================
CREATE OR REPLACE TABLE LTC_SUMMARY_PHU_RAW (
    REPORT_DATA_EXTRACTED               VARCHAR,
    PHU_NUM                             NUMBER,
    PHU                                 VARCHAR,
    LTC_HOMES_WITH_ACTIVE_OUTBREAK      NUMBER,
    LTC_HOMES_WITH_RESOLVED_OUTBREAK    NUMBER,
    CONFIRMED_ACTIVE_LTC_RESIDENT_CASES NUMBER,
    CONFIRMED_ACTIVE_LTC_HCW_CASES      NUMBER,
    TOTAL_LTC_RESIDENT_DEATHS           NUMBER,
    TOTAL_LTC_HCW_DEATHS                NUMBER
);

COPY INTO LTC_SUMMARY_PHU_RAW
FROM @DATA_LOAD/ltc_summary_phu.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

SELECT COUNT(*) AS LTC_SUMMARY_ROWS FROM LTC_SUMMARY_PHU_RAW;

-- ==========================================================================
-- TABLE 4: LTC Resolved - Facility Level (which LTC homes are impacted?)
-- ==========================================================================
CREATE OR REPLACE TABLE LTC_RESOLVED_RAW (
    REPORT_DATA_EXTRACTED       VARCHAR,
    PHU_NUM                     NUMBER,
    PHU                         VARCHAR,
    LTC_HOME                    VARCHAR,
    CITY                        VARCHAR,
    BEDS                        NUMBER,
    TOTAL_LTC_RESIDENT_DEATHS   NUMBER
);

COPY INTO LTC_RESOLVED_RAW
FROM @DATA_LOAD/ltc_resolved.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

SELECT COUNT(*) AS LTC_RESOLVED_ROWS FROM LTC_RESOLVED_RAW;

-- ==========================================================================
-- TABLE 5: Hospital & ICU (what is the impact on hospitals?)
-- ==========================================================================
CREATE OR REPLACE TABLE HOSPITAL_ICU_RAW (
    DATE                        VARCHAR,
    OH_REGION                   VARCHAR,
    ICU_CURRENT_COVID           NUMBER,
    ICU_CURRENT_COVID_VENTED    NUMBER,
    HOSPITALIZATIONS            NUMBER,
    ICU_CRCI_TOTAL              NUMBER,
    ICU_CRCI_TOTAL_VENTED       NUMBER,
    ICU_FORMER_COVID            NUMBER,
    ICU_FORMER_COVID_VENTED     NUMBER
);

COPY INTO HOSPITAL_ICU_RAW
FROM @DATA_LOAD/hospital_icu.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

SELECT COUNT(*) AS HOSPITAL_ICU_ROWS FROM HOSPITAL_ICU_RAW;

-- ==========================================================================
-- VERIFY: Quick sample from each table
-- ==========================================================================
SELECT 'OUTBREAK_CASES' AS SOURCE, * FROM OUTBREAK_CASES_RAW LIMIT 3;
SELECT 'OUTBREAKS_BY_PHU' AS SOURCE, * FROM OUTBREAKS_BY_PHU_RAW LIMIT 3;
SELECT 'LTC_SUMMARY_PHU' AS SOURCE, * FROM LTC_SUMMARY_PHU_RAW LIMIT 3;
SELECT 'LTC_RESOLVED' AS SOURCE, * FROM LTC_RESOLVED_RAW LIMIT 3;
SELECT 'HOSPITAL_ICU' AS SOURCE, * FROM HOSPITAL_ICU_RAW LIMIT 3;
