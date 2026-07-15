-- Environment setup for public health data pipeline: warehouse, database, schema, stage, and file format.
-- Co-authored with CoCo
/*=============================================================================
  HANDS-ON LAB: Ontario Public Health Data Pipeline
  Step 1 - Environment Setup
  
  This script creates the database, schema, warehouse, stage, and file format
  needed to load public health datasets (outbreaks, cases, etc.).
=============================================================================*/

USE ROLE ACCOUNTADMIN;

-- Create warehouse for the lab
CREATE OR REPLACE WAREHOUSE OPS_HOL_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;

-- Create database and schema
CREATE OR REPLACE DATABASE OPS_HACKATHON;
CREATE OR REPLACE SCHEMA OPS_HACKATHON.PUBLIC_HEALTH;

-- Create internal stage for CSV uploads
CREATE OR REPLACE STAGE OPS_HACKATHON.PUBLIC_HEALTH.DATA_LOAD
  DIRECTORY = (ENABLE = TRUE);

-- Create CSV file format
CREATE OR REPLACE FILE FORMAT OPS_HACKATHON.PUBLIC_HEALTH.CSV_FORMAT
  TYPE = 'CSV'
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  SKIP_HEADER = 1
  NULL_IF = ('', 'NULL', 'null')
  EMPTY_FIELD_AS_NULL = TRUE;

/*
  UPLOAD YOUR CSV FILES:
  
  Upload your 5 public health CSV files to the stage.

  Option A - Using Snowsight UI:
    1. Navigate to Data > Databases > OPS_HACKATHON > PUBLIC_HEALTH > Stages
    2. Click on DATA_LOAD
    3. Click "+ Files" button
    4. Upload all 5 CSV files

  Option B - Using SnowSQL or Snowflake CLI:
    PUT file:///path/to/your_file.csv @OPS_HACKATHON.PUBLIC_HEALTH.DATA_LOAD AUTO_COMPRESS = TRUE;
*/

-- Verify stage contents after upload
LIST @OPS_HACKATHON.PUBLIC_HEALTH.DATA_LOAD;
