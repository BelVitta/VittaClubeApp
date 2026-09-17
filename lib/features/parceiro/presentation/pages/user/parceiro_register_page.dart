import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/config/supabase_config.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../admin/presentation/widgets/admin_page_scaffold.dart';
import '../../../../admin/presentation/widgets/admin_form_card.dart';
import '../../../../admin/presentation/widgets/admin_form_field.dart';
import '../../../domain/usecases/partner_application/submit_partner_application_usecase.dart';

class ParceiroRegisterPage extends StatefulWidget {
  const ParceiroRegisterPage({super.key});

  @override
  State<ParceiroRegisterPage> createState() => _ParceiroRegisterPageState();
}

class _ParceiroRegisterPageState extends State<ParceiroRegisterPage> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedCategory = 'laboratorio';
  bool _isSaving = false;

  static const _categories = [
    {'value': 'laboratorio', 'label': 'Laboratório'},
    {'value': 'clinica', 'label': 'Clínica'},
    {'value': 'farmacia', 'label': 'Farmácia'},
    {'value': 'otica', 'label': 'Ótica'},
    {'value': 'outro', 'label': 'Outro'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Preencha nome e e-mail.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final userId = SupabaseConfig.client.auth.currentUser?.id;
    final result = await sl<SubmitPartnerApplicationUseCase>()(
      name: name,
      category: _selectedCategory,
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      email: email,
      userId: userId,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: AppTheme.errorColor,
        ),
      ),
      (_) => _showSuccessDialog(),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.check_circle,
                size: 40,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Candidatura enviada!',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Recebemos sua candidatura como parceiro.\n'
              'Nossa equipe vai analisar e entrar em contato pelo '
              'e-mail informado.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6D7F95),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: 'Entendi',
                onPressed: () {
                  Navigator.pop(ctx);
                  // Volta até a tela anterior ao "Seja Parceiro"
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      title: 'Cadastro Parceiro',
      subtitle: 'Preencha os dados do seu estabelecimento',
      body: Column(
        children: [
          AdminFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminFormField(
                  label: 'Nome do Estabelecimento',
                  controller: _nameController,
                  hintText: 'Ex: Lab Vita Saúde',
                ),
                const SizedBox(height: 16),

                // Category dropdown
                Text(
                  'Categoria',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFCFC),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFDDDFE5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      menuMaxHeight: 300,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF6D7F95),
                      ),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.primaryColor,
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat['value'],
                          child: Text(cat['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                AdminFormField(
                  label: 'Endereço',
                  controller: _addressController,
                  hintText: 'Ex: Av. Santos Dumont, 1500',
                ),
                const SizedBox(height: 16),
                AdminFormField(
                  label: 'Telefone / WhatsApp',
                  controller: _phoneController,
                  hintText: 'Ex: 85999001122',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                AdminFormField(
                  label: 'E-mail para contato',
                  controller: _emailController,
                  hintText: 'Ex: contato@seulab.com',
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: _isSaving ? 'Enviando...' : 'Enviar Candidatura',
            onPressed: _isSaving ? null : _handleSubmit,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
