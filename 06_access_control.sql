-- Role-based access control for the public health semantic view and agent.
-- Co-authored with CoCo
/*=============================================================================
  Ontario Public Health Intelligence Agent
  Step 6 - Access Control & Governance

  Defines role-based permissions so the right people can access the agent,
  semantic view, and underlying data. No data masking is needed here because
  the datasets contain no individual-level PII — all data operates at
  community, regional, institutional, and healthcare system levels using
  publicly reported Ontario open data.

  Roles:
    OPS_ADMIN    - Full access: manage objects, grant permissions, modify schema
    OPS_ANALYST  - Query access: use agent, query tables/views, read semantic view
    OPS_VIEWER   - Agent-only access: interact via CoWork but cannot run direct SQL
=============================================================================*/

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE OPS_HOL_WH;
USE SCHEMA OPS_HACKATHON.PUBLIC_HEALTH;

-- ==========================================================================
-- STEP 6A: Create Roles
-- ==========================================================================
CREATE OR REPLACE ROLE OPS_ADMIN;
CREATE OR REPLACE ROLE OPS_ANALYST;
CREATE OR REPLACE ROLE OPS_VIEWER;

-- Role hierarchy: ADMIN > ANALYST > VIEWER
GRANT ROLE OPS_VIEWER TO ROLE OPS_ANALYST;
GRANT ROLE OPS_ANALYST TO ROLE OPS_ADMIN;
GRANT ROLE OPS_ADMIN TO ROLE ACCOUNTADMIN;

-- ==========================================================================
-- STEP 6B: Warehouse Access
-- ==========================================================================
GRANT USAGE ON WAREHOUSE OPS_HOL_WH TO ROLE OPS_ADMIN;
GRANT USAGE ON WAREHOUSE OPS_HOL_WH TO ROLE OPS_ANALYST;
GRANT USAGE ON WAREHOUSE OPS_HOL_WH TO ROLE OPS_VIEWER;

-- ==========================================================================
-- STEP 6C: Database & Schema Access
-- ==========================================================================
GRANT USAGE ON DATABASE OPS_HACKATHON TO ROLE OPS_ADMIN;
GRANT USAGE ON DATABASE OPS_HACKATHON TO ROLE OPS_ANALYST;
GRANT USAGE ON DATABASE OPS_HACKATHON TO ROLE OPS_VIEWER;

GRANT USAGE ON SCHEMA OPS_HACKATHON.PUBLIC_HEALTH TO ROLE OPS_ADMIN;
GRANT USAGE ON SCHEMA OPS_HACKATHON.PUBLIC_HEALTH TO ROLE OPS_ANALYST;
GRANT USAGE ON SCHEMA OPS_HACKATHON.PUBLIC_HEALTH TO ROLE OPS_VIEWER;

-- ==========================================================================
-- STEP 6D: Table & View Access (Analyst and Admin only)
-- ==========================================================================
GRANT SELECT ON ALL TABLES IN SCHEMA OPS_HACKATHON.PUBLIC_HEALTH TO ROLE OPS_ANALYST;
GRANT SELECT ON ALL VIEWS IN SCHEMA OPS_HACKATHON.PUBLIC_HEALTH TO ROLE OPS_ANALYST;

-- Future tables/views automatically accessible to analysts
GRANT SELECT ON FUTURE TABLES IN SCHEMA OPS_HACKATHON.PUBLIC_HEALTH TO ROLE OPS_ANALYST;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA OPS_HACKATHON.PUBLIC_HEALTH TO ROLE OPS_ANALYST;

-- Admin gets full control
GRANT ALL ON SCHEMA OPS_HACKATHON.PUBLIC_HEALTH TO ROLE OPS_ADMIN;
GRANT SELECT ON ALL TABLES IN SCHEMA OPS_HACKATHON.PUBLIC_HEALTH TO ROLE OPS_ADMIN;
GRANT SELECT ON ALL VIEWS IN SCHEMA OPS_HACKATHON.PUBLIC_HEALTH TO ROLE OPS_ADMIN;

