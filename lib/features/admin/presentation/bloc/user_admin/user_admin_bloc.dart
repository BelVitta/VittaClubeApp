import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/user_admin_entity.dart';
import '../../../domain/usecases/user_admin/get_users_usecase.dart';
import '../../../domain/usecases/user_admin/create_user_usecase.dart';
import '../../../domain/usecases/user_admin/update_user_usecase.dart';
import '../../../domain/usecases/user_admin/delete_user_usecase.dart';
import 'user_admin_event.dart';
import 'user_admin_state.dart';

class UserAdminBloc extends Bloc<UserAdminEvent, UserAdminState> {
  final GetUsersUseCase getUsersUseCase;
  final CreateUserUseCase createUserUseCase;
  final UpdateUserUseCase updateUserUseCase;
  final DeleteUserUseCase deleteUserUseCase;

  UserAdminBloc({
    required this.getUsersUseCase,
    required this.createUserUseCase,
    required this.updateUserUseCase,
    required this.deleteUserUseCase,
  }) : super(const UserAdminState()) {
    on<LoadUsers>(_onLoad);
    on<SearchUsers>(_onSearch);
    on<CreateUserRequested>(_onCreate);
    on<UpdateUserRequested>(_onUpdate);
    on<DeleteUserRequested>(_onDelete);
    on<FilterUsersByStatus>(_onFilterByStatus);
    on<FilterUsersByLevel>(_onFilterByLevel);
    on<ClearUserFilters>(_onClearFilters);
  }

  Future<void> _onLoad(LoadUsers event, Emitter<UserAdminState> emit) async {
    emit(state.copyWith(status: UserAdminStatus.loading));
    final result = await getUsersUseCase();
    result.fold(
      (failure) => emit(state.copyWith(
        status: UserAdminStatus.failure,
        errorMessage: failure.message,
      )),
      (items) => emit(state.copyWith(
        status: UserAdminStatus.loaded,
        items: items,
        filteredItems: items,
      )),
    );
  }

  void _onSearch(SearchUsers event, Emitter<UserAdminState> emit) {
    final newState = state.copyWith(searchQuery: event.query);
    emit(newState.copyWith(filteredItems: _applyFilters(newState)));
  }

  void _onFilterByStatus(FilterUsersByStatus event, Emitter<UserAdminState> emit) {
    final newState = state.copyWith(
      filterStatus: event.status,
      clearFilterStatus: event.status == null,
    );
    emit(newState.copyWith(filteredItems: _applyFilters(newState)));
  }

  void _onFilterByLevel(FilterUsersByLevel event, Emitter<UserAdminState> emit) {
    final newState = state.copyWith(
      filterLevel: event.level,
      clearFilterLevel: event.level == null,
    );
    emit(newState.copyWith(filteredItems: _applyFilters(newState)));
  }

  void _onClearFilters(ClearUserFilters event, Emitter<UserAdminState> emit) {
    final newState = state.copyWith(
      searchQuery: '',
      clearFilterStatus: true,
      clearFilterLevel: true,
    );
    emit(newState.copyWith(filteredItems: newState.items));
  }

  List<UserAdminEntity> _applyFilters(UserAdminState s) {
    var result = s.items.toList();

    if (s.searchQuery.isNotEmpty) {
      final query = s.searchQuery.toLowerCase();
      result = result.where((item) =>
          item.name.toLowerCase().contains(query) ||
          item.email.toLowerCase().contains(query)).toList();
    }

    if (s.filterStatus != null) {
      result = result.where((item) => item.status == s.filterStatus).toList();
    }

    if (s.filterLevel != null) {
      result = result.where((item) => item.planLevelName == s.filterLevel).toList();
    }

    return result;
  }

  Future<void> _onCreate(CreateUserRequested event, Emitter<UserAdminState> emit) async {
    emit(state.copyWith(status: UserAdminStatus.saving));
    final result = await createUserUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(
        status: UserAdminStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: UserAdminStatus.saved));
        add(LoadUsers());
      },
    );
  }

  Future<void> _onUpdate(UpdateUserRequested event, Emitter<UserAdminState> emit) async {
    emit(state.copyWith(status: UserAdminStatus.saving));
    final result = await updateUserUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(
        status: UserAdminStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: UserAdminStatus.saved));
        add(LoadUsers());
      },
    );
  }

  Future<void> _onDelete(DeleteUserRequested event, Emitter<UserAdminState> emit) async {
    emit(state.copyWith(status: UserAdminStatus.deleting));
    final result = await deleteUserUseCase(event.id);
    result.fold(
      (failure) => emit(state.copyWith(
        status: UserAdminStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: UserAdminStatus.deleted));
        add(LoadUsers());
      },
    );
  }
}
