import 'package:flutter/material.dart';
import '../models/saas_field.dart';
import '../models/saved_mapping.dart';
import 'package:provider/provider.dart';
import '../state/mapping_state.dart';
import '../state/saved_mappings_state.dart';

/// A mixin that provides mapping state and functionality
mixin MappingStateMixin<T extends StatefulWidget> on State<T> {
  List<Map<String, dynamic>> mappings = [];
  bool hasUnsavedChanges = false;
  SavedMapping? currentLoadedMapping;

  /// Adds a new mapping or updates an existing one
  void addMapping(String sourceField, String targetField, bool isComplex) {
    setState(() {
      // Remove any existing mapping for this target field
      mappings.removeWhere((m) => m['target'] == targetField);

      // Create the new mapping
      final mapping = {
        'source': sourceField,
        'target': targetField,
        'isComplex': isComplex.toString(),
        'tokens': '[]',
        'jsonataExpr': '',
      };

      mappings.add(mapping);
      hasUnsavedChanges = true;

      // Update state provider if we have a product type
      if (currentLoadedMapping?.product != null) {
        Provider.of<MappingState>(context, listen: false).setMappings(
          'Elastic',
          currentLoadedMapping!.product,
          List.from(mappings),
        );
      }
    });
  }

  /// Removes a mapping for a specific field
  void removeMapping(String fieldName) {
    setState(() {
      mappings.removeWhere((m) => m['target'] == fieldName);
      if (currentLoadedMapping?.product != null) {
        Provider.of<MappingState>(context, listen: false).setMappings(
          'Elastic',
          currentLoadedMapping!.product,
          List.from(mappings),
        );
      }
      hasUnsavedChanges = true;
    });
  }

  /// Updates a complex mapping
  void updateComplexMapping(
      String targetField, String expression, List<Map<String, String>> tokens) {
    setState(() {
      // Remove any existing mapping
      mappings.removeWhere((m) => m['target'] == targetField);

      // Add new complex mapping
      final newMapping = {
        'target': targetField,
        'isComplex': 'true',
        'jsonataExpr': expression,
        'tokens': tokens,
      };
      mappings.add(newMapping);

      // Update state provider
      if (currentLoadedMapping?.product != null) {
        Provider.of<MappingState>(context, listen: false).setMappings(
          'Elastic',
          currentLoadedMapping!.product,
          List.from(mappings),
        );
      }

      hasUnsavedChanges = true;
    });
  }

  /// Loads a saved mapping
  void loadMapping(SavedMapping mapping) {
    setState(() {
      mappings.clear();
      mappings.addAll(mapping.mappings);
      currentLoadedMapping = mapping;
      hasUnsavedChanges = false;

      // Update state provider
      Provider.of<MappingState>(context, listen: false)
          .setMappings('Elastic', mapping.product, List.from(mappings));
    });
  }

  /// Auto-maps fields based on name matching
  void autoMapFields(
    List<String> sourceFields,
    List<SaasField> saasFields,
    Map<String, dynamic> sampleData,
    Function(String, String) onConfigFieldChanged,
  ) {
    final newMappings = List<Map<String, dynamic>>.from(mappings);

    for (final sourceField in sourceFields) {
      final sourceValue = _getNestedValue(sampleData, sourceField);
      if (sourceValue == null) continue;

      for (final saasField in saasFields) {
        final isAlreadyMapped =
            newMappings.any((m) => m['target'] == saasField.name);
        if (isAlreadyMapped) continue;

        final isMatching =
            sourceField.toLowerCase() == saasField.name.toLowerCase();

        if (isMatching) {
          if (saasField.category.toLowerCase() == 'configuration') {
            onConfigFieldChanged(saasField.name, sourceValue.toString());
          } else {
            newMappings.add({
              'source': sourceField,
              'target': saasField.name,
              'isComplex': 'false',
            });
          }
        }
      }
    }

    setState(() {
      mappings = newMappings;
      hasUnsavedChanges = true;
    });
  }

  /// Gets a nested value from a map using a dot-notation path
  dynamic _getNestedValue(Map<String, dynamic> data, String path) {
    final keys = path.split('.');
    dynamic value = data;
    for (final key in keys) {
      if (value is! Map) return null;
      value = value[key];
    }
    return value;
  }

  /// Evaluates a mapping against sample data
  String evaluateMapping(
      Map<String, dynamic> sampleData, Map<String, dynamic> mapping) {
    if (mapping.isEmpty) return '';

    try {
      if (mapping['isComplex'] == 'true' && mapping['tokens'] != null) {
        final tokens = List<Map<String, String>>.from(
          mapping['tokens'].map((t) => Map<String, String>.from(t)),
        );

        final parts = tokens.map((token) {
          if (token['type'] == 'field') {
            final fieldPath = token['value']!.substring(1);
            return _getNestedValue(sampleData, fieldPath)?.toString() ?? '';
          } else if (token['type'] == 'text') {
            return token['value']!.substring(1, token['value']!.length - 1);
          }
          return '';
        }).toList();

        return parts.join('');
      } else if (mapping['source'] != null && mapping['source']!.isNotEmpty) {
        return _getNestedValue(sampleData, mapping['source']!) ?? '';
      }
      return '';
    } catch (e) {
      debugPrint('Error evaluating mapping: $e');
      return '';
    }
  }
}
