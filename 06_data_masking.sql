-- Data masking and role grants for shelter occupancy pipeline including agent access.
-- Co-authored with CoCo
/*=============================================================================
  HANDS-ON LAB: Toronto Shelter Occupancy Data Pipeline
  Step 6 - Data Masking
  
  Demonstrates column-level security using masking policies.
  Shelter location addresses and postal codes are sensitive (they identify
  where vulnerable populations are housed) and must be protected from
  unauthorized access.
  
  Roles:
    OPS_ADMIN   - Full access to all data including addresses
    OPS_ANALYST - Can query data but sees masked PII columns
=============================================================================*/

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE OPS_HOL_WH;
USE SCHEMA OPS_HACKATHON.HOMELESSNESS;

-- ==========================================================================
-- STEP 6A: Create Roles
-- ==========================================================================
CREATE OR REPLACE ROLE OPS_ADMIN;
CREATE OR REPLACE ROLE OPS_ANALYST;

-- Grant hierarchy: both roles can use warehouse and query data
GRANT USAGE ON WAREHOUSE OPS_HOL_WH TO ROLE OPS_ADMIN;
GRANT USAGE ON WAREHOUSE OPS_HOL_WH TO ROLE OPS_ANALYST;

GRANT USAGE ON DATABASE OPS_HACKATHON TO ROLE OPS_ADMIN;
GRANT USAGE ON DATABASE OPS_HACKATHON TO ROLE OPS_ANALYST;

GRANT USAGE ON SCHEMA OPS_HACKATHON.HOMELESSNESS TO ROLE OPS_ADMIN;
GRANT USAGE ON SCHEMA OPS_HACKATHON.HOMELESSNESS TO ROLE OPS_ANALYST;

GRANT SELECT ON ALL TABLES IN SCHEMA OPS_HACKATHON.HOMELESSNESS TO ROLE OPS_ADMIN;
GRANT SELECT ON ALL TABLES IN SCHEMA OPS_HACKATHON.HOMELESSNESS TO ROLE OPS_ANALYST;

GRANT SELECT ON ALL VIEWS IN SCHEMA OPS_HACKATHON.HOMELESSNESS TO ROLE OPS_ADMIN;
GRANT SELECT ON ALL VIEWS IN SCHEMA OPS_HACKATHON.HOMELESSNESS TO ROLE OPS_ANALYST;

-- Grant semantic view access for CoWork access
GRANT SELECT ON SEMANTIC VIEW OPS_HACKATHON.HOMELESSNESS.SHELTER_ANALYTICS TO ROLE OPS_ADMIN;
GRANT SELECT ON SEMANTIC VIEW OPS_HACKATHON.HOMELESSNESS.SHELTER_ANALYTICS TO ROLE OPS_ANALYST;

-- Grant agent access so both roles can see and use the agent in CoWork
GRANT USAGE ON AGENT OPS_HACKATHON.HOMELESSNESS.SHELTER_AGENT TO ROLE OPS_ADMIN;
GRANT USAGE ON AGENT OPS_HACKATHON.HOMELESSNESS.SHELTER_AGENT TO ROLE OPS_ANALYST;

-- Grant roles to current user
GRANT ROLE OPS_ADMIN TO ROLE ACCOUNTADMIN;
GRANT ROLE OPS_ANALYST TO ROLE ACCOUNTADMIN;

-- ==========================================================================
-- STEP 6B: Create Masking Policies
-- ==========================================================================

-- Policy: Full address redaction for non-admin roles
CREATE OR REPLACE MASKING POLICY ADDRESS_MASK AS (val VARCHAR) RETURNS VARCHAR ->
  CASE
    WHEN CURRENT_ROLE() IN ('OPS_ADMIN', 'ACCOUNTADMIN') THEN val
    ELSE '*** REDACTED ***'
  END;

-- Policy: Show only first 3 characters of postal code (Forward Sortation Area)
CREATE OR REPLACE MASKING POLICY POSTAL_CODE_MASK AS (val VARCHAR) RETURNS VARCHAR ->
  CASE
    WHEN CURRENT_ROLE() IN ('OPS_ADMIN', 'ACCOUNTADMIN') THEN val
    ELSE LEFT(val, 3) || ' ***'
  END;

-- ==========================================================================
-- STEP 6C: Apply Masking Policies to Columns
-- ==========================================================================

-- Apply address masking
ALTER TABLE SHELTER_OCCUPANCY 
  MODIFY COLUMN LOCATION_ADDRESS 
  SET MASKING POLICY ADDRESS_MASK;

-- Apply postal code masking
ALTER TABLE SHELTER_OCCUPANCY 
  MODIFY COLUMN LOCATION_POSTAL_CODE 
  SET MASKING POLICY POSTAL_CODE_MASK;

-- ==========================================================================
-- STEP 6D: Demonstrate Masking in Action
-- ==========================================================================

-- As ADMIN - see full data
USE ROLE OPS_ADMIN;
USE WAREHOUSE OPS_HOL_WH;

SELECT 
    OCCUPANCY_DATE,
    SHELTER_GROUP,
    LOCATION_NAME,
    LOCATION_ADDRESS,
    LOCATION_POSTAL_CODE,
    LOCATION_CITY,
    SECTOR,
    OCCUPIED_BEDS
FROM OPS_HACKATHON.HOMELESSNESS.SHELTER_OCCUPANCY
WHERE OCCUPANCY_DATE = '2024-06-01'
LIMIT 5;
-- Expected: Full addresses visible (e.g., "640 Dixon Rd.")

-- As ANALYST - see masked data
USE ROLE OPS_ANALYST;
USE WAREHOUSE OPS_HOL_WH;

SELECT 
    OCCUPANCY_DATE,
    SHELTER_GROUP,
    LOCATION_NAME,
    LOCATION_ADDRESS,
    LOCATION_POSTAL_CODE,
    LOCATION_CITY,
    SECTOR,
    OCCUPIED_BEDS
FROM OPS_HACKATHON.HOMELESSNESS.SHELTER_OCCUPANCY
WHERE OCCUPANCY_DATE = '2024-06-01'
LIMIT 5;
-- Expected: LOCATION_ADDRESS = '*** REDACTED ***'
--           LOCATION_POSTAL_CODE = 'M9W ***' (only FSA visible)

-- ==========================================================================
-- STEP 6E: Verify Masking Policies are Applied
-- ==========================================================================
USE ROLE ACCOUNTADMIN;

-- Show which policies are attached
SELECT * 
FROM TABLE(INFORMATION_SCHEMA.POLICY_REFERENCES(
  REF_ENTITY_NAME => 'OPS_HACKATHON.HOMELESSNESS.SHELTER_OCCUPANCY',
  REF_ENTITY_DOMAIN => 'TABLE'
));

/*=============================================================================
  KEY TAKEAWAY: GOVERNANCE FLOWS THROUGH TO COWORK
  
  When OPS_ANALYST uses the Cortex Agent in CoWork:
  - They can ask "Show me shelter locations with highest occupancy"
  - The agent generates SQL and returns results
  - BUT the address column shows '*** REDACTED ***'
  - The postal code only shows the FSA (first 3 chars)
  
  This means data masking is enforced at the platform level,
  regardless of whether data is accessed via SQL, dashboards, or AI agents.
  No additional configuration needed - governance just works.
=============================================================================*/