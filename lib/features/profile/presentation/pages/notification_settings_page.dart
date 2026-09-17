import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../notifications/domain/entities/notification_preferences_entity.dart';
import '../../../notifications/domain/usecases/get_notification_preferences_usecase.dart';
import '../../../notifications/domain/usecases/update_notification_preferences_usecase.dart';

/// Preferências de categorias de notificação (persistidas no Supabase).
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  NotificationPreferencesEntity _prefs = const NotificationPreferencesEntity();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await sl<GetNotificationPreferencesUseCase>()();
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _loading = false),
      (prefs) => setState(() {
        _prefs = prefs;
        _loading = false;
      }),
    );
  }

  Future<void> _save(NotificationPreferencesEntity next) async {
    setState(() {
      _prefs = next;
      _saving = true;
    });
    final result = await sl<UpdateNotificationPreferencesUseCase>()(next);
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (saved) => setState(() => _prefs = saved),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -16,
              right: -180,
              child: Container(
                width: 503.5,
                height: 283.06,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.gradientLight.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, 1],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 39,
                          height: 39,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF01225B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(19.5),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notificações',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.primaryColor,
                                  letterSpacing: 0.12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Escolha o que deseja receber',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.primaryColor,
                                  letterSpacing: 0.075,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildToggleCard(),
                              if (_saving)
                                const Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: LinearProgressIndicator(
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEEF2)),
      ),
      child: Column(
        children: [
          _buildToggleItem(
            title: 'Sorteios',
            subtitle: 'Novos sorteios e resultados',
            value: _prefs.sorteios,
            onChanged: (v) => _save(_prefs.copyWith(sorteios: v)),
          ),
          _buildToggleItem(
            title: 'Rankings',
            subtitle: 'Atualizações de posição',
            value: _prefs.rankings,
            onChanged: (v) => _save(_prefs.copyWith(rankings: v)),
          ),
          _buildToggleItem(
            title: 'Pagamentos',
            subtitle: 'Cobranças e recibos',
            value: _prefs.pagamentos,
            onChanged: (v) => _save(_prefs.copyWith(pagamentos: v)),
          ),
          _buildToggleItem(
            title: 'Novidades',
            subtitle: 'Dicas, especialistas e promoções',
            value: _prefs.novidades,
            onChanged: (v) => _save(_prefs.copyWith(novidades: v)),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
              Switch(
                value: value,
                onChanged: _saving ? null : onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: AppTheme.primaryColor,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFEBEEF2),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: const Color(0xFFEBEEF2).withValues(alpha: 0.5),
          ),
      ],
    );
  }
}
