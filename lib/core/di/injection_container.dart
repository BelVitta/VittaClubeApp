import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../config/supabase_config.dart';
import '../payment/infinitypay/infinitypay_checkout_service.dart';
import '../payment/payment_gateway.dart';
import '../payment/mock_payment_gateway.dart';
import '../services/clinic_settings_service.dart';

import '../../features/auth/data/datasources/auth_datasource.dart';
import '../../features/auth/data/datasources/auth_supabase_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/services/auth_session_manager.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/google_signin_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

import '../../features/splash/presentation/bloc/splash_bloc.dart';

// Referral
import '../../features/referral/data/datasources/referral_supabase_datasource.dart';
import '../../features/referral/data/repositories/referral_repository_impl.dart';
import '../../features/referral/domain/repositories/referral_repository.dart';
import '../../features/referral/domain/usecases/create_referral_usecase.dart';
import '../../features/referral/domain/usecases/get_referrals_usecase.dart';
import '../../features/referral/domain/usecases/validate_referral_usecase.dart';
import '../../features/referral/domain/usecases/claim_reward_usecase.dart';
import '../../features/referral/presentation/bloc/referral_bloc.dart';

// Badge Progress
import '../../features/badge_progress/data/datasources/badge_progress_supabase_datasource.dart';
import '../../features/badge_progress/data/repositories/badge_progress_repository_impl.dart';
import '../../features/badge_progress/domain/repositories/badge_progress_repository.dart';
import '../../features/badge_progress/domain/usecases/get_badge_progress_usecase.dart';
import '../../features/badge_progress/domain/usecases/check_badge_upgrade_usecase.dart';
import '../../features/badge_progress/presentation/bloc/badge_progress_bloc.dart';

// Admin - Data Sources
import '../../features/admin/data/datasources/admin_datasource.dart';
import '../../features/admin/data/datasources/admin_supabase_datasource.dart';

// Admin - Repositories (interfaces)
import '../../features/admin/domain/repositories/specialty_repository.dart';
import '../../features/admin/domain/repositories/professional_repository.dart';
import '../../features/admin/domain/repositories/plan_admin_repository.dart';
import '../../features/admin/domain/repositories/user_admin_repository.dart';
import '../../features/admin/domain/repositories/payment_admin_repository.dart';
import '../../features/admin/domain/repositories/consultation_admin_repository.dart';
import '../../features/admin/domain/repositories/notification_template_repository.dart';
import '../../features/admin/domain/repositories/draw_repository.dart';
import '../../features/admin/domain/repositories/coupon_repository.dart';
import '../../features/admin/domain/repositories/cancellation_reason_repository.dart';
import '../../features/admin/domain/repositories/badge_repository.dart';

// Admin - Repository Implementations
import '../../features/admin/data/repositories/specialty_repository_impl.dart';
import '../../features/admin/data/repositories/professional_repository_impl.dart';
import '../../features/admin/data/repositories/plan_admin_repository_impl.dart';
import '../../features/admin/data/repositories/user_admin_repository_impl.dart';
import '../../features/admin/data/repositories/payment_admin_repository_impl.dart';
import '../../features/admin/data/repositories/consultation_admin_repository_impl.dart';
import '../../features/admin/data/repositories/notification_template_repository_impl.dart';
import '../../features/admin/data/repositories/draw_repository_impl.dart';
import '../../features/admin/data/repositories/coupon_repository_impl.dart';
import '../../features/admin/data/repositories/cancellation_reason_repository_impl.dart';
import '../../features/admin/data/repositories/badge_repository_impl.dart';

// Admin - Use Cases: Specialty
import '../../features/admin/domain/usecases/specialty/get_specialties_usecase.dart';
import '../../features/admin/domain/usecases/specialty/create_specialty_usecase.dart';
import '../../features/admin/domain/usecases/specialty/update_specialty_usecase.dart';
import '../../features/admin/domain/usecases/specialty/delete_specialty_usecase.dart';

