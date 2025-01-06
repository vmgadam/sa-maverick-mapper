# Maverick Mapper API Documentation

## Table of Contents
1. [Models](#models)
2. [State Management](#state-management)
3. [Widgets](#widgets)
4. [Services](#services)

## Models

### SavedMapping
A model representing a saved field mapping configuration.

```dart
class SavedMapping {
  final String name;              // Name of the mapping (max 200 chars)
  final String product;           // Product identifier
  final String query;            // Query for duplicate detection
  final List<Map<String, dynamic>> mappings;  // Field mappings
  final Map<String, dynamic> configFields;    // Configuration fields
  final int totalFieldsMapped;    // Total number of mapped fields
  final int requiredFieldsMapped; // Number of required fields mapped
  final int totalRequiredFields;  // Total number of required fields
  final DateTime createdAt;       // Creation timestamp
  final DateTime modifiedAt;      // Last modification timestamp

  // Constructor
  SavedMapping({
    required this.name,
    required this.product,
    required this.query,
    required this.mappings,
    required this.configFields,
    required this.totalFieldsMapped,
    required this.requiredFieldsMapped,
    required this.totalRequiredFields,
    DateTime? createdAt,
    DateTime? modifiedAt,
  });

  // Methods
  Map<String, dynamic> toJson();  // Convert to JSON
  SavedMapping copyWith();        // Create copy with optional changes
  static SavedMapping fromJson(); // Create from JSON
  static SavedMapping duplicate(); // Create duplicate with new name
}
```

## State Management

### MappingState
Manages the state of saved mappings and current mapping operations.

```dart
class MappingState extends ChangeNotifier {
  // Properties
  List<SavedMapping> get savedMappings;  // All saved mappings
  BulkOperation? get lastBulkOperation;  // Last bulk operation for revert
  String? get selectedAppId;            // Currently selected app
  String? get selectedAppName;          // Name of selected app

  // Methods
  void setSelectedApp(String appId, String appName);
  void addSavedMapping(SavedMapping mapping);
  void updateSavedMapping(SavedMapping mapping);
  void deleteSavedMapping(SavedMapping mapping);
  void deleteSavedMappings(List<SavedMapping> mappings);
  SavedMapping? duplicateSavedMapping(SavedMapping mapping, {String? newName});
  List<SavedMapping> findMappingsWithQuery(String query);
  void bulkUpdateMappings(List<SavedMapping> mappings, Function(SavedMapping) updateFn);
  void revertLastBulkOperation();
}
```

## Widgets

### SavedMappingsScreen
Main screen for managing saved mappings.

```dart
class SavedMappingsScreen extends StatefulWidget {
  // Features
  - Display saved mappings in a table
  - Support multi-select for bulk operations
  - Provide actions: load, duplicate, delete
  - Show duplicate query indicators
  - Support bulk field updates
  - Support bulk delete
  - Support bulk export
  - Support revert of bulk operations
}
```

### BulkFieldUpdateDialog
Dialog for updating fields across multiple mappings.

```dart
class BulkFieldUpdateDialog extends StatefulWidget {
  final List<SavedMapping> selectedMappings;
  final List<String> availableFields;
  final Map<String, String> sampleValues;

  // Features
  - Select target field to update
  - Choose between simple and complex mapping
  - Configure new mapping
  - Apply changes to selected mappings
}
```

### MappingPreviewDialog
Dialog for previewing mapping details.

```dart
class MappingPreviewDialog extends StatelessWidget {
  final SavedMapping mapping;

  // Features
  - Display mapping details
  - Show field mappings
  - Show configuration
  - Show metadata
}
```

## Services

### MappingExportService
Handles export functionality for mappings.

```dart
class MappingExportService {
  // Methods
  static Map<String, dynamic> formatSingleMapping(SavedMapping mapping);
  static Map<String, dynamic> formatMultipleMappings(List<SavedMapping> mappings);
  static void showSingleMappingExportDialog(BuildContext context, SavedMapping mapping);
  static void showMultipleMappingsExportDialog(BuildContext context, List<SavedMapping> mappings);

  // Features
  - Format mappings for export
  - Maintain backward compatibility
  - Support single and multiple mapping exports
  - Provide copy to clipboard
  - Support future download functionality
}
```

### FieldMappingService
Handles field mapping operations.

```dart
class FieldMappingService {
  // Methods
  static bool validateMapping(Map<String, dynamic> mapping);
  static Map<String, dynamic> createSimpleMapping(String source, String target);
  static Map<String, dynamic> createComplexMapping(String target, List<Map<String, dynamic>> tokens);

  // Features
  - Validate mapping structure
  - Create simple field mappings
  - Create complex mappings with expressions
}
```

## Usage Examples

### State Management
```dart
final mappingState = Provider.of<MappingState>(context);

// Add new mapping
mappingState.addSavedMapping(newMapping);

// Update existing mapping
mappingState.updateSavedMapping(updatedMapping);

// Bulk update
mappingState.bulkUpdateMappings(selectedMappings, (mapping) {
  return mapping.copyWith(
    mappings: updatedMappings,
    modifiedAt: DateTime.now(),
  );
});

// Revert bulk operation
mappingState.revertLastBulkOperation();
```

### Export
```dart
// Export single mapping
MappingExportService.showSingleMappingExportDialog(
  context,
  mapping,
);

// Export multiple mappings
MappingExportService.showMultipleMappingsExportDialog(
  context,
  selectedMappings,
);
```

### Field Mapping
```dart
// Create simple mapping
final simpleMapping = FieldMappingService.createSimpleMapping(
  'sourceField',
  'targetField',
);

// Create complex mapping
final complexMapping = FieldMappingService.createComplexMapping(
  'targetField',
  tokens,
);
```

## Error Handling

### Common Errors
1. **DuplicateNameError**: Thrown when attempting to save a mapping with a duplicate name
2. **ValidationError**: Thrown when mapping validation fails
3. **BulkOperationError**: Thrown when a bulk operation fails

### Error Handling Example
```dart
try {
  mappingState.addSavedMapping(newMapping);
} on DuplicateNameError catch (e) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Duplicate Name'),
      content: Text(e.message),
    ),
  );
} catch (e) {
  // Handle other errors
}
``` 