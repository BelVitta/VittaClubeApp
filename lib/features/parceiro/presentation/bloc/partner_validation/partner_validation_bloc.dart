import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/partner_validation/get_partner_validations_usecase.dart';
import 'partner_validation_event.dart';
import 'partner_validation_state.dart';

class PartnerValidationBloc extends Bloc<PartnerValidationEvent, PartnerValidationState> {
  final GetPartnerValidationsUseCase getPartnerValidationsUseCase;

  PartnerValidationBloc({
    required this.getPartnerValidationsUseCase,
  }) : super(const PartnerValidationState()) {
    on<LoadPartnerValidations>(_onLoad);
    on<SearchPartnerValidations>(_onSearch);
  }

  Future<void> _onLoad(LoadPartnerValidations event, Emitter<PartnerValidationState> emit) async {
    emit(state.copyWith(status: PartnerValidationStatus.loading));
    final result = await getPartnerValidationsUseCase(event.partnerId);
    result.fold(
      (failure) => emit(state.copyWith(
        status: PartnerValidationStatus.failure,
        errorMessage: failure.message,
      )),
      (items) => emit(state.copyWith(
        status: PartnerValidationStatus.loaded,
        items: items,
        filteredItems: items,
      )),
    );
  }

  void _onSearch(SearchPartnerValidations event, Emitter<PartnerValidationState> emit) {
    final query = event.query.toLowerCase();
    if (query.isEmpty) {
      emit(state.copyWith(searchQuery: '', filteredItems: state.items));
    } else {
      final filtered = state.items
          .where((item) =>
              item.userName.toLowerCase().contains(query) ||
              item.serviceName.toLowerCase().contains(query))
          .toList();
      emit(state.copyWith(searchQuery: query, filteredItems: filtered));
    }
  }
}
