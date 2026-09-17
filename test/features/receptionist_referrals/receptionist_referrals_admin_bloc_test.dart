import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/core/error/failures.dart';
import 'package:vita_clube/features/receptionist_referrals/domain/entities/receptionist_referral_entity.dart';
import 'package:vita_clube/features/receptionist_referrals/domain/usecases/correct_referral_attribution_usecase.dart';
import 'package:vita_clube/features/receptionist_referrals/domain/usecases/get_referrals_usecase.dart';
import 'package:vita_clube/features/receptionist_referrals/presentation/bloc/receptionist_referrals_admin_bloc.dart';
import 'package:vita_clube/features/receptionist_referrals/presentation/bloc/receptionist_referrals_admin_event.dart';
import 'package:vita_clube/features/receptionist_referrals/presentation/bloc/receptionist_referrals_admin_state.dart';

class MockGetReceptionistReferralsUseCase extends Mock
    implements GetReceptionistReferralsUseCase {}

class MockCorrectReferralAttributionUseCase extends Mock
    implements CorrectReferralAttributionUseCase {}

void main() {
  late ReceptionistReferralsAdminBloc bloc;
  late MockGetReceptionistReferralsUseCase mockGetReferrals;
  late MockCorrectReferralAttributionUseCase mockCorrectAttribution;

  ReceptionistReferralEntity buildReferral({
    required String id,
    required String referredUserName,
    required String referredUserEmail,
    ReceptionistReferralStatus status = ReceptionistReferralStatus.pending,
  }) {
    return ReceptionistReferralEntity(
      id: id,
      receptionistId: 'r1',
      receptionistName: 'Maria',
      referralCode: 'MAR1234',
      referredUserId: 'u_$id',
      referredUserName: referredUserName,
      referredUserEmail: referredUserEmail,
      referredMemberSince: DateTime(2026, 7, 1),
      status: status,
      createdAt: DateTime(2026, 7, 1),
    );
  }

  final tJoao = buildReferral(
      id: '1',
      referredUserName: 'João Silva',
      referredUserEmail: 'joao@teste.com');
  final tAna = buildReferral(
      id: '2',
      referredUserName: 'Ana Souza',
      referredUserEmail: 'ana@teste.com');

  setUp(() {
    mockGetReferrals = MockGetReceptionistReferralsUseCase();
    mockCorrectAttribution = MockCorrectReferralAttributionUseCase();
    bloc = ReceptionistReferralsAdminBloc(
      getReferralsUseCase: mockGetReferrals,
      correctReferralAttributionUseCase: mockCorrectAttribution,
    );
  });

  tearDown(() => bloc.close());

  blocTest<ReceptionistReferralsAdminBloc, ReceptionistReferralsAdminState>(
    'LoadReferrals emite [loading, loaded] com os itens carregados',
    build: () {
      when(() => mockGetReferrals(
            monthReference: any(named: 'monthReference'),
            receptionistId: any(named: 'receptionistId'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => Right([tJoao, tAna]));
      return bloc;
    },
    act: (b) => b.add(const LoadReferrals()),
    expect: () => [
      isA<ReceptionistReferralsAdminState>().having(
          (s) => s.status, 'status', ReceptionistReferralsAdminStatus.loading),
      isA<ReceptionistReferralsAdminState>()
          .having((s) => s.status, 'status',
              ReceptionistReferralsAdminStatus.loaded)
          .having((s) => s.items.length, 'items.length', 2)
          .having((s) => s.filteredItems.length, 'filteredItems.length', 2),
    ],
  );

  blocTest<ReceptionistReferralsAdminBloc, ReceptionistReferralsAdminState>(
    'SearchReferrals filtra por nome/e-mail do indicado em memória',
    build: () {
      when(() => mockGetReferrals(
            monthReference: any(named: 'monthReference'),
            receptionistId: any(named: 'receptionistId'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => Right([tJoao, tAna]));
      return bloc;
    },
    act: (b) async {
      b.add(const LoadReferrals());
      await Future<void>.delayed(Duration.zero);
      b.add(const SearchReferrals('ana'));
    },
    skip: 2,
    expect: () => [
      isA<ReceptionistReferralsAdminState>()
          .having((s) => s.searchQuery, 'searchQuery', 'ana')
          .having((s) => s.filteredItems.length, 'filteredItems.length', 1)
          .having((s) => s.filteredItems.first.referredUserName, 'name',
              'Ana Souza'),
    ],
  );

  blocTest<ReceptionistReferralsAdminBloc, ReceptionistReferralsAdminState>(
    'CorrectReferralAttributionRequested emite [correcting, corrected] e recarrega',
    build: () {
      when(() => mockCorrectAttribution(
            referralId: any(named: 'referralId'),
            newReceptionistId: any(named: 'newReceptionistId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async => const Right(null));
      when(() => mockGetReferrals(
            monthReference: any(named: 'monthReference'),
            receptionistId: any(named: 'receptionistId'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => Right([tJoao]));
      return bloc;
    },
    act: (b) => b.add(const CorrectReferralAttributionRequested(
      referralId: '1',
      newReceptionistId: 'r2',
      reason: 'Erro de digitação no cadastro',
    )),
    expect: () => [
      isA<ReceptionistReferralsAdminState>().having((s) => s.status, 'status',
          ReceptionistReferralsAdminStatus.correcting),
      isA<ReceptionistReferralsAdminState>().having((s) => s.status, 'status',
          ReceptionistReferralsAdminStatus.corrected),
      isA<ReceptionistReferralsAdminState>().having(
          (s) => s.status, 'status', ReceptionistReferralsAdminStatus.loading),
      isA<ReceptionistReferralsAdminState>().having(
          (s) => s.status, 'status', ReceptionistReferralsAdminStatus.loaded),
    ],
    verify: (_) {
      verify(() => mockCorrectAttribution(
            referralId: '1',
            newReceptionistId: 'r2',
            reason: 'Erro de digitação no cadastro',
          )).called(1);
    },
  );

  blocTest<ReceptionistReferralsAdminBloc, ReceptionistReferralsAdminState>(
    'CorrectReferralAttributionRequested emite [correcting, failure] quando o RPC rejeita',
    build: () {
      when(() => mockCorrectAttribution(
                referralId: any(named: 'referralId'),
                newReceptionistId: any(named: 'newReceptionistId'),
                reason: any(named: 'reason'),
              ))
          .thenAnswer((_) async => const Left(ValidationFailure(
              'Somente o financeiro pode corrigir atribuições.')));
      return bloc;
    },
    act: (b) => b.add(const CorrectReferralAttributionRequested(
      referralId: '1',
      newReceptionistId: 'r1',
      reason: 'Tentativa de autoindicação',
    )),
    expect: () => [
      isA<ReceptionistReferralsAdminState>().having((s) => s.status, 'status',
          ReceptionistReferralsAdminStatus.correcting),
      isA<ReceptionistReferralsAdminState>()
          .having((s) => s.status, 'status',
              ReceptionistReferralsAdminStatus.failure)
          .having((s) => s.errorMessage, 'errorMessage',
              'Somente o financeiro pode corrigir atribuições.'),
    ],
  );
}
