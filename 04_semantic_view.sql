-- Deploy the Ontario Public Health Intelligence semantic view for Cortex Analyst.
-- Co-authored with CoCo
/*=============================================================================
  Ontario Public Health Intelligence Agent
  Step 4 - Semantic View

  This semantic view was generated using Cortex Analyst FastGen and deployed
  to OPS_HACKATHON.PUBLIC_HEALTH.PUBLIC_HEALTH_INTELLIGENCE.

  The YAML definition lives in: cortex_project/PUBLIC_HEALTH_INTELLIGENCE.sv.yaml

  What it defines:
  - 5 tables mapped with dimensions, time dimensions, and measures
  - 5 verified queries (VQRs) that teach the agent how to answer common questions
  - Relationships between tables via PHU_NUM (geographic join key)

  Tables Covered:
    OUTBREAK_CASES     → What is spreading (by category/setting)
    OUTBREAKS_BY_PHU   → Where it is spreading (by Public Health Unit)
    LTC_SUMMARY_PHU    → How vulnerable seniors are affected (PHU-level)
    LTC_RESOLVED       → Which specific LTC homes are impacted
    HOSPITAL_ICU       → Hospital/ICU burden by region

  Verified Queries (pre-validated question → SQL pairs):
    1. Which outbreak categories have the most cases?
    2. Which PHUs currently have the most active outbreaks?
    3. Which PHUs have the highest LTC resident deaths?
    4. Which individual LTC homes have experienced the most deaths?
    5. What is the recent trend in hospitalizations and ICU admissions?
=============================================================================*/

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE OPS_HOL_WH;
USE SCHEMA OPS_HACKATHON.PUBLIC_HEALTH;

-- ==========================================================================
-- VERIFY: Confirm the semantic view exists
-- ==========================================================================
SHOW SEMANTIC VIEWS IN SCHEMA OPS_HACKATHON.PUBLIC_HEALTH;

-- ==========================================================================
-- VERIFY: Describe the semantic view structure
-- ==========================================================================
DESCRIBE SEMANTIC VIEW OPS_HACKATHON.PUBLIC_HEALTH.PUBLIC_HEALTH_INTELLIGENCE;

-- ==========================================================================
-- TEST: Query the semantic view using the SEMANTIC_VIEW() table function
-- ==========================================================================
-- The SEMANTIC_VIEW() function lets you query defined dimensions directly.
-- Note: SNOWFLAKE.CORTEX.ANALYST is NOT a valid function.
-- For natural language queries, use CoWork, the Cortex Analyst REST API,
-- or the Cortex Agent created in step 05.
SELECT * FROM SEMANTIC_VIEW(
  OPS_HACKATHON.PUBLIC_HEALTH.PUBLIC_HEALTH_INTELLIGENCE
  DIMENSIONS OUTBREAK_CASES.OUTBREAK_CATEGORY, OUTBREAK_CASES.OUTBREAK_SETTING
)
LIMIT 10;

/*=============================================================================
  HOW THE SEMANTIC VIEW WORKS

  The YAML defines:

  1. DIMENSIONS (categorical columns for grouping/filtering):
     - OUTBREAK_CATEGORY, OUTBREAK_SETTING (what type of outbreak)
     - PHU_NAME, PHU_NUM (where geographically)
     - REGION (hospital region)
     - LTC_HOME_NAME, CITY (facility-level detail)

  2. TIME DIMENSIONS (date columns for trend analysis):
     - REPORT_DATE on every table (enables time-series questions)

  3. MEASURES (numeric columns for aggregation):
     - TOTAL_CASES, ONGOING_OUTBREAKS
     - ACTIVE_OUTBREAK_HOMES, RESIDENT_CASES, RESIDENT_DEATHS
     - HOSPITALIZATIONS, ICU_COVID_PATIENTS, ICU_COVID_VENTILATED

  4. VERIFIED QUERIES (pre-validated SQL the agent can reuse):
     - 5 VQRs covering the core intelligence themes
     - These give the agent high-confidence answers for common questions

  The semantic view acts as the "brain" between raw data and the Cortex Agent.
  When a user asks a question, Cortex Analyst uses this metadata to generate
  correct SQL — understanding column meanings, valid aggregations, and
  relationships between tables.
=============================================================================*/

/*=============================================================================
  DEPLOYMENT NOTES

  The semantic view was generated and deployed using:
    semantic_studio → semantic_view_generate_spec (FastGen)
    semantic_studio → semantic_view_write (save to workspace)
    semantic_studio → semantic_view_deploy (push to Snowflake)

  To redeploy after YAML edits:
    - Edit cortex_project/PUBLIC_HEALTH_INTELLIGENCE.sv.yaml
    - Use Cortex Code: "deploy my semantic view"
    - Or SQL: CREATE OR ALTER SEMANTIC VIEW ... (requires full spec)

  To add more verified queries:
    - Ask Cortex Code: "suggest VQRs for my semantic view"
    - Or manually add to the verified_queries section of the YAML
=============================================================================*/