// Admin - Use Cases: Professional
import '../../features/admin/domain/usecases/professional/get_professionals_usecase.dart';
import '../../features/admin/domain/usecases/professional/create_professional_usecase.dart';
import '../../features/admin/domain/usecases/professional/update_professional_usecase.dart';
import '../../features/admin/domain/usecases/professional/delete_professional_usecase.dart';

// Admin - Use Cases: Plan
import '../../features/admin/domain/usecases/plan_admin/get_plans_usecase.dart';
import '../../features/admin/domain/usecases/plan_admin/create_plan_usecase.dart';
import '../../features/admin/domain/usecases/plan_admin/update_plan_usecase.dart';
import '../../features/admin/domain/usecases/plan_admin/delete_plan_usecase.dart';

// Admin - Use Cases: User
import '../../features/admin/domain/usecases/user_admin/get_users_usecase.dart';
import '../../features/admin/domain/usecases/user_admin/create_user_usecase.dart';
import '../../features/admin/domain/usecases/user_admin/update_user_usecase.dart';
import '../../features/admin/domain/usecases/user_admin/delete_user_usecase.dart';

// Admin - Use Cases: Payment
import '../../features/admin/domain/usecases/payment_admin/get_payments_usecase.dart';
import '../../features/admin/domain/usecases/payment_admin/create_payment_usecase.dart';
import '../../features/admin/domain/usecases/payment_admin/update_payment_usecase.dart';
import '../../features/admin/domain/usecases/payment_admin/delete_payment_usecase.dart';

// Admin - Use Cases: Consultation
import '../../features/admin/domain/usecases/consultation_admin/get_consultations_usecase.dart';
import '../../features/admin/domain/usecases/consultation_admin/create_consultation_usecase.dart';
import '../../features/admin/domain/usecases/consultation_admin/update_consultation_usecase.dart';
import '../../features/admin/domain/usecases/consultation_admin/delete_consultation_usecase.dart';

// Admin - Use Cases: NotificationTemplate
import '../../features/admin/domain/usecases/notification_template/get_notification_templates_usecase.dart';
import '../../features/admin/domain/usecases/notification_template/create_notification_template_usecase.dart';
import '../../features/admin/domain/usecases/notification_template/update_notification_template_usecase.dart';
import '../../features/admin/domain/usecases/notification_template/delete_notification_template_usecase.dart';

// Admin - Use Cases: Draw
import '../../features/admin/domain/usecases/draw/get_draws_usecase.dart';
import '../../features/admin/domain/usecases/draw/create_draw_usecase.dart';
import '../../features/admin/domain/usecases/draw/update_draw_usecase.dart';
import '../../features/admin/domain/usecases/draw/delete_draw_usecase.dart';
import '../../features/admin/domain/usecases/draw/execute_draw_usecase.dart';

// Admin - Use Cases: Coupon
import '../../features/admin/domain/usecases/coupon/get_coupons_usecase.dart';
import '../../features/admin/domain/usecases/coupon/create_coupon_usecase.dart';
import '../../features/admin/domain/usecases/coupon/update_coupon_usecase.dart';
import '../../features/admin/domain/usecases/coupon/delete_coupon_usecase.dart';

// Admin - Use Cases: CancellationReason
import '../../features/admin/domain/usecases/cancellation_reason/get_cancellation_reasons_usecase.dart';
import '../../features/admin/domain/usecases/cancellation_reason/create_cancellation_reason_usecase.dart';
import '../../features/admin/domain/usecases/cancellation_reason/update_cancellation_reason_usecase.dart';
import '../../features/admin/domain/usecases/cancellation_reason/delete_cancellation_reason_usecase.dart';

// Admin - Use Cases: Badge
import '../../features/admin/domain/usecases/badge/get_badges_usecase.dart';
import '../../features/admin/domain/usecases/badge/create_badge_usecase.dart';
import '../../features/admin/domain/usecases/badge/update_badge_usecase.dart';
import '../../features/admin/domain/usecases/badge/delete_badge_usecase.dart';

// Parceiro - Data Sources
import '../../features/parceiro/data/datasources/parceiro_datasource.dart';
import '../../features/parceiro/data/datasources/parceiro_supabase_datasource.dart';

