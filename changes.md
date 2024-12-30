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