import 'package:equatable/equatable.dart';

abstract class PartnerValidationEvent extends Equatable {
  const PartnerValidationEvent();

  @override
  List<Object?> get props => [];
}

class LoadPartnerValidations extends PartnerValidationEvent {
  final String partnerId;

  const LoadPartnerValidations(this.partnerId);

  @override
  List<Object?> get props => [partnerId];
}

class SearchPartnerValidations extends PartnerValidationEvent {
  final String query;

  const SearchPartnerValidations(this.query);

  @override
  List<Object?> get props => [query];
}
