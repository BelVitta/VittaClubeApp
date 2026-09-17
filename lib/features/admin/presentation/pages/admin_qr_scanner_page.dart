import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../consultation/domain/usecases/record_consultation_usecase.dart';
import '../../../dependents/domain/repositories/qr_validation_repository.dart';
import '../../../dependents/presentation/bloc/qr_validation_bloc.dart';
import '../../../dependents/presentation/bloc/qr_validation_event.dart';
import '../../../dependents/presentation/bloc/qr_validation_state.dart';
import '../../../dependents/presentation/widgets/qr_validation_result_card.dart';
import '../widgets/consultation_value_sheet.dart';

/// Página de scanner QR para admin validar desconto (titular ou dependente).
///
/// Formato do código escaneado decide qual RPC chamar:
/// - Token de dependente (`QrTokenService`) tem formato `payload.assinatura`
///   (contém um "."), validado via `validate_dependent_qr`.
/// - QR da carteirinha do titular é só o UUID do `profiles.id`, validado via
///   `validate_member_qr`.
class AdminQrScannerPage extends StatefulWidget {
  const AdminQrScannerPage({super.key});

  @override
  State<AdminQrScannerPage> createState() => _AdminQrScannerPageState();
}

class _AdminQrScannerPageState extends State<AdminQrScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final barcode = capture.barcodes.firstOrNull;
    final code = barcode?.rawValue;
    if (code == null || code.isEmpty) return;

    final actorUserId = SupabaseConfig.client.auth.currentUser?.id;
    if (actorUserId == null) return;

    setState(() => _hasScanned = true);
    _controller.stop();
    _showValidationSheet(code, actorUserId);
  }

  void _showValidationSheet(String code, String actorUserId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) {
          final bloc = sl<QrValidationBloc>();
          if (code.contains('.') && !code.startsWith('vc:dep:')) {
            bloc.add(
              ValidateQrRequested(qrToken: code, actorUserId: actorUserId),
            );
          } else {
            bloc.add(
              ValidateMemberQrRequested(
                identifier: code,
                actorUserId: actorUserId,
              ),
            );
          }
          return bloc;
        },
        child: _ValidationSheet(
          actorUserId: actorUserId,
          onClose: () {
            Navigator.pop(context);
            setState(() => _hasScanned = false);
            _controller.start();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanArea = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          _ScannerOverlay(scanAreaSize: scanArea),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 22,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Scanner QR',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 100,
            left: 40,
            right: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Aponte a câmera para o QR Code\nda carteirinha ou do agendamento',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _hasScanned ? null : () => _showManualCodeDialog(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  icon: const Icon(Icons.keyboard_outlined, size: 20),
                  label: Text(
                    'Digitar código do membro',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showManualCodeDialog() async {
    final actorUserId = SupabaseConfig.client.auth.currentUser?.id;
    if (actorUserId == null) return;

    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final code = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Código do membro',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 8,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '8 dígitos da carteirinha',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 4,
              ),
              validator: (v) {
                final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if (d.length != 8) return 'Informe os 8 dígitos';
                return null;
              },
              onFieldSubmitted: (_) {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx, controller.text.trim());
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx, controller.text.trim());
                }
              },
              child: Text(
                'Validar',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || code == null || code.isEmpty) return;

    setState(() => _hasScanned = true);
    await _controller.stop();
    if (!mounted) return;
    _showValidationSheet(code, actorUserId);
  }
}

class _ScannerOverlay extends StatelessWidget {
  final double scanAreaSize;

  const _ScannerOverlay({required this.scanAreaSize});

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withValues(alpha: 0.5),
        BlendMode.srcOut,
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          Center(
            child: Container(
              width: scanAreaSize,
              height: scanAreaSize,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet com resultado da validação + gate de identidade da recepção.
///
/// Fluxo aprovado:
/// 1) Card com nome / patente / % / usos
/// 2) Recepção confirma que a pessoa no balcão confere
/// 3) Só então abre o registro do valor da consulta
class _ValidationSheet extends StatefulWidget {
  final String actorUserId;
  final VoidCallback onClose;

  const _ValidationSheet({required this.actorUserId, required this.onClose});

  @override
  State<_ValidationSheet> createState() => _ValidationSheetState();
}

class _ValidationSheetState extends State<_ValidationSheet> {
  bool _identityRejected = false;

  void _openValueSheet(BuildContext context, QrValidationResult result) {
    final holderUserId = result.holderUserId;
    if (holderUserId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ConsultationValueSheet(
        userId: holderUserId,
        validatedBy: widget.actorUserId,
        result: result,
        recordConsultationUseCase: sl<RecordConsultationUseCase>(),
      ),
    ).then((_) => widget.onClose());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: BlocBuilder<QrValidationBloc, QrValidationState>(
        builder: (context, state) {
          final result = state.result;
          final canRegister = result != null &&
              result.isApproved &&
              result.holderUserId != null;

          return Column(
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
              if (state.status == QrValidationStatus.loading ||
                  state.status == QrValidationStatus.initial)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                )
              else if (result != null) ...[
                QrValidationResultCard(result: result),
                if (canRegister) ...[
                  const SizedBox(height: 16),
                  _IdentityCheckPanel(
                    identityRejected: _identityRejected,
                    memberName: result.memberName,
                  ),
                  const SizedBox(height: 16),
                  if (_identityRejected)
                    OutlinedButton(
                      onPressed: () =>
                          setState(() => _identityRejected = false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        foregroundColor: AppTheme.primaryColor,
                      ),
                      child: Text(
                        'Revisar de novo',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else ...[
                    PrimaryButton(
                      text: 'Identidade confere — continuar',
                      onPressed: () => _openValueSheet(context, result),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => setState(() => _identityRejected = true),
                      child: Text(
                        'Não confere / outra pessoa',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                ],
              ],
              GestureDetector(
                onTap: widget.onClose,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Escanear novamente',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Painel de conferência humana: recepção bate o olho nos dados antes
/// de liberar o registro do valor.
class _IdentityCheckPanel extends StatelessWidget {
  final bool identityRejected;
  final String? memberName;

  const _IdentityCheckPanel({
    required this.identityRejected,
    required this.memberName,
  });

  @override
  Widget build(BuildContext context) {
    final name = (memberName?.trim().isNotEmpty ?? false)
        ? memberName!.trim()
        : 'o beneficiário do QR';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: identityRejected
            ? AppTheme.errorColor.withValues(alpha: 0.06)
            : const Color(0xFFF6F8FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: identityRejected
              ? AppTheme.errorColor.withValues(alpha: 0.35)
              : AppTheme.primaryColor.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            identityRejected
                ? 'Identidade não confere'
                : 'Conferência da recepção',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: identityRejected
                  ? AppTheme.errorColor
                  : AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            identityRejected
                ? 'Não registre o valor. Peça o QR correto ou escaneie novamente.'
                : 'Confira se a pessoa no balcão é $name (documento ou apresentação).',
            style: AppTheme.bodyMedium.copyWith(
              color: identityRejected
                  ? AppTheme.errorColor
                  : AppTheme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
