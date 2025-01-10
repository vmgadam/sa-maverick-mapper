import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/saas_field.dart';

/// A mixin that provides elastic data handling functionality
mixin ElasticDataMixin<T extends StatefulWidget> on State<T> {
  final TextEditingController elasticRequestController =
      TextEditingController();
  final TextEditingController elasticResponseController =
      TextEditingController();
  bool _isProcessingRequest = false;
  bool _isProcessingResponse = false;

  List<Map<String, dynamic>> rcEvents = [];
  List<String> rcFields = [];
  Map<String, dynamic> currentRcEvent = {};

  void clearJson() {
    elasticRequestController.clear();
    elasticResponseController.clear();
  }

  List<String> getAllNestedFields(List<dynamic> data, [String prefix = '']) {
    if (data.isEmpty) return [];
    return data.first is Map<String, dynamic>
        ? _extractFields(data.first as Map<String, dynamic>, prefix)
        : [];
  }

  List<String> _extractFields(Map<String, dynamic> map, String prefix) {
    final fields = <String>[];
    map.forEach((key, value) {
      final fieldName = prefix.isEmpty ? key : '$prefix.$key';
      fields.add(fieldName);
      if (value is Map<String, dynamic>) {
        fields.addAll(_extractFields(value, fieldName));
      } else if (value is List && value.isNotEmpty && value.first is Map) {
        fields.addAll(
            _extractFields(value.first as Map<String, dynamic>, fieldName));
      }
    });
    return fields;
  }

  Future<void> parseJson({
    required List<Map<String, dynamic>> mappings,
    required Function(List<Map<String, dynamic>>) onMappingsChanged,
    required Function(String, String) onConfigFieldChanged,
    required List<SaasField> saasFields,
  }) async {
    try {
      // Parse both request and response data
      final requestData = elasticRequestController.text.isNotEmpty
          ? json.decode(elasticRequestController.text)
          : null;
      final responseData = elasticResponseController.text.isNotEmpty
          ? json.decode(elasticResponseController.text)
          : null;

      if (responseData == null) {
        throw Exception('Response data is required for Elastic Raw format');
      }

      // Parse the rawResponse which contains the actual Elastic data
      final rawResponse = responseData['rawResponse'];
      if (rawResponse == null) {
        throw Exception('No rawResponse found in Elastic data');
      }

      // Parse or use the raw response
      final elasticData =
          rawResponse is String ? json.decode(rawResponse) : rawResponse;

      // Extract hits from response data
      final hits = elasticData['hits']?['hits'] as List?;
      if (hits == null || hits.isEmpty) {
        throw Exception('No records found in Elastic Response data');
      }

      // Extract query from request if available
      String? querySection;
      if (requestData != null && requestData['query'] != null) {
        querySection = json.encode(requestData['query']);
      }

      // Get the first hit's fields to extract product type
      final firstHit = hits[0];
      final fields = firstHit['fields'] as Map<String, dynamic>;
      final productType = fields['product.type']?[0] as String? ?? 'Elastic';

      // Update state
      setState(() {
        currentRcEvent = Map<String, dynamic>.from(firstHit['fields']);
        rcFields = getAllNestedFields([currentRcEvent]);
        rcEvents = hits
            .take(5) // Limit to 5 records by default
            .map((hit) => Map<String, dynamic>.from(hit['fields']))
            .toList();

        // Auto-map fields and update configuration
        _autoMapFields(
            mappings, saasFields, onMappingsChanged, onConfigFieldChanged);

        // Set the query section if available
        if (querySection != null) {
          onConfigFieldChanged('eventFilter', querySection);
        }
      });

      // Clear input fields after successful parse
      clearJson();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid JSON: $e')),
      );
    }
  }

  void _autoMapFields(
    List<Map<String, dynamic>> mappings,
    List<SaasField> saasFields,
    Function(List<Map<String, dynamic>>) onMappingsChanged,
    Function(String, String) onConfigFieldChanged,
  ) {
    final newMappings = List<Map<String, dynamic>>.from(mappings);

    for (final sourceField in rcFields) {
      final sourceValue = _getNestedValue(currentRcEvent, sourceField);
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

    onMappingsChanged(newMappings);
  }

  dynamic _getNestedValue(Map<String, dynamic> data, String path) {
    final keys = path.split('.');
    dynamic value = data;
    for (final key in keys) {
      if (value is! Map) return null;
      value = value[key];
    }
    return value;
  }

  @override
  void dispose() {
    elasticRequestController.dispose();
    elasticResponseController.dispose();
    super.dispose();
  }
}
