import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/whatsapp_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_navigation.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../domain/entities/professional_entity.dart';
import '../bloc/professionals_bloc.dart';
import '../bloc/professionals_event.dart';
import '../bloc/professionals_state.dart';
import '../widgets/professional_card.dart';
import '../widgets/specialty_filter_sheet.dart';

/// Página de lista de profissionais com filtro por especialidade.
class ProfessionalsPage extends StatelessWidget {
  const ProfessionalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfessionalsBloc>()..add(const LoadProfessionals()),
      child: const _ProfessionalsView(),
    );
  }
}

class _ProfessionalsView extends StatefulWidget {
  const _ProfessionalsView();

  @override
  State<_ProfessionalsView> createState() => _ProfessionalsViewState();
}

class _ProfessionalsViewState extends State<_ProfessionalsView> {
  String? _activeFilter;
  final int _currentNavIndex = 1;

  List<ProfessionalEntity> _filtered(List<ProfessionalEntity> all) {
    if (_activeFilter == null) return all;
    return all.where((p) => p.specialtyName == _activeFilter).toList();
  }

  Future<void> _openWhatsApp(String professionalName) async {
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

  Future<void> _openFilter(List<String> specialties) async {
    final chosen = await SpecialtyFilterSheet.show(
      context,
      currentFilter: _activeFilter,
      specialties: specialties,
    );
    if (!mounted) return;
    setState(() => _activeFilter = chosen);
  }

  void _onNavTap(int index) => AppNavigation.goToBottomNavIndex(
        context,
        index,
        currentIndex: _currentNavIndex,
      );

  @override
  Widget build(BuildContext context) {
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
                    'Profissionais',
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
            Expanded(
              child: BlocBuilder<ProfessionalsBloc, ProfessionalsState>(
                builder: (context, state) {
                  if (state is ProfessionalsLoading ||
                      state is ProfessionalsInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ProfessionalsError) {
                    return Center(
                      child: Text(
                        'Não foi possível carregar os profissionais.',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFF6D7F95),
                        ),
                      ),
                    );
                  }
                  final all = (state as ProfessionalsLoaded).items;
                  final specialties = all
                      .map((p) => p.specialtyName)
                      .where((s) => s.isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();
                  final list = _filtered(all);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GestureDetector(
                          onTap: () => _openFilter(specialties),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFFEBEEF2)),
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
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 32),
                                itemCount: list.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, i) {
                                  final p = list[i];
                                  return ProfessionalCard(
                                    name: p.name,
                                    specialty: p.specialtyName,
                                    availableDays: p.availableDays,
                                    avatarBgColor: Color(p.avatarBgColor),
                                    avatarUrl: p.avatarUrl,
                                    isLarge: true,
                                    onWhatsApp: () => _openWhatsApp(p.name),
                                  );
                                },
                              ),
                      ),
                    ],
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
