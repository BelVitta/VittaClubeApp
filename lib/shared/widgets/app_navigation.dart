import 'package:flutter/material.dart';

import '../../features/card/presentation/pages/card_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/professionals/presentation/pages/professionals_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

class AppNavigation {
  const AppNavigation._();

  static const int homeIndex = 0;
  static const int consultationsIndex = 1;
  static const int cardIndex = 2;
  static const int profileIndex = 3;

  static void goToBottomNavIndex(
    BuildContext context,
    int index, {
    required int currentIndex,
  }) {
    if (index == currentIndex) return;

    final Widget page = switch (index) {
      homeIndex => const HomePage(),
      consultationsIndex => const ProfessionalsPage(),
      cardIndex => const CardPage(),
      profileIndex => const ProfilePage(),
      _ => const HomePage(),
    };

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }
}
