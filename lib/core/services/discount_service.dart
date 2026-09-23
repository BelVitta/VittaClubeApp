import 'badge_catalog_service.dart';

/// Serviço que calcula descontos publicados para a patente do usuário.
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

  /// Retorna o desconto publicado pelo financeiro para a patente.
  static double getDefaultDiscount(String badgeLevel) {
    return BadgeCatalogService.discountFor(badgeLevel);
  }

  /// Formata o desconto como string
  String get formattedDiscount => '${discountPercentage.toStringAsFixed(0)}%';

  /// Formata um preco em reais
  static String formatPrice(double price) {
    return 'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}
