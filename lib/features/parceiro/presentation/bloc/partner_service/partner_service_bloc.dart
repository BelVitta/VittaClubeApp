import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/partner_service/get_partner_services_usecase.dart';
import '../../../domain/usecases/partner_service/create_partner_service_usecase.dart';
import '../../../domain/usecases/partner_service/update_partner_service_usecase.dart';
import '../../../domain/usecases/partner_service/delete_partner_service_usecase.dart';
import 'partner_service_event.dart';
import 'partner_service_state.dart';

class PartnerServiceBloc extends Bloc<PartnerServiceEvent, PartnerServiceState> {
  final GetPartnerServicesUseCase getPartnerServicesUseCase;
  final CreatePartnerServiceUseCase createPartnerServiceUseCase;
  final UpdatePartnerServiceUseCase updatePartnerServiceUseCase;
  final DeletePartnerServiceUseCase deletePartnerServiceUseCase;

  PartnerServiceBloc({
    required this.getPartnerServicesUseCase,
    required this.createPartnerServiceUseCase,
    required this.updatePartnerServiceUseCase,
    required this.deletePartnerServiceUseCase,
  }) : super(const PartnerServiceState()) {
    on<LoadPartnerServices>(_onLoad);
    on<SearchPartnerServices>(_onSearch);
    on<CreatePartnerServiceRequested>(_onCreate);
    on<UpdatePartnerServiceRequested>(_onUpdate);
    on<DeletePartnerServiceRequested>(_onDelete);
  }

  Future<void> _onLoad(LoadPartnerServices event, Emitter<PartnerServiceState> emit) async {
    emit(state.copyWith(status: PartnerServiceStatus.loading));
    final result = await getPartnerServicesUseCase(event.partnerId);
    result.fold(
      (failure) => emit(state.copyWith(
        status: PartnerServiceStatus.failure,
        errorMessage: failure.message,
      )),
      (items) => emit(state.copyWith(
        status: PartnerServiceStatus.loaded,
        items: items,
        filteredItems: items,
      )),
    );
  }

  void _onSearch(SearchPartnerServices event, Emitter<PartnerServiceState> emit) {
    final query = event.query.toLowerCase();
    if (query.isEmpty) {
      emit(state.copyWith(searchQuery: '', filteredItems: state.items));
    } else {
      final filtered = state.items
          .where((item) => item.name.toLowerCase().contains(query))
          .toList();
      emit(state.copyWith(searchQuery: query, filteredItems: filtered));
    }
  }

  Future<void> _onCreate(CreatePartnerServiceRequested event, Emitter<PartnerServiceState> emit) async {
    emit(state.copyWith(status: PartnerServiceStatus.saving));
    final result = await createPartnerServiceUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(
        status: PartnerServiceStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: PartnerServiceStatus.saved));
        add(LoadPartnerServices(event.entity.partnerId));
      },
    );
  }

  Future<void> _onUpdate(UpdatePartnerServiceRequested event, Emitter<PartnerServiceState> emit) async {
    emit(state.copyWith(status: PartnerServiceStatus.saving));
    final result = await updatePartnerServiceUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(
        status: PartnerServiceStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: PartnerServiceStatus.saved));
        add(LoadPartnerServices(event.entity.partnerId));
      },
    );
  }

  Future<void> _onDelete(DeletePartnerServiceRequested event, Emitter<PartnerServiceState> emit) async {
    emit(state.copyWith(status: PartnerServiceStatus.deleting));
    final result = await deletePartnerServiceUseCase(event.id);
    result.fold(
      (failure) => emit(state.copyWith(
        status: PartnerServiceStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: PartnerServiceStatus.deleted));
        add(LoadPartnerServices(event.partnerId));
      },
    );
  }
}
