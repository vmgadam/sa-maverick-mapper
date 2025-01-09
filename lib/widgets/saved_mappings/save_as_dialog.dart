import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/saved_mapping.dart';
import '../../state/saved_mappings_state.dart';

class SaveAsDialog extends StatefulWidget {
  final String product;
  final String query;
  final List<Map<String, String>> mappings;
  final Map<String, dynamic> configFields;
  final int totalFieldsMapped;
  final int requiredFieldsMapped;
  final int totalRequiredFields;
  final List<Map<String, dynamic>> rawSamples;

  const SaveAsDialog({
    super.key,
    required this.product,
    required this.query,
    required this.mappings,
    required this.configFields,
    required this.totalFieldsMapped,
    required this.requiredFieldsMapped,
    required this.totalRequiredFields,
    required this.rawSamples,
  });

  static Future<String?> show({
    required BuildContext context,
    required String product,
    required String query,
    required List<Map<String, String>> mappings,
    required Map<String, dynamic> configFields,
    required int totalFieldsMapped,
    required int requiredFieldsMapped,
    required int totalRequiredFields,
    required List<Map<String, dynamic>> rawSamples,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SaveAsDialog(
        product: product,
        query: query,
        mappings: mappings,
        configFields: configFields,
        totalFieldsMapped: totalFieldsMapped,
        requiredFieldsMapped: requiredFieldsMapped,
        totalRequiredFields: totalRequiredFields,
        rawSamples: rawSamples,
      ),
    );
  }

  @override
  State<SaveAsDialog> createState() => _SaveAsDialogState();
}

class _SaveAsDialogState extends State<SaveAsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final formState = _formKey.currentState;
    if (formState == null) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a name';
      });
      return;
    }

    if (name.length > 200) {
      setState(() {
        _errorMessage = 'Name must be 200 characters or less';
      });
      return;
    }

    if (!formState.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (!mounted) return;

      final state = Provider.of<SavedMappingsState>(context, listen: false);

      // Create a copy of the raw samples to avoid reference issues
      final rawSamplesCopy = List<Map<String, dynamic>>.from(widget.rawSamples);

      final newMapping = SavedMapping(
        eventName: name,
        product: widget.product,
        query: widget.query,
        mappings: List<Map<String, String>>.from(widget.mappings),
        configFields: Map<String, dynamic>.from(widget.configFields),
        totalFieldsMapped: widget.totalFieldsMapped,
        requiredFieldsMapped: widget.requiredFieldsMapped,
        totalRequiredFields: widget.totalRequiredFields,
        rawSamples: rawSamplesCopy,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      // Use a microtask to avoid blocking the UI
      await Future.microtask(() => state.createMapping(newMapping));

      if (!mounted) return;
      Navigator.of(context).pop(name);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isSaving,
      child: AlertDialog(
        title: const Text('Save Mapping As'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Mapping Name',
                  hintText: 'Enter a name for this mapping',
                  helperText: 'Maximum 200 characters',
                ),
                maxLength: 200,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                enabled: !_isSaving,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
