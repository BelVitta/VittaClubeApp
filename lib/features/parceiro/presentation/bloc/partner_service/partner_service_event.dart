import 'package:equatable/equatable.dart';

import '../../../domain/entities/partner_service_entity.dart';

abstract class PartnerServiceEvent extends Equatable {
  const PartnerServiceEvent();

  @override
  List<Object?> get props => [];
}

class LoadPartnerServices extends PartnerServiceEvent {
  final String partnerId;

  const LoadPartnerServices(this.partnerId);

  @override
  List<Object?> get props => [partnerId];
}

class SearchPartnerServices extends PartnerServiceEvent {
  final String query;

  const SearchPartnerServices(this.query);

  @override
  List<Object?> get props => [query];
}

class CreatePartnerServiceRequested extends PartnerServiceEvent {
  final PartnerServiceEntity entity;

  const CreatePartnerServiceRequested(this.entity);

  @override
  List<Object?> get props => [entity];
}

class UpdatePartnerServiceRequested extends PartnerServiceEvent {
  final PartnerServiceEntity entity;

  const UpdatePartnerServiceRequested(this.entity);

  @override
  List<Object?> get props => [entity];
}

class DeletePartnerServiceRequested extends PartnerServiceEvent {
  final String id;
  final String partnerId;

  const DeletePartnerServiceRequested({required this.id, required this.partnerId});

  @override
  List<Object?> get props => [id, partnerId];
}