// Parceiro - Repositories (interfaces)
import '../../features/parceiro/domain/repositories/partner_repository.dart';
import '../../features/parceiro/domain/repositories/partner_service_repository.dart';
import '../../features/parceiro/domain/repositories/partner_validation_repository.dart';

// Parceiro - Repository Implementations
import '../../features/parceiro/data/repositories/partner_repository_impl.dart';
import '../../features/parceiro/data/repositories/partner_service_repository_impl.dart';
import '../../features/parceiro/data/repositories/partner_validation_repository_impl.dart';

// Parceiro - Use Cases: Partner
import '../../features/parceiro/domain/usecases/partner/get_partners_usecase.dart';
import '../../features/parceiro/domain/usecases/partner/get_partner_by_profile_usecase.dart';
import '../../features/parceiro/domain/usecases/partner/update_partner_usecase.dart';
import '../../features/parceiro/domain/usecases/partner/regenerate_code_usecase.dart';

// Parceiro - Use Cases: PartnerService
import '../../features/parceiro/domain/usecases/partner_service/get_partner_services_usecase.dart';
import '../../features/parceiro/domain/usecases/partner_service/get_all_active_services_usecase.dart';
import '../../features/parceiro/domain/usecases/partner_service/create_partner_service_usecase.dart';
import '../../features/parceiro/domain/usecases/partner_service/update_partner_service_usecase.dart';
import '../../features/parceiro/domain/usecases/partner_service/delete_partner_service_usecase.dart';

// Parceiro - Use Cases: PartnerValidation
import '../../features/parceiro/domain/usecases/partner_validation/get_partner_validations_usecase.dart';
import '../../features/parceiro/domain/usecases/partner_validation/validate_checkin_usecase.dart';
import '../../features/parceiro/domain/usecases/partner_validation/generate_token_usecase.dart';

// Parceiro - BLoCs
import '../../features/parceiro/presentation/bloc/partner_service/partner_service_bloc.dart';
import '../../features/parceiro/presentation/bloc/partner_validation/partner_validation_bloc.dart';
import '../../features/parceiro/presentation/bloc/partner_checkin/partner_checkin_bloc.dart';

// Consultation (consultas do usuário logado)
import '../../features/consultation/data/datasources/consultation_supabase_datasource.dart';
import '../../features/consultation/data/repositories/consultation_repository_impl.dart';
import '../../features/consultation/domain/repositories/consultation_repository.dart';
import '../../features/consultation/domain/usecases/get_user_consultations_usecase.dart';
import '../../features/consultation/domain/usecases/record_consultation_usecase.dart';
import '../../features/consultation/presentation/bloc/consultation_bloc.dart';

// Profile (perfil do usuário logado)
import '../../features/profile/data/datasources/profile_supabase_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_current_profile_usecase.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';

// Plans (leitura de planos oferecidos + benefícios)
import '../../features/plans/data/datasources/plans_supabase_datasource.dart';

// Subscription
import '../../features/subscription/data/datasources/subscription_supabase_datasource.dart';
import '../../features/subscription/data/repositories/subscription_repository_impl.dart';
import '../../features/subscription/domain/repositories/subscription_repository.dart';
import '../../features/subscription/domain/usecases/get_current_subscription_usecase.dart';
import '../../features/subscription/domain/usecases/activate_subscription_usecase.dart';
import '../../features/subscription/domain/usecases/cancel_subscription_usecase.dart';
import '../../features/subscription/domain/usecases/create_pix_automatic_subscription_usecase.dart';
import '../../features/subscription/domain/usecases/refresh_subscription_status_usecase.dart';
import '../../features/subscription/presentation/bloc/subscription_bloc.dart';

