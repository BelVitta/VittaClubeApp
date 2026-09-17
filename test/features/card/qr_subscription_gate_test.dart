import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/core/di/injection_container.dart';
import 'package:vita_clube/features/card/presentation/pages/card_page.dart';
import 'package:vita_clube/features/consultation/presentation/bloc/consultation_bloc.dart';
import 'package:vita_clube/features/consultation/presentation/bloc/consultation_event.dart';
import 'package:vita_clube/features/consultation/presentation/bloc/consultation_state.dart';
import 'package:vita_clube/features/home/domain/entities/plan_level.dart';
import 'package:vita_clube/features/profile/domain/entities/profile_entity.dart';
import 'package:vita_clube/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:vita_clube/features/profile/presentation/bloc/profile_event.dart';
import 'package:vita_clube/features/profile/presentation/bloc/profile_state.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_entity.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_status.dart';
import 'package:vita_clube/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:vita_clube/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:vita_clube/features/subscription/presentation/bloc/subscription_state.dart';

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class MockConsultationBloc
    extends MockBloc<ConsultationEvent, ConsultationState>
    implements ConsultationBloc {}

class MockSubscriptionBloc
    extends MockBloc<SubscriptionEvent, SubscriptionState>
    implements SubscriptionBloc {}

void main() {
  late MockProfileBloc profileBloc;
  late MockConsultationBloc consultationBloc;
  late MockSubscriptionBloc subscriptionBloc;

  setUp(() async {
    await sl.reset();

    profileBloc = MockProfileBloc();
    consultationBloc = MockConsultationBloc();
    subscriptionBloc = MockSubscriptionBloc();

    whenListen(
      profileBloc,
      const Stream<ProfileState>.empty(),
      initialState: ProfileLoaded(_profile()),
    );
    whenListen(
      consultationBloc,
      const Stream<ConsultationState>.empty(),
      initialState: const ConsultationLoaded([]),
    );

    sl.registerFactory<ProfileBloc>(() => profileBloc);
    sl.registerFactory<ConsultationBloc>(() => consultationBloc);
    sl.registerFactory<SubscriptionBloc>(() => subscriptionBloc);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
      'blocked subscription does not open card QR and shows restore CTA',
      (tester) async {
    whenListen(
      subscriptionBloc,
      const Stream<SubscriptionState>.empty(),
      initialState: SubscriptionLoaded(_subscription(blocked: true)),
    );

    // Sem parâmetro — mesmo caminho da bottom nav.
    await tester.pumpWidget(
      const MaterialApp(home: CardPage()),
    );
    await tester.pump();

    expect(find.text('Restaurar conta para usar QR'), findsOneWidget);
    expect(find.text('Mostrar QR Code'), findsNothing);

    await tester.tap(find.text('Restaurar conta para usar QR'));
    await tester.pumpAndSettle();

    expect(find.text('Reative sua conta'), findsOneWidget);
  });

  testWidgets('no subscription shows subscribe CTA and hides QR',
      (tester) async {
    whenListen(
      subscriptionBloc,
      const Stream<SubscriptionState>.empty(),
      initialState: const NoSubscription(),
    );

    await tester.pumpWidget(
      const MaterialApp(home: CardPage()),
    );
    await tester.pump();

    expect(find.text('Assinar para usar o QR'), findsOneWidget);
    expect(find.text('Mostrar QR Code'), findsNothing);
  });

  testWidgets('active subscription shows Mostrar QR Code', (tester) async {
    whenListen(
      subscriptionBloc,
      const Stream<SubscriptionState>.empty(),
      initialState: SubscriptionLoaded(_subscription(blocked: false)),
    );

    await tester.pumpWidget(
      const MaterialApp(home: CardPage()),
    );
    await tester.pump();

    expect(find.text('Mostrar QR Code'), findsOneWidget);
    expect(find.text('Restaurar conta para usar QR'), findsNothing);
    expect(find.text('Assinar para usar o QR'), findsNothing);
  });

  testWidgets(
      'injected subscription still gates QR (test / explicit caller path)',
      (tester) async {
    whenListen(
      subscriptionBloc,
      const Stream<SubscriptionState>.empty(),
      initialState: const SubscriptionInitial(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CardPage(subscription: _subscription(blocked: true)),
      ),
    );
    await tester.pump();

    expect(find.text('Restaurar conta para usar QR'), findsOneWidget);
    expect(find.text('Mostrar QR Code'), findsNothing);
  });
}

ProfileEntity _profile() {
  return ProfileEntity(
    id: 'profile_1',
    name: 'Usuário Teste',
    email: 'user@example.com',
    role: 'user',
    memberSince: DateTime(2026, 6, 2),
    memberCode: '84729103',
  );
}

SubscriptionEntity _subscription({required bool blocked}) {
  return SubscriptionEntity(
    id: 'sub_1',
    userId: 'user_1',
    planId: 'vittaclube-monthly',
    level: blocked ? PlanLevel.inadimplente : PlanLevel.bronze,
    activationDate: DateTime(2026, 6, 2),
    expirationDate: DateTime(2026, 7, 2),
    isCurrent: true,
    pixStatus: blocked
        ? PixAutomaticSubscriptionStatus.blocked
        : PixAutomaticSubscriptionStatus.active,
    paymentAccessStatus:
        blocked ? PaymentAccessStatus.blocked : PaymentAccessStatus.allowed,
  );
}
