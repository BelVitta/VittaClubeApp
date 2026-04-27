/// Servico que calcula descontos baseados no badge do usuario.
///
/// Tabela de descontos (spec):
/// - Bronze: 10%
/// - Prata: 15%
/// - Ouro: 20%
/// - Diamante: 30%
class DiscountService {
  final double discountPercentage;
  final bool isEligibleForDiscount;

  const DiscountService({
    required this.discountPercentage,
    required this.isEligibleForDiscount,
  });

  /// Calcula o valor com desconto
  double calculateDiscountedPrice(double originalPrice) {
    if (!isEligibleForDiscount) return originalPrice;
    final discount = originalPrice * (discountPercentage / 100);
    return originalPrice - discount;
  }

  /// Valor do desconto em reais
  double calculateDiscountAmount(double originalPrice) {
    if (!isEligibleForDiscount) return 0.0;
    return originalPrice * (discountPercentage / 100);
  }

  /// Retorna o desconto padrao por nivel de badge
  static double getDefaultDiscount(String badgeLevel) {
    switch (badgeLevel.toLowerCase()) {
      case 'bronze':
        return 10.0;
      case 'silver':
      case 'prata':
        return 15.0;
      case 'gold':
      case 'ouro':
        return 20.0;
      case 'diamond':
      case 'diamante':
        return 30.0;
      default:
        return 0.0;
    }
  }

  /// Formata o desconto como string
  String get formattedDiscount => '${discountPercentage.toStringAsFixed(0)}%';

  /// Formata um preco em reais
  static String formatPrice(double price) {
    return 'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}
