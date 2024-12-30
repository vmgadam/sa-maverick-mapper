# Maverick Mapper Development Progress

## Project Overview
The Maverick Mapper is a Flutter application designed to facilitate field mapping between RocketCyber events and SaaS Alerts. It provides a user-friendly interface for creating, managing, and exporting field mappings that conform to the SaaS Alerts mapping configuration format.

## To do
 -Multi-product state management to move between products and keep existing mappings.
 -AI support to suggest default mappings based on data.

## Latest Updates - Table Field Configuration
- Removed hardcoded field definitions:
  - All table fields now come directly from fields.json
  - No more hardcoded 'id' field or special handling
  - Consistent field names across the application
- Improved field configuration:
  - Fields are displayed in their defined order from config
  - Maintained all field properties (required, description, etc.)
  - Consistent handling of all standard fields

## Latest Updates - UI Refinements and Message Placement
- Improved table message placement:
  - Moved "Map the first field" message to overlay the table instead of being part of it
  - Used Stack widget to float the message over the empty table
  - Maintained table row sizes by removing message from table structure
  - Message remains centered and visible while table is scrollable underneath
- Enhanced user experience:
  - Cleaner table appearance with consistent row heights
  - Better visual hierarchy with floating message
  - Improved scrolling behavior without message interference

## Latest Updates - UI Refinements and Complex Mapping Improvements

### Field Mapping UI Simplification
- Streamlined the field mapping display:
  - Unmapped fields: Maintained interactive box with "Select field" text and drag indicator
  - Simple mappings: Removed box and indicators, showing only the field name
  - Complex mappings: Removed box and indicators, showing only "[Complex Mapping]" text
  - Consistent X button for removing any type of mapping
  - Code icon button for creating complex mappings only shown for unmapped fields

### Complex Mapping System Improvements
- Extracted complex mapping editor into a reusable widget (`ComplexMappingEditor`)
- Simplified token management:
  - Switched to Map-based structure instead of custom classes
  - Improved token parsing and storage
  - Enhanced error handling
- Standardized terminology:
  - Changed "[Complex Expression]" to "[Complex Mapping]" throughout the UI
  - Consistent labeling in all views (table headers, mapping list, etc.)

### Code Organization
- Created new reusable widget:
  - Separated complex mapping editor into standalone component
  - Made it reusable across different parts of the application
  - Improved component isolation and maintainability
- Enhanced state management:
  - Better handling of mapping states
  - Improved error handling
  - More efficient token management

### Technical Improvements
- Simplified mapping data structure:
  - Consistent format for both simple and complex mappings
  - Improved JSON serialization
  - Better error handling for null values
- Enhanced UI responsiveness:
  - More efficient state updates
  - Better handling of mapping changes
  - Improved visual feedback

## Latest Updates - Navigation Restructuring
- Removed unused `home_screen.dart` to simplify navigation
- Added events display button directly to MaverickMapperScreen
- Made MaverickMapperScreen the primary interface for all functionality
- Integrated event display navigation with the current app selection state

## Latest Updates - Events Display Implementation
- Added new `EventsDisplayScreen` for viewing mapped events:
  - Displays last 20 RocketCyber events using SaaS Alerts field mappings
  - Shows events in a scrollable data table format
  - Supports both simple and complex (JSONata) mappings
  - Provides refresh functionality for live data updates
  - Loads mappings from saved configurations
- Added navigation to events display from Maverick Mapper screen
- Integrated with existing mapping storage system

## Latest Updates - Code Cleanup and Consolidation
- Removed deprecated `mapper_screen.dart` implementation
- Updated `home_screen.dart` to use `MaverickMapperScreen` exclusively
- Removed unused `onViewEvents` callback from navigation
- Consolidated all mapping functionality into the Maverick Mapper implementation

## Initial Setup and Basic Structure
- Created initial `MaverickMapperScreen` with three-panel layout:
  - Left panel: Source Fields (RocketCyber)
    - Displays available fields from RocketCyber events
    - Supports app selection and JSON input
    - Shows field values for context
  - Center panel: Mappings
    - Shows current field mappings
    - Provides JSON preview
    - Offers export functionality
  - Right panel: SaaS Alerts Fields
    - Lists available SaaS Alerts fields
    - Indicates required fields
    - Shows field descriptions
- Implemented drag-and-drop functionality for intuitive field mapping
- Added RocketCyber API integration for live data
- Added JSON paste functionality for offline testing
- Set MaverickMapperScreen as the default home screen
- Updated app title to "Maverick Mapper"

