import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../admin/presentation/widgets/admin_page_scaffold.dart';
import '../../domain/usecases/partner/regenerate_code_usecase.dart';

class PartnerCodePage extends StatefulWidget {
  final String partnerId;

  const PartnerCodePage({super.key, required this.partnerId});

  @override
  State<PartnerCodePage> createState() => _PartnerCodePageState();
}

class _PartnerCodePageState extends State<PartnerCodePage> {
  late Future<String> _codeFuture;

  @override
  void initState() {
    super.initState();
    _codeFuture = _loadCode();
  }

  Future<String> _loadCode() async {
    final row = await SupabaseConfig.client
        .from('partners')
        .select('code')
        .eq('id', widget.partnerId)
        .single();
    return row['code'] as String? ?? '';
  }

  void _handleRegenerate() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Regenerar Codigo'),
        content: const Text(
          'Tem certeza? O codigo atual sera invalidado e um novo sera gerado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result =
                  await sl<RegenerateCodeUseCase>()(widget.partnerId);
              if (!context.mounted) return;
              result.fold(
                (failure) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(failure.message),
                    backgroundColor: AppTheme.errorColor,
                  ),
                ),
                (partner) {
                  setState(() {
                    _codeFuture = Future.value(partner.code);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Codigo regenerado com sucesso!',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                      ),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                },
              );
            },
            child: const Text(
              'Regenerar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      title: 'Meu Codigo',
      allowedRoles: const ['parceiro'],
      body: Column(
        children: [
          const SizedBox(height: 32),
          // Code display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Codigo do Parceiro',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6D7F95),
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<String>(
                  future: _codeFuture,
                  builder: (context, snapshot) {
                    final code =
                        snapshot.connectionState == ConnectionState.done
                            ? snapshot.data ?? ''
                            : '...';
                    return Text(
                      code,
                      style: GoogleFonts.outfit(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                        letterSpacing: 4,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Informe este codigo para os clientes\nno momento da validacao do desconto.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6D7F95),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'Regenerar Codigo',
            onPressed: _handleRegenerate,
          ),
        ],
      ),
    );
  }
}
