/// Enum que representa os tipos de assinatura disponíveis
enum SubscriptionType {
  monthly('Mensal', 34.99, null),
  semiannual('Semestral', 29.99, '30% Off'),
  annual('Anual', 29.99, null);

  final String displayName;
  final double price;
  final String? discount;

  const SubscriptionType(this.displayName, this.price, this.discount);

  /// Retorna o preço formatado
  String get formattedPrice =>
      'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';

  /// Verifica se tem desconto
  bool get hasDiscount => discount != null;
}
