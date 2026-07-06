import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/subscription_guard.dart';
import '../../core/theme/app_theme.dart';

/// Widget que envolve funcionalidades bloqueadas por inadimplencia.
/// Exibe um overlay com mensagem quando o acesso e negado.
class SubscriptionGuardWidget extends StatelessWidget {
  final SubscriptionGuard guard;
  final String featureName;
  final bool Function(SubscriptionGuard) checkAccess;
  final Widget child;

  const SubscriptionGuardWidget({
    super.key,
    required this.guard,
    required this.featureName,
    required this.checkAccess,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (checkAccess(guard)) {
      return child;
    }

    return Stack(
      children: [
        Opacity(opacity: 0.3, child: IgnorePointer(child: child)),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      guard.isCancelado
                          ? Icons.cancel_outlined
                          : Icons.lock_outline,
                      size: 40,
                      color: guard.isCancelado
                          ? AppTheme.secondaryText
                          : const Color(0xFFE8872B),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      guard.getBlockedMessage(featureName),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    if (guard.isInadimplente) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          // TODO: Navegar para pagina de pagamento
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Regularizar Pagamento',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dialog de bloqueio por inadimplencia.
/// Usar quando o usuario tenta acessar funcionalidade bloqueada.
void showSubscriptionBlockedDialog(
    BuildContext context, SubscriptionGuard guard, String featureName) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            guard.isCancelado ? Icons.cancel_outlined : Icons.lock_outline,
            color: guard.isCancelado
                ? AppTheme.secondaryText
                : const Color(0xFFE8872B),
          ),
          const SizedBox(width: 8),
          Text(
            'Acesso Bloqueado',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryText,
            ),
          ),
        ],
      ),
      content: Text(
        guard.getBlockedMessage(featureName),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: AppTheme.secondaryText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Fechar',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (guard.isInadimplente)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navegar para pagina de pagamento
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Regularizar',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
      ],
    ),
  );
}
