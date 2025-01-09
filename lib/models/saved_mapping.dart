import 'package:collection/collection.dart';

class SavedMapping {
  final String eventName;
  final String product;
  final String query;
  final List<Map<String, String>> mappings;
  final Map<String, dynamic> configFields;
  final int totalFieldsMapped;
  final int requiredFieldsMapped;
  final int totalRequiredFields;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String? productType;
  final int? endpointId;
  final String? endpointName;
  final Map<String, dynamic>? accountKey;
  final String? dateKeyField;
  final Map<String, dynamic>? eventFilter;
  final Map<String, dynamic>? schema;
  final Map<String, dynamic>? params;
  final List<Map<String, dynamic>> rawSamples;

  SavedMapping({
    required this.eventName,
    required this.product,
    required this.query,
    required this.mappings,
    required this.configFields,
    required this.totalFieldsMapped,
    required this.requiredFieldsMapped,
    required this.totalRequiredFields,
    required this.createdAt,
    required this.modifiedAt,
    required this.rawSamples,
    this.productType,
    this.endpointId,
    this.endpointName,
    this.accountKey,
    this.dateKeyField,
    this.eventFilter,
    this.schema,
    this.params,
  }) {
    if (eventName.isEmpty) {
      throw ArgumentError('Event name cannot be empty');
    }
    if (eventName.length > 200) {
      throw ArgumentError('Event name must be 200 characters or less');
    }
  }

