import 'package:equatable/equatable.dart';

abstract class BadgeProgressEvent extends Equatable {
  const BadgeProgressEvent();
  @override
  List<Object?> get props => [];
}

class LoadBadgeProgress extends BadgeProgressEvent {
  final String userId;
  const LoadBadgeProgress(this.userId);
  @override
  List<Object?> get props => [userId];
}

class CheckBadgeUpgrade extends BadgeProgressEvent {
  final String userId;
  const CheckBadgeUpgrade(this.userId);
  @override
  List<Object?> get props => [userId];
}
