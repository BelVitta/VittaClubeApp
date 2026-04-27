import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_form_card.dart';
import '../../widgets/admin_form_field.dart';
import '../../bloc/specialty/specialty_bloc.dart';
import '../../bloc/specialty/specialty_event.dart';
import '../../bloc/specialty/specialty_state.dart';
import '../../../domain/entities/specialty_entity.dart';

class AdminSpecialtyFormPage extends StatefulWidget {
  final SpecialtyEntity? entity;

  const AdminSpecialtyFormPage({super.key, this.entity});

  bool get isEditing => entity != null;

  @override
  State<AdminSpecialtyFormPage> createState() =>
      _AdminSpecialtyFormPageState();
}

class _AdminSpecialtyFormPageState extends State<AdminSpecialtyFormPage> {
  late final TextEditingController _nameController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entity?.name ?? '');
    _isActive = widget.entity?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final entity = SpecialtyEntity(
      id: widget.entity?.id ?? '',
      name: _nameController.text.trim(),
      isActive: _isActive,
    );

    if (widget.isEditing) {
      context.read<SpecialtyBloc>().add(UpdateSpecialtyRequested(entity));
    } else {
      context.read<SpecialtyBloc>().add(CreateSpecialtyRequested(entity));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SpecialtyBloc, SpecialtyState>(
      listener: (context, state) {
        if (state.status == SpecialtyStatus.saved) {
          Navigator.pop(context);
        } else if (state.status == SpecialtyStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.errorMessage ?? 'Erro ao salvar')),
          );
        }
      },
      child: AdminPageScaffold(
        title: widget.isEditing ? 'Editar Especialidade' : 'Nova Especialidade',
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
            BlocBuilder<SpecialtyBloc, SpecialtyState>(
              builder: (context, state) {
                return PrimaryButton(
                  text: state.status == SpecialtyStatus.saving
                      ? 'Salvando...'
                      : 'Salvar',
                  onPressed: state.status == SpecialtyStatus.saving
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
