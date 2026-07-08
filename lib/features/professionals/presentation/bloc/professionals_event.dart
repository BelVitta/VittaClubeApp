import 'package:equatable/equatable.dart';

abstract class ProfessionalsEvent extends Equatable {
  const ProfessionalsEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfessionals extends ProfessionalsEvent {
  const LoadProfessionals();
}
