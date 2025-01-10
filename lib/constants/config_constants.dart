/// Constants related to application configuration and defaults
class ConfigConstants {
  // File paths and storage
  static const String mappingsStoragePath = 'mappings';
  static const String configStoragePath = 'config';
  static const String defaultConfigFile = 'default_config.json';
  static const String backupDirectory = 'backups';

  // Default values
  static const int defaultPageSize = 10;
  static const int maxPageSize = 100;
  static const int defaultRecordLimit = 1000;
  static const String defaultDateFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String defaultTimeZone = 'UTC';
  static const String defaultLocale = 'en_US';

  // API endpoints
  static const String elasticEndpoint = '/elastic';
  static const String mappingEndpoint = '/mapping';
  static const String configEndpoint = '/config';
  static const String healthEndpoint = '/health';

  // Headers and content types
  static const String contentTypeHeader = 'Content-Type';
  static const String jsonContentType = 'application/json';
  static const String authorizationHeader = 'Authorization';
  static const String acceptHeader = 'Accept';

  // Timeouts and retry settings
  static const int connectionTimeout = 30000; // milliseconds
  static const int responseTimeout = 60000; // milliseconds
  static const int maxRetries = 3;
  static const int retryDelay = 1000; // milliseconds

  // Cache settings
  static const bool enableCache = true;
  static const int cacheMaxSize = 100;
  static const Duration cacheExpiration = Duration(minutes: 30);

  // Debug and logging
  static const bool enableDebugMode = false;
  static const bool enableVerboseLogging = false;
  static const String logDirectory = 'logs';
  static const String logFilePrefix = 'app_log_';
}
