import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_form_card.dart';
import '../../widgets/admin_form_field.dart';
import '../../widgets/admin_dropdown_field.dart';
import '../../bloc/professional/professional_bloc.dart';
import '../../bloc/professional/professional_event.dart';
import '../../bloc/professional/professional_state.dart';
import '../../../domain/entities/professional_entity.dart';
import '../../../domain/entities/specialty_entity.dart';
import '../../../data/datasources/admin_datasource.dart';

class AdminProfessionalFormPage extends StatefulWidget {
  final ProfessionalEntity? entity;

  const AdminProfessionalFormPage({super.key, this.entity});

  bool get isEditing => entity != null;

  @override
  State<AdminProfessionalFormPage> createState() => _AdminProfessionalFormPageState();
}

class _AdminProfessionalFormPageState extends State<AdminProfessionalFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _availableDaysController;
  late final TextEditingController _avatarUrlController;
  late final TextEditingController _whatsappNumberController;
  late bool _isActive;

  String? _selectedSpecialtyId;
  String _selectedSpecialtyName = '';
  List<SpecialtyEntity> _specialties = [];
  bool _loadingSpecialties = true;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.entity?.name ?? '');
    _availableDaysController =
        TextEditingController(text: widget.entity?.availableDays ?? '');
    _avatarUrlController =
        TextEditingController(text: widget.entity?.avatarUrl ?? '');
    _whatsappNumberController =
        TextEditingController(text: widget.entity?.whatsappNumber ?? '');
    _isActive = widget.entity?.isActive ?? true;
    _selectedSpecialtyId = widget.entity?.specialtyId;
    _selectedSpecialtyName = widget.entity?.specialtyName ?? '';
    _loadSpecialties();
  }

  Future<void> _loadSpecialties() async {
    try {
      final datasource = sl<AdminDataSource>();
      final specialties = await datasource.getSpecialties();
      setState(() {
        _specialties = specialties;
        _loadingSpecialties = false;
      });
    } catch (_) {
      setState(() => _loadingSpecialties = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _availableDaysController.dispose();
    _avatarUrlController.dispose();
    _whatsappNumberController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final entity = ProfessionalEntity(
      id: widget.entity?.id ?? '',
      name: _nameController.text.trim(),
      specialtyId: _selectedSpecialtyId ?? '',
      specialtyName: _selectedSpecialtyName,
      availableDays: _availableDaysController.text.trim(),
      avatarUrl: _avatarUrlController.text.trim(),
      avatarBgColor: widget.entity?.avatarBgColor ?? 0xFFFFCD66,
      whatsappNumber: _whatsappNumberController.text.trim(),
      isActive: _isActive,
    );

    if (widget.isEditing) {
      context.read<ProfessionalBloc>().add(UpdateProfessionalRequested(entity));
    } else {
      context.read<ProfessionalBloc>().add(CreateProfessionalRequested(entity));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfessionalBloc, ProfessionalState>(
      listener: (context, state) {
        if (state.status == ProfessionalStatus.saved) {
          Navigator.pop(context);
        } else if (state.status == ProfessionalStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.errorMessage ?? 'Erro ao salvar')),
          );
        }
      },
      child: AdminPageScaffold(
        title: widget.isEditing ? 'Editar Profissional' : 'Novo Profissional',
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              AdminFormCard(
                child: Column(
                  children: [
                    AdminFormField(
                      label: 'Nome',
                      controller: _nameController,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Nome obrigatorio' : null,
                    ),
                    const SizedBox(height: 16),
                    if (_loadingSpecialties)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      AdminDropdownField(
                        label: 'Especialidade',
                        value: _selectedSpecialtyId,
                        hint: 'Selecione a especialidade',
                        items: _specialties
                            .map((s) => DropdownItem(
                                  id: s.id,
                                  displayName: s.name,
                                ))
                            .toList(),
                        onChanged: (item) {
                          setState(() {
                            _selectedSpecialtyId = item?.id;
                            _selectedSpecialtyName = item?.displayName ?? '';
                          });
                        },
                      ),
                    const SizedBox(height: 16),
                    AdminFormField(
                      label: 'Dias Disponiveis',
                      controller: _availableDaysController,
                    ),
                    const SizedBox(height: 16),
                    AdminFormField(
                      label: 'URL do Avatar',
                      controller: _avatarUrlController,
                    ),
                    const SizedBox(height: 16),
                    AdminFormField(
                      label: 'WhatsApp',
                      controller: _whatsappNumberController,
                      keyboardType: TextInputType.phone,
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
              BlocBuilder<ProfessionalBloc, ProfessionalState>(
                builder: (context, state) {
                  return PrimaryButton(
                    text: state.status == ProfessionalStatus.saving
                        ? 'Salvando...'
                        : 'Salvar',
                    onPressed: state.status == ProfessionalStatus.saving
                        ? null
                        : _handleSave,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
