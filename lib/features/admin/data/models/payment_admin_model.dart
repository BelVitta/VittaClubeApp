import '../../domain/entities/payment_admin_entity.dart';

/// Model de pagamento admin - DTO para serialização.
/// Estende PaymentAdminEntity e adiciona métodos fromJson/toJson.
class PaymentAdminModel extends PaymentAdminEntity {
  const PaymentAdminModel({
    required super.id,
    required super.userId,
    required super.userName,
    required super.planName,
    required super.amount,
    required super.method,
    required super.status,
    required super.date,
    required super.receiptNumber,
  });

  /// Cria PaymentAdminModel a partir de JSON
  factory PaymentAdminModel.fromJson(Map<String, dynamic> json) {
    return PaymentAdminModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      planName: json['planName'] as String,
      amount: (json['amount'] as num).toDouble(),
      method: json['method'] as String,
      status: json['status'] as String,
      date: json['date'] as String,
      receiptNumber: json['receiptNumber'] as String,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'planName': planName,
      'amount': amount,
      'method': method,
      'status': status,
      'date': date,
      'receiptNumber': receiptNumber,
    };
  }

  /// Cria PaymentAdminModel a partir de PaymentAdminEntity
  factory PaymentAdminModel.fromEntity(PaymentAdminEntity entity) {
    return PaymentAdminModel(
      id: entity.id,
      userId: entity.userId,
      userName: entity.userName,
      planName: entity.planName,
      amount: entity.amount,
      method: entity.method,
      status: entity.status,
      date: entity.date,
      receiptNumber: entity.receiptNumber,
    );
  }
}
