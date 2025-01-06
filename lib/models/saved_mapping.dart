import 'package:flutter/foundation.dart';

class SavedMapping {
  final String name;
  final String product;
  final String query;
  final List<Map<String, dynamic>> mappings;
  final Map<String, dynamic> configFields;
  final int totalFieldsMapped;
  final int requiredFieldsMapped;
  final int totalRequiredFields;
  final DateTime createdAt;
  DateTime modifiedAt;

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
  })  : this.createdAt = createdAt ?? DateTime.now(),
        this.modifiedAt = modifiedAt ?? DateTime.now();

  SavedMapping copyWith({
    String? name,
    String? product,
    String? query,
    List<Map<String, dynamic>>? mappings,
    Map<String, dynamic>? configFields,
    int? totalFieldsMapped,
    int? requiredFieldsMapped,
    int? totalRequiredFields,
    DateTime? modifiedAt,
  }) {
    return SavedMapping(
      name: name ?? this.name,
      product: product ?? this.product,
      query: query ?? this.query,
      mappings: mappings ?? List.from(this.mappings),
      configFields: configFields ?? Map.from(this.configFields),
      totalFieldsMapped: totalFieldsMapped ?? this.totalFieldsMapped,
      requiredFieldsMapped: requiredFieldsMapped ?? this.requiredFieldsMapped,
      totalRequiredFields: totalRequiredFields ?? this.totalRequiredFields,
      createdAt: this.createdAt,
      modifiedAt: modifiedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'product': product,
      'query': query,
      'mappings': mappings,
      'configFields': configFields,
      'totalFieldsMapped': totalFieldsMapped,
      'requiredFieldsMapped': requiredFieldsMapped,
      'totalRequiredFields': totalRequiredFields,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
    };
  }

  factory SavedMapping.fromJson(Map<String, dynamic> json) {
    return SavedMapping(
      name: json['name'] as String,
      product: json['product'] as String,
      query: json['query'] as String,
      mappings: List<Map<String, dynamic>>.from(json['mappings']),
      configFields: Map<String, dynamic>.from(json['configFields']),
      totalFieldsMapped: json['totalFieldsMapped'] as int,
      requiredFieldsMapped: json['requiredFieldsMapped'] as int,
      totalRequiredFields: json['totalRequiredFields'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
    );
  }

  factory SavedMapping.duplicate(SavedMapping original, {String? newName}) {
    return SavedMapping(
      name: newName ?? 'Copy of ${original.name}',
      product: original.product,
      query: original.query,
      mappings: List.from(original.mappings),
      configFields: Map.from(original.configFields),
      totalFieldsMapped: original.totalFieldsMapped,
      requiredFieldsMapped: original.requiredFieldsMapped,
      totalRequiredFields: original.totalRequiredFields,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SavedMapping &&
        other.name == name &&
        other.product == product &&
        other.query == query;
  }

  @override
  int get hashCode => Object.hash(name, product, query);
}
