# Changes Log

## UI and Navigation Changes
- Removed initial start screen and `mapper_selection_screen.dart`
- Removed `maverick_mapper_screen.dart`
- Modified app to launch directly into `UnifiedMapperScreen`
- Updated app title to "Maverick Mapper" with fighter plane icon
- Added segmented button for toggling between "Select App" and "Paste JSON" input modes
- Added confirmation dialog when switching input modes with existing mappings

## JSON Input Features
- Added JSON paste functionality with two modes:
  - Elastic Raw: Handles Elastic Search formatted JSON
  - Misc: Handles general JSON formats
- Added Clear and Parse buttons for JSON input
- Added confirmation dialog when parsing new JSON with existing mappings
- Auto-mapping of special fields (e.g., endpoint ID) when parsing Elastic Raw format

## Field Mapping Improvements
- Changed first column title from "SaaS Alerts ID" to "id"
- Made the id field mappable like other fields
- Implemented display order for fields with alphabetical sorting fallback
- Added field sorting:
  1. "id" field always first (displayOrder: 0)
  2. "time" field second (displayOrder: 1)
  3. "partner.id" field third (displayOrder: 2)
  4. Other fields sorted by displayOrder, then alphabetically

## Visual Enhancements
- Added red star indicators for required fields
- Improved table layout and column headers
- Added "Map the first field to display data in table view" message when no mappings exist
- Enhanced drag-and-drop visual feedback

## Configuration
- Updated `fields.json` with proper field definitions and display orders
- Added auto-mapping functionality for special fields in Elastic Raw format 

## Current Status of the Maverick Mapper Project

### Overview
The Maverick Mapper is a Flutter application designed to facilitate field mapping between RocketCyber events and SaaS Alerts. It provides a user-friendly interface for creating, managing, and exporting field mappings that conform to the SaaS Alerts mapping configuration format.

### Key Features Implemented
- **Source Data Input**: Supports API integration and JSON input for RocketCyber events.
- **Field Mapping**: Drag-and-drop interface for mapping source fields to SaaS Alerts fields.
- **Configuration Fields**: Handles configuration fields with support for picklist types.
- **Export Options**: Provides CSV and JSON export functionality.
- **Complex Mapping**: Includes a visual JSONata expression builder for complex mappings.
- **State Management**: Utilizes local state for managing mappings and selections.

### Recent Enhancements
- **UI Refinements**: Improved table message placement and field mapping display.
- **Complex Mapping System**: Enhanced token management and expression building.
- **Field Loading and Sorting**: Ensured all fields from fields.json are loaded and sorted by displayOrder.
- **Scroll Behavior Improvements**: Fixed horizontal scroll interference with browser navigation.

### Pending Features
- JSONata integration for field transformations.
- Validation for required fields.
- Advanced mapping features.

### Next Steps
1. Fix error handling in complex mapping editor.
2. Add JSONata expression validation.
3. Add preview of transformed values.
4. Implement mapping import/export with complex expressions.

### Developer Notes
- The application follows a modular structure for easy maintenance.
- Field definitions are centralized in config/fields.json.
- Export formats strictly follow SaaS Alerts specifications.
- UI components are designed for extensibility.
- Search and filter functions are optimized for performance. 