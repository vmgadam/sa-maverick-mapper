# Field Definitions Guide

## Overview
Field definitions in the Maverick Mapper application are centrally managed in `lib/config/field_definitions.dart`. This file serves as the single source of truth for all field configurations, mappings, and validations.

## Field Types

### Standard Fields
Standard fields represent the core event data fields that are mapped from source events. These are defined in the `standardFields` map and include fields like:
- Event IDs
- Timestamps
- IP addresses
- User information
- Device information
- Event descriptions

### Configuration Fields
Configuration fields handle the mapping configuration and metadata. These are defined in the `configurationFields` map and include:
- Account key configurations
- Date field mappings
- Endpoint configurations
- Event type definitions
- Product references
- Schema definitions

## Field Definition Structure

Fields are defined using the `FieldDefinition` class with the following properties:

```dart
FieldDefinition(
  name: 'field.name',           // Unique identifier for the field
  required: true/false,         // Whether the field is mandatory
  description: 'Description',   // Human-readable description
  type: FieldType.string,       // Field type (string, number, picklist)
  category: FieldCategory.standard, // Category (standard or configuration)
  displayOrder: 1,              // Order in the UI (lower numbers first)
  options: ['opt1', 'opt2'],    // Options for picklist fields (optional)
  defaultMode: FieldMappingType.simple // Mapping mode (simple or complex)
)
```

## Field Categories

### Field Types (`FieldType`)
- `string`: Text-based fields
- `number`: Numeric fields
- `picklist`: Fields with predefined options

### Field Categories (`FieldCategory`)
- `standard`: Core event data fields
- `configuration`: Mapping and configuration fields

### Mapping Types (`FieldMappingType`)
- `simple`: Direct field-to-field mapping
- `complex`: Advanced mapping with expressions or multiple fields

## Special Configurations

### Elastic Mappings
For fields that require special handling with Elastic data, additional mappings can be defined in the `elasticMappings` map:

```dart
ElasticFieldMapping(
  source: 'source.field.path',
  destination: 'destination.field',
  description: 'Mapping description',
  specialHandling: SpecialHandlingType.queryExtraction // Optional
)
```

The application includes several predefined elastic mappings:
1. `product.endpoint.id` → `endpointId`: Maps the endpoint ID from the Response JSON
2. `fields.product.type[0]` → `productType`: Automatically populated from the first event record's product type in the parsed data
3. `request.query` → `eventFilter`: Extracts the query section for filtering
4. `_source.product.type` → `productRef`: Maps the product reference information

### Predefined Options
Common options are defined as constants:
- `generalEventTypes`: Standard event type options
- `deviceEventTypes`: Device-specific event types
- `alertStatusOptions`: Alert status values

## Adding/Removing Fields

1. To add a new field:
   - Add the field definition to either `standardFields` or `configurationFields`
   - Include all required properties
   - Add any necessary elastic mappings if special handling is needed

2. To remove a field:
   - Remove the field definition from the appropriate map
   - Remove any associated elastic mappings
   - Remove any references in predefined options if applicable

## Field Display Order

Fields are displayed in the UI based on:
1. Category (standard vs configuration)
2. Display order (lower numbers first)
3. Alphabetical order (when display orders are equal)

## Automatic Features

The application automatically:
- Validates required fields
- Generates UI components based on field definitions
- Handles field mapping and validation
- Manages configuration field defaults
- Supports complex mapping expressions
- Provides search and filtering capabilities
- Auto-populates fields from Elastic Response data where configured

## Best Practices

1. Field Names:
   - Use dot notation for nested fields (e.g., `user.name`)
   - Keep names consistent with source data
   - Use clear, descriptive names

2. Descriptions:
   - Provide clear, concise descriptions
   - Include any relevant constraints or requirements
   - Document special handling requirements

3. Display Order:
   - Keep related fields grouped together
   - Leave gaps between numbers for future additions
   - Consider UI layout when ordering fields

4. Required Fields:
   - Only mark fields as required if they are essential
   - Ensure required fields have clear validation messages
   - Consider the impact on existing mappings

5. Complex Mappings:
   - Use complex mapping mode for fields that need transformation
   - Document any special handling requirements
   - Consider adding elastic mappings for special cases 