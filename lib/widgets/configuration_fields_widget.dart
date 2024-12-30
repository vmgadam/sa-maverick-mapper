import 'package:flutter/material.dart';

class ConfigurationFieldsWidget extends StatelessWidget {
  final Map<String, String> configFields;
  final Function(String, String) onConfigFieldChanged;
  final List<Map<String, dynamic>> configurationFields;

  const ConfigurationFieldsWidget({
    super.key,
    required this.configFields,
    required this.onConfigFieldChanged,
    required this.configurationFields,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Configuration Fields',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              const Icon(Icons.info_outline, size: 16),
              const SizedBox(width: 4),
              const Text(
                'Fields marked with',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.star, size: 12, color: Colors.red),
              const SizedBox(width: 4),
              const Text(
                'are required',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: configurationFields.map((field) {
              final fieldName = field['name'] as String;
              final isRequired = field['required'] as bool;
              final description = field['description'] as String;
              final type = (field['type'] as String).toLowerCase();
              final options = field['options'] as List<String>?;

              debugPrint('\nBuilding configuration field: $fieldName');
              debugPrint('  type: $type');
              debugPrint('  options: $options');

              String? currentValue = configFields[fieldName];
              if (currentValue == null &&
                  type == 'picklist' &&
                  options != null &&
                  options.isNotEmpty) {
                currentValue = options.first;
                onConfigFieldChanged(fieldName, currentValue);
              }

              return SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          fieldName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isRequired ? Colors.red : null,
                          ),
                        ),
                        if (isRequired)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child:
                                Icon(Icons.star, size: 12, color: Colors.red),
                          ),
                        const Spacer(),
                        Tooltip(
                          message: description,
                          child: const Icon(Icons.info_outline, size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (type == 'picklist' &&
                        options != null &&
                        options.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: currentValue ?? options.first,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        items: options.map((option) {
                          debugPrint('  Creating dropdown item: $option');
                          return DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            debugPrint('  Selected value: $value');
                            onConfigFieldChanged(fieldName, value);
                          }
                        },
                      )
                    else if (type == 'number')
                      TextFormField(
                        initialValue: currentValue ?? '',
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: const OutlineInputBorder(),
                          hintText: description,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) =>
                            onConfigFieldChanged(fieldName, value),
                      )
                    else
                      TextFormField(
                        initialValue: currentValue ?? '',
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: const OutlineInputBorder(),
                          hintText: description,
                        ),
                        onChanged: (value) =>
                            onConfigFieldChanged(fieldName, value),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
