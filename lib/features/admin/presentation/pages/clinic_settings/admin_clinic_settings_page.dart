import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/services/clinic_settings_service.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../widgets/admin_form_card.dart';
import '../../widgets/admin_form_field.dart';
import '../../widgets/admin_page_scaffold.dart';

/// Tela de configurações gerais da clínica. Hoje só edita o número padrão
/// do WhatsApp usado como fallback quando um profissional não tem o próprio.
class AdminClinicSettingsPage extends StatefulWidget {
  const AdminClinicSettingsPage({super.key});

  @override
  State<AdminClinicSettingsPage> createState() =>
      _AdminClinicSettingsPageState();
}

class _AdminClinicSettingsPageState extends State<AdminClinicSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _maxDependentsController = TextEditingController();
  final _monthlyUsesController = TextEditingController();
  final _service = sl<ClinicSettingsService>();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _maxDependentsController.dispose();
    _monthlyUsesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final current =
          await _service.get(ClinicSettingsService.kDefaultWhatsapp);
      final maxDependents = await _service.getMaxDependentsPerHolder();
      final monthlyUses = await _service.getMonthlyUsesPerDependent();
      if (!mounted) return;
      _controller.text = current ?? '';
      _maxDependentsController.text = maxDependents.toString();
      _monthlyUsesController.text = monthlyUses.toString();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar configurações: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _positiveIntValidator(String? value, String fieldLabel) {
    final n = int.tryParse((value ?? '').trim());
    if (n == null || n <= 0) {
      return '$fieldLabel deve ser um número inteiro maior que zero.';
    }
    return null;
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o número do WhatsApp.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.set(ClinicSettingsService.kDefaultWhatsapp, raw);
      await _service
          .setMaxDependentsPerHolder(int.parse(_maxDependentsController.text.trim()));
      await _service.setMonthlyUsesPerDependent(
          int.parse(_monthlyUsesController.text.trim()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      title: 'Configurações da clínica',
      floatingBottom: PrimaryButton(
        text: _saving ? 'Salvando...' : 'Salvar',
        onPressed: _saving || _loading ? null : _handleSave,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: AdminFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Número padrão (WhatsApp)',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Formato E.164 sem espaços: código do país + DDD + número. '
                      'Ex: 5585999000000.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6D7F95),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AdminFormField(
                      label: 'Número',
                      controller: _controller,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Dependentes',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Limite de dependentes por titular e usos com desconto '
                      'liberados por dependente a cada ciclo mensal.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6D7F95),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AdminFormField(
                      label: 'Limite de dependentes por titular',
                      controller: _maxDependentsController,
                      keyboardType: TextInputType.number,
                      validator: (value) => _positiveIntValidator(
                          value, 'Limite de dependentes'),
                    ),
                    const SizedBox(height: 12),
                    AdminFormField(
                      label: 'Usos mensais por dependente',
                      controller: _monthlyUsesController,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          _positiveIntValidator(value, 'Usos mensais'),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }
}
