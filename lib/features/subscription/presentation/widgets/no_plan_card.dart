import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

/// Card chamativo exibido no topo do home quando o usuário ainda não tem
/// assinatura ativa. Convida a assinar, já mostrando o valor do plano mais
/// barato, e leva direto para o pagamento.
class NoPlanCard extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback? onClose;

  /// Preço formatado do plano mais barato (ex: "R\$ 49,90/mês"). `null`
  /// enquanto os planos ainda estão carregando.
  final String? priceLabel;

  const NoPlanCard(
      {super.key, required this.onTap, this.onClose, this.priceLabel});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.85),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Faça parte do Vita Clube',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.075,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tenha acesso a benefícios exclusivos por um único valor mensal.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.3,
                      ),
                    ),
                    if (priceLabel != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Plano completo por apenas $priceLabel',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.08,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Assinar agora',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.065,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                Align(
                  alignment: Alignment.topCenter,
                  child: IconButton(
                    onPressed: onClose,
                    tooltip: 'Fechar',
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
