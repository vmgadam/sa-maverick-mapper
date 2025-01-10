/// Defines the type of field mapping
enum FieldMappingType { simple, complex }

/// Defines the field category
enum FieldCategory { standard, configuration }

/// Defines the field type
enum FieldType { string, number, picklist }

/// Defines special handling types for elastic mappings
enum SpecialHandlingType { queryExtraction }

/// Represents a field definition
class FieldDefinition {
  final String name;
  final bool required;
  final String description;
  final FieldType type;
  final FieldMappingType defaultMode;
  final FieldCategory category;
  final int displayOrder;
  final List<String>? options;

  const FieldDefinition({
    required this.name,
    required this.required,
    required this.description,
    required this.type,
    this.defaultMode = FieldMappingType.simple,
    required this.category,
    this.displayOrder = 999,
    this.options,
  });
}

/// Represents an elastic field mapping
class ElasticFieldMapping {
  final String source;
  final String destination;
  final String description;
  final SpecialHandlingType? specialHandling;

  const ElasticFieldMapping({
    required this.source,
    required this.destination,
    required this.description,
    this.specialHandling,
  });
}

/// Unified configuration for all field definitions and mappings
class FieldDefinitions {
  // Event Types for different contexts
  static const List<String> generalEventTypes = [
    'LOGIN_SUCCESS',
    'LOGIN_FAILURE',
    'USER_CREATED',
    'USER_DELETED',
    'USER_MODIFIED',
    'ROLE_MODIFIED',
    'PERMISSION_MODIFIED',
    'POLICY_MODIFIED',
    'SECURITY_ALERT',
    'DATA_ACCESS',
    'CONFIGURATION_CHANGE',
    'CUSTOM'
  ];

  static const List<String> deviceEventTypes = [
    'DEVICE_STATUS',
    'DEVICE_CONNECTED',
    'DEVICE_DISCONNECTED',
    'DEVICE_MODIFIED',
    'SECURITY_ALERT',
    'CONFIGURATION_CHANGE',
    'CUSTOM'
  ];

  // Standard Fields
  static const Map<String, FieldDefinition> standardFields = {
    '_id': FieldDefinition(
      name: '_id',
      required: true,
      description: 'Unique identifier for the event',
      type: FieldType.string,
      category: FieldCategory.standard,
      displayOrder: 0,
    ),
    'time': FieldDefinition(
      name: 'time',
      required: true,
      description: 'Timestamp of when the event occurred',
      type: FieldType.string,
      category: FieldCategory.standard,
      displayOrder: 1,
    ),
    'ip': FieldDefinition(
      name: 'ip',
      required: true,
      description: 'IP address associated with the event',
      type: FieldType.string,
      category: FieldCategory.standard,
      displayOrder: 3,
    ),
    'user.name': FieldDefinition(
      name: 'user.name',
      required: false,
      description: 'Username associated with the event',
      type: FieldType.string,
      category: FieldCategory.standard,
      displayOrder: 4,
    ),
    'userAgent': FieldDefinition(
      name: 'userAgent',
      required: false,
      description: 'User agent string from the device',
      type: FieldType.string,
      category: FieldCategory.standard,
      displayOrder: 5,
    ),
    'device.sourceInfo.os': FieldDefinition(
      name: 'device.sourceInfo.os',
      required: false,
      description: 'Operating system of the device',
      type: FieldType.string,
      category: FieldCategory.standard,
      displayOrder: 6,
    ),
    'device.sourceInfo.deviceName': FieldDefinition(
      name: 'device.sourceInfo.deviceName',
      required: false,
      description: 'Name of the device',
      type: FieldType.string,
      category: FieldCategory.standard,
      displayOrder: 7,
    ),
    'jointDesc': FieldDefinition(
      name: 'jointDesc',
      required: false,
      description: 'Primary description of the event',
      type: FieldType.string,
      category: FieldCategory.standard,
      displayOrder: 9,
    ),
    'jointDescAdditional': FieldDefinition(
      name: 'jointDescAdditional',
      required: true,
      description: 'Additional descriptive information about the event',
      type: FieldType.string,
      defaultMode: FieldMappingType.complex,
      category: FieldCategory.standard,
      displayOrder: 10,
    ),
    'recommendation': FieldDefinition(
      name: 'recommendation',
      required: false,
      description: 'Recommended actions or additional context',
      type: FieldType.string,
      defaultMode: FieldMappingType.complex,
      category: FieldCategory.standard,
      displayOrder: 11,
    ),
    'device.sourceInfo.msftEntraDeviceId': FieldDefinition(
      name: 'device.sourceInfo.msftEntraDeviceId',
      required: false,
      description: 'Microsoft Entra Device ID',
      type: FieldType.string,
      category: FieldCategory.standard,
      displayOrder: 8,
    ),
    'partner.id': FieldDefinition(
      name: 'partner.id',
      required: true,
      description: 'Id of the SaaS Alerts Partner',
      type: FieldType.string,
      category: FieldCategory.configuration,
      displayOrder: 12,
    ),
    'userKeyField': FieldDefinition(
      name: 'userKeyField',
      required: true,
      description: 'Field path for user identification',
      type: FieldType.string,
      category: FieldCategory.standard,
      displayOrder: 13,
    ),
    'eventFilter': FieldDefinition(
      name: 'eventFilter',
      required: true,
      description: 'Query filter for events',
      type: FieldType.string,
      category: FieldCategory.standard,
      displayOrder: 14,
    ),
  };

