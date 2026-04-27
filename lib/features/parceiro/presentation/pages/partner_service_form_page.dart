import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../admin/presentation/widgets/admin_page_scaffold.dart';
import '../../../admin/presentation/widgets/admin_form_card.dart';
import '../../../admin/presentation/widgets/admin_form_field.dart';
import '../bloc/partner_service/partner_service_bloc.dart';
import '../bloc/partner_service/partner_service_event.dart';
import '../bloc/partner_service/partner_service_state.dart';
import '../../domain/entities/partner_service_entity.dart';

class PartnerServiceFormPage extends StatefulWidget {
  final String partnerId;
  final PartnerServiceEntity? entity;

  const PartnerServiceFormPage({
    super.key,
    required this.partnerId,
    this.entity,
  });

  bool get isEditing => entity != null;

  @override
  State<PartnerServiceFormPage> createState() => _PartnerServiceFormPageState();
}

class _PartnerServiceFormPageState extends State<PartnerServiceFormPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _originalPriceController;
  late final TextEditingController _discountedPriceController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entity?.name ?? '');
    _descriptionController = TextEditingController(text: widget.entity?.description ?? '');
    _originalPriceController = TextEditingController(
      text: widget.entity?.originalPrice.toStringAsFixed(2) ?? '',
    );
    _discountedPriceController = TextEditingController(
      text: widget.entity?.discountedPrice.toStringAsFixed(2) ?? '',
    );
    _isActive = widget.entity?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final entity = PartnerServiceEntity(
      id: widget.entity?.id ?? '',
      partnerId: widget.partnerId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      originalPrice: double.tryParse(_originalPriceController.text) ?? 0,
      discountedPrice: double.tryParse(_discountedPriceController.text) ?? 0,
      isActive: _isActive,
    );

    if (widget.isEditing) {
      context.read<PartnerServiceBloc>().add(UpdatePartnerServiceRequested(entity));
    } else {
      context.read<PartnerServiceBloc>().add(CreatePartnerServiceRequested(entity));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PartnerServiceBloc, PartnerServiceState>(
      listener: (context, state) {
        if (state.status == PartnerServiceStatus.saved) {
          Navigator.pop(context);
        } else if (state.status == PartnerServiceStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Erro ao salvar')),
          );
        }
      },
      child: AdminPageScaffold(
        title: widget.isEditing ? 'Editar Servico' : 'Novo Servico',
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
                    label: 'Descricao',
                    controller: _descriptionController,
                  ),
                  const SizedBox(height: 16),
                  AdminFormField(
                    label: 'Preco Original (R\$)',
                    controller: _originalPriceController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  AdminFormField(
                    label: 'Preco com Desconto (R\$)',
                    controller: _discountedPriceController,
                    keyboardType: TextInputType.number,
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
            BlocBuilder<PartnerServiceBloc, PartnerServiceState>(
              builder: (context, state) {
                return PrimaryButton(
                  text: state.status == PartnerServiceStatus.saving
                      ? 'Salvando...'
                      : 'Salvar',
                  onPressed: state.status == PartnerServiceStatus.saving
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
