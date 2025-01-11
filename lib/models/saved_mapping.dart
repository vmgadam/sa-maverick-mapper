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
  });

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
    List<Map<String, dynamic>>? rawSamples,
  }) {
    return SavedMapping(
      eventName: eventName ?? this.eventName,
      product: product ?? this.product,
      query: query ?? this.query,
      mappings: mappings ?? List.from(this.mappings),
      configFields: configFields ?? Map.from(this.configFields),
      totalFieldsMapped: totalFieldsMapped ?? this.totalFieldsMapped,
      requiredFieldsMapped: requiredFieldsMapped ?? this.requiredFieldsMapped,
      totalRequiredFields: totalRequiredFields ?? this.totalRequiredFields,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      rawSamples: rawSamples ?? List.from(this.rawSamples),
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
      };

  // Convert to mapping configuration format
  Map<String, dynamic> toMappingConfig() {
    final mappingSchema = <String, dynamic>{};
    for (var mapping in mappings) {
      if (mapping['isComplex'] == 'true') {
        mappingSchema[mapping['target']!] = mapping['jsonataExpr'] ?? '';
      } else {
        mappingSchema[mapping['target']!] = mapping['source'];
      }
    }

    return {
      'accountKey': {
        'field': configFields['accountKeyField'] ?? '',
        'type': configFields['accountKeyType'] ?? ''
      },
      'dateKeyField': configFields['dateKeyField'] ?? '',
      'endpointId':
          int.tryParse(configFields['endpointId']?.toString() ?? '') ?? 0,
      'endpointName': configFields['endpointName'] ?? '',
      'eventFilter': configFields['eventFilter'] ?? '{}',
      'eventType': configFields['eventType'] ?? '',
      'eventTypeKey': configFields['eventType'] ?? '',
      'productRef': {'__ref__': configFields['productRef'] ?? ''},
      'userKeyField': configFields['userKeyField'] ?? '',
      'schema': mappingSchema,
    };
  }

  // Create from JSON
  factory SavedMapping.fromJson(Map<String, dynamic> json) => SavedMapping(
        eventName: json['eventName'] as String,
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
        rawSamples: (json['rawSamples'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
}
