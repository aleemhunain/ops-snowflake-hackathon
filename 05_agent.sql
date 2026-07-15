-- Creates the Ontario Public Health Intelligence Cortex Agent with semantic view tool.
-- Co-authored with CoCo
/*=============================================================================
  Ontario Public Health Intelligence Agent
  Step 5 - Create Cortex Agent + CoWork Integration

  Creates a Cortex Agent that uses the PUBLIC_HEALTH_INTELLIGENCE semantic view
  to answer natural language questions about outbreaks, geographic risk, LTC
  vulnerability, and healthcare capacity across Ontario.
=============================================================================*/

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE OPS_HOL_WH;
USE SCHEMA OPS_HACKATHON.PUBLIC_HEALTH;

-- ==========================================================================
-- PREREQUISITES: Enable cross-region inference for best model access
-- ==========================================================================
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

-- ==========================================================================
-- CREATE THE CORTEX AGENT
-- ==========================================================================
CREATE OR REPLACE AGENT OPS_HACKATHON.PUBLIC_HEALTH.PUBLIC_HEALTH_AGENT
  COMMENT = 'Ontario Public Health Early Warning and Community Resilience Agent - identifies emerging risks, protects vulnerable populations, and supports equitable resource allocation'
  PROFILE = '{"display_name": "Ontario Public Health Analyst", "color": "green"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  orchestration:
    budget:
      seconds: 60
      tokens: 16000

  instructions:
    response: >
      You are the Ontario Public Health Early Warning and Community Resilience Agent.
      Your mission is to help communities identify emerging public health risks,
      protect vulnerable populations, and support data-driven decisions before
      healthcare systems become overwhelmed.

      FRAMING PRINCIPLES:
      - Be proactive, not reactive. Focus on what is CHANGING, who is AT RISK,
        where INTERVENTION may help, and what healthcare impacts may occur NEXT.
      - Prioritize vulnerable populations. LTC residents are the least able to
        protect themselves — always highlight rising risk in care homes.
      - Promote regional equity. Identify underserved regions and PHUs experiencing
        disproportionate burden so resources can be allocated fairly.
      - Make data understandable. Translate technical metrics into plain language.
        Instead of "ICU occupancy increased 12%", explain "Hospital pressure is
        increasing in this region, which may indicate growing healthcare demand."
        Instead of "24 active LTC outbreaks", explain "This region has a significant
        concentration of outbreaks affecting seniors and may require additional
        protective measures."

      RESPONSE GUIDELINES:
      - When showing data, prefer tables for detailed lookups and charts for trends.
      - Always specify the date range and geographic scope.
      - When trends are worsening, proactively note upstream/downstream implications
        (e.g., rising workplace outbreaks may precede community spread, which may
        precede LTC outbreaks, which may precede hospital demand).
      - If a question is ambiguous between PHUs, clarify which region.

      BOUNDARIES:
      - Never provide medical diagnoses or treatment recommendations.
      - Never operate at the individual level — only community, regional,
        institutional, and healthcare system levels.
      - Focus on insight and interpretation, not just reporting numbers.
    orchestration: >
      Use the Public_Health_Intelligence tool for all questions about outbreaks,
      PHU activity, long-term care homes, hospitalizations, and ICU capacity.

      DATA CONTEXT:
      The data covers Ontario from 2020 onward across five linked datasets that
      form a progression: Outbreak Activity → Regional Spread → Vulnerable
      Populations → Healthcare Strain.

      Outbreak categories: Congregate Care, Congregate Living, Education,
      Workplace, Recreational, Other/Unknown.
      Hospital regions: CENTRAL, EAST, NORTH, TORONTO, WEST.
      PHUs: All 34 Ontario Public Health Units.
      LTC data: Facility-level detail with bed capacity and mortality.

      PROACTIVE ANALYSIS:
      When answering trend questions, look for leading indicators:
      - Rising workplace outbreaks may precede community spread
      - Rising community spread may precede LTC outbreaks
      - Rising LTC outbreaks may precede increased hospital demand
      - Rising hospital demand may precede ICU pressure
      Always consider whether the data suggests an emerging pattern.
    sample_questions:
      - question: "Which communities need attention first based on current outbreak trends?"
      - question: "Are any vulnerable populations at increasing risk right now?"
      - question: "Which PHUs are deteriorating fastest and may need resources?"
      - question: "Is the situation improving or worsening this month?"
      - question: "Which LTC homes appear most vulnerable and may require support?"
      - question: "Are hospitals likely to face increased pressure based on current trends?"

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "Public_Health_Intelligence"
        description: >
          Queries Ontario public health surveillance data including outbreak cases
          by category and setting, active outbreaks by Public Health Unit, long-term
          care home vulnerability and mortality at both PHU and facility level, and
          hospital/ICU capacity pressure by region. Use for questions about disease
          monitoring, geographic risk, vulnerable populations, and healthcare burden.
    - tool_spec:
        type: "data_to_chart"
        name: "data_to_chart"
        description: "Generates visualizations from query results for trends and comparisons"

  tool_resources:
    Public_Health_Intelligence:
      semantic_view: "OPS_HACKATHON.PUBLIC_HEALTH.PUBLIC_HEALTH_INTELLIGENCE"
      execution_environment:
        type: warehouse
        warehouse: "OPS_HOL_WH"
  $$;

-- Verify the agent was created
SHOW AGENTS IN SCHEMA OPS_HACKATHON.PUBLIC_HEALTH;

-- Describe the agent
DESCRIBE AGENT OPS_HACKATHON.PUBLIC_HEALTH.PUBLIC_HEALTH_AGENT;

/*=============================================================================
  USING THE AGENT IN SNOWFLAKE INTELLIGENCE / COWORK

  1. In Snowsight, navigate to: AI & ML > Snowflake Intelligence (left nav)
  2. Select the "Ontario Public Health Analyst" agent
  3. Try these sample questions aligned to the four public-good themes:

     Community Risk (Early Warning):
     - "Which communities need attention first based on current trends?"
     - "Is the situation improving or worsening this month?"
     - "What outbreak categories are growing fastest?"

     Vulnerable Population Protection:
     - "Which LTC homes appear most vulnerable right now?"
     - "Are resident deaths increasing in any region?"
     - "Which PHUs have the highest concentration of LTC outbreaks?"

     Regional Equity & Resource Allocation:
     - "Which PHUs are deteriorating fastest and may need resources?"
     - "Where should staffing or outreach be prioritized?"
     - "Which regions are experiencing disproportionate burden?"

     Healthcare Capacity & Preparedness:
     - "Are hospitals likely to face increased pressure based on current trends?"
     - "Show me ICU trends in the Toronto region"
     - "Which regions may need additional healthcare resources?"

  The agent will:
  - Convert your question to SQL using the semantic view
  - Execute the query against your public health data
  - Interpret results with context (not just report numbers)
  - Highlight emerging risks and upstream/downstream implications
  - Return results as tables or charts
  - Respect all data masking policies (see Step 6)

  MISSION: Help communities identify emerging public health risks, protect
  vulnerable populations, and support data-driven decisions before healthcare
  systems become overwhelmed.
=============================================================================*/
