class SaasField {
  final String name;
  final bool required;
  final String description;
  final String type;
  final String defaultMode;
  final String category;
  final int displayOrder;
  final List<String>? options;

  const SaasField({
    required this.name,
    required this.required,
    required this.description,
    required this.type,
    this.defaultMode = 'simple',
    required this.category,
    this.displayOrder = 999,
    this.options,
  });

  /// Creates a SaasField instance from a JSON map
  /// [name] is the field name
  /// [json] is the JSON map containing the field properties
  factory SaasField.fromJson(String name, Map<String, dynamic> json) {
    final required = json['required'] == true;
    final description = json['description']?.toString() ?? '';
    final type = json['type']?.toString().toLowerCase() ?? 'string';
    final defaultMode = json['defaultMode']?.toString() ?? 'simple';
    final category = json['category']?.toString() ?? 'Standard';
    final displayOrder = json['displayOrder'] as int? ?? 999;

    List<String>? options;
    if (json['options'] is List) {
      options = (json['options'] as List).map((e) => e.toString()).toList();
    }

    return SaasField(
      name: name,
      required: required,
      description: description,
      type: type,
      defaultMode: defaultMode,
      category: category,
      displayOrder: displayOrder,
      options: options,
    );
  }

  /// Converts the SaasField to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'required': required,
      'description': description,
      'type': type,
      'defaultMode': defaultMode,
      'category': category,
      'displayOrder': displayOrder,
      if (options != null) 'options': options,
    };
  }

  /// Creates a copy of this SaasField with the given fields replaced with new values
  SaasField copyWith({
    String? name,
    bool? required,
    String? description,
    String? type,
    String? defaultMode,
    String? category,
    int? displayOrder,
    List<String>? options,
  }) {
    return SaasField(
      name: name ?? this.name,
      required: required ?? this.required,
      description: description ?? this.description,
      type: type ?? this.type,
      defaultMode: defaultMode ?? this.defaultMode,
      category: category ?? this.category,
      displayOrder: displayOrder ?? this.displayOrder,
      options: options ?? this.options,
    );
  }
}
