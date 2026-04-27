import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/notification_template/get_notification_templates_usecase.dart';
import '../../../domain/usecases/notification_template/create_notification_template_usecase.dart';
import '../../../domain/usecases/notification_template/update_notification_template_usecase.dart';
import '../../../domain/usecases/notification_template/delete_notification_template_usecase.dart';
import '../../../domain/entities/notification_template_entity.dart';
import 'notification_template_event.dart';
import 'notification_template_state.dart';

class NotificationTemplateBloc extends Bloc<NotificationTemplateEvent, NotificationTemplateState> {
  final GetNotificationTemplatesUseCase getNotificationTemplatesUseCase;
  final CreateNotificationTemplateUseCase createNotificationTemplateUseCase;
  final UpdateNotificationTemplateUseCase updateNotificationTemplateUseCase;
  final DeleteNotificationTemplateUseCase deleteNotificationTemplateUseCase;

  NotificationTemplateBloc({
    required this.getNotificationTemplatesUseCase,
    required this.createNotificationTemplateUseCase,
    required this.updateNotificationTemplateUseCase,
    required this.deleteNotificationTemplateUseCase,
  }) : super(const NotificationTemplateState()) {
    on<LoadNotificationTemplates>(_onLoad);
    on<SearchNotificationTemplates>(_onSearch);
    on<CreateNotificationTemplateRequested>(_onCreate);
    on<UpdateNotificationTemplateRequested>(_onUpdate);
    on<DeleteNotificationTemplateRequested>(_onDelete);
    on<FilterNotificationsByType>(_onFilterByType);
    on<FilterNotificationsByStatus>(_onFilterByStatus);
    on<ClearNotificationFilters>(_onClearFilters);
  }

  Future<void> _onLoad(LoadNotificationTemplates event, Emitter<NotificationTemplateState> emit) async {
    emit(state.copyWith(status: NotificationTemplateStatus.loading));
    final result = await getNotificationTemplatesUseCase();
    result.fold(
      (failure) => emit(state.copyWith(status: NotificationTemplateStatus.failure, errorMessage: failure.message)),
      (items) => emit(state.copyWith(status: NotificationTemplateStatus.loaded, items: items, filteredItems: items)),
    );
  }

  void _onSearch(SearchNotificationTemplates event, Emitter<NotificationTemplateState> emit) {
    final newState = state.copyWith(searchQuery: event.query);
    emit(newState.copyWith(filteredItems: _applyFilters(newState)));
  }

  void _onFilterByType(FilterNotificationsByType event, Emitter<NotificationTemplateState> emit) {
    final newState = state.copyWith(
      filterType: event.type,
      clearType: event.type == null,
    );
    emit(newState.copyWith(filteredItems: _applyFilters(newState)));
  }

  void _onFilterByStatus(FilterNotificationsByStatus event, Emitter<NotificationTemplateState> emit) {
    final newState = state.copyWith(
      filterIsActive: event.isActive,
      clearIsActive: event.isActive == null,
    );
    emit(newState.copyWith(filteredItems: _applyFilters(newState)));
  }

  void _onClearFilters(ClearNotificationFilters event, Emitter<NotificationTemplateState> emit) {
    final newState = state.copyWith(
      searchQuery: '',
      clearType: true,
      clearIsActive: true,
    );
    emit(newState.copyWith(filteredItems: newState.items));
  }

  List<NotificationTemplateEntity> _applyFilters(NotificationTemplateState s) {
    var result = s.items.toList();

    if (s.searchQuery.isNotEmpty) {
      final query = s.searchQuery.toLowerCase();
      result = result.where((item) =>
          item.title.toLowerCase().contains(query) ||
          item.body.toLowerCase().contains(query)).toList();
    }

    if (s.filterType != null) {
      result = result.where((item) => item.type == s.filterType).toList();
    }

    if (s.filterIsActive != null) {
      result = result.where((item) => item.isActive == s.filterIsActive).toList();
    }

    return result;
  }

  Future<void> _onCreate(CreateNotificationTemplateRequested event, Emitter<NotificationTemplateState> emit) async {
    emit(state.copyWith(status: NotificationTemplateStatus.saving));
    final result = await createNotificationTemplateUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(status: NotificationTemplateStatus.failure, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(status: NotificationTemplateStatus.saved));
        add(LoadNotificationTemplates());
      },
    );
  }

  Future<void> _onUpdate(UpdateNotificationTemplateRequested event, Emitter<NotificationTemplateState> emit) async {
    emit(state.copyWith(status: NotificationTemplateStatus.saving));
    final result = await updateNotificationTemplateUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(status: NotificationTemplateStatus.failure, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(status: NotificationTemplateStatus.saved));
        add(LoadNotificationTemplates());
      },
    );
  }

  Future<void> _onDelete(DeleteNotificationTemplateRequested event, Emitter<NotificationTemplateState> emit) async {
    emit(state.copyWith(status: NotificationTemplateStatus.deleting));
    final result = await deleteNotificationTemplateUseCase(event.id);
    result.fold(
      (failure) => emit(state.copyWith(status: NotificationTemplateStatus.failure, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(status: NotificationTemplateStatus.deleted));
        add(LoadNotificationTemplates());
      },
    );
  }
}
