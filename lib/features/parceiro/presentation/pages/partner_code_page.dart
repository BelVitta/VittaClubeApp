import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../admin/presentation/widgets/admin_page_scaffold.dart';
import '../../domain/entities/partner_entity.dart';
import '../../domain/usecases/partner/regenerate_code_usecase.dart';

class PartnerCodePage extends StatefulWidget {
  final PartnerEntity partner;

  const PartnerCodePage({super.key, required this.partner});

  @override
  State<PartnerCodePage> createState() => _PartnerCodePageState();
}

class _PartnerCodePageState extends State<PartnerCodePage> {
  late String _code = widget.partner.code;
  bool _regenerating = false;

  Future<void> _handleRegenerate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Regenerar código'),
        content: const Text(
          'Tem certeza? O código atual será invalidado e um novo será gerado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Regenerar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _regenerating = true);
    final result = await sl<RegenerateCodeUseCase>()(widget.partner.id);
    if (!mounted) return;
    setState(() => _regenerating = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: AppTheme.errorColor,
        ),
      ),
      (updated) {
        setState(() => _code = updated.code);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Código regenerado com sucesso!',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      title: 'Meu código',
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
                  'Código do parceiro',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6D7F95),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _code,
                  style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Informe este código para os clientes\nno momento da validação do desconto.',
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
            text: _regenerating ? 'Regenerando...' : 'Regenerar código',
            onPressed: _regenerating ? null : _handleRegenerate,
          ),
        ],
      ),
    );
  }
}
