import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_form_card.dart';
import '../../widgets/admin_form_field.dart';
import '../../../domain/entities/coupon_entity.dart';
import '../../bloc/coupon/coupon_bloc.dart';
import '../../bloc/coupon/coupon_event.dart';
import '../../bloc/coupon/coupon_state.dart';

/// Formulario de criacao/edicao de cupom de desconto.
/// Passa entity nula para criar, ou entity existente para editar.
class AdminCouponFormPage extends StatefulWidget {
  final CouponEntity? entity;

  const AdminCouponFormPage({super.key, this.entity});

  @override
  State<AdminCouponFormPage> createState() => _AdminCouponFormPageState();
}

class _AdminCouponFormPageState extends State<AdminCouponFormPage> {
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _discountPercentageController;
  late final TextEditingController _expiryDateController;
  late final TextEditingController _usageLimitController;
  late final TextEditingController _usedCountController;
  late bool _isActive;
  DateTime? _selectedExpiryDate;

  bool get _isEditing => widget.entity != null;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.entity?.code ?? '');
    _descriptionController =
        TextEditingController(text: widget.entity?.description ?? '');
    _discountPercentageController = TextEditingController(
      text: widget.entity?.discountPercentage.toString() ?? '',
    );
    _selectedExpiryDate = widget.entity?.expiryDate;
    _expiryDateController = TextEditingController(
      text: _selectedExpiryDate != null
          ? _formatDate(_selectedExpiryDate!)
          : '',
    );
    _usageLimitController = TextEditingController(
      text: widget.entity?.usageLimit.toString() ?? '0',
    );
    _usedCountController = TextEditingController(
      text: widget.entity?.usedCount.toString() ?? '0',
    );
    _isActive = widget.entity?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountPercentageController.dispose();
    _expiryDateController.dispose();
    _usageLimitController.dispose();
    _usedCountController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedExpiryDate = picked;
        _expiryDateController.text = _formatDate(picked);
      });
    }
  }

  void _handleSave() {
    final entity = CouponEntity(
      id: widget.entity?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      code: _codeController.text.trim(),
      description: _descriptionController.text.trim(),
      discountPercentage:
          double.tryParse(_discountPercentageController.text.trim()) ?? 0.0,
      expiryDate: _selectedExpiryDate ?? DateTime.now(),
      usageLimit: int.tryParse(_usageLimitController.text.trim()) ?? 0,
      usedCount: int.tryParse(_usedCountController.text.trim()) ?? 0,
      isActive: _isActive,
    );

    if (_isEditing) {
      context.read<CouponBloc>().add(UpdateCouponRequested(entity));
    } else {
      context.read<CouponBloc>().add(CreateCouponRequested(entity));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CouponBloc, CouponState>(
      listener: (context, state) {
        if (state.status == CouponStatus.saved) {
          Navigator.of(context).pop();
        } else if (state.status == CouponStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Erro ao salvar cupom'),
            ),
          );
        }
      },
      child: AdminPageScaffold(
        title: _isEditing ? 'Editar Cupom' : 'Novo Cupom',
        floatingBottom: PrimaryButton(
          text: 'Salvar',
          onPressed: _handleSave,
        ),
        body: AdminFormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Codigo
              AdminFormField(
                label: 'Codigo',
                controller: _codeController,
              ),
              const SizedBox(height: 16),

              // Descricao
              AdminFormField(
                label: 'Descricao',
                controller: _descriptionController,
              ),
              const SizedBox(height: 16),

              // Percentual de desconto
              AdminFormField(
                label: 'Percentual de Desconto (%)',
                controller: _discountPercentageController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Data de expiracao
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data de Expiracao',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickExpiryDate,
                    child: AbsorbPointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCFCFC),
                          borderRadius: BorderRadius.circular(24),
                          border:
                              Border.all(color: const Color(0xFFDDDFE5)),
                        ),
                        child: TextField(
                          controller: _expiryDateController,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.primaryColor,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            suffixIcon: const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: AppTheme.primaryColor,
                            ),
                            hintText: 'DD/MM/AAAA',
                            hintStyle: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF6D7F95),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Limite de uso
              AdminFormField(
                label: 'Limite de Uso',
                controller: _usageLimitController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Quantidade de usos
              AdminFormField(
                label: 'Quantidade de Usos',
                controller: _usedCountController,
                keyboardType: TextInputType.number,
                readOnly: !_isEditing,
              ),
              const SizedBox(height: 16),

              // Ativo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ativo',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    activeTrackColor: AppTheme.primaryColor,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                  ),
                ],
              ),

              // Espacamento para o botao flutuante
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
