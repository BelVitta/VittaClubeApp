import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_form_card.dart';
import '../../widgets/admin_form_field.dart';
import '../../../domain/entities/draw_entity.dart';
import '../../bloc/draw/draw_bloc.dart';
import '../../bloc/draw/draw_event.dart';
import '../../bloc/draw/draw_state.dart';

class AdminDrawFormPage extends StatefulWidget {
  final DrawEntity? entity;

  const AdminDrawFormPage({super.key, this.entity});

  @override
  State<AdminDrawFormPage> createState() => _AdminDrawFormPageState();
}

class _AdminDrawFormPageState extends State<AdminDrawFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _prizeNameController;
  late final TextEditingController _prizeDescriptionController;
  late final TextEditingController _drawDateController;
  late final TextEditingController _registrationStartController;
  late final TextEditingController _registrationEndController;
  late final TextEditingController _rulesController;
  DateTime? _selectedDrawDate;
  DateTime? _selectedRegStart;
  DateTime? _selectedRegEnd;
  final Set<String> _selectedPlanLevels = {};

  static const _planLevelOptions = ['bronze', 'prata', 'ouro', 'diamante'];

  bool get _isEditing => widget.entity != null;
  bool get _isCompleted => widget.entity?.status == 'realizado';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entity?.name ?? '');
    _prizeNameController =
        TextEditingController(text: widget.entity?.prizeName ?? '');
    _prizeDescriptionController =
        TextEditingController(text: widget.entity?.prizeDescription ?? '');
    _rulesController = TextEditingController(text: widget.entity?.rules ?? '');

    _selectedDrawDate = widget.entity?.drawDate;
    _drawDateController = TextEditingController(
      text: _selectedDrawDate != null ? _formatDate(_selectedDrawDate!) : '',
    );

    _selectedRegStart = widget.entity?.registrationStartDate;
    _registrationStartController = TextEditingController(
      text: _selectedRegStart != null ? _formatDate(_selectedRegStart!) : '',
    );

    _selectedRegEnd = widget.entity?.registrationEndDate;
    _registrationEndController = TextEditingController(
      text: _selectedRegEnd != null ? _formatDate(_selectedRegEnd!) : '',
    );

    if (widget.entity?.eligiblePlanLevels != null) {
      _selectedPlanLevels.addAll(widget.entity!.eligiblePlanLevels);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _prizeNameController.dispose();
    _prizeDescriptionController.dispose();
    _drawDateController.dispose();
    _registrationStartController.dispose();
    _registrationEndController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<DateTime?> _pickDate({DateTime? initial}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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
    return picked;
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDrawDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a data do sorteio')),
      );
      return;
    }

    final entity = DrawEntity(
      id: widget.entity?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      prizeName: _prizeNameController.text.trim(),
      prizeDescription: _prizeDescriptionController.text.trim().isEmpty
          ? null
          : _prizeDescriptionController.text.trim(),
      prizeImageUrl: widget.entity?.prizeImageUrl,
      drawDate: _selectedDrawDate!,
      registrationStartDate: _selectedRegStart,
      registrationEndDate: _selectedRegEnd,
      status: widget.entity?.status ?? 'agendado',
      participantCount: widget.entity?.participantCount ?? 0,
      eligiblePlanLevels: _selectedPlanLevels.toList(),
      rules: _rulesController.text.trim().isEmpty
          ? null
          : _rulesController.text.trim(),
      winnerId: widget.entity?.winnerId,
      winnerName: widget.entity?.winnerName,
      drawSeedHash: widget.entity?.drawSeedHash,
      participantListHash: widget.entity?.participantListHash,
      executedAt: widget.entity?.executedAt,
      winnerIndex: widget.entity?.winnerIndex,
    );

    if (_isEditing) {
      context.read<DrawBloc>().add(UpdateDrawRequested(entity));
    } else {
      context.read<DrawBloc>().add(CreateDrawRequested(entity));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DrawBloc, DrawState>(
      listener: (context, state) {
        if (state.status == DrawStatus.saved) {
          Navigator.of(context).pop();
        } else if (state.status == DrawStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Erro ao salvar sorteio'),
            ),
          );
        }
      },
      child: AdminPageScaffold(
        title: _isEditing
            ? (_isCompleted ? 'Detalhes do Sorteio' : 'Editar Sorteio')
            : 'Novo Sorteio',
        floatingBottom: _isCompleted
            ? null
            : PrimaryButton(
                text: 'Salvar',
                onPressed: _handleSave,
              ),
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Se já foi realizado, mostra resultado no topo
              if (_isCompleted) ...[
                _buildDrawResultCard(),
                const SizedBox(height: 16),
              ],

              AdminFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Informacoes do Sorteio'),
                    const SizedBox(height: 12),
                    AdminFormField(
                      label: 'Nome do Sorteio',
                      controller: _nameController,
                      enabled: !_isCompleted,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Nome obrigatorio' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(
                      label: 'Data do Sorteio',
                      controller: _drawDateController,
                      enabled: !_isCompleted,
                      onTap: () async {
                        final date = await _pickDate(initial: _selectedDrawDate);
                        if (date != null) {
                          setState(() {
                            _selectedDrawDate = date;
                            _drawDateController.text = _formatDate(date);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              AdminFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Premio'),
                    const SizedBox(height: 12),
                    AdminFormField(
                      label: 'Nome do Premio',
                      controller: _prizeNameController,
                      enabled: !_isCompleted,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Premio obrigatorio' : null,
                    ),
                    const SizedBox(height: 16),
                    AdminFormField(
                      label: 'Descricao do Premio',
                      controller: _prizeDescriptionController,
                      enabled: !_isCompleted,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    // Placeholder para foto do prêmio
                    _buildImagePicker(),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              AdminFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Periodo de Inscricao'),
                    const SizedBox(height: 12),
                    _buildDateField(
                      label: 'Inicio das Inscricoes',
                      controller: _registrationStartController,
                      enabled: !_isCompleted,
                      onTap: () async {
                        final date = await _pickDate(initial: _selectedRegStart);
                        if (date != null) {
                          setState(() {
                            _selectedRegStart = date;
                            _registrationStartController.text = _formatDate(date);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(
                      label: 'Fim das Inscricoes',
                      controller: _registrationEndController,
                      enabled: !_isCompleted,
                      onTap: () async {
                        final date = await _pickDate(initial: _selectedRegEnd);
                        if (date != null) {
                          setState(() {
                            _selectedRegEnd = date;
                            _registrationEndController.text = _formatDate(date);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              AdminFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Elegibilidade'),
                    const SizedBox(height: 12),
                    _buildPlanLevelChips(),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              AdminFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Regulamento'),
                    const SizedBox(height: 12),
                    AdminFormField(
                      label: 'Regras e regulamento',
                      controller: _rulesController,
                      enabled: !_isCompleted,
                      maxLines: 5,
                      hintText: 'Descreva as regras do sorteio, questoes legais, etc.',
                    ),
                  ],
                ),
              ),

              // Se já foi realizado, mostra dados de auditoria
              if (_isCompleted && widget.entity?.drawSeedHash != null) ...[
                const SizedBox(height: 16),
                _buildAuditCard(),
              ],

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: AbsorbPointer(
            child: Container(
              decoration: BoxDecoration(
                color: enabled ? const Color(0xFFFCFCFC) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFDDDFE5)),
              ),
              child: TextField(
                controller: controller,
                enabled: false,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.primaryColor,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  suffixIcon: const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  hintText: 'DD/MM/AAAA',
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6D7F95),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto do Premio',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isCompleted
              ? null
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Upload de imagem sera implementado com o backend'),
                    ),
                  );
                },
          child: Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFDDDFE5),
                style: BorderStyle.solid,
              ),
            ),
            child: widget.entity?.prizeImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      widget.entity!.prizeImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                    ),
                  )
                : _buildImagePlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 36,
            color: const Color(0xFF6D7F95).withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            _isCompleted ? 'Sem imagem' : 'Toque para adicionar foto',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: const Color(0xFF6D7F95),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanLevelChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Niveis de Plano Elegiveis',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _planLevelOptions.map((level) {
            final isSelected = _selectedPlanLevels.contains(level);
            return FilterChip(
              label: Text(
                level[0].toUpperCase() + level.substring(1),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                ),
              ),
              selected: isSelected,
              onSelected: _isCompleted
                  ? null
                  : (selected) {
                      setState(() {
                        if (selected) {
                          _selectedPlanLevels.add(level);
                        } else {
                          _selectedPlanLevels.remove(level);
                        }
                      });
                    },
              selectedColor: AppTheme.primaryColor,
              backgroundColor: const Color(0xFFF5F6FA),
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : const Color(0xFFDDDFE5),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Text(
          _selectedPlanLevels.isEmpty
              ? 'Nenhum selecionado = todos elegiveis'
              : '${_selectedPlanLevels.length} nivel(is) selecionado(s)',
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: const Color(0xFF6D7F95),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawResultCard() {
    final entity = widget.entity!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C4156), Color(0xFF1A2A3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 40, color: Color(0xFFFFD700)),
          const SizedBox(height: 12),
          Text(
            'Sorteio Realizado!',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ganhador(a)',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entity.winnerName ?? 'N/A',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (entity.executedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Realizado em ${_formatDate(entity.executedAt!)} as ${entity.executedAt!.hour.toString().padLeft(2, '0')}:${entity.executedAt!.minute.toString().padLeft(2, '0')}',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.white60,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuditCard() {
    final entity = widget.entity!;
    return AdminFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              _buildSectionTitle('Auditoria e Transparencia'),
            ],
          ),
          const SizedBox(height: 12),
          _buildAuditRow('Indice sorteado', '${entity.winnerIndex}'),
          _buildAuditRow('Total participantes', '${entity.participantCount}'),
          const Divider(height: 20),
          _buildAuditRow('Seed Hash (SHA-256)', entity.drawSeedHash ?? '', mono: true),
          const SizedBox(height: 8),
          _buildAuditRow('Hash dos Participantes', entity.participantListHash ?? '', mono: true),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'O sorteio utilizou um algoritmo baseado em SHA-256 com seed composta pelo ID do sorteio, hash da lista de participantes e timestamp da execucao. O resultado e deterministico e verificavel.',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppTheme.primaryColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditRow(String label, String value, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6D7F95),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: mono
                ? GoogleFonts.sourceCodePro(
                    fontSize: 10,
                    color: AppTheme.primaryColor,
                  )
                : GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