-- ==========================================================================
-- STEP 6E: Semantic View Access (Analyst and Viewer)
-- ==========================================================================
GRANT SELECT ON SEMANTIC VIEW OPS_HACKATHON.PUBLIC_HEALTH.PUBLIC_HEALTH_INTELLIGENCE TO ROLE OPS_ANALYST;
GRANT SELECT ON SEMANTIC VIEW OPS_HACKATHON.PUBLIC_HEALTH.PUBLIC_HEALTH_INTELLIGENCE TO ROLE OPS_VIEWER;

-- ==========================================================================
-- STEP 6F: Agent Access (all roles can use the agent)
-- ==========================================================================
GRANT USAGE ON AGENT OPS_HACKATHON.PUBLIC_HEALTH.PUBLIC_HEALTH_AGENT TO ROLE OPS_ADMIN;
GRANT USAGE ON AGENT OPS_HACKATHON.PUBLIC_HEALTH.PUBLIC_HEALTH_AGENT TO ROLE OPS_ANALYST;
GRANT USAGE ON AGENT OPS_HACKATHON.PUBLIC_HEALTH.PUBLIC_HEALTH_AGENT TO ROLE OPS_VIEWER;

-- ==========================================================================
-- STEP 6G: Verify Role Grants
-- ==========================================================================
SHOW GRANTS TO ROLE OPS_ADMIN;
SHOW GRANTS TO ROLE OPS_ANALYST;
SHOW GRANTS TO ROLE OPS_VIEWER;

-- ==========================================================================
-- STEP 6H: Test Access Levels
-- ==========================================================================

-- As ANALYST: can query tables directly AND use the agent
USE ROLE OPS_ANALYST;
USE WAREHOUSE OPS_HOL_WH;

SELECT PHU_NAME, SUM(ONGOING_OUTBREAKS) AS TOTAL
FROM OPS_HACKATHON.PUBLIC_HEALTH.OUTBREAKS_BY_PHU
WHERE REPORT_DATE = (SELECT MAX(REPORT_DATE) FROM OPS_HACKATHON.PUBLIC_HEALTH.OUTBREAKS_BY_PHU)
GROUP BY PHU_NAME
ORDER BY TOTAL DESC
LIMIT 5;
-- Expected: Returns results (direct SQL access granted)

-- As VIEWER: can use the agent but NOT query tables directly
USE ROLE OPS_VIEWER;
USE WAREHOUSE OPS_HOL_WH;

SELECT * FROM OPS_HACKATHON.PUBLIC_HEALTH.OUTBREAKS_BY_PHU LIMIT 1;
-- Expected: FAILS with insufficient privileges
-- (Viewers interact through the agent in CoWork only)

-- Reset to admin
USE ROLE ACCOUNTADMIN;

/*=============================================================================
  ACCESS MODEL SUMMARY

  Role          | Direct SQL | Semantic View | Agent (CoWork) | Manage Objects
  --------------|-----------|---------------|----------------|---------------
  OPS_ADMIN     | Yes        | Yes           | Yes            | Yes
  OPS_ANALYST   | Yes        | Yes           | Yes            | No
  OPS_VIEWER    | No         | Yes           | Yes            | No
  
  KEY PRINCIPLE: Governance flows through to the agent automatically.
  
  When OPS_VIEWER uses the agent in Snowflake Intelligence:
  - They can ask natural language questions
  - The agent generates and executes SQL on their behalf
  - Results are returned through the agent's response
  - They cannot bypass the agent to run arbitrary SQL
  
  This creates a controlled, conversational interface for stakeholders
  (policymakers, community leaders, media) who need insights but should
  not have direct database access.

  TO ADD TEAM MEMBERS:
    GRANT ROLE OPS_ANALYST TO USER <username>;   -- data analysts
    GRANT ROLE OPS_VIEWER TO USER <username>;    -- stakeholders/executives
    GRANT ROLE OPS_ADMIN TO USER <username>;     -- data engineers
=============================================================================*/
