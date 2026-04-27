import 'package:flutter/material.dart';
import '../../features/error/presentation/pages/no_connection_page.dart';

/// Helper para lidar com conectividade
class ConnectivityHelper {
  /// Navega para a página de sem conexão
  static void showNoConnectionPage(
    BuildContext context, {
    VoidCallback? onRetry,
    bool showNavigation = true,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoConnectionPage(
          onRetry: onRetry,
          showNavigation: showNavigation,
        ),
      ),
    );
  }

  /// Navega e substitui a tela atual pela página de sem conexão
  static void replaceWithNoConnectionPage(
    BuildContext context, {
    VoidCallback? onRetry,
    bool showNavigation = true,
  }) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => NoConnectionPage(
          onRetry: onRetry,
          showNavigation: showNavigation,
        ),
      ),
    );
  }

  /// Exibe um bottom sheet com erro de conexão
  static void showNoConnectionBottomSheet(
    BuildContext context, {
    required VoidCallback onRetry,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sem Conexão',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verifique sua conexão com a internet e tente novamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onRetry();
                },
                child: const Text('Tentar Novamente'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
