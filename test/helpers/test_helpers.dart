import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vita_clube/features/auth/data/services/auth_session_manager.dart';
import 'package:vita_clube/features/auth/domain/repositories/auth_repository.dart';
import 'package:vita_clube/features/referral/domain/repositories/referral_repository.dart';
import 'package:vita_clube/features/badge_progress/domain/repositories/badge_progress_repository.dart';
import 'package:vita_clube/features/admin/domain/repositories/specialty_repository.dart';
import 'package:vita_clube/features/admin/domain/repositories/professional_repository.dart';
import 'package:vita_clube/features/admin/domain/repositories/plan_admin_repository.dart';
import 'package:vita_clube/features/admin/domain/repositories/user_admin_repository.dart';
import 'package:vita_clube/features/admin/domain/repositories/payment_admin_repository.dart';
import 'package:vita_clube/features/admin/domain/repositories/consultation_admin_repository.dart';
import 'package:vita_clube/features/admin/domain/repositories/draw_repository.dart';
import 'package:vita_clube/features/admin/domain/repositories/coupon_repository.dart';
import 'package:vita_clube/features/admin/domain/repositories/cancellation_reason_repository.dart';
import 'package:vita_clube/features/admin/domain/repositories/badge_repository.dart';
import 'package:vita_clube/features/admin/domain/repositories/notification_template_repository.dart';
import 'package:vita_clube/features/parceiro/domain/repositories/partner_repository.dart';
import 'package:vita_clube/features/parceiro/domain/repositories/partner_service_repository.dart';
import 'package:vita_clube/features/parceiro/domain/repositories/partner_validation_repository.dart';

// ── Repository Mocks ──
class MockAuthRepository extends Mock implements AuthRepository {}

class MockReferralRepository extends Mock implements ReferralRepository {}

class MockBadgeProgressRepository extends Mock
    implements BadgeProgressRepository {}

class MockSpecialtyRepository extends Mock implements SpecialtyRepository {}

class MockProfessionalRepository extends Mock
    implements ProfessionalRepository {}

class MockPlanAdminRepository extends Mock implements PlanAdminRepository {}

class MockUserAdminRepository extends Mock implements UserAdminRepository {}

class MockPaymentAdminRepository extends Mock
    implements PaymentAdminRepository {}

class MockConsultationAdminRepository extends Mock
    implements ConsultationAdminRepository {}

class MockDrawRepository extends Mock implements DrawRepository {}

class MockCouponRepository extends Mock implements CouponRepository {}

class MockCancellationReasonRepository extends Mock
    implements CancellationReasonRepository {}

class MockBadgeRepository extends Mock implements BadgeRepository {}

class MockNotificationTemplateRepository extends Mock
    implements NotificationTemplateRepository {}

class MockPartnerRepository extends Mock implements PartnerRepository {}

class MockPartnerServiceRepository extends Mock
    implements PartnerServiceRepository {}

class MockPartnerValidationRepository extends Mock
    implements PartnerValidationRepository {}

// ── External Mocks ──
class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockAuthSessionManager extends Mock implements AuthSessionManager {}
