import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/discount_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../dependents/domain/repositories/qr_validation_repository.dart';
import '../../../dependents/presentation/bloc/qr_validation_bloc.dart';
import '../../../dependents/presentation/bloc/qr_validation_event.dart';
import '../../../dependents/presentation/bloc/qr_validation_state.dart';
import '../../../dependents/presentation/widgets/qr_validation_result_card.dart';
import '../../domain/usecases/partner_validation/confirm_partner_validation_usecase.dart';

/// Validador no aparelho do parceiro: lê a carteirinha e aplica o % do acordo.
class ParceiroValidatePage extends StatefulWidget {
  const ParceiroValidatePage({super.key});

  @override
  State<ParceiroValidatePage> createState() => _ParceiroValidatePageState();
}

class _ParceiroValidatePageState extends State<ParceiroValidatePage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    final actorUserId = SupabaseConfig.client.auth.currentUser?.id;
    if (actorUserId == null) return;

    setState(() => _hasScanned = true);
    _controller.stop();
    _showSheet(code, actorUserId);
  }

  void _showSheet(String code, String actorUserId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) {
          final bloc = sl<QrValidationBloc>();
          bloc.add(
            ValidateMemberQrRequested(
              identifier: code,
              actorUserId: actorUserId,
            ),
          );
          return bloc;
        },
        child: _PartnerValidationSheet(
          onClose: () {
            Navigator.pop(context);
            setState(() => _hasScanned = false);
            _controller.start();
          },
        ),
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            validator: (v) {
              final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
              if (d.length != 8) return 'Informe os 8 dígitos';
              return null;
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
      ),
    );
    if (!mounted || code == null || code.isEmpty) return;
    setState(() => _hasScanned = true);
    await _controller.stop();
    if (!mounted) return;
    _showSheet(code, actorUserId);
  }

  @override
  Widget build(BuildContext context) {
    final scanArea = MediaQuery.of(context).size.width * 0.7;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          ColorFiltered(
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
                    width: scanArea,
                    height: scanArea,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                'Validar desconto',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 80,
            left: 40,
            right: 40,
            child: Column(
              children: [
                Text(
                  'Aponte a câmera para a carteirinha do membro.\nO desconto que vale aqui é o % do seu acordo.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _hasScanned ? null : _showManualCodeDialog,
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
}

class _PartnerValidationSheet extends StatefulWidget {
  final VoidCallback onClose;

  const _PartnerValidationSheet({required this.onClose});

  @override
  State<_PartnerValidationSheet> createState() =>
      _PartnerValidationSheetState();
}

class _PartnerValidationSheetState extends State<_PartnerValidationSheet> {
  final _valueController = TextEditingController();
  bool _saving = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  double get _original {
    final n = _valueController.text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(n.trim()) ?? 0;
  }

  Future<void> _confirm(QrValidationResult result) async {
    final validationId = result.validationId;
    if (validationId == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final response = await sl<ConfirmPartnerValidationUseCase>()(
      ConfirmPartnerValidationParams(
        validationId: validationId,
        originalValue: _original > 0 ? _original : null,
      ),
    );
    if (!mounted) return;
    response.fold(
      (failure) => setState(() {
        _saving = false;
        _error = failure.message;
      }),
      (_) => setState(() {
        _saving = false;
        _done = true;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: BlocBuilder<QrValidationBloc, QrValidationState>(
          builder: (context, state) {
            if (state.status == QrValidationStatus.loading ||
                state.status == QrValidationStatus.initial) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (state.status == QrValidationStatus.failure) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.errorMessage ?? 'Falha ao validar.'),
                  const SizedBox(height: 16),
                  PrimaryButton(text: 'Fechar', onPressed: widget.onClose),
                ],
              );
            }
            final result = state.result;
            if (result == null) {
              return PrimaryButton(text: 'Fechar', onPressed: widget.onClose);
            }
            if (_done) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle,
                      color: Color(0xFF4CAF50), size: 56),
                  const SizedBox(height: 12),
                  Text(
                    'Desconto confirmado',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aplique o percentual no seu caixa. O app só registra a autorização.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF6D7F95),
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(text: 'Pronto', onPressed: widget.onClose),
                ],
              );
            }

            final pct = result.discountPercentage ?? 0;
            final savings = DiscountService(
              discountPercentage: pct,
              isEligibleForDiscount: pct > 0,
            ).calculateDiscountAmount(_original);
            final finalValue = DiscountService(
              discountPercentage: pct,
              isEligibleForDiscount: pct > 0,
            ).calculateDiscountedPrice(_original);

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  QrValidationResultCard(result: result),
                  if (result.cpfMasked != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'CPF ${result.cpfMasked}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF6D7F95),
                      ),
                    ),
                  ],
                  if (result.isApproved) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Valor do pedido (opcional)',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _valueController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d,]')),
                      ],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixText: 'R\$ ',
                        hintText: '250,00',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (_original > 0) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Original ${DiscountService.formatPrice(_original)} · '
                        'Desconto ${pct.toStringAsFixed(0)}% · '
                        'Cliente economiza ${DiscountService.formatPrice(savings)} · '
                        'A pagar ${DiscountService.formatPrice(finalValue)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 16),
                    PrimaryButton(
                      text: _saving ? 'Confirmando...' : 'Confirmar desconto',
                      onPressed: _saving ? null : () => _confirm(result),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    PrimaryButton(text: 'Fechar', onPressed: widget.onClose),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
