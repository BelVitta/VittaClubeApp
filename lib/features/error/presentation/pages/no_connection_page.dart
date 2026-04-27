import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/error_states/error_state_widget.dart';

/// Página exibida quando não há conexão com a internet.
class NoConnectionPage extends StatefulWidget {
  final VoidCallback? onRetry;
  final bool showNavigation;

  const NoConnectionPage({
    super.key,
    this.onRetry,
    this.showNavigation = true,
  });

  @override
  State<NoConnectionPage> createState() => _NoConnectionPageState();
}

class _NoConnectionPageState extends State<NoConnectionPage> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ErrorStateWidget(
                icon: Icons.wifi_off_rounded,
                title: 'Sem conexão',
                message:
                    'Não foi possível conectar à internet. Verifique sua rede e tente novamente.',
                buttonText: 'Tentar novamente',
                onButtonPressed: widget.onRetry,
              ),
            ),
            if (widget.showNavigation)
              AppBottomNavigation(
                currentIndex: _currentNavIndex,
                onTap: (index) => setState(() => _currentNavIndex = index),
              ),
          ],
        ),
      ),
    );
  }
}
