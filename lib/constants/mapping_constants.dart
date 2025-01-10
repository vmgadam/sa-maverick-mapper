/// Constants related to mapping functionality and configuration
class MappingConstants {
  // Record limits for data display
  static const List<int> recordLimits = [1, 5, 10, 20, 50, 100, 200];
  static const int defaultRecordLimit = 5;

  // Field categories
  static const String standardCategory = 'Standard';
  static const String configurationCategory = 'Configuration';

  // Mapping types
  static const String simpleMapping = 'false';
  static const String complexMapping = 'true';
  static const String defaultMappingMode = 'simple';

  // Default values
  static const int defaultDisplayOrder = 999;
  static const String defaultProductType = 'Elastic';
  static const String defaultFieldType = 'string';

  // Field keys
  static const String sourceKey = 'source';
  static const String targetKey = 'target';
  static const String isComplexKey = 'isComplex';
  static const String tokensKey = 'tokens';
  static const String jsonataExprKey = 'jsonataExpr';

  // Token types
  static const String fieldTokenType = 'field';
  static const String textTokenType = 'text';

  // Elastic specific fields
  static const String timestampField = '@timestamp';
  static const String productTypeField = 'product.type';
  static const String rawResponseField = 'rawResponse';
  static const String hitsField = 'hits';

  // Validation
  static const int maxEventNameLength = 200;
  static const String emptyTokens = '[]';
  static const String emptyExpression = '';
}
