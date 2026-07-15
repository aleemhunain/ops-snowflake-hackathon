/*=============================================================================
  HANDS-ON LAB: Toronto Shelter Occupancy Data Pipeline
  Step 1 - Environment Setup
  
  This script creates the database, schema, warehouse, stage, and file format
  needed to load the Toronto Daily Shelter & Overnight Service Occupancy data.
=============================================================================*/

USE ROLE ACCOUNTADMIN;

-- Create warehouse for the lab
CREATE OR REPLACE WAREHOUSE OPS_HOL_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;

-- Create database and schema
CREATE OR REPLACE DATABASE OPS_HACKATHON;
CREATE OR REPLACE SCHEMA OPS_HACKATHON.HOMELESSNESS;

-- Create internal stage for CSV uploads
CREATE OR REPLACE STAGE OPS_HACKATHON.HOMELESSNESS.DATA_LOAD
  DIRECTORY = (ENABLE = TRUE);

-- Create CSV file format (matches the Toronto Open Data export)
CREATE OR REPLACE FILE FORMAT OPS_HACKATHON.HOMELESSNESS.CSV_FORMAT
  TYPE = 'CSV'
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  SKIP_HEADER = 1
  NULL_IF = ('', 'NULL', 'null')
  EMPTY_FIELD_AS_NULL = TRUE;

/*
  UPLOAD YOUR CSV FILES:
  
  You have 3 files to upload:
    - shelter_2023.csv
    - shelter_2024.csv
    - shelter_2025.csv

  Option A - Using Snowsight UI:
    1. Navigate to Data > Databases > OPS_HACKATHON > HOMELESSNESS > Stages
    2. Click on DATA_LOAD
    3. Click "+ Files" button
    4. Upload all 3 CSV files

  Option B - Using SnowSQL or Snowflake CLI:
    PUT file:///path/to/shelter_2023.csv @OPS_HACKATHON.HOMELESSNESS.DATA_LOAD AUTO_COMPRESS = TRUE;
    PUT file:///path/to/shelter_2024.csv @OPS_HACKATHON.HOMELESSNESS.DATA_LOAD AUTO_COMPRESS = TRUE;
    PUT file:///path/to/shelter_2025.csv @OPS_HACKATHON.HOMELESSNESS.DATA_LOAD AUTO_COMPRESS = TRUE;
*/

-- Verify stage contents after upload
LIST @OPS_HACKATHON.HOMELESSNESS.DATA_LOAD;
