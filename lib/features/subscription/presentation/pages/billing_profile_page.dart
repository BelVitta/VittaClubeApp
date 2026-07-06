import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/repositories/subscription_repository.dart';

class BillingProfilePage extends StatefulWidget {
  final PixAutomaticBillingProfile? initialProfile;

  const BillingProfilePage({super.key, this.initialProfile});

  @override
  State<BillingProfilePage> createState() => _BillingProfilePageState();
}

class _BillingProfilePageState extends State<BillingProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _zipcodeController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    final User? user = SupabaseConfig.client.auth.currentUser;
    _nameController.text = profile?.name ??
        user?.userMetadata?['name']?.toString() ??
        user?.userMetadata?['full_name']?.toString() ??
        '';
    _taxIdController.text = profile?.taxId ?? '';
    _emailController.text = profile?.email ?? user?.email ?? '';
    _phoneController.text = profile?.phone ?? user?.phone ?? '';
    _zipcodeController.text = profile?.address.zipcode ?? '';
    _streetController.text = profile?.address.street ?? '';
    _numberController.text = profile?.address.number ?? '';
    _complementController.text = profile?.address.complement ?? '';
    _neighborhoodController.text = profile?.address.neighborhood ?? '';
    _cityController.text = profile?.address.city ?? '';
    _stateController.text = profile?.address.state ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taxIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _zipcodeController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final profile = PixAutomaticBillingProfile(
      name: _nameController.text.trim(),
      taxId: _digitsOnly(_taxIdController.text),
      email: _emailController.text.trim(),
      phone: _normalizeBrazilianPhone(_phoneController.text),
      address: PixAutomaticBillingAddress(
        zipcode: _digitsOnly(_zipcodeController.text),
        street: _streetController.text.trim(),
        number: _numberController.text.trim(),
        complement: _complementController.text.trim().isEmpty
            ? null
            : _complementController.text.trim(),
        neighborhood: _neighborhoodController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim().toUpperCase(),
      ),
    );

    final result =
        await sl<SubscriptionRepository>().saveBillingProfile(profile);
    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (failure) => _showError(failure.message),
      (saved) => Navigator.of(context).pop(saved),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Dados de cobrança'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Text(
                'Esses dados são obrigatórios para criar o Pix Automático.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF6D7F95),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 16),
              _field('Nome completo', _nameController, _requiredName),
              _field(
                'CPF',
                _taxIdController,
                _requiredCpf,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
              ),
              _field(
                'E-mail',
                _emailController,
                _requiredEmail,
                keyboardType: TextInputType.emailAddress,
              ),
              _field(
                'Telefone com DDD',
                _phoneController,
                _requiredPhone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(13),
                ],
              ),
              _field(
                'CEP',
                _zipcodeController,
                _requiredCep,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
              ),
              _field('Rua', _streetController, _requiredText),
              _field('Número', _numberController, _requiredText),
              _field('Complemento', _complementController, (_) => null),
              _field('Bairro', _neighborhoodController, _requiredText),
              _field('Cidade', _cityController, _requiredText),
              _field(
                'UF',
                _stateController,
                _requiredState,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [LengthLimitingTextInputFormatter(2)],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: PrimaryButton(
          text: _saving ? 'Salvando...' : 'Salvar e continuar',
          onPressed: _saving ? null : _save,
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String? Function(String?) validator, {
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

String? _requiredText(String? value) =>
    value == null || value.trim().isEmpty ? 'Campo obrigatório.' : null;

String? _requiredName(String? value) => value == null || value.trim().length < 3
    ? 'Informe o nome completo.'
    : null;

String? _requiredCpf(String? value) => _digitsOnly(value ?? '').length != 11
    ? 'Informe um CPF com 11 dígitos.'
    : null;

String? _requiredEmail(String? value) {
  final email = value?.trim() ?? '';
  return email.contains('@') && email.contains('.')
      ? null
      : 'Informe um e-mail válido.';
}

String? _requiredPhone(String? value) {
  final digits = _digitsOnly(value ?? '');
  return digits.length < 10 ? 'Informe telefone com DDD.' : null;
}

String? _requiredCep(String? value) => _digitsOnly(value ?? '').length != 8
    ? 'Informe um CEP com 8 dígitos.'
    : null;

String? _requiredState(String? value) {
  final uf = value?.trim().toUpperCase() ?? '';
  return RegExp(r'^[A-Z]{2}$').hasMatch(uf)
      ? null
      : 'Informe a UF com 2 letras.';
}

String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

String _normalizeBrazilianPhone(String value) {
  final digits = _digitsOnly(value);
  if (digits.startsWith('55')) return digits;
  return '55$digits';
}
