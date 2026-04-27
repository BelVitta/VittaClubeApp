import 'package:equatable/equatable.dart';

/// Entidade que representa uma ação rápida no dashboard
class QuickActionEntity extends Equatable {
  final String id;
  final String title;
  final String iconUrl;
  final String route;

  const QuickActionEntity({
    required this.id,
    required this.title,
    required this.iconUrl,
    required this.route,
  });

  @override
  List<Object?> get props => [id, title, iconUrl, route];
}
