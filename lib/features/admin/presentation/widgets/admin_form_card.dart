import 'package:flutter/material.dart';

/// Container de formulário com fundo branco, borda e bordas arredondadas.
/// Envolve campos de formulário no módulo admin.
class AdminFormCard extends StatelessWidget {
  final Widget child;

  const AdminFormCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEEF2)),
      ),
      child: child,
    );
  }
}
