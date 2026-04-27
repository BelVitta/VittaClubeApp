import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_current_profile_usecase.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetCurrentProfileUseCase getCurrentProfileUseCase;

  ProfileBloc({required this.getCurrentProfileUseCase})
      : super(const ProfileInitial()) {
    on<LoadCurrentProfile>(_onLoad);
  }

  Future<void> _onLoad(
    LoadCurrentProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    final result = await getCurrentProfileUseCase();
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (profile) {
        if (profile == null) {
          emit(const ProfileError('Usuário não autenticado.'));
        } else {
          emit(ProfileLoaded(profile));
        }
      },
    );
  }
}
