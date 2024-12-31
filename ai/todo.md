# Code Improvement Priority Tiers

## Tier 1: Basic required, functionality for MVP
- [x] Ability to paste the output of Elastic Kabana Inspector Request and Response data into the app and have it parse the data into a useable format for mapping fields.
  - [x] Added Request/Response tabs for Elastic Raw data
  - [x] Implemented correct parsing of Elastic fields structure
  - [x] Added unit tests to verify field mapping functionality
  - [x] Properly handling array values from Elastic fields
  - [x] Filtering out .keyword variants
  - [x] Side-by-side Request/Response input areas
  - [x] Improved field removal handling in complex mappings
  - [x] Added visual indicators for removed fields
  - [x] Added edit buttons for complex mappings in both table and list views
- [x] Ability to extract the query from the Elastic Kabana Inspector Request and use it to build the query section of the JSONata export.
  - [x] Implemented query extraction from request data
  - [x] Auto-populating eventFilter field with extracted query
- [x] Performance optimization for large datasets
  - [x] Added record limit selector (1, 5, 10, 20, 50, 100, 200)
  - [x] Implemented initial load limit of 5 records by default
  - [x] Optimized memory usage by limiting loaded records
  - [x] Improved UI responsiveness with large datasets
  - [x] Delayed RC app loading until needed
- [x] UI Improvements
  - [x] Fixed SearchableDropdown lifecycle issues
  - [x] Optimized dropdown performance
  - [x] Added sample value truncation to prevent rendering issues
  - [x] Maintained search functionality while improving stability
  - [x] Improved complex mapping display with inline removed field indicators
  - [x] Added edit capabilities for complex mappings in both views
  - [x] Optimized RC app loading to reduce unnecessary API calls
- [ ] Ability to validate Jsonata expressions and final JSON output for formatting and errors.
- [ ] Ability to make multiple mappings for a single product (event mappings where the eventType changes) based on specific queries and filters and load/switch between them
- [ ] Ability to make mappings across products and switch between them
- [ ] Unit tests for existing code
  - [x] Added unit tests for Elastic field mapping functionality
  - [ ] Need tests for other core functionality
- [ ] Ability to export all mappings to a file and then upload them via firefoo as seperate documents in the configMapping collection.

## Known Issues/Bugs
- [ ] Complex mapping preview text manipulation issue (first/last character being stripped from removed field markers)

## Tier 2: Worth Considering
These improvements offer good value but require more careful consideration:

### State Management
- [ ] Move mapping logic into a dedicated service class
- [ ] Create proper state classes instead of using strings
- [ ] Consider moving to Riverpod for specific complex state scenarios

### SearchableDropdown Improvements
- [ ] Consider using Flutter's native `SearchAnchor` widget
- [ ] Add basic keyboard navigation
- [ ] Improve focus management

### Configuration
- [ ] Move configuration fields into a dedicated service
- [ ] Add basic validation for configuration values
- [ ] Implement simple persistence for settings


## Implementation Strategy
1. Start with Tier 1 improvements - these are MVP features
2. Evaluate Tier 2 improvements based on specific pain points as they arise

Remember: The goal is to maintain a balance between code quality and development speed. Focus on improvements that solve real problems rather than theoretical ones. 

## Elastic Kibana Inspector Feature Details

### Overview
The app needs to handle Elastic Kibana Inspector data for both Accounts and Devices, with separate field configurations for each.

### Requirements
1. Input Handling
   - [x] Support for both Request and Response data from Kibana Inspector
   - [x] UI selection for data type (Accounts/Devices) when "Elastic Raw" is selected
   - [x] Separate input areas for Request and Response data
   - [ ] Clear confirmation when switching between Accounts/Devices if mappings exist
   - [ ] Preserve matching Configuration Fields when switching between types

2. Configuration Files
   - [ ] Current `config/fields.json` contains Account-related fields
   - [ ] New `config/fields_devices.json` created with:
     - [ ] All Configuration type fields from `fields.json`
     - [ ] Standard fields specific to devices (OS, IP, deviceName)
     - [ ] Same structure and format as `fields.json`
   - [ ] `config/elastic_mapping.json` defines special field handling:
     ```json
     {
       "field_mappings": {
         "_source.product.endpoint.id": {
           "destination": "endpointId",
           "description": "Maps to the configuration field endpointId"
         },
         "_source.product.type": {
           "destination": "productRef",
           "description": "Maps to the configuration field productRef"
         }
       },
       "special_handling": {
         "request.query": {
           "destination": "eventFilter",
           "description": "The query section from the request should be extracted and used in the eventFilter field of the JSONata export",
           "handling": "query_extraction"
         }
       }
     }
     ```

3. Data Processing
   - [x] Parse both Request and Response data
   - [x] Extract and process special fields according to `elastic_mapping.json`:
     - [x] Map `product.endpoint.id` to `endpointId` configuration field
     - [ ] Map `product.type` to `productRef` configuration field
     - [x] Extract query section from Request and use in `eventFilter` field of JSONata export
   - [ ] Map fields according to selected type (Accounts/Devices)
   - [x] Validate data format matches Kibana Inspector structure

