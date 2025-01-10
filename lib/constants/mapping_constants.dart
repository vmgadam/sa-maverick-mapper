import 'type_definitions.dart';

/// Constants related to mapping functionality and configuration
class MappingConstants {
  // Record limits for data display
  static const List<int> recordLimits = [1, 5, 10, 20, 50, 100, 200];
  static const int defaultRecordLimit = 5;

  // Field categories
  static const FieldCategory defaultCategory = FieldCategory.standard;
  static const List<FieldCategory> availableCategories = FieldCategory.values;

  // Mapping types
  static const MappingMode defaultMappingMode = MappingMode.simple;

  // Default values
  static const int defaultDisplayOrder = 999;
  static const ProductType defaultProductType = ProductType.elastic;
  static const FieldType defaultFieldType = FieldType.string;

  // Field keys - using MappingKeys class
  static const String sourceKey = MappingKeys.source;
  static const String targetKey = MappingKeys.target;
  static const String isComplexKey = MappingKeys.isComplex;
  static const String tokensKey = MappingKeys.tokens;
  static const String jsonataExprKey = MappingKeys.jsonataExpr;

  // Token types - using TokenType enum
  static const TokenType defaultTokenType = TokenType.field;
  static const List<TokenType> availableTokenTypes = TokenType.values;

  // Elastic specific fields - using ElasticFields class
  static const String timestampField = ElasticFields.timestamp;
  static const String productTypeField = ElasticFields.productType;
  static const String rawResponseField = ElasticFields.rawResponse;
  static const String hitsField = ElasticFields.hits;

  // Empty values
  static const String emptyTokens = '[]';
  static const String emptyExpression = '';
}
