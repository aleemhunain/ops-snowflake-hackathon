/*=============================================================================
  HANDS-ON LAB: Toronto Shelter Occupancy Data Pipeline
  Step 2 - Load CSV into Snowflake
  
  This script loads the 3 yearly CSV files from the internal stage into 
  a single raw landing table (~148,000 rows across 2023-2025).
=============================================================================*/

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE OPS_HOL_WH;
USE SCHEMA OPS_HACKATHON.HOMELESSNESS;

-- Create the raw landing table
CREATE OR REPLACE TABLE SHELTER_OCCUPANCY_RAW (
    _ID                     NUMBER,
    OCCUPANCY_DATE          VARCHAR,
    ORGANIZATION_ID         NUMBER,
    ORGANIZATION_NAME       VARCHAR,
    SHELTER_ID              NUMBER,
    SHELTER_GROUP           VARCHAR,
    LOCATION_ID             NUMBER,
    LOCATION_NAME           VARCHAR,
    LOCATION_ADDRESS        VARCHAR,
    LOCATION_POSTAL_CODE    VARCHAR,
    LOCATION_CITY           VARCHAR,
    LOCATION_PROVINCE       VARCHAR,
    PROGRAM_ID              NUMBER,
    PROGRAM_NAME            VARCHAR,
    SECTOR                  VARCHAR,
    PROGRAM_MODEL           VARCHAR,
    OVERNIGHT_SERVICE_TYPE  VARCHAR,
    PROGRAM_AREA            VARCHAR,
    SERVICE_USER_COUNT      NUMBER,
    CAPACITY_TYPE           VARCHAR,
    CAPACITY_ACTUAL_BED     NUMBER,
    CAPACITY_FUNDING_BED    NUMBER,
    OCCUPIED_BEDS           NUMBER,
    UNOCCUPIED_BEDS         NUMBER,
    UNAVAILABLE_BEDS        NUMBER,
    CAPACITY_ACTUAL_ROOM    NUMBER,
    CAPACITY_FUNDING_ROOM   NUMBER,
    OCCUPIED_ROOMS          NUMBER,
    UNOCCUPIED_ROOMS        NUMBER,
    UNAVAILABLE_ROOMS       NUMBER,
    OCCUPANCY_RATE_BEDS     FLOAT,
    OCCUPANCY_RATE_ROOMS    FLOAT
);

-- Load all 3 yearly files from stage
COPY INTO SHELTER_OCCUPANCY_RAW
FROM @DATA_LOAD
FILE_FORMAT = CSV_FORMAT
PATTERN = '.*shelter_202[3-5].*\\.csv.*'
ON_ERROR = 'CONTINUE';

-- Verify the load
SELECT COUNT(*) AS ROW_COUNT FROM SHELTER_OCCUPANCY_RAW;
-- Expected: ~148,000 rows (48K + 49K + 52K across 3 years)

-- Quick sample to confirm data looks correct
SELECT * FROM SHELTER_OCCUPANCY_RAW LIMIT 10;

-- Check date range covers all 3 years
SELECT 
    MIN(OCCUPANCY_DATE) AS EARLIEST_DATE,
    MAX(OCCUPANCY_DATE) AS LATEST_DATE,
    COUNT(DISTINCT LEFT(OCCUPANCY_DATE, 4)) AS NUM_YEARS
FROM SHELTER_OCCUPANCY_RAW;