4. User Interface
   - [x] Add Accounts/Devices selector when "Elastic Raw" is selected
   - [x] Show confirmation dialog when switching types if mappings exist
   - [x] Clear validation feedback for proper Kibana Inspector format
   - [x] Preview of extracted query data
   - [x] Do not change any of the existing UI, except for the specific changes needed for this feature.
   - [x] Do not touch existing code that is not related to this feature.
   - [x] Do not reconfigure the UI in any major way.

### Implementation Notes
- Need to maintain separate field mappings for Accounts and Devices
- Implement proper error handling for malformed Kibana Inspector data
- Add validation to ensure both Request and Response data are provided when needed
- Configuration field preservation process:
  1. Before switching types, identify which Configuration fields exist in both files
  2. Save values of matching fields temporarily
  3. Clear all mappings (with confirmation)
  4. Load new fields for selected type
  5. Restore saved Configuration values for matching fields

### Field Handling Details
1. Special Field Mappings:
   - Endpoint ID extraction from `_source.product.endpoint.id`
   - Product type extraction from `_source.product.type`
   - These mappings should be automatic when parsing Elastic data

2. Query Extraction:
   - Extract query section from Request data
   - Format and insert into eventFilter field
   - Maintain query structure during extraction

3. Device-Specific Fields:
   - OS field (required)
   - IP field (required)
   - deviceName field (required)
   - All standard fields follow same structure as accounts

4. Configuration Field Handling:
   - Preserve shared configuration fields during type switching
   - Maintain picklist options and other field properties
   - Keep configuration category consistent between types 

### Implementation Steps

1. Configuration Setup (Phase 1)
   - [ ] Use `fields_devices.json` with device-specific fields
   - [ ] Use `elastic_mapping.json` for special field handling
   - [ ] Add validation tests for configuration file formats
   - [ ] Create utility functions to load and validate configuration files

2. UI Modifications (Phase 2)
   - [ ] Add Accounts/Devices segmented button to Elastic Raw section
   - [ ] Create separate text areas for Request and Response data that are like the existing JSON input area and just flip back and forth between them with tabs.
   - [ ] Add validation indicators for both input areas
   - [ ] Implement confirmation dialog for type switching
   - [ ] Add loading indicators for configuration changes

3. Data Parsing Implementation (Phase 3)
   - [ ] Create ElasticParsingService class with methods:
     - [ ] parseRequest(String requestJson)
     - [ ] parseResponse(String responseJson)
     - [ ] validateElasticFormat(String json)
     - [ ] extractSpecialFields(Map<String, dynamic> data)
   - [ ] Implement query extraction from request data
   - [ ] Add error handling for malformed data
   - [ ] Create tests for parsing functions

4. Field Mapping Logic (Phase 4)
   - [ ] Utilize existing Field Mapping Service functionality to handle:
     - [ ] Loading appropriate fields based on type
     - [ ] Mapping special fields from elastic_mapping.json
     - [ ] Preserving shared configuration values
   - [ ] Implement configuration field preservation logic
   - [ ] Add validation for required fields
   - [ ] Create tests for mapping functions

5. State Management Updates (Phase 5)
   - [ ] Add state variables for:
     - [ ] Selected type (Accounts/Devices)
     - [ ] Request/Response data
     - [ ] Validation states
     - [ ] Configuration preservation
   - [ ] Implement state persistence for last used settings
   - [ ] Create tests for state management

6. Integration (Phase 6)
   - [ ] Connect UI components to parsing service
   - [ ] Integrate field mapping service
   - [ ] Add error handling and user feedback
   - [ ] Implement loading states
   - [ ] Add integration tests

7. Testing and Validation (Phase 7)
   - [ ] Create test suite for:
     - [ ] Configuration file loading
     - [ ] Data parsing
     - [ ] Field mapping
     - [ ] State management
     - [ ] UI interactions
   - [ ] Test with sample Elastic data
   - [ ] Test error scenarios
   - [ ] Test configuration preservation

8. Documentation and Cleanup (Phase 8)
   - [ ] Add inline documentation
   - [ ] Create usage examples
   - [ ] Document error scenarios and handling
   - [ ] Clean up and optimize code
   - [ ] Update README with new features

### Dependencies Between Steps
- Phase 1 must be completed before Phases 2-4
- Phase 2 can be worked on in parallel with Phase 3
- Phase 4 depends on Phase 3 completion
- Phase 5 can be started after Phase 2
- Phase 6 requires Phases 2-5 to be completed
- Phase 7 can begin after each individual phase
- Phase 8 should be done throughout but finalized last

### Testing Strategy
1. Unit Tests
   - Configuration file loading and validation
   - Data parsing and transformation
   - Field mapping logic
   - State management

2. Integration Tests
   - UI interaction flows
   - Data flow through services
   - Configuration switching
   - Error handling

3. End-to-End Tests
   - Complete workflows
   - Data persistence
   - Cross-component interaction

### Rollout Strategy
1. Implement basic functionality (Phases 1-3)
2. Add field mapping and state management (Phases 4-5)
3. Integrate and test (Phases 6-7)
4. Document and refine (Phase 8)

Each phase should be reviewed and tested before moving to the next to ensure stability and correctness. 