import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_form_card.dart';
import '../../widgets/admin_form_field.dart';
import '../../widgets/admin_dropdown_field.dart';
import '../../bloc/consultation_admin/consultation_admin_bloc.dart';
import '../../bloc/consultation_admin/consultation_admin_event.dart';
import '../../bloc/consultation_admin/consultation_admin_state.dart';
import '../../../domain/entities/consultation_admin_entity.dart';
import '../../../domain/entities/professional_entity.dart';
import '../../../domain/entities/user_admin_entity.dart';
import '../../../data/datasources/admin_datasource.dart';

class AdminConsultationFormPage extends StatefulWidget {
  final ConsultationAdminEntity? entity;

  const AdminConsultationFormPage({super.key, this.entity});

  bool get isEditing => entity != null;

  @override
  State<AdminConsultationFormPage> createState() =>
      _AdminConsultationFormPageState();
}

class _AdminConsultationFormPageState extends State<AdminConsultationFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _dateController;

  DateTime? _selectedDate;
  String? _selectedProfessionalId;
  String _selectedProfessionalName = '';
  String? _selectedUserId;
  String _selectedUserName = '';

  List<ProfessionalEntity> _professionals = [];
  List<UserAdminEntity> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.entity?.title ?? '');
    _subtitleController =
        TextEditingController(text: widget.entity?.subtitle ?? '');
    _selectedDate = widget.entity?.date;
    _dateController = TextEditingController(
      text: widget.entity != null
          ? DateFormat('dd/MM/yyyy').format(widget.entity!.date)
          : '',
    );
    _selectedProfessionalId = widget.entity?.professionalId;
    _selectedProfessionalName = widget.entity?.professionalName ?? '';
    _selectedUserId = widget.entity?.userId;
    _selectedUserName = widget.entity?.userName ?? '';
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final datasource = sl<AdminDataSource>();
      final results = await Future.wait([
        datasource.getProfessionals(),
        datasource.getUsers(),
      ]);
      setState(() {
        _professionals = results[0] as List<ProfessionalEntity>;
        _users = results[1] as List<UserAdminEntity>;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final entity = ConsultationAdminEntity(
      id: widget.entity?.id ?? '',
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim(),
      date: _selectedDate ?? DateTime.now(),
      professionalId: _selectedProfessionalId ?? '',
      professionalName: _selectedProfessionalName,
      userId: _selectedUserId ?? '',
      userName: _selectedUserName,
    );

    if (widget.isEditing) {
      context
          .read<ConsultationAdminBloc>()
          .add(UpdateConsultationRequested(entity));
    } else {
      context
          .read<ConsultationAdminBloc>()
          .add(CreateConsultationRequested(entity));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConsultationAdminBloc, ConsultationAdminState>(
      listener: (context, state) {
        if (state.status == ConsultationAdminStatus.saved) {
          Navigator.pop(context);
        } else if (state.status == ConsultationAdminStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.errorMessage ?? 'Erro ao salvar')),
          );
        }
      },
      child: AdminPageScaffold(
        title: widget.isEditing ? 'Editar Consulta' : 'Nova Consulta',
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              AdminFormCard(
                child: Column(
                  children: [
                    AdminFormField(
                      label: 'Titulo',
                      controller: _titleController,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Titulo obrigatorio' : null,
                    ),
                    const SizedBox(height: 16),
                    AdminFormField(
                      label: 'Subtitulo',
                      controller: _subtitleController,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: AdminFormField(
                          label: 'Data',
                          controller: _dateController,
                          readOnly: true,
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else ...[
                      AdminDropdownField(
                        label: 'Profissional',
                        value: _selectedProfessionalId,
                        hint: 'Selecione o profissional',
                        items: _professionals
                            .map((p) => DropdownItem(
                                  id: p.id,
                                  displayName: p.name,
                                ))
                            .toList(),
                        onChanged: (item) {
                          setState(() {
                            _selectedProfessionalId = item?.id;
                            _selectedProfessionalName =
                                item?.displayName ?? '';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      AdminDropdownField(
                        label: 'Usuario',
                        value: _selectedUserId,
                        hint: 'Selecione o usuario',
                        items: _users
                            .map((u) => DropdownItem(
                                  id: u.id,
                                  displayName: u.name,
                                ))
                            .toList(),
                        onChanged: (item) {
                          setState(() {
                            _selectedUserId = item?.id;
                            _selectedUserName = item?.displayName ?? '';
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              BlocBuilder<ConsultationAdminBloc, ConsultationAdminState>(
                builder: (context, state) {
                  return PrimaryButton(
                    text: state.status == ConsultationAdminStatus.saving
                        ? 'Salvando...'
                        : 'Salvar',
                    onPressed: state.status == ConsultationAdminStatus.saving
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
