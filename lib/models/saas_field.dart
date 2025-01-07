class SaasField {
  final String name;
  final bool required;
  final String description;
  final String type;
  final String category;
  final int displayOrder;

  const SaasField({
    required this.name,
    required this.required,
    required this.description,
    required this.type,
    required this.category,
    required this.displayOrder,
  });

  factory SaasField.fromJson(Map<String, dynamic> json) {
    return SaasField(
      name: json['name'] as String,
      required: json['required'] as bool,
      description: json['description'] as String,
      type: json['type'] as String,
      category: json['category'] as String,
      displayOrder: json['displayOrder'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'required': required,
      'description': description,
      'type': type,
      'category': category,
      'displayOrder': displayOrder,
    };
  }

  SaasField copyWith({
    String? name,
    bool? required,
    String? description,
    String? type,
    String? category,
    int? displayOrder,
  }) {
    return SaasField(
      name: name ?? this.name,
      required: required ?? this.required,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}
