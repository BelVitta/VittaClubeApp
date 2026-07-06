import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';

class DependentForm extends StatefulWidget {
  final void Function({
    required String name,
    required String cpf,
    required DateTime birthDate,
    required String relationship,
  }) onSubmit;

  const DependentForm({super.key, required this.onSubmit});

  @override
  State<DependentForm> createState() => _DependentFormState();
}

class _DependentFormState extends State<DependentForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _relationshipController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _birthDateController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final parts = _birthDateController.text.split('/');
    widget.onSubmit(
      name: _nameController.text.trim(),
      cpf: _cpfController.text.trim(),
      birthDate: DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      ),
      relationship: _relationshipController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: AppTheme.inputDecoration(label: 'Nome do dependente'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Informe o nome.'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cpfController,
            keyboardType: TextInputType.number,
            decoration: AppTheme.inputDecoration(label: 'CPF'),
            validator: (value) =>
                Validators.isValidCpf(value ?? '') ? null : 'CPF invalido.',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _birthDateController,
            keyboardType: TextInputType.datetime,
            decoration:
                AppTheme.inputDecoration(label: 'Nascimento (dd/mm/aaaa)'),
            validator: (value) {
              final raw = value ?? '';
              final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
              return regex.hasMatch(raw) ? null : 'Use o formato dd/mm/aaaa.';
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _relationshipController,
            decoration: AppTheme.inputDecoration(label: 'Parentesco'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Informe o parentesco.'
                : null,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('Salvar dependente'),
            ),
          ),
        ],
      ),
    );
  }
}
