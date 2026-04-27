import 'package:url_launcher/url_launcher.dart';

import '../di/injection_container.dart';
import 'clinic_settings_service.dart';

/// Abre o WhatsApp via `wa.me/{numero}?text={msg}`.
/// Se o profissional tiver número próprio, usa ele; caso contrário, cai no
/// número global da clínica (configurado em `clinic_settings`).
class WhatsAppLauncher {
  static Future<WhatsAppLaunchResult> open({
    String? professionalNumber,
    String? presetMessage,
  }) async {
    final number = await _resolveNumber(professionalNumber);
    if (number == null || number.isEmpty) {
      return WhatsAppLaunchResult.missingNumber;
    }

    final sanitized = _sanitize(number);
    final query = presetMessage == null
        ? ''
        : '?text=${Uri.encodeComponent(presetMessage)}';
    final uri = Uri.parse('https://wa.me/$sanitized$query');

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    return launched
        ? WhatsAppLaunchResult.ok
        : WhatsAppLaunchResult.launchFailed;
  }

  static Future<String?> _resolveNumber(String? professionalNumber) async {
    if (professionalNumber != null && professionalNumber.trim().isNotEmpty) {
      return professionalNumber.trim();
    }
    return sl<ClinicSettingsService>()
        .get(ClinicSettingsService.kDefaultWhatsapp);
  }

  /// Remove tudo que não for dígito (wa.me aceita só números).
  static String _sanitize(String raw) => raw.replaceAll(RegExp(r'\D'), '');
}

enum WhatsAppLaunchResult {
  ok,
  missingNumber,
  launchFailed,
}
