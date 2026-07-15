/*=============================================================================
  HANDS-ON LAB: Toronto Shelter Occupancy Data Pipeline
  Step 3 - Standardize & Transform
  
  Demonstrates the "T" in ETL:
  - Type casting and column standardization
  - Aggregated daily summary by sector and city
  - Monthly trend view with occupancy calculations
=============================================================================*/

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE OPS_HOL_WH;
USE SCHEMA OPS_HACKATHON.HOMELESSNESS;

-- ==========================================================================
-- STEP 3A: Create a clean, typed table from raw landing zone
-- ==========================================================================
CREATE OR REPLACE TABLE SHELTER_OCCUPANCY AS
SELECT
    _ID,
    TRY_TO_DATE(OCCUPANCY_DATE, 'YYYY-MM-DD')  AS OCCUPANCY_DATE,
    ORGANIZATION_ID,
    TRIM(ORGANIZATION_NAME)                     AS ORGANIZATION_NAME,
    SHELTER_ID,
    TRIM(SHELTER_GROUP)                         AS SHELTER_GROUP,
    LOCATION_ID,
    TRIM(LOCATION_NAME)                         AS LOCATION_NAME,
    TRIM(LOCATION_ADDRESS)                      AS LOCATION_ADDRESS,
    UPPER(TRIM(LOCATION_POSTAL_CODE))           AS LOCATION_POSTAL_CODE,
    TRIM(LOCATION_CITY)                         AS LOCATION_CITY,
    TRIM(LOCATION_PROVINCE)                     AS LOCATION_PROVINCE,
    PROGRAM_ID,
    TRIM(PROGRAM_NAME)                          AS PROGRAM_NAME,
    TRIM(SECTOR)                                AS SECTOR,
    TRIM(PROGRAM_MODEL)                         AS PROGRAM_MODEL,
    TRIM(OVERNIGHT_SERVICE_TYPE)                AS OVERNIGHT_SERVICE_TYPE,
    TRIM(PROGRAM_AREA)                          AS PROGRAM_AREA,
    COALESCE(SERVICE_USER_COUNT, 0)             AS SERVICE_USER_COUNT,
    TRIM(CAPACITY_TYPE)                         AS CAPACITY_TYPE,
    COALESCE(CAPACITY_ACTUAL_BED, 0)            AS CAPACITY_ACTUAL_BED,
    COALESCE(CAPACITY_FUNDING_BED, 0)           AS CAPACITY_FUNDING_BED,
    COALESCE(OCCUPIED_BEDS, 0)                  AS OCCUPIED_BEDS,
    COALESCE(UNOCCUPIED_BEDS, 0)               AS UNOCCUPIED_BEDS,
    COALESCE(UNAVAILABLE_BEDS, 0)              AS UNAVAILABLE_BEDS,
    COALESCE(CAPACITY_ACTUAL_ROOM, 0)           AS CAPACITY_ACTUAL_ROOM,
    COALESCE(CAPACITY_FUNDING_ROOM, 0)          AS CAPACITY_FUNDING_ROOM,
    COALESCE(OCCUPIED_ROOMS, 0)                 AS OCCUPIED_ROOMS,
    COALESCE(UNOCCUPIED_ROOMS, 0)              AS UNOCCUPIED_ROOMS,
    COALESCE(UNAVAILABLE_ROOMS, 0)             AS UNAVAILABLE_ROOMS,
    OCCUPANCY_RATE_BEDS,
    OCCUPANCY_RATE_ROOMS
FROM SHELTER_OCCUPANCY_RAW;

-- Verify
SELECT COUNT(*) AS ROWS_CLEANED FROM SHELTER_OCCUPANCY;

-- ==========================================================================
-- STEP 3B: Daily Summary by Sector and City
-- ==========================================================================
CREATE OR REPLACE VIEW DAILY_OCCUPANCY_SUMMARY AS
SELECT
    OCCUPANCY_DATE,
    SECTOR,
    LOCATION_CITY,
    COUNT(DISTINCT LOCATION_ID)                     AS NUM_LOCATIONS,
    SUM(SERVICE_USER_COUNT)                         AS TOTAL_USERS,
    SUM(CAPACITY_ACTUAL_BED + CAPACITY_ACTUAL_ROOM) AS TOTAL_CAPACITY,
    SUM(OCCUPIED_BEDS + OCCUPIED_ROOMS)             AS TOTAL_OCCUPIED,
    ROUND(
        DIV0(
            SUM(OCCUPIED_BEDS + OCCUPIED_ROOMS),
            NULLIF(SUM(CAPACITY_ACTUAL_BED + CAPACITY_ACTUAL_ROOM), 0)
        ) * 100, 1
    )                                               AS OCCUPANCY_RATE_PCT
FROM SHELTER_OCCUPANCY
GROUP BY OCCUPANCY_DATE, SECTOR, LOCATION_CITY;

-- Quick check
SELECT * FROM DAILY_OCCUPANCY_SUMMARY
WHERE OCCUPANCY_DATE = '2024-01-15'
ORDER BY SECTOR, LOCATION_CITY;

-- ==========================================================================
-- STEP 3C: Monthly Trend with Month-over-Month Change
-- ==========================================================================
CREATE OR REPLACE VIEW MONTHLY_OCCUPANCY_TREND AS
WITH MONTHLY AS (
    SELECT
        DATE_TRUNC('MONTH', OCCUPANCY_DATE)::DATE   AS MONTH,
        SECTOR,
        SUM(OCCUPIED_BEDS + OCCUPIED_ROOMS)         AS TOTAL_OCCUPIED,
        SUM(CAPACITY_ACTUAL_BED + CAPACITY_ACTUAL_ROOM) AS TOTAL_CAPACITY,
        ROUND(
            DIV0(
                SUM(OCCUPIED_BEDS + OCCUPIED_ROOMS),
                NULLIF(SUM(CAPACITY_ACTUAL_BED + CAPACITY_ACTUAL_ROOM), 0)
            ) * 100, 1
        )                                           AS OCCUPANCY_RATE_PCT
    FROM SHELTER_OCCUPANCY
    GROUP BY DATE_TRUNC('MONTH', OCCUPANCY_DATE), SECTOR
)
SELECT
    MONTH,
    SECTOR,
    TOTAL_OCCUPIED,
    TOTAL_CAPACITY,
    OCCUPANCY_RATE_PCT,
    LAG(OCCUPANCY_RATE_PCT) OVER (
        PARTITION BY SECTOR ORDER BY MONTH
    )                                               AS PREV_MONTH_RATE,
    OCCUPANCY_RATE_PCT - LAG(OCCUPANCY_RATE_PCT) OVER (
        PARTITION BY SECTOR ORDER BY MONTH
    )                                               AS MOM_CHANGE_PCT
FROM MONTHLY
ORDER BY MONTH, SECTOR;

-- Preview the trend
SELECT * FROM MONTHLY_OCCUPANCY_TREND
WHERE MONTH >= '2024-01-01'
ORDER BY MONTH, SECTOR;