// Admin - BLoCs
import '../../features/admin/presentation/bloc/specialty/specialty_bloc.dart';
import '../../features/admin/presentation/bloc/professional/professional_bloc.dart';
import '../../features/admin/presentation/bloc/plan_admin/plan_admin_bloc.dart';
import '../../features/admin/presentation/bloc/user_admin/user_admin_bloc.dart';
import '../../features/admin/presentation/bloc/payment_admin/payment_admin_bloc.dart';
import '../../features/admin/presentation/bloc/consultation_admin/consultation_admin_bloc.dart';
import '../../features/admin/presentation/bloc/notification_template/notification_template_bloc.dart';
import '../../features/admin/presentation/bloc/draw/draw_bloc.dart';
import '../../features/admin/presentation/bloc/coupon/coupon_bloc.dart';
import '../../features/admin/presentation/bloc/cancellation_reason/cancellation_reason_bloc.dart';
import '../../features/admin/presentation/bloc/badge/badge_bloc.dart';

final sl = GetIt.instance;

/// Inicializa todas as dependências do app
Future<void> init() async {
  //============================================================
  // Core / Config
  //============================================================
  sl.registerLazySingleton<AppConfig>(() => AppConfig.instance);

  // Payment Gateway — mock no dev/staging, placeholder bloqueante em prod.
  sl.registerLazySingleton<PaymentGateway>(
    () => AppConfig.instance.isProd
        ? UnimplementedPaymentGateway()
        : MockPaymentGateway(),
  );

  // Config service — lê/escreve configurações globais da clínica (ex: WhatsApp).
  sl.registerLazySingleton<ClinicSettingsService>(
    () => ClinicSettingsService(),
  );

  sl.registerLazySingleton<InfinityPayCheckoutService>(
    () => InfinityPayCheckoutService(
      handle: AppConfig.instance.infinityPayHandle,
    ),
  );

  //============================================================
  // Features - Auth
  //============================================================

  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      googleSignInUseCase: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => GoogleSignInUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      dataSource: sl(),
      authSessionManager: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<AuthDataSource>(
    () => AuthSupabaseDataSource(supabaseClient: SupabaseConfig.client),
  );
  sl.registerLazySingleton(
    () => AuthSessionManager(
      sharedPreferences: sl(),
      authClient: SupabaseConfig.isInitialized ? SupabaseConfig.auth : null,
    ),
  );

  //============================================================
  // Features - Splash
  //============================================================
  sl.registerFactory(
    () => SplashBloc(
      sharedPreferences: sl(),
      authSessionManager: sl(),
    ),
  );

  //============================================================
  // Features - Admin
  //============================================================

  // Data Source
  sl.registerLazySingleton<AdminDataSource>(
    () => AdminSupabaseDataSource(supabaseClient: SupabaseConfig.client),
  );

  // --- Specialty ---
  sl.registerFactory(() => SpecialtyBloc(
        getSpecialtiesUseCase: sl(),
        createSpecialtyUseCase: sl(),
        updateSpecialtyUseCase: sl(),
        deleteSpecialtyUseCase: sl(),
      ));
  sl.registerLazySingleton(() => GetSpecialtiesUseCase(sl()));
  sl.registerLazySingleton(() => CreateSpecialtyUseCase(sl()));
  sl.registerLazySingleton(() => UpdateSpecialtyUseCase(sl()));
  sl.registerLazySingleton(() => DeleteSpecialtyUseCase(sl()));
  sl.registerLazySingleton<SpecialtyRepository>(
    () => SpecialtyRepositoryImpl(dataSource: sl()),
  );

  // --- Professional ---
  sl.registerFactory(() => ProfessionalBloc(
        getProfessionalsUseCase: sl(),
        createProfessionalUseCase: sl(),
        updateProfessionalUseCase: sl(),
        deleteProfessionalUseCase: sl(),
      ));
  sl.registerLazySingleton(() => GetProfessionalsUseCase(sl()));
  sl.registerLazySingleton(() => CreateProfessionalUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfessionalUseCase(sl()));
  sl.registerLazySingleton(() => DeleteProfessionalUseCase(sl()));
  sl.registerLazySingleton<ProfessionalRepository>(
    () => ProfessionalRepositoryImpl(dataSource: sl()),
  );

  // --- Plan ---
  sl.registerFactory(() => PlanAdminBloc(
        getPlansUseCase: sl(),
        createPlanUseCase: sl(),
        updatePlanUseCase: sl(),
        deletePlanUseCase: sl(),
      ));
  sl.registerLazySingleton(() => GetPlansUseCase(sl()));
  sl.registerLazySingleton(() => CreatePlanUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePlanUseCase(sl()));
  sl.registerLazySingleton(() => DeletePlanUseCase(sl()));
  sl.registerLazySingleton<PlanAdminRepository>(
    () => PlanAdminRepositoryImpl(dataSource: sl()),
  );

  // --- User ---
  sl.registerFactory(() => UserAdminBloc(
        getUsersUseCase: sl(),
        createUserUseCase: sl(),
        updateUserUseCase: sl(),
        deleteUserUseCase: sl(),
      ));
  sl.registerLazySingleton(() => GetUsersUseCase(sl()));
  sl.registerLazySingleton(() => CreateUserUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUserUseCase(sl()));
  sl.registerLazySingleton(() => DeleteUserUseCase(sl()));
  sl.registerLazySingleton<UserAdminRepository>(
    () => UserAdminRepositoryImpl(dataSource: sl()),
  );

  // --- Payment ---
  sl.registerFactory(() => PaymentAdminBloc(
        getPaymentsUseCase: sl(),
        createPaymentUseCase: sl(),
        updatePaymentUseCase: sl(),
        deletePaymentUseCase: sl(),
      ));
  sl.registerLazySingleton(() => GetPaymentsUseCase(sl()));
  sl.registerLazySingleton(() => CreatePaymentUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePaymentUseCase(sl()));
  sl.registerLazySingleton(() => DeletePaymentUseCase(sl()));
  sl.registerLazySingleton<PaymentAdminRepository>(
    () => PaymentAdminRepositoryImpl(dataSource: sl()),
  );

  // --- Consultation ---
  sl.registerFactory(() => ConsultationAdminBloc(
        getConsultationsUseCase: sl(),
        createConsultationUseCase: sl(),
        updateConsultationUseCase: sl(),
        deleteConsultationUseCase: sl(),
      ));
  sl.registerLazySingleton(() => GetConsultationsUseCase(sl()));
  sl.registerLazySingleton(() => CreateConsultationUseCase(sl()));
  sl.registerLazySingleton(() => UpdateConsultationUseCase(sl()));
  sl.registerLazySingleton(() => DeleteConsultationUseCase(sl()));
  sl.registerLazySingleton<ConsultationAdminRepository>(
    () => ConsultationAdminRepositoryImpl(dataSource: sl()),
  );

  // --- NotificationTemplate ---
  sl.registerFactory(() => NotificationTemplateBloc(
        getNotificationTemplatesUseCase: sl(),
        createNotificationTemplateUseCase: sl(),
        updateNotificationTemplateUseCase: sl(),
        deleteNotificationTemplateUseCase: sl(),
      ));
  sl.registerLazySingleton(() => GetNotificationTemplatesUseCase(sl()));
  sl.registerLazySingleton(() => CreateNotificationTemplateUseCase(sl()));
  sl.registerLazySingleton(() => UpdateNotificationTemplateUseCase(sl()));
  sl.registerLazySingleton(() => DeleteNotificationTemplateUseCase(sl()));
  sl.registerLazySingleton<NotificationTemplateRepository>(
    () => NotificationTemplateRepositoryImpl(dataSource: sl()),
  );

  // --- Draw ---
  sl.registerFactory(() => DrawBloc(
        getDrawsUseCase: sl(),
        createDrawUseCase: sl(),
        updateDrawUseCase: sl(),
        deleteDrawUseCase: sl(),
        executeDrawUseCase: sl(),
      ));
  sl.registerLazySingleton(() => GetDrawsUseCase(sl()));
  sl.registerLazySingleton(() => CreateDrawUseCase(sl()));
  sl.registerLazySingleton(() => UpdateDrawUseCase(sl()));
  sl.registerLazySingleton(() => DeleteDrawUseCase(sl()));
  sl.registerLazySingleton(() => ExecuteDrawUseCase(sl()));
  sl.registerLazySingleton<DrawRepository>(
    () => DrawRepositoryImpl(dataSource: sl()),
  );

  // --- Coupon ---
  sl.registerFactory(() => CouponBloc(
        getCouponsUseCase: sl(),
        createCouponUseCase: sl(),
        updateCouponUseCase: sl(),
        deleteCouponUseCase: sl(),
      ));
  sl.registerLazySingleton(() => GetCouponsUseCase(sl()));
  sl.registerLazySingleton(() => CreateCouponUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCouponUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCouponUseCase(sl()));
  sl.registerLazySingleton<CouponRepository>(
    () => CouponRepositoryImpl(dataSource: sl()),
  );

  // --- CancellationReason ---
  sl.registerFactory(() => CancellationReasonBloc(
        getCancellationReasonsUseCase: sl(),
        createCancellationReasonUseCase: sl(),
        updateCancellationReasonUseCase: sl(),
        deleteCancellationReasonUseCase: sl(),
      ));
  sl.registerLazySingleton(() => GetCancellationReasonsUseCase(sl()));
  sl.registerLazySingleton(() => CreateCancellationReasonUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCancellationReasonUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCancellationReasonUseCase(sl()));
  sl.registerLazySingleton<CancellationReasonRepository>(
    () => CancellationReasonRepositoryImpl(dataSource: sl()),
  );

  // --- Badge ---
  sl.registerFactory(() => BadgeBloc(
        getBadgesUseCase: sl(),
        createBadgeUseCase: sl(),
        updateBadgeUseCase: sl(),
        deleteBadgeUseCase: sl(),
      ));
  sl.registerLazySingleton(() => GetBadgesUseCase(sl()));
  sl.registerLazySingleton(() => CreateBadgeUseCase(sl()));
  sl.registerLazySingleton(() => UpdateBadgeUseCase(sl()));
  sl.registerLazySingleton(() => DeleteBadgeUseCase(sl()));
  sl.registerLazySingleton<BadgeRepository>(
    () => BadgeRepositoryImpl(dataSource: sl()),
  );

  //============================================================
  // Features - Referral (Indicacoes)
  //============================================================

  // BLoC
  sl.registerFactory(() => ReferralBloc(
        getReferralsUseCase: sl(),
        createReferralUseCase: sl(),
        validateReferralUseCase: sl(),
        claimRewardUseCase: sl(),
      ));

  // Use Cases
  sl.registerLazySingleton(() => GetReferralsUseCase(sl()));
  sl.registerLazySingleton(() => CreateReferralUseCase(sl()));
  sl.registerLazySingleton(() => ValidateReferralUseCase(sl()));
  sl.registerLazySingleton(() => ClaimRewardUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ReferralRepository>(
    () => ReferralRepositoryImpl(dataSource: sl()),
  );

  // Data Source
  sl.registerLazySingleton(
    () => ReferralSupabaseDataSource(supabaseClient: SupabaseConfig.client),
  );

  //============================================================
  // Features - Consultation (Consultas do usuário logado)
  //============================================================

  sl.registerFactory(
    () => ConsultationBloc(getUserConsultationsUseCase: sl()),
  );

  sl.registerLazySingleton(() => GetUserConsultationsUseCase(sl()));
  sl.registerLazySingleton(() => RecordConsultationUseCase(sl()));

  sl.registerLazySingleton<ConsultationRepository>(
    () => ConsultationRepositoryImpl(dataSource: sl()),
  );

  sl.registerLazySingleton(
    () => ConsultationSupabaseDataSource(supabaseClient: SupabaseConfig.client),
  );

  //============================================================
  // Features - Profile (Perfil do usuário logado)
  //============================================================

  sl.registerFactory(
    () => ProfileBloc(getCurrentProfileUseCase: sl()),
  );

  sl.registerLazySingleton(() => GetCurrentProfileUseCase(sl()));

  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(dataSource: sl()),
  );

  sl.registerLazySingleton(
    () => ProfileSupabaseDataSource(supabaseClient: SupabaseConfig.client),
  );

  //============================================================
  // Features - Subscription (Assinatura atual do usuario)
  //============================================================

  sl.registerFactory(
    () => SubscriptionBloc(getCurrentSubscriptionUseCase: sl()),
  );

  sl.registerLazySingleton(() => GetCurrentSubscriptionUseCase(sl()));
  sl.registerLazySingleton(() => ActivateSubscriptionUseCase(sl()));
  sl.registerLazySingleton(() => CancelSubscriptionUseCase(sl()));
  sl.registerLazySingleton(() => CreatePixAutomaticSubscriptionUseCase(sl()));
  sl.registerLazySingleton(() => RefreshSubscriptionStatusUseCase(sl()));

  sl.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(dataSource: sl()),
  );

  sl.registerLazySingleton(
    () => SubscriptionSupabaseDataSource(supabaseClient: SupabaseConfig.client),
  );

  // Plans datasource (leitura dos planos oferecidos + benefícios)
  sl.registerLazySingleton(
    () => PlansSupabaseDataSource(supabaseClient: SupabaseConfig.client),
  );

  //============================================================
  // Features - Badge Progress (Progressao de Badges)
  //============================================================

  // BLoC
  sl.registerFactory(() => BadgeProgressBloc(
        getBadgeProgressUseCase: sl(),
        checkBadgeUpgradeUseCase: sl(),
      ));

  // Use Cases
  sl.registerLazySingleton(() => GetBadgeProgressUseCase(sl()));
  sl.registerLazySingleton(() => CheckBadgeUpgradeUseCase(sl()));

  // Repository
  sl.registerLazySingleton<BadgeProgressRepository>(
    () => BadgeProgressRepositoryImpl(dataSource: sl()),
  );

  // Data Source
  sl.registerLazySingleton(
    () =>
        BadgeProgressSupabaseDataSource(supabaseClient: SupabaseConfig.client),
  );

  //============================================================
  // Features - Parceiro
  //============================================================

  // Data Source
  sl.registerLazySingleton<ParceiroDataSource>(
    () => ParceiroSupabaseDataSource(supabaseClient: SupabaseConfig.client),
  );

  // --- Partner ---
  sl.registerLazySingleton(() => GetPartnersUseCase(sl()));
  sl.registerLazySingleton(() => GetPartnerByProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePartnerUseCase(sl()));
  sl.registerLazySingleton(() => RegenerateCodeUseCase(sl()));
  sl.registerLazySingleton<PartnerRepository>(
    () => PartnerRepositoryImpl(dataSource: sl()),
  );

  // --- PartnerService ---
  sl.registerFactory(() => PartnerServiceBloc(
        getPartnerServicesUseCase: sl(),
        createPartnerServiceUseCase: sl(),
        updatePartnerServiceUseCase: sl(),
        deletePartnerServiceUseCase: sl(),
      ));
  sl.registerLazySingleton(() => GetPartnerServicesUseCase(sl()));
  sl.registerLazySingleton(() => GetAllActiveServicesUseCase(sl()));
  sl.registerLazySingleton(() => CreatePartnerServiceUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePartnerServiceUseCase(sl()));
  sl.registerLazySingleton(() => DeletePartnerServiceUseCase(sl()));
  sl.registerLazySingleton<PartnerServiceRepository>(
    () => PartnerServiceRepositoryImpl(dataSource: sl()),
  );

  // --- PartnerValidation ---
  sl.registerFactory(() => PartnerValidationBloc(
        getPartnerValidationsUseCase: sl(),
      ));
  sl.registerLazySingleton(() => GetPartnerValidationsUseCase(sl()));
  sl.registerLazySingleton(() => ValidateCheckinUseCase(sl()));
  sl.registerLazySingleton(() => GenerateTokenUseCase(sl()));
  sl.registerLazySingleton<PartnerValidationRepository>(
    () => PartnerValidationRepositoryImpl(dataSource: sl()),
  );

  // --- PartnerCheckin ---
  sl.registerFactory(() => PartnerCheckinBloc(
        generateTokenUseCase: sl(),
        validateCheckinUseCase: sl(),
      ));

  //============================================================
  // Core / External
  //============================================================

  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
}
