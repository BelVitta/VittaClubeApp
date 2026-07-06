import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../entities/subscription_entity.dart';

/// Contrato de acesso à assinatura do usuário atual.
abstract class SubscriptionRepository {
  /// Retorna a assinatura ativa do usuário logado.
  /// `Right(null)` significa que o usuário ainda não tem plano — a UI deve
  /// exibir o card de "adquira seu plano".
  Future<Either<Failure, SubscriptionEntity?>> getCurrent();

  /// Cria uma nova assinatura após pagamento aprovado.
  Future<Either<Failure, SubscriptionEntity>> activate({
    required String planId,
    required String planLevelDb,
  });

  Future<Either<Failure, SubscriptionEntity>> createPixAutomaticSubscription({
    required String planId,
    required PixAutomaticCustomer customer,
  });

  Future<Either<Failure, PixAutomaticBillingProfile?>> getBillingProfile();

  Future<Either<Failure, PixAutomaticBillingProfile>> saveBillingProfile(
    PixAutomaticBillingProfile profile,
  );

  Future<Either<Failure, SubscriptionEntity?>> refreshSubscriptionStatus();

  Future<Either<Failure, void>> cancelSubscription({
    required String subscriptionId,
    String? reason,
  });
}

class PixAutomaticCustomer {
  final String name;
  final String taxId;
  final String email;
  final String phone;
  final PixAutomaticBillingAddress address;

  const PixAutomaticCustomer({
    required this.name,
    required this.taxId,
    required this.email,
    required this.phone,
    required this.address,
  });

  bool get isComplete =>
      name.trim().length >= 3 &&
      taxId.length == 11 &&
      email.contains('@') &&
      phone.length >= 10 &&
      address.isComplete;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'taxID': taxId,
      'email': email,
      'phone': phone,
      'address': address.toJson(),
    };
  }
}

class PixAutomaticBillingAddress extends Equatable {
  final String zipcode;
  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;

  const PixAutomaticBillingAddress({
    required this.zipcode,
    required this.street,
    required this.number,
    this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
  });

  bool get isComplete =>
      zipcode.length == 8 &&
      street.trim().isNotEmpty &&
      number.trim().isNotEmpty &&
      neighborhood.trim().isNotEmpty &&
      city.trim().isNotEmpty &&
      RegExp(r'^[A-Z]{2}$').hasMatch(state);

  Map<String, dynamic> toJson() {
    return {
      'zipcode': zipcode,
      'street': street,
      'number': number,
      if (complement != null && complement!.trim().isNotEmpty)
        'complement': complement,
      'neighborhood': neighborhood,
      'city': city,
      'state': state,
    };
  }

  @override
  List<Object?> get props => [
        zipcode,
        street,
        number,
        complement,
        neighborhood,
        city,
        state,
      ];
}

class PixAutomaticBillingProfile extends Equatable {
  final String? userId;
  final String name;
  final String taxId;
  final String email;
  final String phone;
  final PixAutomaticBillingAddress address;

  const PixAutomaticBillingProfile({
    this.userId,
    required this.name,
    required this.taxId,
    required this.email,
    required this.phone,
    required this.address,
  });

  bool get isComplete =>
      name.trim().length >= 3 &&
      taxId.length == 11 &&
      email.contains('@') &&
      phone.length >= 10 &&
      address.isComplete;

  PixAutomaticCustomer toCustomer() {
    return PixAutomaticCustomer(
      name: name,
      taxId: taxId,
      email: email,
      phone: phone,
      address: address,
    );
  }

  @override
  List<Object?> get props => [userId, name, taxId, email, phone, address];
}
