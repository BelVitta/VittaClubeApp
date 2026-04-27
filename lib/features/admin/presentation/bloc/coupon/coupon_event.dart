import 'package:equatable/equatable.dart';
import '../../../domain/entities/coupon_entity.dart';

abstract class CouponEvent extends Equatable {
  const CouponEvent();
  @override
  List<Object?> get props => [];
}

class LoadCoupons extends CouponEvent {}

class SearchCoupons extends CouponEvent {
  final String query;
  const SearchCoupons(this.query);
  @override
  List<Object?> get props => [query];
}

class CreateCouponRequested extends CouponEvent {
  final CouponEntity entity;
  const CreateCouponRequested(this.entity);
  @override
  List<Object?> get props => [entity];
}

class UpdateCouponRequested extends CouponEvent {
  final CouponEntity entity;
  const UpdateCouponRequested(this.entity);
  @override
  List<Object?> get props => [entity];
}

class DeleteCouponRequested extends CouponEvent {
  final String id;
  const DeleteCouponRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class FilterCouponsByStatus extends CouponEvent {
  final bool? isActive;
  const FilterCouponsByStatus(this.isActive);
  @override
  List<Object?> get props => [isActive];
}

class ClearCouponFilters extends CouponEvent {}
