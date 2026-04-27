import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/whatsapp_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../card/presentation/pages/card_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../widgets/professional_card.dart';
import '../widgets/specialty_filter_sheet.dart';

/// Entidade local (mock) para profissionais exibidos na listagem.
/// TODO: substituir por feature lendo `professionals` do Supabase.
class _ProfessionalData {
  final String name;
  final String specialty;
  final String availableDays;
  final Color avatarBgColor;

  const _ProfessionalData({
    required this.name,
    required this.specialty,
    required this.availableDays,
    this.avatarBgColor = const Color(0xFFFFCD66),
  });
}

/// Página de lista de profissionais com filtro por especialidade.
class ProfessionalsPage extends StatefulWidget {
  const ProfessionalsPage({super.key});

  @override
  State<ProfessionalsPage> createState() => _ProfessionalsPageState();
}

class _ProfessionalsPageState extends State<ProfessionalsPage> {
  String? _activeFilter;
  int _currentNavIndex = 1;

  static const List<_ProfessionalData> _all = [
    _ProfessionalData(
      name: 'Dra. Marina Silva',
      specialty: 'Clínico Geral',
      availableDays: 'Seg, Qua, Sex',
      avatarBgColor: Color(0xFFFFCD66),
    ),
    _ProfessionalData(
      name: 'Dr. Ricardo Alves',
      specialty: 'Nutrição',
      availableDays: 'Ter, Qui',
      avatarBgColor: Color(0xFF7BDFF2),
    ),
    _ProfessionalData(
      name: 'Dra. Laura Mendes',
      specialty: 'Fisioterapia',
      availableDays: 'Seg a Sex',
      avatarBgColor: Color(0xFFB2F7A1),
    ),
    _ProfessionalData(
      name: 'Dr. Pedro Ramirez',
      specialty: 'Psiquiatria',
      availableDays: 'Qua, Sex',
      avatarBgColor: Color(0xFFF2A4D3),
    ),
  ];

  List<_ProfessionalData> get _filtered {
    if (_activeFilter == null) return _all;
    return _all.where((p) => p.specialty == _activeFilter).toList();
  }

  Future<void> _openWhatsApp(String professionalName) async {
    // TODO: passar professionalNumber quando trocarmos o mock `_all` por dados
    // reais da tabela `professionals` (campo whatsapp_encrypted descriptografado).
    final result = await WhatsAppLauncher.open(
      presetMessage:
          'Olá! Gostaria de agendar uma consulta com $professionalName pelo Vita Clube.',
    );
    if (!mounted) return;
    switch (result) {
      case WhatsAppLaunchResult.ok:
        break;
      case WhatsAppLaunchResult.missingNumber:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Número da clínica ainda não foi configurado. Peça ao administrador.',
            ),
          ),
        );
      case WhatsAppLaunchResult.launchFailed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Não foi possível abrir o WhatsApp neste dispositivo.'),
          ),
        );
    }
  }

  Future<void> _openFilter() async {
    final chosen = await SpecialtyFilterSheet.show(
      context,
      currentFilter: _activeFilter,
    );
    if (!mounted) return;
    setState(() => _activeFilter = chosen);
  }

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
    Widget? next;
    if (index == 0) {
      Navigator.pop(context);
      return;
    } else if (index == 2) {
      next = const CardPage();
    } else if (index == 3) {
      next = const ProfilePage();
    }
    if (next != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => next!)).then(
        (_) {
          if (mounted) setState(() => _currentNavIndex = 1);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Médicos',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF031535),
                      letterSpacing: 0.12,
                    ),
                  ),
                  Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      color: const Color(0xFF01225B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(19.5),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        size: 19,
                        color: Color(0xFF01225B),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsPage()),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: _openFilter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEBEEF2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune,
                            size: 12, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          _activeFilter ?? 'Filtrar',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                            letterSpacing: 0.06,
                          ),
                        ),
                        if (_activeFilter != null) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _activeFilter = null),
                            child: const Icon(Icons.close,
                                size: 12, color: Color(0xFF6D7F95)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum profissional encontrado.',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFF6D7F95),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final p = list[i];
                        return ProfessionalCard(
                          name: p.name,
                          specialty: p.specialty,
                          availableDays: p.availableDays,
                          avatarBgColor: p.avatarBgColor,
                          isLarge: true,
                          onWhatsApp: () => _openWhatsApp(p.name),
                        );
                      },
                    ),
            ),
            AppBottomNavigation(
              currentIndex: _currentNavIndex,
              onTap: _onNavTap,
            ),
          ],
        ),
      ),
    );
  }

}
