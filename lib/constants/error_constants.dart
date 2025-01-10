/// Constants related to error messages and error handling
class ErrorConstants {
  // General errors
  static const String unknownError = 'An unknown error occurred';
  static const String networkError = 'Network connection error';
  static const String timeoutError = 'Request timed out';
  static const String serverError = 'Server error occurred';
  static const String invalidRequest = 'Invalid request';

  // Authentication errors
  static const String unauthorized = 'Unauthorized access';
  static const String invalidCredentials = 'Invalid credentials';
  static const String sessionExpired = 'Session has expired';
  static const String accessDenied = 'Access denied';

  // Data errors
  static const String dataNotFound = 'Data not found';
  static const String invalidData = 'Invalid data format';
  static const String dataCorrupted = 'Data is corrupted';
  static const String incompatibleData = 'Incompatible data format';

  // File operation errors
  static const String fileNotFound = 'File not found';
  static const String fileAccessDenied = 'File access denied';
  static const String fileCorrupted = 'File is corrupted';
  static const String invalidFilePath = 'Invalid file path';

  // Mapping errors
  static const String mappingNotFound = 'Mapping not found';
  static const String invalidMapping = 'Invalid mapping format';
  static const String mappingExists = 'Mapping already exists';
  static const String mappingCorrupted = 'Mapping data is corrupted';

  // Configuration errors
  static const String configNotFound = 'Configuration not found';
  static const String invalidConfig = 'Invalid configuration';
  static const String configCorrupted = 'Configuration is corrupted';
  static const String missingConfig = 'Required configuration missing';

  // Error codes
  static const int errorCodeUnknown = 1000;
  static const int errorCodeNetwork = 1001;
  static const int errorCodeTimeout = 1002;
  static const int errorCodeServer = 1003;
  static const int errorCodeAuth = 1004;
  static const int errorCodeData = 1005;
  static const int errorCodeFile = 1006;
  static const int errorCodeMapping = 1007;
  static const int errorCodeConfig = 1008;
}
