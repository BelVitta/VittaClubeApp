import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme.dart';

/// Caminhos dos SVGs de navegação — uma única fonte de verdade para todas
/// as páginas que usam a `AppBottomNavigation`.
const List<String> kAppBottomNavIcons = [
  'assets/icons/icon_home.svg',
  'assets/icons/icon_medical.svg',
  'assets/icons/icon_carteira.svg',
  'assets/icons/icon_person.svg',
];

/// Widget da barra de navegação inferior do app. Renderiza SVGs do
/// `assets/icons/`.
class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<String> iconAssets;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.iconAssets = kAppBottomNavIcons,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 63 + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFEBEEF2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          iconAssets.length,
          (index) => _NavItem(
            assetPath: iconAssets[index],
            isActive: index == currentIndex,
            onTap: () => onTap(index),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String assetPath;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.assetPath,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? AppTheme.primaryColor
        : AppTheme.primaryColor.withValues(alpha: 0.4);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: SvgPicture.asset(
          assetPath,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    );
  }
}
