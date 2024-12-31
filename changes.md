## Bugs/TODOs

### Complex Mapping Display Issue
- **Bug**: In complex mappings, removed field tokens are incorrectly displayed in previews and tables
- **Description**: When a field is marked as removed (e.g., "data.activityType(removed)"), the preview incorrectly strips the first and last characters, showing "ata.activityType(removed" instead
- **Location**: `_getComplexMappingPreview` method in UnifiedMapperScreen
- **Root Cause**: The preview logic is treating removed field markers as quoted text and stripping characters
- **Fix Required**: Update the string manipulation logic to preserve the full removed field marker text 