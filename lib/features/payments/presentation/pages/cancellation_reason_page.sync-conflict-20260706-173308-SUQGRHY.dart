import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../subscription/domain/usecases/cancel_subscription_usecase.dart';

/// Página de Cancelamento - Etapa 2: Motivo do cancelamento
class CancellationReasonPage extends StatefulWidget {
  const CancellationReasonPage({super.key});

  @override
  State<CancellationReasonPage> createState() => _CancellationReasonPageState();
}

class _CancellationReasonPageState extends State<CancellationReasonPage> {
  String? _selectedReason;
  final _commentsController = TextEditingController();
  late final Future<List<String>> _reasonsFuture;

  @override
  void initState() {
    super.initState();
    _reasonsFuture = _loadReasons();
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<List<String>> _loadReasons() async {
    final rows = await SupabaseConfig.client
        .from('cancellation_reasons')
        .select('text')
        .order('text');
    final reasons = (rows as List<dynamic>)
        .map((row) => (row as Map<String, dynamic>)['text'] as String? ?? '')
        .where((text) => text.isNotEmpty)
        .toList();
    return reasons.isEmpty ? ['Outro motivo'] : reasons;
  }

  Future<void> _handleContinue() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || _selectedReason == null) return;

    final subscription = await SupabaseConfig.client
        .from('subscriptions')
        .select('id')
        .eq('user_id', userId)
        .eq('is_current', true)
        .maybeSingle();
    final subscriptionId = subscription?['id'] as String?;
    if (subscriptionId == null) return;

    final reason = [
      _selectedReason!,
      if (_commentsController.text.trim().isNotEmpty)
        _commentsController.text.trim(),
    ].join(' - ');

    final result = await sl<CancelSubscriptionUseCase>()(
      subscriptionId: subscriptionId,
      reason: reason,
    );
    if (!mounted) return;
    final failed = result.fold((failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return true;
    }, (_) => false);
    if (failed) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plano cancelado com sucesso.')),
    );
    Navigator.of(context)
      ..pop()
      ..pop();
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

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'Cancelamento',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                            letterSpacing: 0.12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Antes de cancelar, veja o que você perderá',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6D7F95),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Reason card
                        FutureBuilder<List<String>>(
                          future: _reasonsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return _buildReasonCard(
                              snapshot.data ?? const ['Outro motivo'],
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // Comments card
                        _buildCommentsCard(),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Bottom buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    children: [
                      PrimaryButton(
                        text: 'Continuar',
                        onPressed:
                            _selectedReason != null ? _handleContinue : null,
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppTheme.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Voltar',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonCard(List<String> reasons) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEEF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Por que você está cancelando?',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Seu feedback é muito importante para\nmelhorarmos nossos serviços.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6D7F95),
            ),
          ),
          const SizedBox(height: 12),
          ...reasons.map((reason) => _buildReasonOption(reason)),
        ],
      ),
    );
  }

  Widget _buildReasonOption(String reason) {
    final isSelected = _selectedReason == reason;
    return GestureDetector(
      onTap: () => setState(() => _selectedReason = reason),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : const Color(0xFF6D7F95),
                  width: isSelected ? 5 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              reason,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEEF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comentários Adicionais (opcional)',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFCFCFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDDFE5)),
            ),
            child: TextField(
              controller: _commentsController,
              maxLines: 4,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppTheme.primaryColor,
              ),
              decoration: InputDecoration(
                hintText: 'Lorem ipsum',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF6D7F95).withValues(alpha: 0.5),
                ),
                contentPadding: const EdgeInsets.all(12),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
