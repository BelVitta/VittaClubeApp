import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../admin/presentation/widgets/admin_page_scaffold.dart';
import '../../../../admin/presentation/widgets/admin_form_card.dart';
import '../../../../admin/presentation/widgets/admin_form_field.dart';

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
  final _passwordController = TextEditingController();
  String _selectedCategory = 'laboratorio';
  bool _isSaving = false;

  static const _categories = [
    {'value': 'laboratorio', 'label': 'Laboratorio'},
    {'value': 'clinica', 'label': 'Clinica'},
    {'value': 'farmacia', 'label': 'Farmacia'},
    {'value': 'otica', 'label': 'Otica'},
    {'value': 'outro', 'label': 'Outro'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Preencha nome, e-mail e senha.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'A senha deve ter pelo menos 6 caracteres.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Simula delay de rede
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isSaving = false);

    _showSuccessDialog();
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
              'Cadastro enviado!',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seu cadastro como parceiro foi recebido.\n\n'
              'No ambiente de testes, voce ja pode acessar com:\n\n'
              'E-mail: parceiro@vitaclube.com\n'
              'Senha: parceiro123',
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
                  // Volta ate a tela anterior ao "Seja Parceiro"
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
                  hintText: 'Ex: Lab Vita Saude',
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
                  label: 'Endereco',
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
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Credenciais de acesso
          AdminFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Credenciais de Acesso',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Voce usara esses dados para acessar o painel de parceiro.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6D7F95),
                  ),
                ),
                const SizedBox(height: 16),
                AdminFormField(
                  label: 'E-mail',
                  controller: _emailController,
                  hintText: 'Ex: contato@seulab.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                AdminFormField(
                  label: 'Senha',
                  controller: _passwordController,
                  hintText: 'Minimo 6 caracteres',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          PrimaryButton(
            text: _isSaving ? 'Enviando...' : 'Cadastrar',
            onPressed: _isSaving ? null : _handleSubmit,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
