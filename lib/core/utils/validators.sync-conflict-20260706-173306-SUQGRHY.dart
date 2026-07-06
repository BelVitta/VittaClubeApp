/// Validadores centralizados para formulários.
/// Usado pelo AuthState e outras features.
class Validators {
  Validators._();

  /// Valida nome (mínimo 3 caracteres)
  static bool isValidName(String name) => name.trim().length >= 3;

  /// Valida CPF (11 dígitos numéricos)
  static bool isValidCpf(String cpf) {
    final numbers = cpf.replaceAll(RegExp(r'\D'), '');
    return numbers.length == 11;
  }

  /// Valida telefone (mínimo 10 dígitos)
  static bool isValidPhone(String phone) {
    final numbers = phone.replaceAll(RegExp(r'\D'), '');
    return numbers.length >= 10;
  }

  /// Valida formato de e-mail
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Valida senha (mínimo 6 caracteres)
  static bool isValidPassword(String password) => password.length >= 6;

  /// Verifica se senhas coincidem
  static bool passwordsMatch(String password, String confirmPassword) {
    return confirmPassword == password && confirmPassword.isNotEmpty;
  }

  /// Valida número inteiro positivo para configurações operacionais.
  static bool isPositiveInteger(String value) {
    final parsed = int.tryParse(value.trim());
    return parsed != null && parsed > 0;
  }

  static String? positiveIntegerMessage(
    String? value, {
    String fieldName = 'Valor',
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe $fieldName.';
    }

    if (!isPositiveInteger(value)) {
      return '$fieldName deve ser um número inteiro maior que zero.';
    }

    return null;
  }
}
