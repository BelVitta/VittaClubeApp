import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/config/supabase_config.dart';
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
  bool _isFinanceiro = false;

  static const _statusOptions = [
    'ativo',
    'inativo',
    'inadimplente',
    'cancelado'
  ];
  static const _levelOptions = [
    'Bronze',
    'Prata',
    'Ouro',
    'Diamante',
    'Sem plano'
  ];
  static const _roleOptions = [
    {'value': 'user', 'label': 'Usuário'},
    {'value': 'admin', 'label': 'Administrador'},
    {'value': 'financeiro', 'label': 'Financeiro'},
    {'value': 'parceiro', 'label': 'Parceiro'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entity?.name ?? '');
    _emailController = TextEditingController(text: widget.entity?.email ?? '');
    _cpfController = TextEditingController(text: widget.entity?.cpf ?? '');
    _phoneController = TextEditingController(text: widget.entity?.phone ?? '');
    _selectedPlanId = widget.entity?.currentPlanId;
    _selectedPlanLevel = widget.entity?.planLevelName ?? '';
    _selectedStatus = widget.entity?.status ?? 'ativo';
    _selectedRole = widget.entity?.role ?? 'user';

    // Parse memberSince date (vem do Supabase em ISO 8601/timestamptz)
    if (widget.entity?.memberSince != null &&
        widget.entity!.memberSince.isNotEmpty) {
      try {
        _memberSinceDate = DateTime.parse(widget.entity!.memberSince);
      } catch (_) {
        // fallback - keep text as-is
      }
    }
    _memberSinceController = TextEditingController(
      text: _memberSinceDate != null
          ? DateFormat('dd/MM/yyyy').format(_memberSinceDate!)
          : (widget.entity?.memberSince ?? ''),
    );

    _loadPlans();
    _loadAccessAndSensitiveData();
  }

  Future<void> _loadAccessAndSensitiveData() async {
    try {
      final currentUser = SupabaseConfig.client.auth.currentUser;
      if (currentUser == null) return;
      final caller = await SupabaseConfig.client
          .from('profiles')
          .select('role')
          .eq('id', currentUser.id)
          .single();
      final isFinanceiro = caller['role'] == 'financeiro';

      if (widget.isEditing) {
        final fullUser =
            await sl<AdminDataSource>().getUserById(widget.entity!.id);
        if (!mounted) return;
        _cpfController.text = fullUser.cpf;
        _phoneController.text = fullUser.phone;
      }

      if (mounted) setState(() => _isFinanceiro = isFinanceiro);
    } catch (_) {
      // Campos sensíveis permanecem vazios/máscarados quando o servidor nega
      // acesso; nunca usamos a máscara como valor editável.
    }
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
      role: _isFinanceiro ? _selectedRole : (widget.entity?.role ?? 'user'),
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
            SnackBar(content: Text(state.errorMessage ?? 'Erro ao salvar')),
          );
        }
      },
      child: AdminPageScaffold(
        title: widget.isEditing ? 'Editar usuário' : 'Novo usuário',
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
                        if (v == null || v.trim().isEmpty)
                          return 'Nome obrigatório';
                        if (!Validators.isValidName(v))
                          return 'Mínimo 3 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AdminFormField(
                      label: 'E-mail',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'E-mail obrigatório';
                        if (!Validators.isValidEmail(v.trim()))
                          return 'E-mail inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AdminFormField(
                      label: 'CPF',
                      controller: _cpfController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'CPF obrigatório';
                        if (!Validators.isValidCpf(v.trim()))
                          return 'CPF inválido (11 digitos)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AdminFormField(
                      label: 'Telefone',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Telefone obrigatório';
                        if (!Validators.isValidPhone(v.trim()))
                          return 'Telefone inválido';
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
                      label: 'Nível do plano',
                      value: _selectedPlanLevel.isNotEmpty
                          ? _selectedPlanLevel
                          : null,
                      hint: 'Selecione o nível',
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
                    if (_isFinanceiro) ...[
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
                    ],
                    if (_isFinanceiro &&
                        _selectedRole == 'admin' &&
                        widget.entity?.receptionistCode != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E4EC)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Código de indicação (recepcionista)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.entity!.receptionistCode!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_outlined,
                                  size: 18, color: AppTheme.primaryColor),
                              tooltip: 'Copiar código',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                    text: widget.entity!.receptionistCode!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Código copiado!')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
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
