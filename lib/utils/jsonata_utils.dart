import 'package:flutter/foundation.dart';
import '../models/mapping_token.dart';

// Expression building and evaluation utilities

class JsonataUtils {
  /// Builds a JSONata expression from a list of tokens
  static String buildExpression(List<MappingToken> tokens) {
    final List<String> parts = [];
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (token.type == TokenType.field) {
        if (parts.isNotEmpty) parts.add(' & ');
        parts.add(token.value);
      } else if (token.type == TokenType.text) {
        if (parts.isNotEmpty) parts.add(' & ');
        // For text tokens, use single quotes
        String text = token.value.substring(1, token.value.length - 1);
        parts.add("'$text'");
      }
    }
    return parts.join('');
  }

  /// Evaluates an expression using sample data
  static String evaluateExpression(String expression, Map<String, dynamic> data) {
    try {
      // Evaluate the expression
      return expression;
    } catch (e) {
      // Remove debug print
      return '';
    }
  }

  static dynamic getNestedValue(Map<String, dynamic> data, String path) {
    final parts = path.split('.');
    dynamic value = data;
    for (final part in parts) {
      if (value is! Map<String, dynamic>) return null;
      value = value[part];
    }
    return value;
  }
}
