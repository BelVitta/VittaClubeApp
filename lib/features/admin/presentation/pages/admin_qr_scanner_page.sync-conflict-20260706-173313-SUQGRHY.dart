import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../dependents/domain/repositories/qr_validation_repository.dart';
import '../../../dependents/presentation/bloc/qr_validation_bloc.dart';
import '../../../dependents/presentation/bloc/qr_validation_event.dart';
import '../../../dependents/presentation/bloc/qr_validation_state.dart';
import '../../../dependents/presentation/widgets/qr_validation_result_card.dart';
import '../widgets/consultation_value_sheet.dart';

/// Página de scanner QR para admin validar desconto de membros.
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
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _hasScanned = true);
    _controller.stop();

    final code = barcode.rawValue!;
    if (_isUuid(code)) {
      _showMemberSheet(code);
    } else {
      _showAppointmentSheet(code);
    }
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  String? get _actorUserId {
    if (!SupabaseConfig.isInitialized) return null;
    return SupabaseConfig.auth.currentUser?.id;
  }

  void _showMemberSheet(String code) {
    final actorUserId = _actorUserId;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<QrValidationBloc>(),
        child: _MemberValidationSheet(
          userId: code,
          actorUserId: actorUserId,
          onClose: _closeSheetAndResume,
        ),
      ),
    );
  }

  void _showAppointmentSheet(String qrToken) {
    final actorUserId = _actorUserId;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<QrValidationBloc>(),
        child: _AppointmentValidationSheet(
          qrToken: qrToken,
          actorUserId: actorUserId,
          onClose: _closeSheetAndResume,
        ),
      ),
    );
  }

  void _closeSheetAndResume() {
    Navigator.pop(context);
    setState(() => _hasScanned = false);
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final scanArea = MediaQuery.of(context).size.width * 0.7;

    return BlocProvider(
      create: (_) => sl<QrValidationBloc>(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Câmera
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),

            // Overlay escuro com recorte central
            _ScannerOverlay(scanAreaSize: scanArea),

            // Botão voltar
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

            // Título
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

            // Instrução
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 80,
              left: 40,
              right: 40,
              child: Center(
                child: Text(
                  'Aponte a câmera para o QR Code\nda carteirinha do membro',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlay escuro com viewfinder recortado no centro
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
                color: Colors.red, // Cor irrelevante, será recortada
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet com dados do membro escaneado
class _MemberValidationSheet extends StatefulWidget {
  final String userId;
  final String? actorUserId;
  final VoidCallback onClose;

  const _MemberValidationSheet({
    required this.userId,
    required this.actorUserId,
    required this.onClose,
  });

  @override
  State<_MemberValidationSheet> createState() => _MemberValidationSheetState();
}

class _MemberValidationSheetState extends State<_MemberValidationSheet> {
  @override
  void initState() {
    super.initState();
    if (widget.actorUserId != null) {
      context.read<QrValidationBloc>().add(
            ValidateMemberQrRequested(
              userId: widget.userId,
              actorUserId: widget.actorUserId!,
            ),
          );
    }
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
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFEBEEF2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Ícone de sucesso
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.gradientLight.withValues(alpha: 0.2),
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              size: 32,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Validação de membro',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),

          if (widget.actorUserId == null)
            _SheetMessage(
              title: 'Sessão indisponível',
              message: 'Faça login como administrador para validar o QR.',
            )
          else
            BlocBuilder<QrValidationBloc, QrValidationState>(
              builder: (context, state) {
                if (state.status == QrValidationStatus.loading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  );
                }
                if (state.status == QrValidationStatus.failure) {
                  return _SheetMessage(
                    title: 'QR inválido',
                    message: state.errorMessage ?? 'Não foi possível validar.',
                  );
                }

                final result = state.result;
                if (result == null) {
                  return _SheetMessage(
                    title: 'Aguardando validação',
                    message: 'Validando dados do membro...',
                  );
                }
                if (!result.isApproved) {
                  return QrValidationResultCard(result: result);
                }

                return _ApprovedMemberContent(
                  userId: widget.userId,
                  actorUserId: widget.actorUserId!,
                  result: result,
                );
              },
            ),
          const SizedBox(height: 12),

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
      ),
    );
  }
}

class _AppointmentValidationSheet extends StatefulWidget {
  final String qrToken;
  final String? actorUserId;
  final VoidCallback onClose;

  const _AppointmentValidationSheet({
    required this.qrToken,
    required this.actorUserId,
    required this.onClose,
  });

  @override
  State<_AppointmentValidationSheet> createState() =>
      _AppointmentValidationSheetState();
}

class _AppointmentValidationSheetState
    extends State<_AppointmentValidationSheet> {
  @override
  void initState() {
    super.initState();
    if (widget.actorUserId != null) {
      context.read<QrValidationBloc>().add(
            ValidateQrRequested(
              qrToken: widget.qrToken,
              actorUserId: widget.actorUserId!,
            ),
          );
    }
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
          if (widget.actorUserId == null)
            _SheetMessage(
              title: 'Sessão indisponível',
              message: 'Faça login como administrador para validar o QR.',
            )
          else
            BlocBuilder<QrValidationBloc, QrValidationState>(
              builder: (context, state) {
                if (state.status == QrValidationStatus.loading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  );
                }
                if (state.status == QrValidationStatus.failure) {
                  return _SheetMessage(
                    title: 'QR inválido',
                    message: state.errorMessage ?? 'Não foi possível validar.',
                  );
                }
                final result = state.result;
                if (result == null) {
                  return _SheetMessage(
                    title: 'Aguardando validação',
                    message: 'Validando agendamento...',
                  );
                }
                return QrValidationResultCard(result: result);
              },
            ),
          const SizedBox(height: 12),
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
      ),
    );
  }
}

class _ApprovedMemberContent extends StatelessWidget {
  final String userId;
  final String actorUserId;
  final QrValidationResult result;

  const _ApprovedMemberContent({
    required this.userId,
    required this.actorUserId,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final discountPercentage = result.discountPercentage ?? 0;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFCFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDDFE5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: 'Nome', value: result.memberName ?? 'Membro'),
              _InfoRow(label: 'Nível', value: result.planLevel ?? '-'),
              _InfoRow(
                label: 'Desconto',
                value: '${discountPercentage.toStringAsFixed(0)}%',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          text: 'Informar valor da consulta',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => ConsultationValueSheet(
                userId: userId,
                validatedBy: actorUserId,
                result: result,
                recordConsultationUseCase: sl(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF6D7F95),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetMessage extends StatelessWidget {
  final String title;
  final String message;

  const _SheetMessage({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF6D7F95),
            ),
          ),
        ],
      ),
    );
  }
}
