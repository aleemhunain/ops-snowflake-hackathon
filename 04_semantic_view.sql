-- Semantic view for Toronto shelter occupancy using SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML.
-- Co-authored with CoCo
/*=============================================================================
  HANDS-ON LAB: Toronto Shelter Occupancy Data Pipeline
  Step 4 - Create Semantic View
  
  Creates a semantic view over the shelter occupancy data for use with
  Cortex Analyst and Snowflake CoWork.
  
  NOTE: The data_type field has been removed from all dimensions/facts as it
  is no longer supported in the current semantic view YAML specification.
  Types are inferred from the expr field.
=============================================================================*/

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE OPS_HOL_WH;
USE SCHEMA OPS_HACKATHON.HOMELESSNESS;

-- Grant required privilege
GRANT CREATE SEMANTIC VIEW ON SCHEMA OPS_HACKATHON.HOMELESSNESS TO ROLE ACCOUNTADMIN;

-- Create the semantic view (using schema path as first argument, view name from YAML)
CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
  'OPS_HACKATHON.HOMELESSNESS',
  $$
name: SHELTER_ANALYTICS
description: >
  Semantic view for Toronto Daily Shelter & Overnight Service Occupancy data.
  Covers bed and room capacity, occupancy, and service usage across shelter
  programs in the Greater Toronto Area from 2023 to 2025.

