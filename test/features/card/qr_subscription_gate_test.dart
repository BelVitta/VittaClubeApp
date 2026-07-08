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

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class MockConsultationBloc
    extends MockBloc<ConsultationEvent, ConsultationState>
    implements ConsultationBloc {}

void main() {
  late MockProfileBloc profileBloc;
  late MockConsultationBloc consultationBloc;

  setUp(() async {
    await sl.reset();

    profileBloc = MockProfileBloc();
    consultationBloc = MockConsultationBloc();

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
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
      'blocked subscription does not open card QR and shows restore CTA',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CardPage(subscription: _subscription(blocked: true)),
      ),
    );

    expect(find.text('Restaurar conta para usar QR'), findsOneWidget);

    await tester.tap(find.text('Restaurar conta para usar QR'));
    await tester.pumpAndSettle();

    expect(find.text('Reative sua conta'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });
}

ProfileEntity _profile() {
  return ProfileEntity(
    id: 'profile_1',
    name: 'Usuário Teste',
    email: 'user@example.com',
    role: 'user',
    memberSince: DateTime(2026, 6, 2),
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
