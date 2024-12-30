import 'package:flutter/material.dart';

class ConfigurationFieldsWidget extends StatelessWidget {
  final Map<String, String> configFields;
  final List<String> eventTypes;
  final Function(String, String) onConfigFieldChanged;
  final TextEditingController eventTypeController;

  const ConfigurationFieldsWidget({
    super.key,
    required this.configFields,
    required this.eventTypes,
    required this.onConfigFieldChanged,
    required this.eventTypeController,
  });

  @override
  Widget build(BuildContext context) {
    bool isCustomEventType = !eventTypes.contains(configFields['eventType']);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuration Fields',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Product Reference',
                    hintText: 'products/default',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  controller: TextEditingController(
                    text: configFields['productRef'],
                  ),
                  onChanged: (value) =>
                      onConfigFieldChanged('productRef', value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Endpoint ID',
                    hintText: '0',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  controller: TextEditingController(
                    text: configFields['endpointId'],
                  ),
                  onChanged: (value) =>
                      onConfigFieldChanged('endpointId', value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: isCustomEventType
                    ? TextField(
                        decoration: const InputDecoration(
                          labelText: 'Custom Event Type',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        controller: eventTypeController,
                        onChanged: (value) =>
                            onConfigFieldChanged('eventType', value),
                      )
                    : DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Event Type',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        value: eventTypes.contains(configFields['eventType'])
                            ? configFields['eventType']
                            : eventTypes.first,
                        items: [
                          ...eventTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }),
                          const DropdownMenuItem<String>(
                            value: 'CUSTOM',
                            child: Text('CUSTOM'),
                          ),
                        ],
                        onChanged: (String? value) {
                          if (value == 'CUSTOM') {
                            eventTypeController.text = '';
                            onConfigFieldChanged('eventType', '');
                          } else if (value != null) {
                            eventTypeController.text = value;
                            onConfigFieldChanged('eventType', value);
                          }
                        },
                      ),
              ),
              if (isCustomEventType)
                IconButton(
                  icon: const Icon(Icons.list),
                  tooltip: 'Show predefined types',
                  onPressed: () {
                    final defaultType = eventTypes.first;
                    eventTypeController.text = defaultType;
                    onConfigFieldChanged('eventType', defaultType);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
