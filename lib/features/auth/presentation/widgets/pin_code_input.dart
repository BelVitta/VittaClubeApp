import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget para entrada de código PIN com 6 dígitos
/// Usado na verificação de código de recuperação de senha
class PinCodeInput extends StatefulWidget {
  final Function(String) onCompleted;
  final Function(String) onChanged;
  final int length;

  const PinCodeInput({
    super.key,
    required this.onCompleted,
    required this.onChanged,
    this.length = 6,
  });

  @override
  State<PinCodeInput> createState() => _PinCodeInputState();
}

class _PinCodeInputState extends State<PinCodeInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  String _code = '';

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (index) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty) {
      // Move para o próximo campo se houver
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Último campo - remove foco
        _focusNodes[index].unfocus();
      }
    }

    // Atualiza o código completo
    _code = _controllers.map((c) => c.text).join();
    widget.onChanged(_code);

    // Se todos os campos estiverem preenchidos, chama onCompleted
    if (_code.length == widget.length) {
      widget.onCompleted(_code);
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        // Move para o campo anterior
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.length,
        (index) => Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: index == 0
                  ? 0
                  : index == widget.length - 1
                      ? 0
                      : 5,
            ),
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) => _onKeyEvent(index, event),
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF031535),
                  letterSpacing: 0.12,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF6F8FE),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: Color(0xFFDDDFE5),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: Color(0xFFDDDFE5),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                  ),
                ),
                onChanged: (value) => _onChanged(index, value),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
