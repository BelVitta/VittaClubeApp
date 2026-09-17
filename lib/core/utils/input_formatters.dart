import 'package:flutter/services.dart';

/// Formata CPF enquanto o usuário digita: 000.000.000-00.
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final text = digits.length > 11 ? digits.substring(0, 11) : digits;
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 2 || i == 5) {
        if (i + 1 != text.length) buffer.write('.');
      } else if (i == 8) {
        if (i + 1 != text.length) buffer.write('-');
      }
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

/// Formata telefone enquanto o usuário digita: (00) 00000-0000 (celular,
/// 11 dígitos) ou (00) 0000-0000 (fixo, 10 dígitos).
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final text = digits.length > 11 ? digits.substring(0, 11) : digits;
    final isMobile = text.length > 10;
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 0) buffer.write('(');
      buffer.write(text[i]);
      if (i == 1) {
        buffer.write(') ');
      } else if ((isMobile && i == 6) || (!isMobile && i == 5)) {
        if (i + 1 != text.length) buffer.write('-');
      }
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
