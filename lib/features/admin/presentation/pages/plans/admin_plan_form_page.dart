import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_form_card.dart';
import '../../widgets/admin_form_field.dart';
import '../../bloc/plan_admin/plan_admin_bloc.dart';
import '../../bloc/plan_admin/plan_admin_event.dart';
import '../../bloc/plan_admin/plan_admin_state.dart';
import '../../../domain/entities/plan_admin_entity.dart';

class AdminPlanFormPage extends StatefulWidget {
  final PlanAdminEntity? entity;

  const AdminPlanFormPage({super.key, this.entity});

  bool get isEditing => entity != null;

  @override
  State<AdminPlanFormPage> createState() => _AdminPlanFormPageState();
}

class _AdminPlanFormPageState extends State<AdminPlanFormPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _subscriptionTypeController;
  late final TextEditingController _priceController;
  late final TextEditingController _discountLabelController;
  late final List<TextEditingController> _benefitControllers;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.entity?.name ?? '');
    _subscriptionTypeController =
        TextEditingController(text: widget.entity?.subscriptionType ?? '');
    _priceController = TextEditingController(
      text: widget.entity != null
          ? widget.entity!.price.toStringAsFixed(2)
          : '',
    );
    _discountLabelController =
        TextEditingController(text: widget.entity?.discountLabel ?? '');
    _benefitControllers = (widget.entity?.benefits ?? [])
        .map((b) => TextEditingController(text: b))
        .toList();
    _isActive = widget.entity?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subscriptionTypeController.dispose();
    _priceController.dispose();
    _discountLabelController.dispose();
    for (final controller in _benefitControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addBenefit() {
    setState(() {
      _benefitControllers.add(TextEditingController());
    });
  }

  void _removeBenefit(int index) {
    setState(() {
      _benefitControllers[index].dispose();
      _benefitControllers.removeAt(index);
    });
  }

  void _handleSave() {
    final benefits = _benefitControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final entity = PlanAdminEntity(
      id: widget.entity?.id ?? '',
      name: _nameController.text.trim(),
      subscriptionType: _subscriptionTypeController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0.0,
      discountLabel: _discountLabelController.text.trim().isEmpty
          ? null
          : _discountLabelController.text.trim(),
      benefits: benefits,
      isActive: _isActive,
    );

    if (widget.isEditing) {
      context.read<PlanAdminBloc>().add(UpdatePlanRequested(entity));
    } else {
      context.read<PlanAdminBloc>().add(CreatePlanRequested(entity));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlanAdminBloc, PlanAdminState>(
      listener: (context, state) {
        if (state.status == PlanAdminStatus.saved) {
          Navigator.pop(context);
        } else if (state.status == PlanAdminStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.errorMessage ?? 'Erro ao salvar')),
          );
        }
      },
      child: AdminPageScaffold(
        title: widget.isEditing ? 'Editar Plano' : 'Novo Plano',
        body: Column(
          children: [
            AdminFormCard(
              child: Column(
                children: [
                  AdminFormField(
                    label: 'Nome',
                    controller: _nameController,
                  ),
                  const SizedBox(height: 16),
                  AdminFormField(
                    label: 'Tipo de Assinatura',
                    controller: _subscriptionTypeController,
                  ),
                  const SizedBox(height: 16),
                  AdminFormField(
                    label: 'Preco',
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  AdminFormField(
                    label: 'Label de Desconto',
                    controller: _discountLabelController,
                  ),
                  const SizedBox(height: 16),
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Beneficios
            AdminFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Beneficios',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._benefitControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: AdminFormField(
                              label: 'Beneficio ${index + 1}',
                              controller: controller,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _removeBenefit(index),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFF5963)
                                    .withValues(alpha: 0.1),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Color(0xFFFF5963),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _addBenefit,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Adicionar Beneficio',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
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
            const SizedBox(height: 16),
            BlocBuilder<PlanAdminBloc, PlanAdminState>(
              builder: (context, state) {
                return PrimaryButton(
                  text: state.status == PlanAdminStatus.saving
                      ? 'Salvando...'
                      : 'Salvar',
                  onPressed: state.status == PlanAdminStatus.saving
                      ? null
                      : _handleSave,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
