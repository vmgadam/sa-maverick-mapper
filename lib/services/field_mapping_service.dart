import 'package:flutter/foundation.dart';

class FieldMappingService {
  /// Gets a value from a nested structure, handling both Elastic-style array fields
  /// and Rocket Cyber-style nested objects.
  static String getNestedValue(Map<String, dynamic> data, String path) {
    try {
      // First check if the path exists directly (Elastic style)
      if (data.containsKey(path)) {
        final value = data[path];
        if (value is List && value.isNotEmpty) {
          return value[0]?.toString() ?? '';
        }
        return value?.toString() ?? '';
      }

      // If not found directly, try nested path (Rocket Cyber style)
      final keys = path.split('.');
      dynamic value = data;

      for (final key in keys) {
        if (value is! Map) {
          return '';
        }
        value = value[key];

        // Handle array values at any level
        if (value is List && value.isNotEmpty) {
          value = value[0];
        }
      }

      return value?.toString() ?? '';
    } catch (e) {
      debugPrint('Error getting nested value for path $path: $e');
      return '';
    }
  }

  /// Extracts all fields from a data structure, handling both formats
  static List<String> getAllFields(Map<String, dynamic> data,
      [String prefix = '']) {
    final fields = <String>{};

    void processValue(dynamic value, String currentPrefix) {
      if (value is Map<String, dynamic>) {
        value.forEach((key, val) {
          if (!key.endsWith('.keyword')) {
            final fieldName =
                currentPrefix.isEmpty ? key : '$currentPrefix.$key';
            fields.add(fieldName);
            processValue(val, fieldName);
          }
        });
      } else if (value is List && value.isNotEmpty) {
        // For array fields, add the current prefix as a field
        if (!currentPrefix.endsWith('.keyword')) {
          fields.add(currentPrefix);
        }
        // Don't process list contents for field names
      } else {
        // For scalar values, add the current prefix as a field
        if (!currentPrefix.endsWith('.keyword')) {
          fields.add(currentPrefix);
        }
      }
    }

    processValue(data, prefix);
    return fields.toList()..sort();
  }
}
