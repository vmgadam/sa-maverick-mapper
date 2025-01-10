/// Constants related to validation rules and messages
class ValidationConstants {
  // Field validation
  static const int minEventNameLength = 1;
  static const int maxEventNameLength = 200;
  static const int minFieldNameLength = 1;
  static const int maxFieldNameLength = 100;

  // Required field messages
  static const String eventNameRequired = 'Event name is required';
  static const String responseDataRequired =
      'Response data is required for Elastic Raw format';
  static const String rawResponseRequired =
      'No rawResponse found in Elastic data';
  static const String noRecordsFound =
      'No records found in Elastic Response data';

  // Format validation messages
  static const String invalidEventNameLength =
      'Event name must be between $minEventNameLength and $maxEventNameLength characters';
  static const String invalidFieldNameLength =
      'Field name must be between $minFieldNameLength and $maxFieldNameLength characters';
  static const String invalidJsonFormat = 'Invalid JSON format';
  static const String duplicateEventName =
      'An event with this name already exists';

  // Mapping validation messages
  static const String noFieldsSelected = 'No fields have been mapped';
  static const String requiredFieldsMissing = 'Required fields must be mapped';
  static const String invalidMappingFormat = 'Invalid mapping format';
  static const String invalidTokenFormat = 'Invalid token format';

  // Regular expressions
  static const String validFieldNamePattern = r'^[a-zA-Z][a-zA-Z0-9_]*$';
  static const String validEventNamePattern = r'^[a-zA-Z0-9_\- ]+$';

  // Validation rules
  static const bool allowEmptyFields = false;
  static const bool requireUniqueNames = true;
  static const bool validateFieldNames = true;
}
