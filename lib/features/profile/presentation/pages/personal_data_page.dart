import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/secondary_button.dart';
import '../../../auth/data/services/auth_session_manager.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../home/presentation/pages/home_page.dart';

/// Página de Dados Pessoais - alterna entre modo visualização e edição
class PersonalDataPage extends StatefulWidget {
  final bool requiredCompletion;

  /// Prefill vindo do AuthBloc (login/registro) — evita tela vazia se o
  /// fetch remoto falhar ou o perfil ainda não existir.
  final String? initialName;
  final String? initialEmail;
  final String? initialCpf;
  final String? initialPhone;

  const PersonalDataPage({
    super.key,
    this.requiredCompletion = false,
    this.initialName,
    this.initialEmail,
    this.initialCpf,
    this.initialPhone,
  });

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
    _applyKnownValues(
      name: widget.initialName,
      email: widget.initialEmail,
      cpf: widget.initialCpf,
      phone: widget.initialPhone,
    );
    _isEditing = widget.requiredCompletion;
    _loadProfile();
  }

  void _applyKnownValues({
    String? name,
    String? email,
    String? cpf,
    String? phone,
  }) {
    if (name != null && name.trim().isNotEmpty) {
      _nameController.text = name.trim();
    }
    if (email != null && email.trim().isNotEmpty) {
      _emailController.text = email.trim();
    }
    if (cpf != null && cpf.trim().isNotEmpty) {
      _cpfController.text = _formatCpf(cpf);
    }
    if (phone != null && phone.trim().isNotEmpty) {
      _phoneController.text = _formatPhone(phone);
    }
  }

  String _metaString(Map<String, dynamic>? meta, String key) {
    final value = meta?[key];
    if (value == null) return '';
    return value.toString().trim();
  }

  Future<void> _loadProfile() async {
    try {
      if (!SupabaseConfig.isInitialized) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final client = SupabaseConfig.client;
      final user = client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      // Auth / Google metadata — sempre preenche o que faltar.
      final meta = user.userMetadata;
      final authName = _metaString(meta, 'full_name').isNotEmpty
          ? _metaString(meta, 'full_name')
          : _metaString(meta, 'name');
      final authEmail = user.email ?? _metaString(meta, 'email');
      final authCpf = _metaString(meta, 'cpf');
      final authPhone = _metaString(meta, 'phone');
      _applyKnownValues(
        name: authName,
        email: authEmail,
        cpf: authCpf,
        phone: authPhone,
      );

      // Cria profiles se o trigger de signup tiver falhado.
      try {
        await client.rpc('ensure_own_profile');
      } catch (_) {}

      final profile = await client
          .from('profiles')
          .select('name, email')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        _applyKnownValues(
          name: profile['name'] as String?,
          email: profile['email'] as String?,
        );
      }

      try {
        final sensitive = await client.rpc(
          'get_user_sensitive_profile',
          params: {'p_user_id': user.id},
        );
        final rows = sensitive is List
            ? sensitive
            : (sensitive == null ? const [] : [sensitive]);
        if (rows.isNotEmpty) {
          final row = Map<String, dynamic>.from(rows.first as Map);
          _applyKnownValues(
            cpf: (row['cpf'] ?? '').toString(),
            phone: (row['phone'] ?? '').toString(),
          );
        }
      } catch (_) {
        // CPF/telefone podem estar vazios no primeiro login Google.
      }

      if (mounted) {
        setState(() {
          _loading = false;
          _isEditing = widget.requiredCompletion;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatCpf(String value) => CpfInputFormatter()
      .formatEditUpdate(
        const TextEditingValue(),
        TextEditingValue(text: value),
      )
      .text;

  String _formatPhone(String value) => PhoneInputFormatter()
      .formatEditUpdate(
        const TextEditingValue(),
        TextEditingValue(text: value),
      )
      .text;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  /// Voltar após Google/login incompleto: a stack foi limpa com
  /// [pushAndRemoveUntil], então [Navigator.pop] deixa tela preta.
  /// Encerra a sessão e reabre o login.
  Future<void> _handleBack() async {
    if (widget.requiredCompletion) {
      await sl<AuthSessionManager>().clearSession();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleSave() async {
    if (!Validators.isValidName(_nameController.text) ||
        !Validators.isValidCpf(_cpfController.text) ||
        !Validators.isValidPhone(_phoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confira nome, CPF e telefone.')),
      );
      return;
    }
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      try {
        await SupabaseConfig.client.rpc('ensure_own_profile');
      } catch (_) {}

      await SupabaseConfig.client.from('profiles').update({
        'name': _nameController.text.trim(),
      }).eq('id', user.id);
      await SupabaseConfig.client.rpc('update_user_sensitive_profile', params: {
        'p_user_id': user.id,
        'p_cpf': _cpfController.text,
        'p_phone': _phoneController.text,
      });
      if (!mounted) return;
      setState(() {
        _saving = false;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados salvos com sucesso!')),
      );
      if (widget.requiredCompletion && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível salvar os dados: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.requiredCompletion && Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _handleBack,
                          child: Container(
                            width: 39,
                            height: 39,
                            decoration: BoxDecoration(
                              color: const Color(0xFF01225B)
                                  .withValues(alpha: 0.2),
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
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_loading)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          if (widget.requiredCompletion && !_loading)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF4D6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Complete CPF e telefone para concluir seu cadastro.',
                              ),
                            ),
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
                          _buildFormCard(),
                          const SizedBox(height: 6),
                          if (_isEditing)
                            PrimaryButton(
                              text: _saving ? 'Salvando...' : 'Salvar',
                              onPressed: _handleSave,
                            )
                          else
                            SecondaryButton(
                              text: 'Editar',
                              onPressed: () =>
                                  setState(() => _isEditing = true),
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
          _buildField(
            'E-mail',
            _emailController,
            keyboardType: TextInputType.emailAddress,
            readOnly: true,
          ),
          const SizedBox(height: 6),
          _buildField(
            'Telefone',
            _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [PhoneInputFormatter()],
          ),
          const SizedBox(height: 6),
          _buildField(
            'CPF',
            _cpfController,
            keyboardType: TextInputType.number,
            inputFormatters: [CpfInputFormatter()],
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool? readOnly,
  }) {
    final isReadOnly = readOnly ?? !_isEditing;
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
            color:
                isReadOnly ? const Color(0xFFF3F4F6) : const Color(0xFFFCFCFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDDDFE5)),
          ),
          child: TextField(
            controller: controller,
            readOnly: isReadOnly,
            enableInteractiveSelection: true,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isReadOnly
                  ? AppTheme.primaryColor.withValues(alpha: 0.75)
                  : AppTheme.primaryColor,
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
