import 'package:flutter/material.dart';

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

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Table constants
  static const double tableRowHeight = 48.0;
  static const double tableHeaderHeight = 56.0;
  static const double columnWidth = 180.0;
  static const int maxTableRows = 50;

  // Scroll behavior
  static const ScrollPhysics defaultScrollPhysics =
      AlwaysScrollableScrollPhysics();
  static const bool defaultScrollbarVisibility = true;
}
