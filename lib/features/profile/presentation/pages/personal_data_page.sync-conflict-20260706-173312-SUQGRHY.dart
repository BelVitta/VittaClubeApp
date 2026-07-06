import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/secondary_button.dart';

/// Página de Dados Pessoais - alterna entre modo visualização e edição
class PersonalDataPage extends StatefulWidget {
  const PersonalDataPage({super.key});

  @override
  State<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends State<PersonalDataPage> {
  bool _isEditing = false;
  bool _loading = true;
  bool _saving = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cpfController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    final row = await SupabaseConfig.client
        .from('profiles')
        .select('name, email')
        .eq('id', userId)
        .maybeSingle();
    if (!mounted) return;
    _nameController.text = row?['name'] as String? ?? '';
    _emailController.text = row?['email'] as String? ?? '';
    _phoneController.text = 'Protegido';
    _cpfController.text = 'Protegido';
    setState(() => _loading = false);
  }

  Future<void> _handleSave() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || _saving) return;
    setState(() => _saving = true);
    await SupabaseConfig.client.from('profiles').update({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
    }).eq('id', userId);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dados salvos com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient circle
            Positioned(
              top: -16,
              right: -180,
              child: Container(
                width: 503.5,
                height: 283.06,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.gradientLight.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, 1],
                  ),
                ),
              ),
            ),

            Column(
              children: [
                // Back button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 39,
                          height: 39,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF01225B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(19.5),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'Dados Pessoais',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                            letterSpacing: 0.12,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Subtitle
                        Text(
                          'Informações Básicas',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                            letterSpacing: 0.075,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Form card
                        if (_loading)
                          const Center(child: CircularProgressIndicator())
                        else
                          _buildFormCard(),
                        const SizedBox(height: 6),

                        // Action button
                        if (_isEditing)
                          PrimaryButton(
                            text: _saving ? 'Salvando...' : 'Salvar',
                            onPressed: _saving ? null : _handleSave,
                          )
                        else
                          SecondaryButton(
                            text: 'Editar',
                            onPressed: () => setState(() => _isEditing = true),
                          ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEEF2)),
      ),
      child: Column(
        children: [
          _buildField('Nome Completo', _nameController),
          const SizedBox(height: 6),
          _buildField('E-mail', _emailController,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 6),
          _buildField(
            'Telefone',
            _phoneController,
            keyboardType: TextInputType.phone,
            forceReadOnly: true,
          ),
          const SizedBox(height: 6),
          _buildField(
            'CPF',
            _cpfController,
            keyboardType: TextInputType.number,
            forceReadOnly: true,
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool forceReadOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFCFCFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDDDFE5)),
          ),
          child: TextField(
            controller: controller,
            readOnly: forceReadOnly || !_isEditing,
            keyboardType: keyboardType,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppTheme.primaryColor,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
