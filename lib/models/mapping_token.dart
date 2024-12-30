import 'dart:convert';

enum TokenType { field, text }

class MappingToken {
  final TokenType type;
  final String value;

  MappingToken({
    required this.type,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        'type': type.toString().split('.').last,
        'value': value,
      };

  factory MappingToken.fromJson(Map<String, dynamic> json) {
    return MappingToken(
      type: TokenType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      value: json['value'],
    );
  }

  static List<MappingToken> listFromJson(String jsonString) {
    if (jsonString.isEmpty) return [];
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => MappingToken.fromJson(json)).toList();
  }

  static String listToJson(List<MappingToken> tokens) {
    return json.encode(tokens.map((t) => t.toJson()).toList());
  }
}
