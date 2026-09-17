import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/core/error/failures.dart';
import 'package:vita_clube/features/receptionist_referrals/domain/entities/receptionist_ranking_entry_entity.dart';
import 'package:vita_clube/features/receptionist_referrals/domain/usecases/get_monthly_ranking_usecase.dart';
import 'package:vita_clube/features/receptionist_referrals/presentation/bloc/receptionist_ranking_bloc.dart';
import 'package:vita_clube/features/receptionist_referrals/presentation/bloc/receptionist_ranking_event.dart';
import 'package:vita_clube/features/receptionist_referrals/presentation/bloc/receptionist_ranking_state.dart';

class MockGetMonthlyRankingUseCase extends Mock
    implements GetMonthlyRankingUseCase {}

void main() {
  late ReceptionistRankingBloc bloc;
  late MockGetMonthlyRankingUseCase mockGetMonthlyRanking;

  const tEntries = [
    ReceptionistRankingEntryEntity(
      position: 1,
      receptionistId: 'r1',
      receptionistName: 'Maria',
      receptionistCode: 'MAR1234',
      indicacoesCount: 5,
      conversoesCount: 3,
      totalGerado: 104.70,
    ),
    ReceptionistRankingEntryEntity(
      position: 2,
      receptionistId: 'r2',
      receptionistName: 'João',
      receptionistCode: 'JOA5678',
      indicacoesCount: 2,
      conversoesCount: 1,
      totalGerado: 34.90,
    ),
  ];

  setUp(() {
    mockGetMonthlyRanking = MockGetMonthlyRankingUseCase();
    bloc = ReceptionistRankingBloc(
        getMonthlyRankingUseCase: mockGetMonthlyRanking);
  });

  tearDown(() => bloc.close());

  test(
      'estado inicial usa o mês corrente e sem usuário logado (Supabase não inicializado)',
      () {
    expect(bloc.state.status, ReceptionistRankingStatus.initial);
    expect(bloc.state.currentUserId, isNull);
    expect(bloc.state.entries, isEmpty);
  });

  blocTest<ReceptionistRankingBloc, ReceptionistRankingState>(
    'LoadReceptionistRanking emite [loading, loaded] com as entradas ordenadas',
    build: () {
      when(() => mockGetMonthlyRanking(any()))
          .thenAnswer((_) async => const Right(tEntries));
      return bloc;
    },
    act: (b) => b.add(const LoadReceptionistRanking(monthReference: '2026-07')),
    expect: () => [
      isA<ReceptionistRankingState>()
          .having((s) => s.status, 'status', ReceptionistRankingStatus.loading)
          .having((s) => s.monthReference, 'monthReference', '2026-07'),
      isA<ReceptionistRankingState>()
          .having((s) => s.status, 'status', ReceptionistRankingStatus.loaded)
          .having((s) => s.entries, 'entries', tEntries),
    ],
    verify: (_) {
      verify(() => mockGetMonthlyRanking('2026-07')).called(1);
    },
  );

  blocTest<ReceptionistRankingBloc, ReceptionistRankingState>(
    'LoadReceptionistRanking emite [loading, failure] quando o usecase falha',
    build: () {
      when(() => mockGetMonthlyRanking(any())).thenAnswer(
          (_) async => const Left(ServerFailure('Erro ao buscar ranking')));
      return bloc;
    },
    act: (b) => b.add(const LoadReceptionistRanking(monthReference: '2026-07')),
    expect: () => [
      isA<ReceptionistRankingState>()
          .having((s) => s.status, 'status', ReceptionistRankingStatus.loading),
      isA<ReceptionistRankingState>()
          .having((s) => s.status, 'status', ReceptionistRankingStatus.failure)
          .having(
              (s) => s.errorMessage, 'errorMessage', 'Erro ao buscar ranking'),
    ],
  );

  test('ownEntry retorna a linha do usuário logado quando presente', () {
    final state = ReceptionistRankingState(
      monthReference: '2026-07',
      entries: tEntries,
      currentUserId: 'r2',
    );
    expect(state.ownEntry?.receptionistName, 'João');
  });

  test('ownEntry é nulo quando o usuário logado não está no ranking', () {
    final state = ReceptionistRankingState(
      monthReference: '2026-07',
      entries: tEntries,
      currentUserId: 'nao-existe',
    );
    expect(state.ownEntry, isNull);
  });
}
