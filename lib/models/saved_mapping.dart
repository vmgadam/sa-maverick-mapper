class SavedMapping {
  final String name;
  final String product;
  final String query;
  final String eventName;
  final List<Map<String, String>> mappings;
  final Map<String, dynamic> configFields;
  final int totalFieldsMapped;
  final int requiredFieldsMapped;
  final int totalRequiredFields;
  final DateTime createdAt;
  final DateTime modifiedAt;

  SavedMapping({
    required this.name,
    required this.product,
    required this.query,
    this.eventName = '',
    required this.mappings,
    required this.configFields,
    required this.totalFieldsMapped,
    required this.requiredFieldsMapped,
    required this.totalRequiredFields,
    required this.createdAt,
    required this.modifiedAt,
  }) {
    if (name.isEmpty) {
      throw ArgumentError('Name cannot be empty');
    }
    if (name.length > 200) {
      throw ArgumentError('Name must be 200 characters or less');
    }
  }

  // Create a copy with optional parameter updates
  SavedMapping copyWith({
    String? name,
    String? product,
    String? query,
    String? eventName,
    List<Map<String, String>>? mappings,
    Map<String, dynamic>? configFields,
    int? totalFieldsMapped,
    int? requiredFieldsMapped,
    int? totalRequiredFields,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return SavedMapping(
      name: name ?? this.name,
      product: product ?? this.product,
      query: query ?? this.query,
      eventName: eventName ?? this.eventName,
      mappings: mappings ?? this.mappings,
      configFields: configFields ?? this.configFields,
      totalFieldsMapped: totalFieldsMapped ?? this.totalFieldsMapped,
      requiredFieldsMapped: requiredFieldsMapped ?? this.requiredFieldsMapped,
      totalRequiredFields: totalRequiredFields ?? this.totalRequiredFields,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'name': name,
        'product': product,
        'query': query,
        'eventName': eventName,
        'mappings': mappings,
        'configFields': configFields,
        'totalFieldsMapped': totalFieldsMapped,
        'requiredFieldsMapped': requiredFieldsMapped,
        'totalRequiredFields': totalRequiredFields,
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
      };

  // Create from JSON
  factory SavedMapping.fromJson(Map<String, dynamic> json) => SavedMapping(
        name: json['name'] as String,
        product: json['product'] as String,
        query: json['query'] as String,
        eventName: json['eventName'] as String? ?? '',
        mappings: (json['mappings'] as List<dynamic>)
            .map((e) => Map<String, String>.from(e as Map))
            .toList(),
        configFields: json['configFields'] as Map<String, dynamic>,
        totalFieldsMapped: json['totalFieldsMapped'] as int,
        requiredFieldsMapped: json['requiredFieldsMapped'] as int,
        totalRequiredFields: json['totalRequiredFields'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      );
}