  // Create a copy with optional parameter updates
  SavedMapping copyWith({
    String? eventName,
    String? product,
    String? query,
    List<Map<String, String>>? mappings,
    Map<String, dynamic>? configFields,
    int? totalFieldsMapped,
    int? requiredFieldsMapped,
    int? totalRequiredFields,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? productType,
    int? endpointId,
    String? endpointName,
    Map<String, dynamic>? accountKey,
    String? dateKeyField,
    Map<String, dynamic>? eventFilter,
    Map<String, dynamic>? schema,
    Map<String, dynamic>? params,
    List<Map<String, dynamic>>? rawSamples,
  }) {
    return SavedMapping(
      eventName: eventName ?? this.eventName,
      product: product ?? this.product,
      query: query ?? this.query,
      mappings: mappings ?? this.mappings,
      configFields: configFields ?? this.configFields,
      totalFieldsMapped: totalFieldsMapped ?? this.totalFieldsMapped,
      requiredFieldsMapped: requiredFieldsMapped ?? this.requiredFieldsMapped,
      totalRequiredFields: totalRequiredFields ?? this.totalRequiredFields,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      rawSamples: rawSamples ?? this.rawSamples,
      productType: productType ?? this.productType,
      endpointId: endpointId ?? this.endpointId,
      endpointName: endpointName ?? this.endpointName,
      accountKey: accountKey ?? this.accountKey,
      dateKeyField: dateKeyField ?? this.dateKeyField,
      eventFilter: eventFilter ?? this.eventFilter,
      schema: schema ?? this.schema,
      params: params ?? this.params,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'eventName': eventName,
        'product': product,
        'query': query,
        'mappings': mappings,
        'configFields': configFields,
        'totalFieldsMapped': totalFieldsMapped,
        'requiredFieldsMapped': requiredFieldsMapped,
        'totalRequiredFields': totalRequiredFields,
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
        'rawSamples': rawSamples,
        'productType': productType,
        'endpointId': endpointId,
        'endpointName': endpointName,
        'accountKey': accountKey,
        'dateKeyField': dateKeyField,
        'eventFilter': eventFilter,
        'schema': schema,
        'params': params,
      };

  // Create from JSON
  factory SavedMapping.fromJson(Map<String, dynamic> json) => SavedMapping(
        eventName: json['eventName'] as String? ??
            json['name'] as String, // Handle legacy format
        product: json['product'] as String,
        query: json['query'] as String,
        mappings: (json['mappings'] as List<dynamic>)
            .map((e) => Map<String, String>.from(e as Map))
            .toList(),
        configFields: json['configFields'] as Map<String, dynamic>,
        totalFieldsMapped: json['totalFieldsMapped'] as int,
        requiredFieldsMapped: json['requiredFieldsMapped'] as int,
        totalRequiredFields: json['totalRequiredFields'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        modifiedAt: DateTime.parse(json['modifiedAt'] as String),
        rawSamples: (json['rawSamples'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
        productType: json['productType'] as String?,
        endpointId: json['endpointId'] as int?,
        endpointName: json['endpointName'] as String?,
        accountKey: json['accountKey'] as Map<String, dynamic>?,
        dateKeyField: json['dateKeyField'] as String?,
        eventFilter: json['eventFilter'] as Map<String, dynamic>?,
        schema: json['schema'] as Map<String, dynamic>?,
        params: json['params'] as Map<String, dynamic>?,
      );

  // Export to mappingConfig.json format
  Map<String, dynamic> toMappingConfig() {
    final String id = eventName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return {
      'meta': {
        'format': 'JSON',
        'version': '1.1.0',
        'projectId': id,
        'resourcePath': ['mappingConfig'],
        'recursive': false,
        'creationTime': createdAt.millisecondsSinceEpoch ~/ 1000,
        'app': 'maverick-mapper'
      },
      'data': {
        id: {
          'accountKey': accountKey,
          'dateKeyField': dateKeyField,
          'endpointId': endpointId,
          'endpointName': endpointName,
          'eventFilter': eventFilter,
          'productType': productType,
          'schema': schema,
          'params': params ?? {'skipOAL': false},
          '__collections__': {}
        }
      }
    };
  }

  // Create from mappingConfig.json format
  factory SavedMapping.fromMappingConfig(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final firstKey = data.keys.first;
    final mapping = data[firstKey] as Map<String, dynamic>;

    return SavedMapping(
      eventName: firstKey,
      product: mapping['productType'] as String? ?? '',
      query: mapping['eventFilter']?.toString() ?? '',
      mappings: [], // This will need to be populated from the schema
      configFields: {}, // This will need to be populated from the full config
      totalFieldsMapped: 0, // This will need to be calculated
      requiredFieldsMapped: 0, // This will need to be calculated
      totalRequiredFields: 0, // This will need to be calculated
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (json['meta']['creationTime'] as int) * 1000),
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['meta']['creationTime'] as int) * 1000),
      rawSamples: [], // Initialize with empty list as this is from config
      productType: mapping['productType'] as String?,
      endpointId: mapping['endpointId'] as int?,
      endpointName: mapping['endpointName'] as String?,
      accountKey: mapping['accountKey'] as Map<String, dynamic>?,
      dateKeyField: mapping['dateKeyField'] as String?,
      eventFilter: mapping['eventFilter'] as Map<String, dynamic>?,
      schema: mapping['schema'] as Map<String, dynamic>?,
      params: mapping['params'] as Map<String, dynamic>?,
    );
  }

  // Check if this mapping is equal to another mapping
  bool isEquivalentTo(SavedMapping other) {
    return eventName == other.eventName &&
        product == other.product &&
        query == other.query &&
        const DeepCollectionEquality().equals(mappings, other.mappings) &&
        const DeepCollectionEquality()
            .equals(configFields, other.configFields) &&
        totalFieldsMapped == other.totalFieldsMapped &&
        requiredFieldsMapped == other.requiredFieldsMapped &&
        totalRequiredFields == other.totalRequiredFields &&
        productType == other.productType &&
        endpointId == other.endpointId &&
        endpointName == other.endpointName &&
        const DeepCollectionEquality().equals(accountKey, other.accountKey) &&
        dateKeyField == other.dateKeyField &&
        const DeepCollectionEquality().equals(eventFilter, other.eventFilter) &&
        const DeepCollectionEquality().equals(schema, other.schema) &&
        const DeepCollectionEquality().equals(params, other.params);
  }
}
