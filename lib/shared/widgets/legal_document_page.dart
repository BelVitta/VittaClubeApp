import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

/// Exibe Política ou Termos a partir dos arquivos em assets/legal/.
class LegalDocumentPage extends StatelessWidget {
  final String title;
  final String assetPath;

  const LegalDocumentPage({
    super.key,
    required this.title,
    required this.assetPath,
  });

  static const privacyAsset = 'assets/legal/politica-de-privacidade.md';
  static const termsAsset = 'assets/legal/termos-de-uso.md';

  static Future<void> openPrivacy(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LegalDocumentPage(
          title: 'Política de Privacidade',
          assetPath: privacyAsset,
        ),
      ),
    );
  }

  static Future<void> openTerms(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LegalDocumentPage(
          title: 'Termos de Uso',
          assetPath: termsAsset,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryColor),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: SelectableText(
              snapshot.data!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.5,
                color: const Color(0xFF2C4156),
              ),
            ),
          );
        },
      ),
    );
  }
}
