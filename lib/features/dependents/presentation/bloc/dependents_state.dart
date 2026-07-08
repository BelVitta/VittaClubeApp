import 'package:equatable/equatable.dart';

import '../../domain/usecases/get_dependents_usecase.dart';

enum DependentsStatus { initial, loading, loaded, saving, saved, failure }

class DependentsState extends Equatable {
  final DependentsStatus status;
  final List<DependentWithQuota> items;
  final String? errorMessage;
  final bool limitReached;

  const DependentsState({
    this.status = DependentsStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.limitReached = false,
  });

  DependentsState copyWith({
    DependentsStatus? status,
    List<DependentWithQuota>? items,
    String? errorMessage,
    bool? limitReached,
  }) {
    return DependentsState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
      limitReached: limitReached ?? this.limitReached,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage, limitReached];
}
