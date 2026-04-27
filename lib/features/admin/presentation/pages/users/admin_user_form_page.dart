import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_form_card.dart';
import '../../widgets/admin_form_field.dart';
import '../../widgets/admin_dropdown_field.dart';
import '../../bloc/user_admin/user_admin_bloc.dart';
import '../../bloc/user_admin/user_admin_event.dart';
import '../../bloc/user_admin/user_admin_state.dart';
import '../../../domain/entities/user_admin_entity.dart';
import '../../../domain/entities/plan_admin_entity.dart';
import '../../../data/datasources/admin_datasource.dart';

class AdminUserFormPage extends StatefulWidget {
  final UserAdminEntity? entity;

  const AdminUserFormPage({super.key, this.entity});

  bool get isEditing => entity != null;

  @override
  State<AdminUserFormPage> createState() => _AdminUserFormPageState();
}

class _AdminUserFormPageState extends State<AdminUserFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _cpfController;
  late final TextEditingController _phoneController;
  late final TextEditingController _memberSinceController;

  String? _selectedPlanId;
  String _selectedPlanLevel = '';
  String _selectedStatus = 'ativo';
  String _selectedRole = 'user';
  DateTime? _memberSinceDate;

  List<PlanAdminEntity> _plans = [];
  bool _loadingPlans = true;

  static const _statusOptions = ['ativo', 'inativo', 'inadimplente', 'cancelado'];
  static const _levelOptions = ['Bronze', 'Prata', 'Ouro', 'Diamante', 'Sem plano'];
  static const _roleOptions = [
    {'value': 'user', 'label': 'Usuario'},
    {'value': 'admin', 'label': 'Administrador'},
    {'value': 'financeiro', 'label': 'Financeiro'},
    {'value': 'parceiro', 'label': 'Parceiro'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.entity?.name ?? '');
    _emailController =
        TextEditingController(text: widget.entity?.email ?? '');
    _cpfController =
        TextEditingController(text: widget.entity?.cpf ?? '');
    _phoneController =
        TextEditingController(text: widget.entity?.phone ?? '');
    _selectedPlanId = widget.entity?.currentPlanId;
    _selectedPlanLevel = widget.entity?.planLevelName ?? '';
    _selectedStatus = widget.entity?.status ?? 'ativo';
    _selectedRole = widget.entity?.role ?? 'user';

    // Parse memberSince date
    if (widget.entity?.memberSince != null && widget.entity!.memberSince.isNotEmpty) {
      try {
        _memberSinceDate = DateFormat('dd/MM/yyyy').parse(widget.entity!.memberSince);
      } catch (_) {
        // fallback - keep text as-is
      }
    }
    _memberSinceController = TextEditingController(
      text: widget.entity?.memberSince ?? '',
    );

    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final datasource = sl<AdminDataSource>();
      final plans = await datasource.getPlans();
      setState(() {
        _plans = plans;
        _loadingPlans = false;
      });
    } catch (_) {
      setState(() => _loadingPlans = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
    _memberSinceController.dispose();
    super.dispose();
  }

  Future<void> _pickMemberSince() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _memberSinceDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
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
        _memberSinceDate = picked;
        _memberSinceController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final entity = UserAdminEntity(
      id: widget.entity?.id ?? '',
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      cpf: _cpfController.text.trim(),
      phone: _phoneController.text.trim(),
      currentPlanId: _selectedPlanId,
      planLevelName: _selectedPlanLevel,
      status: _selectedStatus,
      memberSince: _memberSinceController.text.trim(),
      role: _selectedRole,
    );

    if (widget.isEditing) {
      context.read<UserAdminBloc>().add(UpdateUserRequested(entity));
    } else {
      context.read<UserAdminBloc>().add(CreateUserRequested(entity));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserAdminBloc, UserAdminState>(
      listener: (context, state) {
        if (state.status == UserAdminStatus.saved) {
          Navigator.pop(context);
        } else if (state.status == UserAdminStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.errorMessage ?? 'Erro ao salvar')),
          );
        }
      },
      child: AdminPageScaffold(
        title: widget.isEditing ? 'Editar Usuario' : 'Novo Usuario',
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
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Nome obrigatorio';
                        if (!Validators.isValidName(v)) return 'Minimo 3 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AdminFormField(
                      label: 'E-mail',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'E-mail obrigatorio';
                        if (!Validators.isValidEmail(v.trim())) return 'E-mail invalido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AdminFormField(
                      label: 'CPF',
                      controller: _cpfController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'CPF obrigatorio';
                        if (!Validators.isValidCpf(v.trim())) return 'CPF invalido (11 digitos)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AdminFormField(
                      label: 'Telefone',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Telefone obrigatorio';
                        if (!Validators.isValidPhone(v.trim())) return 'Telefone invalido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_loadingPlans)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      AdminDropdownField(
                        label: 'Plano Atual',
                        value: _selectedPlanId,
                        hint: 'Sem plano',
                        items: [
                          const DropdownItem(id: '', displayName: 'Sem plano'),
                          ..._plans.map((p) => DropdownItem(
                                id: p.id,
                                displayName: p.name,
                              )),
                        ],
                        onChanged: (item) {
                          setState(() {
                            _selectedPlanId =
                                (item?.id != null && item!.id.isNotEmpty)
                                    ? item.id
                                    : null;
                          });
                        },
                      ),
                    const SizedBox(height: 16),
                    AdminDropdownField(
                      label: 'Nivel do Plano',
                      value: _selectedPlanLevel.isNotEmpty
                          ? _selectedPlanLevel
                          : null,
                      hint: 'Selecione o nivel',
                      items: _levelOptions
                          .map((l) => DropdownItem(id: l, displayName: l))
                          .toList(),
                      onChanged: (item) {
                        setState(() {
                          _selectedPlanLevel = item?.id ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    AdminDropdownField(
                      label: 'Status',
                      value: _selectedStatus,
                      items: _statusOptions
                          .map((s) => DropdownItem(id: s, displayName: s))
                          .toList(),
                      onChanged: (item) {
                        setState(() {
                          _selectedStatus = item?.id ?? 'ativo';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    AdminDropdownField(
                      label: 'Role',
                      value: _selectedRole,
                      items: _roleOptions
                          .map((r) => DropdownItem(
                                id: r['value']!,
                                displayName: r['label']!,
                              ))
                          .toList(),
                      onChanged: (item) {
                        setState(() {
                          _selectedRole = item?.id ?? 'user';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickMemberSince,
                      child: AbsorbPointer(
                        child: AdminFormField(
                          label: 'Membro Desde',
                          controller: _memberSinceController,
                          readOnly: true,
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              BlocBuilder<UserAdminBloc, UserAdminState>(
                builder: (context, state) {
                  return PrimaryButton(
                    text: state.status == UserAdminStatus.saving
                        ? 'Salvando...'
                        : 'Salvar',
                    onPressed: state.status == UserAdminStatus.saving
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
