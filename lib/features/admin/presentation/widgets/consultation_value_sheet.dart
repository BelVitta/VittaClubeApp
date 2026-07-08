import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/services/discount_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../consultation/domain/usecases/record_consultation_usecase.dart';
import '../../../dependents/domain/repositories/qr_validation_repository.dart';

class ConsultationValueSheet extends StatefulWidget {
  final String userId;
  final String validatedBy;
  final QrValidationResult result;
  final RecordConsultationUseCase recordConsultationUseCase;

  const ConsultationValueSheet({
    super.key,
    required this.userId,
    required this.validatedBy,
    required this.result,
    required this.recordConsultationUseCase,
  });

  @override
  State<ConsultationValueSheet> createState() => _ConsultationValueSheetState();
}

class _ConsultationValueSheetState extends State<ConsultationValueSheet> {
  final TextEditingController _valueController = TextEditingController();
  bool _saving = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  double get _originalValue => _parseCurrency(_valueController.text);

  double get _discountPercentage => widget.result.discountPercentage ?? 0;

  DiscountService get _discountService => DiscountService(
        discountPercentage: _discountPercentage,
        isEligibleForDiscount: _discountPercentage > 0,
      );

  double get _discountAmount =>
      _discountService.calculateDiscountAmount(_originalValue);

  double get _finalValue =>
      _discountService.calculateDiscountedPrice(_originalValue);

  double _parseCurrency(String value) {
    final normalized = value.replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0;
  }

  Future<void> _confirm() async {
    if (_originalValue <= 0 || _saving) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await widget.recordConsultationUseCase(
      RecordConsultationParams(
        userId: widget.userId,
        validatedBy: widget.validatedBy,
        originalValue: _originalValue,
        discountPercentage: _discountPercentage,
      ),
    );

    if (!mounted) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'Falha ao confirmar valor da consulta.',
          name: 'ConsultationValueSheet',
          context: {
            'failureType': failure.runtimeType.toString(),
            'message': failure.message,
          },
        );
        setState(() {
          _saving = false;
          _error = 'Erro no servidor. Não foi possível registrar a consulta.';
        });
      },
      (_) async {
        setState(() {
          _saving = false;
          _success = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (mounted) Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _success ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      key: const ValueKey('form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFEBEEF2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Valor da consulta',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _valueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d,]')),
          ],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixText: 'R\$ ',
            hintText: '200,00',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildPreview(),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ],
        const SizedBox(height: 20),
        PrimaryButton(
          text: _saving ? 'Confirmando...' : 'Confirmar',
          onPressed: _saving || _originalValue <= 0 ? null : _confirm,
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDDFE5)),
      ),
      child: Text(
        'Valor original ${DiscountService.formatPrice(_originalValue)} | '
        'Desconto ${_discountPercentage.toStringAsFixed(0)}% | '
        'Você economiza ${DiscountService.formatPrice(_discountAmount)} | '
        'Final ${DiscountService.formatPrice(_finalValue)}',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          height: 1.5,
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 260),
          tween: Tween(begin: 0.6, end: 1),
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.gradientLight.withValues(alpha: 0.2),
            ),
            child: const Icon(
              Icons.check,
              size: 36,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Consulta registrada',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }
}