tables:
  - name: SHELTER_OCCUPANCY
    description: >
      Daily occupancy records for each shelter program location in Toronto.
      Each row represents one program at one location on one day.
    base_table:
      database: OPS_HACKATHON
      schema: HOMELESSNESS
      table: SHELTER_OCCUPANCY
    primary_key:
      columns:
        - _ID
    dimensions:
      - name: OCCUPANCY_DATE
        synonyms:
          - date
          - day
          - report date
        description: The date of the occupancy record
        expr: SHELTER_OCCUPANCY.OCCUPANCY_DATE
      - name: SECTOR
        synonyms:
          - population group
          - demographic
          - client type
        description: >
          The population sector served: Families, Men, Mixed Adult, Women, or Youth
        expr: SHELTER_OCCUPANCY.SECTOR
      - name: LOCATION_CITY
        synonyms:
          - city
          - municipality
        description: City where the shelter is located (Toronto, Scarborough, North York, Etobicoke)
        expr: SHELTER_OCCUPANCY.LOCATION_CITY
      - name: PROGRAM_MODEL
        synonyms:
          - program type
          - shelter model
        description: Type of program - Emergency, Transitional, or other
        expr: SHELTER_OCCUPANCY.PROGRAM_MODEL
      - name: OVERNIGHT_SERVICE_TYPE
        synonyms:
          - service type
          - shelter type
          - facility type
        description: >
          Specific type of overnight service (Shelter, Motel/Hotel, 24-Hour Respite, etc.)
        expr: SHELTER_OCCUPANCY.OVERNIGHT_SERVICE_TYPE
      - name: ORGANIZATION_NAME
        synonyms:
          - operator
          - provider
          - organization
        description: Name of the organization operating the shelter program
        expr: SHELTER_OCCUPANCY.ORGANIZATION_NAME
      - name: SHELTER_GROUP
        synonyms:
          - shelter name
          - facility group
        description: Name of the shelter group or facility
        expr: SHELTER_OCCUPANCY.SHELTER_GROUP
      - name: LOCATION_POSTAL_CODE
        synonyms:
          - postal code
          - zip code
          - FSA
        description: Postal code of the shelter location
        expr: SHELTER_OCCUPANCY.LOCATION_POSTAL_CODE
      - name: CAPACITY_TYPE
        synonyms:
          - measurement type
        description: Whether capacity is measured in beds or rooms
        expr: SHELTER_OCCUPANCY.CAPACITY_TYPE
      - name: PROGRAM_AREA
        synonyms:
          - program category
        description: Program area classification (e.g., Base Program, COVID-19 Response, Temporary Refugee Response)
        expr: SHELTER_OCCUPANCY.PROGRAM_AREA
    facts:
      - name: SERVICE_USER_COUNT
        synonyms:
          - users
          - clients
          - people served
        description: Number of people using the service on that day
        expr: SHELTER_OCCUPANCY.SERVICE_USER_COUNT
      - name: CAPACITY_ACTUAL_BED
        synonyms:
          - bed capacity
          - total beds
          - available beds
        description: Actual bed capacity at the location
        expr: SHELTER_OCCUPANCY.CAPACITY_ACTUAL_BED
      - name: OCCUPIED_BEDS
        synonyms:
          - beds used
          - beds occupied
        description: Number of beds occupied on that day
        expr: SHELTER_OCCUPANCY.OCCUPIED_BEDS
      - name: UNOCCUPIED_BEDS
        synonyms:
          - empty beds
          - beds available
          - vacant beds
        description: Number of beds that were unoccupied
        expr: SHELTER_OCCUPANCY.UNOCCUPIED_BEDS
      - name: UNAVAILABLE_BEDS
        synonyms:
          - beds out of service
        description: Number of beds unavailable (maintenance, closure, etc.)
        expr: SHELTER_OCCUPANCY.UNAVAILABLE_BEDS
      - name: CAPACITY_ACTUAL_ROOM
        synonyms:
          - room capacity
          - total rooms
        description: Actual room capacity at the location
        expr: SHELTER_OCCUPANCY.CAPACITY_ACTUAL_ROOM
      - name: OCCUPIED_ROOMS
        synonyms:
          - rooms used
          - rooms occupied
        description: Number of rooms occupied on that day
        expr: SHELTER_OCCUPANCY.OCCUPIED_ROOMS
      - name: UNOCCUPIED_ROOMS
        synonyms:
          - empty rooms
          - rooms available
          - vacant rooms
        description: Number of rooms that were unoccupied
        expr: SHELTER_OCCUPANCY.UNOCCUPIED_ROOMS
      - name: UNAVAILABLE_ROOMS
        synonyms:
          - rooms out of service
        description: Number of rooms unavailable
        expr: SHELTER_OCCUPANCY.UNAVAILABLE_ROOMS
      - name: OCCUPANCY_RATE_BEDS
        synonyms:
          - bed occupancy rate
          - bed utilization
        description: Percentage of beds occupied (0-100)
        expr: SHELTER_OCCUPANCY.OCCUPANCY_RATE_BEDS
      - name: OCCUPANCY_RATE_ROOMS
        synonyms:
          - room occupancy rate
          - room utilization
        description: Percentage of rooms occupied (0-100)
        expr: SHELTER_OCCUPANCY.OCCUPANCY_RATE_ROOMS
    metrics:
      - name: AVG_OCCUPANCY_RATE
        synonyms:
          - average occupancy
          - mean occupancy rate
        description: Average bed occupancy rate across locations
        expr: AVG(SHELTER_OCCUPANCY.OCCUPANCY_RATE_BEDS)
      - name: TOTAL_CAPACITY
        synonyms:
          - total beds and rooms
          - system capacity
        description: Total combined bed and room capacity
        expr: SUM(SHELTER_OCCUPANCY.CAPACITY_ACTUAL_BED + SHELTER_OCCUPANCY.CAPACITY_ACTUAL_ROOM)
      - name: TOTAL_OCCUPIED
        synonyms:
          - total people housed
          - beds and rooms in use
        description: Total occupied beds and rooms combined
        expr: SUM(SHELTER_OCCUPANCY.OCCUPIED_BEDS + SHELTER_OCCUPANCY.OCCUPIED_ROOMS)
      - name: TOTAL_USERS_SERVED
        synonyms:
          - people served
          - total clients
        description: Total number of service users
        expr: SUM(SHELTER_OCCUPANCY.SERVICE_USER_COUNT)
      - name: UTILIZATION_PCT
        synonyms:
          - system utilization
          - overall occupancy
        description: Overall system utilization percentage (occupied / capacity * 100)
        expr: >
          DIV0(
            SUM(SHELTER_OCCUPANCY.OCCUPIED_BEDS + SHELTER_OCCUPANCY.OCCUPIED_ROOMS),
            NULLIF(SUM(SHELTER_OCCUPANCY.CAPACITY_ACTUAL_BED + SHELTER_OCCUPANCY.CAPACITY_ACTUAL_ROOM), 0)
          ) * 100

