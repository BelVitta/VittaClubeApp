import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/primary_button.dart';

/// Bottom sheet com termos e condições / política de privacidade
class TermsBottomSheet extends StatelessWidget {
  const TermsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seus dados pessoais são processados para realizar transações, fornecer suporte e para fins estatísticos. '
            'Também podemos usar seus dados para comunicação de marketing, caso você concorde; '
            'o consentimento é voluntário e pode ser revogado a qualquer momento, '
            'clicando no link "cancelar inscrição" em nossos e-mails '
            'ou entrando em contato com o Suporte ao Cliente. '
            'Se você criar uma conta no Vita Clube, poderemos processar mais dados pessoais, '
            'conforme descrito em nossa Política de Privacidade.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6D7F95),
              height: 1.4,
              letterSpacing: 0.065,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Fechar',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
