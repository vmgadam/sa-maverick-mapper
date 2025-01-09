import 'package:collection/collection.dart';

// New class to represent the schema structure
class SchemaDefinition {
  final String eventId;
  final String? ip;
  final String? jointDescAdditional;
  final String? result;
  final String time;

  SchemaDefinition({
    required this.eventId,
    this.ip,
    this.jointDescAdditional,
    this.result,
    required this.time,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        if (ip != null) 'ip': ip,
        if (jointDescAdditional != null)
          'jointDescAdditional': jointDescAdditional,
        if (result != null) 'result': result,
        'time': time,
      };

  // Create from JSON
  factory SchemaDefinition.fromJson(Map<String, dynamic> json) {
    return SchemaDefinition(
      eventId: json['eventId'] as String,
      ip: json['ip'] as String?,
      jointDescAdditional: json['jointDescAdditional'] as String?,
      result: json['result'] as String?,
      time: json['time'] as String,
    );
  }

  // Check if this schema is equal to another schema
  bool isEquivalentTo(SchemaDefinition other) {
    return eventId == other.eventId &&
        ip == other.ip &&
        jointDescAdditional == other.jointDescAdditional &&
        result == other.result &&
        time == other.time;
  }
}

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
  final SchemaDefinition? schema;
  final Map<String, dynamic>? params;
  final List<Map<String, dynamic>> rawSamples;
  final String? eventTypeKey;

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
    this.eventTypeKey,
  }) {
    if (eventName.isEmpty) {
      throw ArgumentError('Event name cannot be empty');
    }
    if (eventName.length > 200) {
      throw ArgumentError('Event name must be 200 characters or less');
    }
    if (accountKey != null) {
      if (!accountKey!.containsKey('field') ||
          !accountKey!.containsKey('type')) {
        throw ArgumentError(
            'accountKey must contain "field" and "type" properties');
      }
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
    SchemaDefinition? schema,
    Map<String, dynamic>? params,
    List<Map<String, dynamic>>? rawSamples,
    String? eventTypeKey,
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
      eventTypeKey: eventTypeKey ?? this.eventTypeKey,
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
        'schema': schema?.toJson(),
        'params': params,
        'eventTypeKey': eventTypeKey,
      };

  // Create from JSON
  factory SavedMapping.fromJson(Map<String, dynamic> json) => SavedMapping(
        eventName: json['eventName'] as String? ?? json['name'] as String,
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
        schema: json['schema'] != null
            ? SchemaDefinition.fromJson(json['schema'] as Map<String, dynamic>)
            : null,
        params: json['params'] as Map<String, dynamic>?,
        eventTypeKey: json['eventTypeKey'] as String?,
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
          'eventType': eventTypeKey ?? 'EVENT',
          'eventTypeKey': eventTypeKey ?? 'EVENT',
          'productType': productType,
          'schema': schema?.toJson(),
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
      mappings: [],
      configFields: {},
      totalFieldsMapped: 0,
      requiredFieldsMapped: 0,
      totalRequiredFields: 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (json['meta']['creationTime'] as int) * 1000),
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['meta']['creationTime'] as int) * 1000),
      rawSamples: [],
      productType: mapping['productType'] as String?,
      endpointId: mapping['endpointId'] as int?,
      endpointName: mapping['endpointName'] as String?,
      accountKey: mapping['accountKey'] as Map<String, dynamic>?,
      dateKeyField: mapping['dateKeyField'] as String?,
      eventFilter: mapping['eventFilter'] as Map<String, dynamic>?,
      schema: mapping['schema'] != null
          ? SchemaDefinition.fromJson(mapping['schema'] as Map<String, dynamic>)
          : null,
      params: mapping['params'] as Map<String, dynamic>?,
      eventTypeKey: mapping['eventTypeKey'] as String?,
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
        (schema?.isEquivalentTo(other.schema!) ?? other.schema == null) &&
        const DeepCollectionEquality().equals(params, other.params) &&
        eventTypeKey == other.eventTypeKey;
  }
}