verified_queries:
  - name: daily_occupancy_by_sector
    question: What is the daily occupancy rate by sector?
    sql: >
      SELECT OCCUPANCY_DATE, SECTOR,
             ROUND(AVG(OCCUPANCY_RATE_BEDS), 1) AS AVG_OCCUPANCY_RATE
      FROM OPS_HACKATHON.HOMELESSNESS.SHELTER_OCCUPANCY
      WHERE OCCUPANCY_RATE_BEDS IS NOT NULL
      GROUP BY OCCUPANCY_DATE, SECTOR
      ORDER BY OCCUPANCY_DATE DESC, SECTOR
    verified_at: 1719600000
    verified_by: lab_admin
  - name: busiest_shelters
    question: Which shelters have the highest occupancy?
    sql: >
      SELECT SHELTER_GROUP, LOCATION_POSTAL_CODE,
             ROUND(AVG(OCCUPANCY_RATE_BEDS), 1) AS AVG_OCCUPANCY_RATE,
             SUM(OCCUPIED_BEDS) AS TOTAL_OCCUPIED_BEDS
      FROM OPS_HACKATHON.HOMELESSNESS.SHELTER_OCCUPANCY
      WHERE OCCUPANCY_RATE_BEDS IS NOT NULL
      GROUP BY SHELTER_GROUP, LOCATION_POSTAL_CODE
      ORDER BY AVG_OCCUPANCY_RATE DESC
      LIMIT 20
    verified_at: 1719600000
    verified_by: lab_admin
  - name: monthly_trend
    question: Show me the monthly occupancy trend for 2024
    sql: >
      SELECT DATE_TRUNC('MONTH', OCCUPANCY_DATE)::DATE AS MONTH,
             ROUND(AVG(OCCUPANCY_RATE_BEDS), 1) AS AVG_OCCUPANCY_RATE,
             SUM(OCCUPIED_BEDS) AS TOTAL_OCCUPIED_BEDS,
             SUM(CAPACITY_ACTUAL_BED) AS TOTAL_CAPACITY
      FROM OPS_HACKATHON.HOMELESSNESS.SHELTER_OCCUPANCY
      WHERE YEAR(OCCUPANCY_DATE) = 2024
        AND OCCUPANCY_RATE_BEDS IS NOT NULL
      GROUP BY DATE_TRUNC('MONTH', OCCUPANCY_DATE)
      ORDER BY MONTH
    verified_at: 1719600000
    verified_by: lab_admin
  - name: capacity_by_city
    question: What is the total shelter capacity by city?
    sql: >
      SELECT LOCATION_CITY,
             SUM(CAPACITY_ACTUAL_BED) AS TOTAL_BED_CAPACITY,
             SUM(CAPACITY_ACTUAL_ROOM) AS TOTAL_ROOM_CAPACITY,
             COUNT(DISTINCT LOCATION_ID) AS NUM_LOCATIONS
      FROM OPS_HACKATHON.HOMELESSNESS.SHELTER_OCCUPANCY
      WHERE OCCUPANCY_DATE = (SELECT MAX(OCCUPANCY_DATE) FROM OPS_HACKATHON.HOMELESSNESS.SHELTER_OCCUPANCY)
      GROUP BY LOCATION_CITY
      ORDER BY TOTAL_BED_CAPACITY DESC
    verified_at: 1719600000
    verified_by: lab_admin
  $$
);

-- Verify the semantic view was created
SHOW SEMANTIC VIEWS IN SCHEMA OPS_HACKATHON.HOMELESSNESS;

-- Describe it
DESCRIBE SEMANTIC VIEW OPS_HACKATHON.HOMELESSNESS.SHELTER_ANALYTICS;
