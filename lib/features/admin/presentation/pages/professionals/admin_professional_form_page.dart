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
  State<AdminProfessionalFormPage> createState() =>
      _AdminProfessionalFormPageState();
}

class _AdminProfessionalFormPageState extends State<AdminProfessionalFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _availabilityNoteController;
  late final TextEditingController _avatarUrlController;
  late final TextEditingController _whatsappNumberController;
  late bool _isActive;

  static const _weekdayOptions = [
    ('seg', 'Seg'),
    ('ter', 'Ter'),
    ('qua', 'Qua'),
    ('qui', 'Qui'),
    ('sex', 'Sex'),
    ('sab', 'Sáb'),
    ('dom', 'Dom'),
  ];

  final Set<String> _selectedDays = {};
  String? _selectedSpecialtyId;
  String _selectedSpecialtyName = '';
  List<SpecialtyEntity> _specialties = [];
  bool _loadingSpecialties = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entity?.name ?? '');
    _availabilityNoteController =
        TextEditingController(text: widget.entity?.availabilityNote ?? '');
    _avatarUrlController =
        TextEditingController(text: widget.entity?.avatarUrl ?? '');
    _whatsappNumberController =
        TextEditingController(text: widget.entity?.whatsappNumber ?? '');
    _isActive = widget.entity?.isActive ?? true;
    _selectedSpecialtyId = widget.entity?.specialtyId;
    _selectedSpecialtyName = widget.entity?.specialtyName ?? '';
    final knownCodes = _weekdayOptions.map((d) => d.$1).toSet();
    _selectedDays.addAll(
      (widget.entity?.availableDays ?? '')
          .split(',')
          .map((d) => d.trim().toLowerCase())
          .where(knownCodes.contains),
    );
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
    _availabilityNoteController.dispose();
    _avatarUrlController.dispose();
    _whatsappNumberController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final orderedDays = _weekdayOptions
        .map((d) => d.$1)
        .where(_selectedDays.contains)
        .join(', ');
    final note = _availabilityNoteController.text.trim();

    final entity = ProfessionalEntity(
      id: widget.entity?.id ?? '',
      name: _nameController.text.trim(),
      specialtyId: _selectedSpecialtyId ?? '',
      specialtyName: _selectedSpecialtyName,
      availableDays: orderedDays,
      availabilityNote: note.isEmpty ? null : note,
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
            SnackBar(content: Text(state.errorMessage ?? 'Erro ao salvar')),
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
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nome obrigatório'
                          : null,
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
                    Text(
                      'Dias de Atendimento',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _weekdayOptions.map((day) {
                        final code = day.$1;
                        final label = day.$2;
                        final isSelected = _selectedDays.contains(code);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedDays.remove(code);
                              } else {
                                _selectedDays.add(code);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : const Color(0xFFF5F6FA),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : const Color(0xFFE0E4EC),
                              ),
                            ),
                            child: Text(
                              label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF6D7F95),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    AdminFormField(
                      label: 'Observação de Disponibilidade (opcional)',
                      controller: _availabilityNoteController,
                      maxLines: 2,
                      maxLength: 80,
                      hintText: 'Deixe em branco para os dias marcados acima. '
                          'Preencha só em exceções, ex: atende 1x por mês',
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
