/// Validadores centralizados para formulários.
/// Usado pelo AuthState e outras features.
class Validators {
  Validators._();

  /// Valida nome (mínimo 3 caracteres)
  static bool isValidName(String name) => name.trim().length >= 3;

  /// Valida CPF: 11 dígitos, não repetidos, com dígitos verificadores corretos.
  static bool isValidCpf(String cpf) {
    final numbers = cpf.replaceAll(RegExp(r'\D'), '');
    if (numbers.length != 11) return false;
    if (RegExp(r'^(\d)\1*$').hasMatch(numbers)) return false;

    final digits = numbers.split('').map(int.parse).toList();

    int calculateDigit(List<int> base) {
      var sum = 0;
      var weight = base.length + 1;
      for (final digit in base) {
        sum += digit * weight;
        weight--;
      }
      final remainder = sum % 11;
      return remainder < 2 ? 0 : 11 - remainder;
    }

    final firstCheck = calculateDigit(digits.sublist(0, 9));
    if (firstCheck != digits[9]) return false;

    final secondCheck = calculateDigit(digits.sublist(0, 10));
    if (secondCheck != digits[10]) return false;

    return true;
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
}
