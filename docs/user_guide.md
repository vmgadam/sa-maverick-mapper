# Maverick Mapper User Guide

## Table of Contents
1. [Installation](#installation)
2. [Getting Started](#getting-started)
3. [Basic Usage](#basic-usage)
4. [Saved Mappings](#saved-mappings)
5. [Bulk Operations](#bulk-operations)
6. [Export/Import](#exportimport)

## Installation

### Prerequisites
- Flutter SDK (2.0.0 or higher)
- Dart SDK (2.12.0 or higher)

### Setup
1. Add the package to your `pubspec.yaml`:
   ```yaml
   dependencies:
     maverick_mapper: ^1.0.0
   ```
2. Run `flutter pub get` to install dependencies
3. Import the package in your code:
   ```dart
   import 'package:maverick_mapper/maverick_mapper.dart';
   ```

## Getting Started

The Maverick Mapper allows you to create, manage, and reuse field mappings between different data sources. Key features include:
- Field mapping with simple and complex transformations
- Save and reuse mappings
- Bulk operations for efficient management
- Export/import functionality

## Basic Usage

### Creating a New Mapping
1. Open the Maverick Mapper screen
2. Input your source data (JSON or Elastic format)
3. Map fields using the field mapping interface:
   - Select target fields from the dropdown
   - Choose between simple and complex mapping
   - For complex mappings, use the expression editor

### Saving a Mapping
1. Click the "Save" button in the app bar
2. Enter a name for your mapping (max 200 characters)
3. Review any duplicate query warnings
4. Click "Save" to confirm

## Saved Mappings

### Viewing Saved Mappings
1. Click "Saved Mappings" in the app bar
2. View your mappings in the table with:
   - Name and product
   - Field mapping counts
   - Required fields status
   - Last modified date
   - Action buttons

### Managing Individual Mappings
- **Load**: Click the edit icon to load a mapping
- **Duplicate**: Click the copy icon to create a copy
- **Delete**: Click the delete icon to remove a mapping

### Duplicate Query Detection
- Mappings with the same query are marked with a warning icon
- Review duplicate mappings before saving
- Choose to save anyway or modify the query

## Bulk Operations

### Selecting Multiple Mappings
- Use checkboxes to select individual mappings
- Use the header checkbox to select/deselect all
- Selected count is shown in the action buttons

### Bulk Field Updates
1. Select mappings to update
2. Click "Update Field" in the toolbar
3. Choose the target field to update
4. Select simple or complex mapping
5. Configure the new mapping
6. Click "Apply to Selected"

### Bulk Delete
1. Select mappings to delete
2. Click "Delete" in the toolbar
3. Confirm the deletion
4. Selected mappings will be removed

### Reverting Bulk Actions
1. After a bulk operation, a "Revert Last Bulk Action" button appears
2. Click to undo the last bulk operation
3. All affected mappings will be restored

## Export/Import

### Exporting Mappings
1. Select one or more mappings
2. Click "Export" in the toolbar
3. Choose from available options:
   - Copy to clipboard
   - Download as file (coming soon)

### Export Format
The export format includes:
```json
{
  "version": "1.0",
  "exportedAt": "timestamp",
  "mappings": [
    {
      "accountKey": {"field": "data.id", "type": "id"},
      "dateKeyField": "data.createdAt",
      "endpointId": 123,
      "endpointName": "events",
      "eventFilter": "query",
      "eventType": "EVENT_TYPE",
      "schema": [],
      "metadata": {
        "name": "Mapping Name",
        "product": "Product Name",
        "totalFieldsMapped": 0,
        "requiredFieldsMapped": 0,
        "totalRequiredFields": 0,
        "createdAt": "timestamp",
        "modifiedAt": "timestamp"
      }
    }
  ]
}
```

### Best Practices
1. **Naming Conventions**:
   - Use descriptive names
   - Include product/version info
   - Keep names under 200 characters

2. **Field Mapping**:
   - Map required fields first
   - Use complex mapping for transformations
   - Test mappings before saving

3. **Bulk Operations**:
   - Review selections before applying changes
   - Use revert functionality if needed
   - Export before major changes

4. **Organization**:
   - Group related mappings
   - Use consistent naming
   - Document complex mappings

## Troubleshooting

### Common Issues
1. **Duplicate Queries**:
   - Review existing mappings
   - Modify query if needed
   - Document why duplicates exist

2. **Required Fields**:
   - Check required field count
   - Ensure all required fields are mapped
   - Review field mapping status

3. **Complex Mappings**:
   - Validate expressions
   - Test with sample data
   - Document transformations

### Getting Help
- Check the documentation
- Review example usage
- Submit issues on GitHub
- Contact support team 