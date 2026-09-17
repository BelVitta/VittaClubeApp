import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';

/// Bottom sheet com QR Code da carteirinha.
///
/// - [qrPayload]: conteúdo do QR (UUID do membro — validação por câmera).
/// - [memberCodeDisplay] / [memberCodeRaw]: código curto para a recepção digitar.
class QrCodeSheet extends StatelessWidget {
  final String qrPayload;
  final String memberCodeDisplay;
  final String? memberCodeRaw;

  const QrCodeSheet({
    super.key,
    required this.qrPayload,
    required this.memberCodeDisplay,
    this.memberCodeRaw,
  });

  static Future<void> show(
    BuildContext context, {
    required String qrPayload,
    required String memberCodeDisplay,
    String? memberCodeRaw,
    @Deprecated('Use qrPayload') String? memberCode,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QrCodeSheet(
        qrPayload: qrPayload.isNotEmpty ? qrPayload : (memberCode ?? ''),
        memberCodeDisplay: memberCodeDisplay,
        memberCodeRaw: memberCodeRaw,
      ),
    );
  }

  String get _copyValue {
    final raw = (memberCodeRaw ?? '').replaceAll(RegExp(r'\D'), '');
    if (raw.length == 8) return raw;
    return memberCodeDisplay == '—' ? qrPayload : memberCodeDisplay;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFEBEEF2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Mostre no caixa',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'O atendente lê este QR no aparelho dele. Se a câmera falhar, informe o código.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEBEEF2)),
            ),
            child: Center(
              child: QrImageView(
                data: qrPayload,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.circle,
                  color: AppTheme.primaryColor,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Código do membro',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6D7F95),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _copyValue));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Código copiado!')),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFCFCFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFDDDFE5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      memberCodeDisplay,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.copy,
                    size: 18,
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'Pronto',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
