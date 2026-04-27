import 'package:equatable/equatable.dart';
import '../../domain/entities/badge_progress_entity.dart';

enum BadgeProgressStatus {
  initial,
  loading,
  loaded,
  upgraded,
  failure,
}

class BadgeProgressState extends Equatable {
  final BadgeProgressStatus status;
  final BadgeProgressEntity? progress;
  final String? previousLevel;
  final String? errorMessage;

  const BadgeProgressState({
    this.status = BadgeProgressStatus.initial,
    this.progress,
    this.previousLevel,
    this.errorMessage,
  });

  BadgeProgressState copyWith({
    BadgeProgressStatus? status,
    BadgeProgressEntity? progress,
    String? previousLevel,
    String? errorMessage,
  }) {
    return BadgeProgressState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      previousLevel: previousLevel ?? this.previousLevel,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, progress, previousLevel, errorMessage];
}
