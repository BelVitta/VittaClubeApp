import '../../domain/entities/badge_entity.dart';
import '../../domain/entities/cancellation_reason_entity.dart';
import '../../domain/entities/consultation_admin_entity.dart';
import '../../domain/entities/coupon_entity.dart';
import '../../domain/entities/professional_entity.dart';
import '../../domain/entities/draw_entity.dart';
import '../../domain/entities/notification_template_entity.dart';
import '../../domain/entities/payment_admin_entity.dart';
import '../../domain/entities/plan_admin_entity.dart';
import '../../domain/entities/specialty_entity.dart';
import '../../domain/entities/user_admin_entity.dart';
import '../models/badge_model.dart';
import '../models/cancellation_reason_model.dart';
import '../models/consultation_admin_model.dart';
import '../models/coupon_model.dart';
import '../models/professional_model.dart';
import '../models/draw_model.dart';
import '../models/notification_template_model.dart';
import '../models/payment_admin_model.dart';
import '../models/plan_admin_model.dart';
import '../models/specialty_model.dart';
import '../models/user_admin_model.dart';

/// Contrato abstrato do data source admin.
/// Define todas as operações CRUD para o painel administrativo.
abstract class AdminDataSource {
  // Professionals
  Future<List<ProfessionalModel>> getProfessionals();
  Future<ProfessionalModel> getProfessionalById(String id);
  Future<ProfessionalModel> createProfessional(ProfessionalEntity professional);
  Future<ProfessionalModel> updateProfessional(ProfessionalEntity professional);
  Future<void> deleteProfessional(String id);

  // Specialties
  Future<List<SpecialtyModel>> getSpecialties();
  Future<SpecialtyModel> getSpecialtyById(String id);
  Future<SpecialtyModel> createSpecialty(SpecialtyEntity specialty);
  Future<SpecialtyModel> updateSpecialty(SpecialtyEntity specialty);
  Future<void> deleteSpecialty(String id);

  // Plans
  Future<List<PlanAdminModel>> getPlans();
  Future<PlanAdminModel> getPlanById(String id);
  Future<PlanAdminModel> createPlan(PlanAdminEntity plan);
  Future<PlanAdminModel> updatePlan(PlanAdminEntity plan);
  Future<void> deletePlan(String id);

  // Users
  Future<List<UserAdminModel>> getUsers();
  Future<UserAdminModel> getUserById(String id);
  Future<UserAdminModel> createUser(UserAdminEntity user);
  Future<UserAdminModel> updateUser(UserAdminEntity user);
  Future<void> deleteUser(String id);

  // Payments
  Future<List<PaymentAdminModel>> getPayments();
  Future<PaymentAdminModel> getPaymentById(String id);
  Future<PaymentAdminModel> createPayment(PaymentAdminEntity payment);
  Future<PaymentAdminModel> updatePayment(PaymentAdminEntity payment);
  Future<void> deletePayment(String id);

  // Consultations
  Future<List<ConsultationAdminModel>> getConsultations();
  Future<ConsultationAdminModel> getConsultationById(String id);
  Future<ConsultationAdminModel> createConsultation(
      ConsultationAdminEntity consultation);
  Future<ConsultationAdminModel> updateConsultation(
      ConsultationAdminEntity consultation);
  Future<void> deleteConsultation(String id);

  // Notifications
  Future<List<NotificationTemplateModel>> getNotifications();
  Future<NotificationTemplateModel> getNotificationById(String id);
  Future<NotificationTemplateModel> createNotification(
      NotificationTemplateEntity notification);
  Future<NotificationTemplateModel> updateNotification(
      NotificationTemplateEntity notification);
  Future<void> deleteNotification(String id);

  // Draws
  Future<List<DrawModel>> getDraws();
  Future<DrawModel> getDrawById(String id);
  Future<DrawModel> createDraw(DrawEntity draw);
  Future<DrawModel> updateDraw(DrawEntity draw);
  Future<void> deleteDraw(String id);
  Future<DrawModel> executeDraw(String drawId);

  // Coupons
  Future<List<CouponModel>> getCoupons();
  Future<CouponModel> getCouponById(String id);
  Future<CouponModel> createCoupon(CouponEntity coupon);
  Future<CouponModel> updateCoupon(CouponEntity coupon);
  Future<void> deleteCoupon(String id);

  // Cancellation Reasons
  Future<List<CancellationReasonModel>> getCancellationReasons();
  Future<CancellationReasonModel> getCancellationReasonById(String id);
  Future<CancellationReasonModel> createCancellationReason(
      CancellationReasonEntity reason);
  Future<CancellationReasonModel> updateCancellationReason(
      CancellationReasonEntity reason);
  Future<void> deleteCancellationReason(String id);

  // Badges
  Future<List<BadgeModel>> getBadges();
  Future<BadgeModel> getBadgeById(String id);
  Future<BadgeModel> createBadge(BadgeEntity badge);
  Future<BadgeModel> updateBadge(BadgeEntity badge);
  Future<void> deleteBadge(String id);
}
