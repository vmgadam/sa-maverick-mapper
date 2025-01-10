import 'package:flutter/material.dart';

/// Enum for different field categories
enum FieldCategory {
  standard('Standard'),
  configuration('Configuration');

  final String value;
  const FieldCategory(this.value);
}

/// Enum for mapping modes
enum MappingMode {
  simple('false'),
  complex('true');

  final String value;
  const MappingMode(this.value);

  bool get isComplex => this == MappingMode.complex;
}

/// Enum for token types
enum TokenType {
  field('field'),
  text('text');

  final String value;
  const TokenType(this.value);
}

/// Enum for product types
enum ProductType {
  elastic('Elastic');

  final String value;
  const ProductType(this.value);
}

/// Enum for field types
enum FieldType {
  string('string'),
  number('number'),
  boolean('boolean'),
  date('date'),
  object('object'),
  array('array');

  final String value;
  const FieldType(this.value);
}

/// Class for mapping-related keys
class MappingKeys {
  static const String source = 'source';
  static const String target = 'target';
  static const String isComplex = 'isComplex';
  static const String tokens = 'tokens';
  static const String jsonataExpr = 'jsonataExpr';
}

/// Class for elastic-specific field paths
class ElasticFields {
  static const String timestamp = '@timestamp';
  static const String productType = 'product.type';
  static const String rawResponse = 'rawResponse';
  static const String hits = 'hits';
}

/// Record for table configuration
class TableConfig {
  static const double rowHeight = 48.0;
  static const double headerHeight = 56.0;
  static const double columnWidth = 180.0;
  static const int maxRows = 50;
}

/// Record for animation durations
class AnimationDurations {
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 500);
}

/// Record for API timeouts
class ApiTimeouts {
  static const Duration connection = Duration(milliseconds: 30000);
  static const Duration response = Duration(milliseconds: 60000);
  static const Duration retry = Duration(milliseconds: 1000);
  static const int maxRetries = 3;
}

/// Record for cache configuration
class CacheConfig {
  static const Duration expiration = Duration(minutes: 30);
  static const int maxSize = 100;
  static const bool enabled = true;
}
