import 'package:flutter/material.dart';
import '../models/saas_field.dart';

class EventDataSource extends DataTableSource {
  final List<Map<String, dynamic>> events;
  final List<SaasField> fields;
  final List<Map<String, dynamic>> mappings;
  final Function(Map<String, dynamic>, Map<String, dynamic>) evaluateMapping;

  EventDataSource(
      this.events, this.fields, this.mappings, this.evaluateMapping);

  @override
  DataRow? getRow(int index) {
    if (index >= events.length) return null;
    final event = events[index];
    return DataRow(
      cells: fields.map((field) {
        final mapping = mappings.firstWhere(
          (m) => m['target'] == field.name,
          orElse: () => {},
        );
        final value = evaluateMapping(event, mapping);
        return DataCell(
          Text(
            value.isEmpty ? '' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => events.length;

  @override
  int get selectedRowCount => 0;
}
