import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../profile/domain/usecases/get_current_profile_usecase.dart';
import '../../../domain/entities/professional_entity.dart';
import '../../../domain/entities/user_admin_entity.dart';
import '../../../domain/usecases/professional/get_professionals_usecase.dart';
import '../../../domain/usecases/user_admin/get_users_usecase.dart';
import '../../bloc/notification_campaign/notification_campaign_bloc.dart';
import '../../bloc/notification_campaign/notification_campaign_event.dart';
import '../../bloc/notification_campaign/notification_campaign_state.dart';
import '../../widgets/admin_dropdown_field.dart';
import '../../widgets/admin_form_card.dart';
import '../../widgets/admin_form_field.dart';
import '../../widgets/admin_page_scaffold.dart';

class AdminCampaignFormPage extends StatefulWidget {
  const AdminCampaignFormPage({super.key});

  @override
  State<AdminCampaignFormPage> createState() => _AdminCampaignFormPageState();
}

class _AdminCampaignFormPageState extends State<AdminCampaignFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String _selectedType = 'divulgacao';
  String _audience = 'user';
  String _action = 'none';
  String? _targetUserId;
  String? _professionalId;
  bool _isFinanceiro = false;
  bool _loadingLookups = true;
  List<UserAdminEntity> _users = const [];
  List<ProfessionalEntity> _professionals = const [];

  static const _typeOptions = [
    DropdownItem(id: 'divulgacao', displayName: 'Divulgação'),
    DropdownItem(id: 'profissional', displayName: 'Especialista'),
    DropdownItem(id: 'sorteio', displayName: 'Sorteio'),
    DropdownItem(id: 'cupom', displayName: 'Cupom'),
    DropdownItem(id: 'consulta', displayName: 'Consulta'),
    DropdownItem(id: 'sistema', displayName: 'Sistema'),
    DropdownItem(id: 'badge', displayName: 'Patente'),
  ];

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    final profileResult = await sl<GetCurrentProfileUseCase>()();
    final usersResult = await sl<GetUsersUseCase>()();
    final professionalsResult = await sl<GetProfessionalsUseCase>()();

    if (!mounted) return;

    profileResult.fold((_) {}, (profile) {
      _isFinanceiro = profile?.role == 'financeiro';
    });
    usersResult.fold((_) {}, (users) {
      _users = users.where((u) => u.role == 'user').toList();
    });
    professionalsResult.fold((_) {}, (list) {
      _professionals = list.where((p) => p.isActive).toList();
    });

    setState(() => _loadingLookups = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (!_formKey.currentState!.validate()) return;

    if (_audience == 'user' &&
        (_targetUserId == null || _targetUserId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha o membro destinatário.')),
      );
      return;
    }

    if (_audience == 'all_users' && !_isFinanceiro) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apenas o financeiro pode enviar para todos.'),
        ),
      );
      return;
    }

    var action = _action;
    if (_selectedType == 'profissional') {
      action = _professionalId != null ? 'professional' : 'professionals';
    }

    ProfessionalEntity? professional;
    if (_professionalId != null) {
      for (final p in _professionals) {
        if (p.id == _professionalId) {
          professional = p;
          break;
        }
      }
    }

    final data = <String, dynamic>{
      'action': action,
      if (professional != null) 'professional_id': professional.id,
      if (professional != null) 'professional_name': professional.name,
    };

    context.read<NotificationCampaignBloc>().add(
          SendNotificationCampaignRequested(
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            type: _selectedType,
            audience: _audience,
            targetUserId: _audience == 'user' ? _targetUserId : null,
            data: data,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationCampaignBloc, NotificationCampaignState>(
      listener: (context, state) {
        if (state.status == NotificationCampaignStatus.sent) {
          final count = state.lastRecipientCount ?? 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Enviada para $count membro(s).'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state.status == NotificationCampaignStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Erro ao enviar campanha'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      },
      child: AdminPageScaffold(
        title: 'Enviar campanha',
        subtitle: 'Divulgação in-app para membros',
        floatingBottom:
            BlocBuilder<NotificationCampaignBloc, NotificationCampaignState>(
          builder: (context, state) {
            final sending = state.status == NotificationCampaignStatus.sending;
            return PrimaryButton(
              text: sending ? 'Enviando...' : 'Enviar agora',
              onPressed: sending ? null : _handleSend,
            );
          },
        ),
        body: _loadingLookups
            ? const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                ),
              )
            : Form(
                key: _formKey,
                child: AdminFormCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdminFormField(
                        label: 'Título',
                        controller: _titleController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Título obrigatório'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      AdminFormField(
                        label: 'Corpo',
                        controller: _bodyController,
                        maxLines: 4,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Corpo obrigatório'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      AdminDropdownField(
                        label: 'Tipo',
                        value: _selectedType,
                        items: _typeOptions,
                        onChanged: (item) {
                          setState(() {
                            _selectedType = item?.id ?? 'divulgacao';
                            if (_selectedType == 'profissional') {
                              _action = 'professional';
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      AdminDropdownField(
                        label: 'Público',
                        value: _audience,
                        items: [
                          const DropdownItem(
                            id: 'user',
                            displayName: 'Um membro',
                          ),
                          if (_isFinanceiro)
                            const DropdownItem(
                              id: 'all_users',
                              displayName: 'Todos os membros',
                            ),
                        ],
                        onChanged: (item) {
                          setState(() => _audience = item?.id ?? 'user');
                        },
                      ),
                      if (_audience == 'user') ...[
                        const SizedBox(height: 16),
                        AdminDropdownField(
                          label: 'Membro',
                          value: _targetUserId,
                          hint: 'Selecione o membro',
                          items: _users
                              .map((u) => DropdownItem(
                                    id: u.id,
                                    displayName: '${u.name} · ${u.email}',
                                  ))
                              .toList(),
                          onChanged: (item) {
                            setState(() => _targetUserId = item?.id);
                          },
                        ),
                      ],
                      if (_selectedType == 'profissional' ||
                          _action == 'professional') ...[
                        const SizedBox(height: 16),
                        AdminDropdownField(
                          label: 'Especialista (opcional)',
                          value: _professionalId,
                          hint: 'Abrir lista de profissionais',
                          items: _professionals
                              .map((p) => DropdownItem(
                                    id: p.id,
                                    displayName:
                                        '${p.name} · ${p.specialtyName}',
                                  ))
                              .toList(),
                          onChanged: (item) {
                            setState(() {
                              _professionalId = item?.id;
                              _action = item == null
                                  ? 'professionals'
                                  : 'professional';
                            });
                          },
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        AdminDropdownField(
                          label: 'Ao tocar, abrir',
                          value: _action,
                          items: const [
                            DropdownItem(id: 'none', displayName: 'Nada'),
                            DropdownItem(
                              id: 'professionals',
                              displayName: 'Profissionais',
                            ),
                            DropdownItem(id: 'plans', displayName: 'Planos'),
                            DropdownItem(
                              id: 'partners',
                              displayName: 'Parceiros',
                            ),
                          ],
                          onChanged: (item) {
                            setState(() => _action = item?.id ?? 'none');
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        _isFinanceiro
                            ? 'Broadcast: 1 por dia. Envio individual: 10 por dia.'
                            : 'Recepcionista envia só para um membro (até 10 por dia).',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF6D7F95),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
