import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_form_card.dart';
import '../../widgets/admin_form_field.dart';
import '../../../domain/entities/cancellation_reason_entity.dart';
import '../../bloc/cancellation_reason/cancellation_reason_bloc.dart';
import '../../bloc/cancellation_reason/cancellation_reason_event.dart';
import '../../bloc/cancellation_reason/cancellation_reason_state.dart';

/// Formulario de criacao/edicao de motivo de cancelamento.
/// Passa entity nula para criar, ou entity existente para editar.
class AdminReasonFormPage extends StatefulWidget {
  final CancellationReasonEntity? entity;

  const AdminReasonFormPage({super.key, this.entity});

  @override
  State<AdminReasonFormPage> createState() => _AdminReasonFormPageState();
}

class _AdminReasonFormPageState extends State<AdminReasonFormPage> {
  late final TextEditingController _textController;
  late final TextEditingController _usageCountController;
  late bool _isActive;

  bool get _isEditing => widget.entity != null;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.entity?.text ?? '');
    _usageCountController = TextEditingController(
      text: widget.entity?.usageCount.toString() ?? '0',
    );
    _isActive = widget.entity?.isActive ?? true;
  }

  @override
  void dispose() {
    _textController.dispose();
    _usageCountController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final entity = CancellationReasonEntity(
      id: widget.entity?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: _textController.text.trim(),
      usageCount: int.tryParse(_usageCountController.text.trim()) ?? 0,
      isActive: _isActive,
    );

    if (_isEditing) {
      context
          .read<CancellationReasonBloc>()
          .add(UpdateCancellationReasonRequested(entity));
    } else {
      context
          .read<CancellationReasonBloc>()
          .add(CreateCancellationReasonRequested(entity));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CancellationReasonBloc, CancellationReasonState>(
      listener: (context, state) {
        if (state.status == CancellationReasonStatus.saved) {
          Navigator.of(context).pop();
        } else if (state.status == CancellationReasonStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  state.errorMessage ?? 'Erro ao salvar motivo de cancelamento'),
            ),
          );
        }
      },
      child: AdminPageScaffold(
        title: _isEditing ? 'Editar Motivo' : 'Novo Motivo',
        floatingBottom: PrimaryButton(
          text: 'Salvar',
          onPressed: _handleSave,
        ),
        body: AdminFormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Texto do motivo
              AdminFormField(
                label: 'Texto',
                controller: _textController,
              ),
              const SizedBox(height: 16),

              // Quantidade de usos
              AdminFormField(
                label: 'Quantidade de Usos',
                controller: _usageCountController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Ativo
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

              // Espacamento para o botao flutuante
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
