import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_form_card.dart';
import '../../widgets/admin_form_field.dart';
import '../../widgets/admin_dropdown_field.dart';
import '../../../domain/entities/notification_template_entity.dart';
import '../../bloc/notification_template/notification_template_bloc.dart';
import '../../bloc/notification_template/notification_template_event.dart';
import '../../bloc/notification_template/notification_template_state.dart';

class AdminNotificationFormPage extends StatefulWidget {
  final NotificationTemplateEntity? entity;

  const AdminNotificationFormPage({super.key, this.entity});

  @override
  State<AdminNotificationFormPage> createState() =>
      _AdminNotificationFormPageState();
}

class _AdminNotificationFormPageState extends State<AdminNotificationFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _triggerEventController;
  late bool _isActive;
  String _selectedType = 'geral';

  static const _typeOptions = [
    DropdownItem(id: 'sorteio', displayName: 'Sorteio'),
    DropdownItem(id: 'cupom', displayName: 'Cupom'),
    DropdownItem(id: 'consulta', displayName: 'Consulta'),
    DropdownItem(id: 'geral', displayName: 'Geral'),
  ];

  bool get _isEditing => widget.entity != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entity?.title ?? '');
    _bodyController = TextEditingController(text: widget.entity?.body ?? '');
    _selectedType = widget.entity?.type ?? 'geral';
    _triggerEventController =
        TextEditingController(text: widget.entity?.triggerEvent ?? '');
    _isActive = widget.entity?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _triggerEventController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final entity = NotificationTemplateEntity(
      id: widget.entity?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      type: _selectedType,
      triggerEvent: _triggerEventController.text.trim(),
      isActive: _isActive,
    );

    if (_isEditing) {
      context
          .read<NotificationTemplateBloc>()
          .add(UpdateNotificationTemplateRequested(entity));
    } else {
      context
          .read<NotificationTemplateBloc>()
          .add(CreateNotificationTemplateRequested(entity));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationTemplateBloc, NotificationTemplateState>(
      listener: (context, state) {
        if (state.status == NotificationTemplateStatus.saved) {
          Navigator.of(context).pop();
        } else if (state.status == NotificationTemplateStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Erro ao salvar notificacao'),
            ),
          );
        }
      },
      child: AdminPageScaffold(
        title: _isEditing ? 'Editar Notificacao' : 'Nova Notificacao',
        floatingBottom: PrimaryButton(
          text: 'Salvar',
          onPressed: _handleSave,
        ),
        body: Form(
          key: _formKey,
          child: AdminFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminFormField(
                  label: 'Titulo',
                  controller: _titleController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Titulo obrigatorio' : null,
                ),
                const SizedBox(height: 16),

                AdminFormField(
                  label: 'Corpo',
                  controller: _bodyController,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                AdminDropdownField(
                  label: 'Tipo',
                  value: _selectedType,
                  items: _typeOptions,
                  onChanged: (item) {
                    setState(() {
                      _selectedType = item?.id ?? 'geral';
                    });
                  },
                ),
                const SizedBox(height: 16),

                AdminFormField(
                  label: 'Evento Gatilho',
                  controller: _triggerEventController,
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

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
