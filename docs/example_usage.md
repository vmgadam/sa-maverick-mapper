# Maverick Mapper Example Usage

## Table of Contents
1. [Basic Mapping Examples](#basic-mapping-examples)
2. [Complex Mapping Examples](#complex-mapping-examples)
3. [Bulk Operation Examples](#bulk-operation-examples)
4. [Export/Import Examples](#exportimport-examples)

## Basic Mapping Examples

### Creating and Saving a Simple Mapping

```dart
// Initialize state
final mappingState = Provider.of<MappingState>(context, listen: false);

// Create a new mapping
final newMapping = SavedMapping(
  name: 'User Events Mapping',
  product: 'UserService',
  query: '{"term": {"type": "user_event"}}',
  mappings: [
    {
      'source': 'data.userId',
      'target': 'userId',
      'isComplex': 'false'
    },
    {
      'source': 'data.eventType',
      'target': 'eventType',
      'isComplex': 'false'
    }
  ],
  configFields: {
    'endpointId': '123',
    'eventType': 'USER_EVENT',
    'productRef': 'products/user-service'
  },
  totalFieldsMapped: 2,
  requiredFieldsMapped: 2,
  totalRequiredFields: 2,
);

// Save the mapping
mappingState.addSavedMapping(newMapping);
```

### Loading and Updating a Mapping

```dart
// Load an existing mapping
void loadMapping(SavedMapping mapping) {
  // Check for unsaved changes
  if (hasUnsavedChanges) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unsaved Changes'),
        content: Text('Would you like to save your changes first?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _saveCurrentMapping();
              _applyMapping(mapping);
            },
            child: Text('Save First'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _applyMapping(mapping);
            },
            child: Text('Discard and Load'),
          ),
        ],
      ),
    );
  } else {
    _applyMapping(mapping);
  }
}

// Update an existing mapping
void updateMapping(SavedMapping mapping) {
  final updatedMapping = mapping.copyWith(
    mappings: [
      ...mapping.mappings,
      {
        'source': 'data.newField',
        'target': 'newTarget',
        'isComplex': 'false'
      }
    ],
    totalFieldsMapped: mapping.totalFieldsMapped + 1,
  );
  
  mappingState.updateSavedMapping(updatedMapping);
}
```

## Complex Mapping Examples

### Creating a Complex Field Mapping

```dart
// Complex mapping with multiple fields
final complexMapping = SavedMapping(
  name: 'Complex User Events',
  product: 'UserService',
  query: '{"term": {"type": "user_event"}}',
  mappings: [
    {
      'source': '',
      'target': 'fullName',
      'isComplex': 'true',
      'tokens': [
        {'type': 'field', 'value': 'data.firstName'},
        {'type': 'text', 'value': ' '},
        {'type': 'field', 'value': 'data.lastName'}
      ]
    },
    {
      'source': '',
      'target': 'age',
      'isComplex': 'true',
      'tokens': [
        {'type': 'function', 'value': 'calculateAge'},
        {'type': 'field', 'value': 'data.birthDate'}
      ]
    }
  ],
  configFields: {
    'endpointId': '123',
    'eventType': 'USER_EVENT',
    'productRef': 'products/user-service'
  },
  totalFieldsMapped: 2,
  requiredFieldsMapped: 2,
  totalRequiredFields: 2,
);

// Save the complex mapping
mappingState.addSavedMapping(complexMapping);
```

### Using the Complex Mapping Editor

```dart
// Show complex mapping editor
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Edit Complex Mapping'),
    content: ComplexMappingEditor(
      sourceFields: availableFields,
      sampleValues: sampleValues,
      initialTokens: existingTokens,
      onSave: (expression, tokens) {
        // Update mapping with new expression
        final updatedMapping = {
          'target': selectedField,
          'isComplex': 'true',
          'tokens': tokens,
        };
        // Apply the update
        _updateMapping(updatedMapping);
      },
    ),
  ),
);
```

## Bulk Operation Examples

### Bulk Field Update

```dart
// Select mappings to update
final selectedMappings = <SavedMapping>[mapping1, mapping2, mapping3];

// Show bulk update dialog
showDialog(
  context: context,
  builder: (context) => BulkFieldUpdateDialog(
    selectedMappings: selectedMappings,
    availableFields: availableFields,
    sampleValues: sampleValues,
  ),
).then((newMapping) {
  if (newMapping != null) {
    // Apply bulk update
    mappingState.bulkUpdateMappings(
      selectedMappings,
      (mapping) {
        final updatedMappings = List<Map<String, dynamic>>.from(mapping.mappings);
        final index = updatedMappings
            .indexWhere((m) => m['target'] == newMapping['target']);
            
        if (index != -1) {
          updatedMappings[index] = Map<String, dynamic>.from(newMapping);
        } else {
          updatedMappings.add(Map<String, dynamic>.from(newMapping));
        }

        return mapping.copyWith(
          mappings: updatedMappings,
          modifiedAt: DateTime.now(),
          totalFieldsMapped: updatedMappings.length,
        );
      },
    );
  }
});
```

### Bulk Delete

```dart
// Select mappings to delete
final selectedMappings = <SavedMapping>[mapping1, mapping2];

// Show confirmation dialog
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Delete Selected Mappings'),
    content: Text(
      'Are you sure you want to delete ${selectedMappings.length} mapping(s)?'
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancel'),
      ),
      TextButton(
        onPressed: () {
          // Perform bulk delete
          mappingState.deleteSavedMappings(selectedMappings);
          Navigator.pop(context);
        },
        child: Text('Delete'),
      ),
    ],
  ),
);
```

## Export/Import Examples

### Exporting Multiple Mappings

```dart
// Select mappings to export
final selectedMappings = <SavedMapping>[mapping1, mapping2];

// Show export dialog
MappingExportService.showMultipleMappingsExportDialog(
  context,
  selectedMappings,
);
```

### Export Format Example

```json
{
  "version": "1.0",
  "exportedAt": "2024-01-20T10:30:00Z",
  "mappings": [
    {
      "accountKey": {"field": "data.id", "type": "id"},
      "dateKeyField": "data.createdAt",
      "endpointId": 123,
      "endpointName": "events",
      "eventFilter": {"term": {"type": "user_event"}},
      "eventType": "USER_EVENT",
      "eventTypeKey": "USER_EVENT",
      "productRef": {"__ref__": "products/user-service"},
      "userKeyField": "data.userId",
      "schema": [
        {
          "source": "data.userId",
          "target": "userId",
          "isComplex": "false"
        },
        {
          "source": "",
          "target": "fullName",
          "isComplex": "true",
          "tokens": [
            {"type": "field", "value": "data.firstName"},
            {"type": "text", "value": " "},
            {"type": "field", "value": "data.lastName"}
          ]
        }
      ],
      "metadata": {
        "name": "User Events Mapping",
        "product": "UserService",
        "totalFieldsMapped": 2,
        "requiredFieldsMapped": 2,
        "totalRequiredFields": 2,
        "createdAt": "2024-01-20T10:00:00Z",
        "modifiedAt": "2024-01-20T10:30:00Z"
      }
    }
  ]
}
```

### Best Practices

1. **Naming and Organization**:
   ```dart
   // Use descriptive names with product/version
   final mapping = SavedMapping(
     name: 'UserService_v2_LoginEvents',
     product: 'UserService',
     // ...
   );
   ```

2. **Field Mapping**:
   ```dart
   // Map required fields first
   final requiredMappings = [
     {'source': 'data.userId', 'target': 'userId', 'isComplex': 'false'},
     {'source': 'data.eventType', 'target': 'eventType', 'isComplex': 'false'},
   ];
   
   // Then add optional fields
   final optionalMappings = [
     {'source': 'data.metadata', 'target': 'additionalInfo', 'isComplex': 'false'},
   ];
   ```

3. **Complex Mappings**:
   ```dart
   // Document complex transformations
   final complexMapping = {
     'source': '',
     'target': 'displayName',
     'isComplex': 'true',
     'tokens': [
       {'type': 'field', 'value': 'data.title'},
       {'type': 'text', 'value': '. '},
       {'type': 'field', 'value': 'data.firstName'},
       {'type': 'text', 'value': ' '},
       {'type': 'field', 'value': 'data.lastName'},
     ],
     'description': 'Combines title, first name, and last name with proper formatting'
   };
   ```

4. **Bulk Operations**:
   ```dart
   // Export before major changes
   void performBulkUpdate() {
     // First export current state
     MappingExportService.showMultipleMappingsExportDialog(
       context,
       selectedMappings,
     );
     
     // Then perform bulk update
     mappingState.bulkUpdateMappings(
       selectedMappings,
       updateFunction,
     );
   }
   ``` 