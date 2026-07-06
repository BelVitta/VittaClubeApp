import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/whatsapp_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_navigation.dart';
import '../../../admin/domain/entities/professional_entity.dart';
import '../../../admin/presentation/bloc/professional/professional_bloc.dart';
import '../../../admin/presentation/bloc/professional/professional_event.dart';
import '../../../admin/presentation/bloc/professional/professional_state.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../widgets/professional_card.dart';
import '../widgets/specialty_filter_sheet.dart';

/// Página de lista de profissionais com filtro por especialidade.
class ProfessionalsPage extends StatefulWidget {
  const ProfessionalsPage({super.key});

  @override
  State<ProfessionalsPage> createState() => _ProfessionalsPageState();
}

class _ProfessionalsPageState extends State<ProfessionalsPage> {
  late final ProfessionalBloc _professionalBloc;
  String? _activeFilter;
  final int _currentNavIndex = 1;

  @override
  void initState() {
    super.initState();
    _professionalBloc = sl<ProfessionalBloc>()..add(LoadProfessionals());
  }

  @override
  void dispose() {
    _professionalBloc.close();
    super.dispose();
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

  void _onNavTap(int index) {
    AppNavigation.goToBottomNavIndex(
      context,
      index,
      currentIndex: AppNavigation.consultationsIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _professionalBloc,
      child: Scaffold(
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
                            builder: (_) => const NotificationsPage(),
                          ),
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
                  child: BlocBuilder<ProfessionalBloc, ProfessionalState>(
                    builder: (context, state) {
                      final specialties = _specialtiesFrom(state.items);
                      return GestureDetector(
                        onTap: () => _openFilter(specialties),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEBEEF2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.tune,
                                size: 12,
                                color: AppTheme.primaryColor,
                              ),
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
                                  child: const Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Color(0xFF6D7F95),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<ProfessionalBloc, ProfessionalState>(
                  builder: (context, state) {
                    if (state.status == ProfessionalStatus.loading ||
                        state.status == ProfessionalStatus.initial) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.status == ProfessionalStatus.failure) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Não foi possível carregar os profissionais.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: const Color(0xFF6D7F95),
                            ),
                          ),
                        ),
                      );
                    }

                    final list = _visibleProfessionals(state.items);
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          'Nenhum profissional encontrado.',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: const Color(0xFF6D7F95),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final p = list[i];
                        return ProfessionalCard(
                          name: p.name,
                          specialty: p.specialtyName,
                          availableDays: p.availableDays,
                          avatarUrl: p.avatarUrl.isEmpty ? null : p.avatarUrl,
                          avatarBgColor: _avatarColor(p.avatarBgColor),
                          isLarge: true,
                          onWhatsApp: () => _openWhatsApp(p.name),
                        );
                      },
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
      ),
    );
  }

  List<ProfessionalEntity> _visibleProfessionals(
    List<ProfessionalEntity> professionals,
  ) {
    return professionals.where((p) {
      if (!p.isActive) return false;
      if (_activeFilter == null) return true;
      return p.specialtyName == _activeFilter;
    }).toList();
  }

  List<String> _specialtiesFrom(List<ProfessionalEntity> professionals) {
    final specialties = professionals
        .where((p) => p.isActive)
        .map((p) => p.specialtyName)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    specialties.sort();
    return specialties.isEmpty
        ? SpecialtyFilterSheet.defaultSpecialties
        : specialties;
  }

  Color _avatarColor(int value) {
    if (value == 0) return const Color(0xFFFFCD66);
    return Color(value);
  }
}