  // Configuration Fields
  static const Map<String, FieldDefinition> configurationFields = {
    'accountKey': FieldDefinition(
      name: 'accountKey',
      required: true,
      description: 'Field path for account identification',
      type: FieldType.string,
      defaultMode: FieldMappingType.complex,
      category: FieldCategory.configuration,
      displayOrder: 1,
    ),
    'accountKey.field': FieldDefinition(
      name: 'accountKey.field',
      required: true,
      description: 'Field path for account identification',
      type: FieldType.string,
      defaultMode: FieldMappingType.complex,
      category: FieldCategory.configuration,
      displayOrder: 2,
    ),
    'accountKey.type': FieldDefinition(
      name: 'accountKey.type',
      required: false,
      description: 'Type of account key (e.g., "id")',
      type: FieldType.string,
      category: FieldCategory.configuration,
      displayOrder: 3,
    ),
    'dateKeyField': FieldDefinition(
      name: 'dateKeyField',
      required: true,
      description: 'Field path for event timestamp',
      type: FieldType.string,
      category: FieldCategory.configuration,
      displayOrder: 4,
    ),
    'endpointId': FieldDefinition(
      name: 'endpointId',
      required: true,
      description: 'Numeric identifier for the endpoint',
      type: FieldType.number,
      category: FieldCategory.configuration,
      displayOrder: 5,
    ),
    'eventType': FieldDefinition(
      name: 'eventType',
      required: true,
      description: 'Type of event',
      type: FieldType.picklist,
      category: FieldCategory.configuration,
      options: generalEventTypes,
      displayOrder: 7,
    ),
    'productRef': FieldDefinition(
      name: 'productRef',
      required: true,
      description: 'Reference to product configuration',
      type: FieldType.string,
      category: FieldCategory.configuration,
      displayOrder: 9,
    ),
    'productType': FieldDefinition(
      name: 'productType',
      required: true,
      description: 'Type of product (e.g., "OKTA", "MS")',
      type: FieldType.string,
      category: FieldCategory.configuration,
      displayOrder: 10,
    )
  };

  // Elastic Mappings
  static const Map<String, ElasticFieldMapping> elasticMappings = {
    'product.endpoint.id': ElasticFieldMapping(
      source: 'product.endpoint.id',
      destination: 'endpointId',
      description:
          'Maps to the configuration field endpointId from the Response JSON',
    ),
    '_source.product.type': ElasticFieldMapping(
      source: '_source.product.type',
      destination: 'productRef',
      description: 'Maps to the configuration field productRef',
    ),
    'request.query': ElasticFieldMapping(
      source: 'request.query',
      destination: 'eventFilter',
      description:
          'The query section from the request should be extracted and used in the eventFilter field of the JSONata export',
      specialHandling: SpecialHandlingType.queryExtraction,
    ),
    'fields.product.type[0]': ElasticFieldMapping(
      source: 'fields.product.type[0]',
      destination: 'productType',
      description:
          'Maps to the configuration field productType from the first event record in the parsed data',
    ),
  };

  // Helper methods
  static List<FieldDefinition> getAllFields() {
    return [...standardFields.values, ...configurationFields.values];
  }

  static List<FieldDefinition> getRequiredFields() {
    return getAllFields().where((field) => field.required).toList();
  }

  static List<FieldDefinition> getFieldsByCategory(FieldCategory category) {
    return getAllFields().where((field) => field.category == category).toList();
  }

  static FieldDefinition? getFieldByName(String name) {
    return standardFields[name] ?? configurationFields[name];
  }

  static ElasticFieldMapping? getElasticMapping(String source) {
    return elasticMappings[source];
  }
}
