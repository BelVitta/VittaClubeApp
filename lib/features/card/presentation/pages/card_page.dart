import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_navigation.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../widgets/qr_code_sheet.dart';
import '../widgets/transaction_item.dart';

/// Página da Carteirinha Digital VitaClube.
class CardPage extends StatefulWidget {
  const CardPage({super.key});

  @override
  State<CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  // TODO: substituir por ProfileBloc / subscription do usuário.
  static const String _memberName = 'Diana Santos';
  static const String _memberCode = '53465123';

  static const int _currentNavIndex = AppNavigation.cardIndex;

  final List<_Transaction> _transactions = const [
    _Transaction(
      title: 'Lab Vita Saúde',
      subtitle: 'Exames laboratoriais',
      valueText: '-R\$ 120,00',
    ),
    _Transaction(
      title: 'Clínica Bem Estar',
      subtitle: 'Consulta clínica geral',
      valueText: '-R\$ 80,00',
    ),
    _Transaction(
      title: 'Farmácia Popular',
      subtitle: '15% de desconto aplicado',
      valueText: '-R\$ 32,50',
    ),
  ];

  void _onNavTap(int index) {
    AppNavigation.goToBottomNavIndex(
      context,
      index,
      currentIndex: AppNavigation.cardIndex,
    );
  }

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
                  // Root tab: no back button (ALA-19). Keeps layout balance.
                  const SizedBox(width: 39, height: 39),
                  Text(
                    'Carteirinha',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  _circleIconButton(
                    icon: Icons.notifications_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsPage()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCard(),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      text: 'Mostrar QR Code',
                      onPressed: () => QrCodeSheet.show(
                        context,
                        memberCode: _memberCode,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Histórico de uso',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF031535),
                        letterSpacing: 0.075,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._transactions.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: TransactionItem(
                          title: t.title,
                          subtitle: t.subtitle,
                          valueText: t.valueText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
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

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, Color(0xFF39586D)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vita Clube',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Icon(Icons.verified_outlined, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Titular',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _memberName,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Código',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _memberCode,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 39,
        height: 39,
        decoration: BoxDecoration(
          color: const Color(0xFF01225B).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(19.5),
        ),
        child: Icon(icon, size: 19, color: const Color(0xFF01225B)),
      ),
    );
  }
}

class _Transaction {
  final String title;
  final String subtitle;
  final String valueText;

  const _Transaction({
    required this.title,
    required this.subtitle,
    required this.valueText,
  });
}