## Field Definition and Structure
- Created `config/fields.json` to define SaaS Alerts fields:
  - Standard Event Fields:
    - time: Event timestamp
    - result: Event result/status
    - ip: IP address
    - eventId: Unique identifier
    - userAgent: Client user agent
    - device.sourceInfo.*: Device information
    - jointDesc/jointDescAdditional: Event descriptions
  - Configuration Fields:
    - accountKey.field/type: Account identification
    - dateKeyField: Timestamp field path
    - endpointId/Name: Endpoint configuration
    - eventType/Key: Event classification
    - productRef/Type: Product information
    - userKeyField: User identification
    - eventFilter: Query configuration
  - Field Attributes:
    - required: Boolean flag for mandatory fields
    - description: Detailed field explanation
    - type: Data type (string/number)
    - defaultMode: Preferred mapping mode (simple/complex)

## Complex Mapping Implementation
- Added support for two mapping modes:
  - Simple mode: Direct field-to-field mapping using drag-and-drop
  - Complex mode: Visual JSONata expression builder
- Enhanced field configuration:
  - Added defaultMode to fields.json to specify preferred mapping mode
  - Pre-configured complex mode for fields likely to need transformations
- Added visual expression builder:
  - Drag-and-drop interface for fields and text
  - "+ Add Text" button for custom text (up to 255 characters)
  - "+ Add Space" button for quick space insertion
  - Automatic string concatenation with "&" operator
  - Reorderable tokens with drag-and-drop
  - Live preview of evaluated expression
  - Color-coded tokens (blue for fields, green for text)
- Updated mapping display:
  - Simple mappings show as "source → target"
  - Complex mappings show as "[Complex Expression] → target"
  - Edit and delete buttons for complex mappings
  - Delete-only for simple mappings
- Updated JSON export format:
  - Proper schema structure with field names as keys
  - Simple mappings as direct field references
  - Complex mappings with jsonataExpr property
  - Standard SaaS Alerts configuration format

## UI Enhancements
- Expression Builder:
  - Split-panel design with fields and expression area
  - Visual token system for building expressions
  - Drag-and-drop reordering of expression elements
  - Clear All button for resetting expressions
  - Live preview with sample data evaluation
- Mapping Management:
  - Improved visual distinction between simple and complex mappings
  - Simplified controls based on mapping type
  - Better error handling and null value management

## Export Functionality
- Export Formats:
  - CSV Export:
    - Source app and field information
    - Field mappings and relationships
    - Record identification
  - JSON Export:
    - Exact mappingConfig.json format
    - Complete field configuration
    - All required mapping attributes
    - Proper schema structure
- Export Features:
  - Contextual export buttons
  - Live JSON preview
  - Format validation
  - Pretty printing

## Technical Implementation
- State Management:
  - Efficient field filtering
  - Real-time mapping updates
  - Search state handling
  - Export state management
- Data Structures:
  - SaasField class for field metadata
  - Mapping representation
  - Search and filter algorithms
- API Integration:
  - RocketCyber API service
  - SaaS Alerts API service
  - Error handling
  - Data transformation
- Added token-based expression building:
  - Token types: field, text, operator
  - Automatic operator insertion
  - Token serialization for storage
  - Expression rebuilding from tokens
- Enhanced state management:
  - Proper handling of complex mapping state
  - Token persistence between edits
  - Improved error handling
- Export format compliance:
  - Standard SaaS Alerts schema structure
  - Proper handling of both mapping types
  - Correct field reference format

## Current Features
- [x] Source data input (API and JSON)
- [x] Drag-and-drop field mapping
- [x] Field validation and indicators
- [x] Search and filtering
- [x] Export functionality (CSV/JSON)
- [x] Live data preview
- [x] Configuration field support
- [x] Mapping visualization

## Pending Features
- [ ] JSONata integration for field transformations
- [ ] Field combination and conditional logic
- [ ] Validation for required fields
- [ ] Advanced mapping features

## Next Steps
1. Fix error handling in complex mapping editor
2. Add JSONata expression validation
3. Add preview of transformed values
4. Implement mapping import/export with complex expressions

## Bug Fixes and Improvements
- Fixed SaaS Alerts fields loading with proper asset configuration
- Improved field organization with config directory
- Enhanced JSON export format to match specification
- Added comprehensive field definitions

## Developer Notes
- The application follows a modular structure for easy maintenance
- Field definitions are centralized in config/fields.json
- Export formats strictly follow SaaS Alerts specifications
- UI components are designed for extensibility
- Search and filter functions are optimized for performance 

## Latest Updates - Complex Mapping System
- Implemented visual JSONata expression builder:
  - Drag-and-drop interface for building expressions
  - Token-based system for precise expression control
  - Live preview with real-time evaluation
  - Proper JSONata expression formatting
  - Automatic operator handling
  - Expression reordering capabilities

### Expression Builder Features
1. Visual Token System:
   - Blue chips for field references (e.g., $data.user_name)
   - Green chips for text literals (e.g., 'Record URL:')
   - Drag-and-drop reordering of tokens
   - Delete capability for individual tokens

