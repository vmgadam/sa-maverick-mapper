import 'package:flutter/material.dart';
import '../configuration_fields_widget.dart';
import '../../models/saas_field.dart';

class ConfigurationSection extends StatelessWidget {
  final Map<String, String> configFields;
  final Function(String, String) onConfigFieldChanged;
  final List<SaasField> saasFields;
  final bool showConfiguration;

  const ConfigurationSection({
    super.key,
    required this.configFields,
    required this.onConfigFieldChanged,
    required this.saasFields,
    required this.showConfiguration,
  });

  List<Map<String, dynamic>> get configurationFieldsForWidget {
    final fields = saasFields
        .where((field) => field.category.toLowerCase() == 'configuration')
        .map((field) {
      return {
        'name': field.name,
        'required': field.required,
        'description': field.description,
        'type': field.type,
        'options': field.options,
      };
    }).toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    return fields;
  }

  @override
  Widget build(BuildContext context) {
    if (!showConfiguration) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ConfigurationFieldsWidget(
          configFields: configFields,
          onConfigFieldChanged: onConfigFieldChanged,
          configurationFields: configurationFieldsForWidget,
        ),
        const Divider(),
      ],
    );
  }
}
