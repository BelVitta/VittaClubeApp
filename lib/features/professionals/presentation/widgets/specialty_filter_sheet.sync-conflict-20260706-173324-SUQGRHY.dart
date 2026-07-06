import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';

/// Bottom sheet com filtro de especialidades.
/// Retorna a especialidade selecionada (ou null se "Fechar").
class SpecialtyFilterSheet extends StatefulWidget {
  final String? currentFilter;
  final List<String> specialties;

  const SpecialtyFilterSheet({
    super.key,
    this.currentFilter,
    this.specialties = defaultSpecialties,
  });

  static Future<String?> show(
    BuildContext context, {
    String? currentFilter,
    List<String> specialties = defaultSpecialties,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SpecialtyFilterSheet(
        currentFilter: currentFilter,
        specialties: specialties,
      ),
    );
  }

  static const List<String> defaultSpecialties = [
    'Clínico Geral',
    'Pediatria',
    'Dermatologia',
    'Ginecologia/Obstetrícia',
    'Cardiologia',
    'Ortopedia',
    'Psiquiatria',
    'Oftalmologia',
    'Nutrição',
    'Fisioterapia',
  ];

  @override
  State<SpecialtyFilterSheet> createState() => _SpecialtyFilterSheetState();
}

class _SpecialtyFilterSheetState extends State<SpecialtyFilterSheet> {
  String? _selected;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _selected = widget.currentFilter;
  }

  List<String> get _filteredSpecialties {
    if (_search.isEmpty) return widget.specialties;
    return widget.specialties
        .where((s) => s.toLowerCase().contains(_search.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Especialidades',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),

          // Search field
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFCFCFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFDDDFE5)),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppTheme.primaryColor,
              ),
              decoration: InputDecoration(
                hintText: 'Pesquisar especialidade',
                hintStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF7B61FF),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Specialty list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredSpecialties.length,
              itemBuilder: (context, index) {
                final specialty = _filteredSpecialties[index];
                final isSelected = _selected == specialty;
                return _buildSpecialtyItem(specialty, isSelected);
              },
            ),
          ),
          const SizedBox(height: 12),

          // Buttons
          PrimaryButton(
            text: 'Filtrar',
            onPressed: () => Navigator.pop(context, _selected),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => Navigator.pop(context, null),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  'Fechar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyItem(String specialty, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selected = _selected == specialty ? null : specialty;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: AppTheme.primaryColor) : null,
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : const Color(0xFF6D7F95),
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 10,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              specialty,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
