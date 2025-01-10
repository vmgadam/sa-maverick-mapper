import 'package:flutter/material.dart';
import 'type_definitions.dart';

/// Constants related to UI configuration and styling
class UIConstants {
  // Layout dimensions
  static const double defaultPadding = 8.0;
  static const double defaultSpacing = 8.0;
  static const double headerHeight = 56.0;
  static const double inputSectionHeight = 0.3; // 30% of screen height
  static const double borderRadius = 4.0;

  // Font sizes
  static const double headerFontSize = 16.0;
  static const double bodyFontSize = 14.0;
  static const double smallFontSize = 12.0;

  // Icon sizes
  static const double largeIconSize = 24.0;
  static const double mediumIconSize = 20.0;
  static const double smallIconSize = 16.0;
  static const double tinyIconSize = 12.0;

  // Colors
  static const Color borderColor = Colors.grey;
  static const Color requiredFieldColor = Colors.red;
  static const Color disabledColor = Colors.grey;

  // Text styles
  static const TextStyle monospaceStyle = TextStyle(
    fontFamily: 'monospace',
    height: 1.5,
  );

  static const TextStyle headerStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: headerFontSize,
  );

  static const TextStyle labelStyle = TextStyle(
    fontWeight: FontWeight.bold,
  );

  // Input decoration
  static const EdgeInsets contentPadding = EdgeInsets.all(8.0);
  static const OutlineInputBorder defaultBorder = OutlineInputBorder();

  // Animation durations - using AnimationDurations class
  static const Duration shortAnimation = AnimationDurations.short;
  static const Duration mediumAnimation = AnimationDurations.medium;
  static const Duration longAnimation = AnimationDurations.long;

  // Table constants - using TableConfig class
  static const double tableRowHeight = TableConfig.rowHeight;
  static const double tableHeaderHeight = TableConfig.headerHeight;
  static const double columnWidth = TableConfig.columnWidth;
  static const int maxTableRows = TableConfig.maxRows;

  // Scroll behavior
  static const ScrollPhysics defaultScrollPhysics =
      AlwaysScrollableScrollPhysics();
  static const bool defaultScrollbarVisibility = true;
}
