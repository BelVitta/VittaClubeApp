import 'package:integration_test/integration_test.dart';
import 'package:patrol/patrol.dart';
import 'package:vita_clube/main_dev.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  patrolTest(
    'novo usuário vê onboarding, pula e chega na tela de login',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      // Splash aguarda ~2s antes de decidir a rota.
      await $('Pular').waitUntilVisible(timeout: const Duration(seconds: 6));
      await $('Pular').tap();
      await $.pumpAndSettle();

      expect($('Entrar').visible, true);
      expect($('E-mail').visible, true);
      expect($('Senha').visible, true);
    },
  );
}