2. Expression Controls:
   - "Add Text" button for custom text insertion
   - "Add Space" button for explicit space characters
   - "Clear All" button for resetting the expression
   - Automatic & operator insertion between tokens

3. Expression Preview:
   - Real-time evaluation using sample data
   - Shows actual concatenated result
   - Updates dynamically as tokens are added/removed
   - Helps visualize the final output

4. JSONata Expression Format:
   - Proper formatting with & operators
   - Correct use of single quotes for literals
   - No automatic space insertion
   - Example: $data.user_name & ' ' & $data.action & 'Record URL:' & $data.record_url

### Mapping Management
1. Display Improvements:
   - Clear indication of complex mappings with [Complex Expression] label
   - Edit button for complex mappings
   - Delete button for all mapping types
   - Proper schema structure in JSON output

2. State Management:
   - Token persistence between edits
   - Proper handling of complex mapping state
   - Undo capability through Cancel button
   - Automatic state updates on changes

### Technical Implementation
1. Token System:
   - Token Types:
     - field: References to source data fields
     - text: Literal text values
   - Token Structure:
     ```json
     {
       "type": "field|text",
       "value": "token_value"
     }
     ```

2. Expression Building:
   - Automatic & operator insertion
   - Proper spacing for readability
   - Correct JSONata syntax
   - Token serialization for storage

3. JSON Output Format:
   ```json
   {
     "schema": {
       "fieldName": "$source.field & ' ' & 'literal text'"
     }
   }
   ```

### Code Organization
1. Expression Builder:
   - Token management functions
   - Expression evaluation logic
   - UI components for token display
   - Drag-and-drop handlers

2. State Management:
   - Token state persistence
   - Mapping state updates
   - UI state synchronization
   - Error handling

3. User Interface:
   - Split-panel design
   - Visual token system
   - Interactive controls
   - Live preview

### Next Steps
1. Expression Validation:
   - JSONata syntax validation
   - Expression testing
   - Error feedback
   - Syntax highlighting

2. Advanced Features:
   - Expression templates
   - Common patterns library
   - Bulk editing capabilities
   - Import/export of expressions 

## Latest Updates - Events Display Screen Enhancements

- Enhanced the Events Display Screen to show all required SaaS Alerts fields in the table
- Required fields are now prominently displayed first, with red headers and star icons
- Unmapped required fields are highlighted in red with italic text
- Added loading of all SaaS Alerts fields from the API
- Improved field organization:
  - Required fields are shown first in the table
  - Optional fields follow required fields
  - All fields are sorted alphabetically
- Added visual indicators for mapping status:
  - "No mapping defined" shown in red for required fields
  - "No mapping defined" shown in italic for optional fields
- Updated the screen header to show total field count and required field count 

## Latest Updates - UI Refinements and Message Placement
- Improved table message placement:
  - Moved "Map the first field" message to overlay the table instead of being part of it
  - Used Stack widget to float the message over the empty table
  - Maintained table row sizes by removing message from table structure
  - Message remains centered and visible while table is scrollable underneath
- Enhanced user experience:
  - Cleaner table appearance with consistent row heights
  - Better visual hierarchy with floating message
  - Improved scrolling behavior without message interference 

## Latest Updates - JSON Processing Improvements
- Enhanced JSON parsing functionality:
  - Process entire JSON structure for Elastic Raw format instead of just 'data' field
  - Flatten all nested fields into dot-notation paths
  - Skip map-like structures while keeping their child fields
  - Maintain consistent field path format with API data
- Improved field discovery:
  - All nested fields are now available for mapping
  - Better field visibility in complex JSON structures
  - Consistent field path representation across data sources 

## Latest Updates - Browser Navigation Fix
- Fixed browser back navigation interference:
  - Added ScrollConfiguration to control scroll behavior
  - Implemented ClampingScrollPhysics for both vertical and horizontal scrolling
  - Disabled browser scrollbars to prevent interference
  - Prevented browser history manipulation during table scrolling 

## Latest Updates - Scroll Behavior Improvements
- Fixed horizontal scroll interference with browser navigation:
  - Implemented custom scroll behavior to handle horizontal scrolling
  - Prevented browser back/forward triggers during table navigation
  - Added support for touch, mouse, and trackpad interactions
  - Disabled browser's default scroll behavior overrides
- Enhanced scroll experience:
  - Smoother horizontal scrolling through wide tables
  - Consistent behavior across different input devices
  - Eliminated browser navigation interference 

## Latest Updates - Field Loading and Sorting Improvements
- Enhanced field loading from configuration:
  - Ensured all fields from fields.json are loaded including '_id'
  - Removed premature sorting during initial load
  - Fixed field ordering to respect displayOrder property
- Improved field sorting logic:
  - Primary sort by displayOrder as defined in fields.json
  - Secondary alphabetical sort for fields with same displayOrder
  - Consistent field order across all views 