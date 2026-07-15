-- Creates a Cortex Agent with semantic view tool for shelter occupancy analytics.
/*=============================================================================
  HANDS-ON LAB: Toronto Shelter Occupancy Data Pipeline
  Step 5 - Create Cortex Agent + CoWork Integration
  
  Creates a Cortex Agent that uses the semantic view to answer natural language
  questions about shelter occupancy data. This agent integrates with Snowflake
  CoWork for a conversational analytics experience.
=============================================================================*/

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE OPS_HOL_WH;
USE SCHEMA OPS_HACKATHON.HOMELESSNESS;

-- ==========================================================================
-- PREREQUISITES: Enable cross-region inference (recommended for best model access)
-- ==========================================================================
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

-- ==========================================================================
-- CREATE THE CORTEX AGENT
-- ==========================================================================
CREATE OR REPLACE AGENT OPS_HACKATHON.HOMELESSNESS.SHELTER_AGENT
  COMMENT = 'Cortex Agent for Toronto shelter occupancy analytics - answers questions about capacity, occupancy trends, and service delivery'
  PROFILE = '{"display_name": "Toronto Shelter Analyst", "color": "blue"}'
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
      You are an analyst specializing in Toronto's shelter system data.
      Provide clear, concise answers about shelter occupancy, capacity, and trends.
      When showing data, prefer tables for detailed lookups and suggest charts for trends.
      Always specify the date range of the data you are presenting.
      If the user asks about a specific shelter or organization, search by name.
    orchestration: >
      Use the Shelter_Analytics tool for all questions about shelter occupancy,
      capacity, service users, bed counts, room counts, and trends.
      The data covers Toronto shelters from January 2023 to December 2025.
      Sectors include: Families, Men, Mixed Adult, Women, and Youth.
      Cities include: Toronto, Scarborough, North York, Etobicoke, and Vaughan.
    sample_questions:
      - question: "What is the current average occupancy rate across all shelters?"
      - question: "Show me the monthly trend of shelter occupancy for 2024"
      - question: "Which sector has the highest demand for beds?"
      - question: "How many people are served daily in the family sector?"
      - question: "What is the total shelter capacity in Toronto vs Scarborough?"

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "Shelter_Analytics"
        description: >
          Queries Toronto Daily Shelter & Overnight Service Occupancy data.
          Contains daily records from 2023-2025 for all shelter programs including
          bed/room capacity, occupancy rates, service user counts, and program details.
          Use for questions about shelter capacity, occupancy trends, sector breakdowns,
          and location-level analysis.
    - tool_spec:
        type: "data_to_chart"
        name: "data_to_chart"
        description: "Generates visualizations from query results"

  tool_resources:
    Shelter_Analytics:
      semantic_view: "OPS_HACKATHON.HOMELESSNESS.SHELTER_ANALYTICS"
      execution_environment:
        type: warehouse
        warehouse: "OPS_HOL_WH"
  $$;

-- Verify the agent was created
SHOW AGENTS IN SCHEMA OPS_HACKATHON.HOMELESSNESS;

-- Describe the agent
DESCRIBE AGENT OPS_HACKATHON.HOMELESSNESS.SHELTER_AGENT;

/*=============================================================================
  USING THE AGENT IN SNOWFLAKE COWORK
  
  1. In Snowsight, navigate to: AI & ML > CoWork (left navigation)
  2. Select the "Toronto Shelter Analyst" agent from the agent list
  3. Try these sample questions:
  
     - "What is the average occupancy rate by sector for the last 3 months?"
     - "Show me a chart of monthly occupancy trends in 2024"
     - "Which organizations operate the most shelter locations?"
     - "How has youth shelter capacity changed over time?"
     - "What percentage of beds are unavailable on average?"
  
  The agent will:
  - Convert your question to SQL using the semantic view
  - Execute the query against your shelter data
  - Return results as tables or charts
  - Respect all data masking policies (see Step 6)
=============================================================================*/
