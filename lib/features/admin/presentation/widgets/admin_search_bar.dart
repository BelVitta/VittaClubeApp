import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Barra de pesquisa com debounce de 300ms para o módulo admin.
/// Inclui ícone de busca, hint "Pesquisar..." e botão limpar.
class AdminSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String? hintText;

  const AdminSearchBar({
    super.key,
    required this.onChanged,
    this.hintText,
  });

  @override
  State<AdminSearchBar> createState() => _AdminSearchBarState();
}

class _AdminSearchBarState extends State<AdminSearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      widget.onChanged(value);
    });
    // Rebuild para mostrar/esconder o botão limpar
    setState(() {});
  }

  void _onClear() {
    _controller.clear();
    _debounceTimer?.cancel();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDDFE5)),
      ),
      child: TextField(
        controller: _controller,
        onChanged: _onChanged,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppTheme.primaryColor,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Pesquisar...',
          hintStyle: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D7F95),
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: Color(0xFF6D7F95),
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: _onClear,
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFF6D7F95),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
