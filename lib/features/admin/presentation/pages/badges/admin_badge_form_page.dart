import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_form_card.dart';
import '../../widgets/admin_form_field.dart';
import '../../../domain/entities/badge_entity.dart';
import '../../bloc/badge/badge_bloc.dart';
import '../../bloc/badge/badge_event.dart';
import '../../bloc/badge/badge_state.dart';

/// Formulario de criacao/edicao de badge/emblema.
/// Passa entity nula para criar, ou entity existente para editar.
class AdminBadgeFormPage extends StatefulWidget {
  final BadgeEntity? entity;

  const AdminBadgeFormPage({super.key, this.entity});

  @override
  State<AdminBadgeFormPage> createState() => _AdminBadgeFormPageState();
}

class _AdminBadgeFormPageState extends State<AdminBadgeFormPage> {
  late final TextEditingController _levelNameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _badgeImageUrlController;
  late final TextEditingController _progressColorController;
  late final TextEditingController _progressBgColorController;
  late final TextEditingController _sortOrderController;
  late final TextEditingController _discountController;
  late final TextEditingController _maxConsultationsController;

  bool get _isEditing => widget.entity != null;

  @override
  void initState() {
    super.initState();
    _levelNameController =
        TextEditingController(text: widget.entity?.levelName ?? '');
    _displayNameController =
        TextEditingController(text: widget.entity?.displayName ?? '');
    _badgeImageUrlController =
        TextEditingController(text: widget.entity?.badgeImageUrl ?? '');
    _progressColorController = TextEditingController(
      text: widget.entity != null
          ? widget.entity!.progressColor.toRadixString(16).toUpperCase()
          : '',
    );
    _progressBgColorController = TextEditingController(
      text: widget.entity != null
          ? widget.entity!.progressBgColor.toRadixString(16).toUpperCase()
          : '',
    );
    _sortOrderController = TextEditingController(
      text: widget.entity?.sortOrder.toString() ?? '',
    );
    _discountController = TextEditingController(
      text: widget.entity != null
          ? widget.entity!.discountPercentage.toString()
          : '',
    );
    _maxConsultationsController = TextEditingController(
      text: widget.entity != null
          ? widget.entity!.maxConsultationsPerMonth.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _levelNameController.dispose();
    _displayNameController.dispose();
    _badgeImageUrlController.dispose();
    _progressColorController.dispose();
    _progressBgColorController.dispose();
    _sortOrderController.dispose();
    _discountController.dispose();
    _maxConsultationsController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final entity = BadgeEntity(
      id: widget.entity?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      levelName: _levelNameController.text.trim(),
      displayName: _displayNameController.text.trim(),
      badgeImageUrl: _badgeImageUrlController.text.trim(),
      progressColor:
          int.tryParse(_progressColorController.text.trim(), radix: 16) ??
              0xFF2C4156,
      progressBgColor:
          int.tryParse(_progressBgColorController.text.trim(), radix: 16) ??
              0xFF2C4156,
      sortOrder: int.tryParse(_sortOrderController.text.trim()) ?? 0,
      discountPercentage:
          double.tryParse(_discountController.text.trim()) ?? 0,
      maxConsultationsPerMonth:
          int.tryParse(_maxConsultationsController.text.trim()) ?? 0,
    );

    if (_isEditing) {
      context.read<BadgeBloc>().add(UpdateBadgeRequested(entity));
    } else {
      context.read<BadgeBloc>().add(CreateBadgeRequested(entity));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BadgeBloc, BadgeState>(
      listener: (context, state) {
        if (state.status == BadgeStatus.saved) {
          Navigator.of(context).pop();
        } else if (state.status == BadgeStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Erro ao salvar badge'),
            ),
          );
        }
      },
      child: AdminPageScaffold(
        title: _isEditing ? 'Editar Badge' : 'Novo Badge',
        floatingBottom: PrimaryButton(
          text: 'Salvar',
          onPressed: _handleSave,
        ),
        body: AdminFormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nome do nivel
              AdminFormField(
                label: 'Nome do Nivel',
                controller: _levelNameController,
              ),
              const SizedBox(height: 16),

              // Nome de exibicao
              AdminFormField(
                label: 'Nome de Exibicao',
                controller: _displayNameController,
              ),
              const SizedBox(height: 16),

              // URL da imagem
              AdminFormField(
                label: 'URL da Imagem do Badge',
                controller: _badgeImageUrlController,
              ),
              const SizedBox(height: 16),

              // Cor de progresso (hex)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cor de Progresso (hex, ex: FF2C4156)',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCFCFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFDDDFE5)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _progressColorController,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.primaryColor,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              hintText: 'FF2C4156',
                              hintStyle: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF6D7F95),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Color(
                              int.tryParse(
                                      _progressColorController.text.trim(),
                                      radix: 16) ??
                                  0xFF2C4156,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: const Color(0xFFDDDFE5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Cor de fundo de progresso (hex)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cor de Fundo de Progresso (hex, ex: FF2C4156)',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCFCFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFDDDFE5)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _progressBgColorController,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.primaryColor,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              hintText: 'FF2C4156',
                              hintStyle: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF6D7F95),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Color(
                              int.tryParse(
                                      _progressBgColorController.text.trim(),
                                      radix: 16) ??
                                  0xFF2C4156,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: const Color(0xFFDDDFE5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Desconto (%)
              AdminFormField(
                label: 'Desconto (%)',
                controller: _discountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // Consultas/Mes
              AdminFormField(
                label: 'Consultas/Mes',
                controller: _maxConsultationsController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Ordem de exibicao
              AdminFormField(
                label: 'Ordem de Exibicao',
                controller: _sortOrderController,
                keyboardType: TextInputType.number,
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
