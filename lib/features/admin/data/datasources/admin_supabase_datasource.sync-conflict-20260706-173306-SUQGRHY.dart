import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/badge_entity.dart';
import '../../domain/entities/cancellation_reason_entity.dart';
import '../../domain/entities/consultation_admin_entity.dart';
import '../../domain/entities/coupon_entity.dart';
import '../../domain/entities/draw_entity.dart';
import '../../domain/entities/notification_template_entity.dart';
import '../../domain/entities/payment_admin_entity.dart';
import '../../domain/entities/plan_admin_entity.dart';
import '../../domain/entities/professional_entity.dart';
import '../../domain/entities/specialty_entity.dart';
import '../../domain/entities/user_admin_entity.dart';
import '../models/badge_model.dart';
import '../models/cancellation_reason_model.dart';
import '../models/consultation_admin_model.dart';
import '../models/coupon_model.dart';
import '../models/draw_model.dart';
import '../models/notification_template_model.dart';
import '../models/payment_admin_model.dart';
import '../models/plan_admin_model.dart';
import '../models/professional_model.dart';
import '../models/specialty_model.dart';
import '../models/user_admin_model.dart';
import 'admin_datasource.dart';

class AdminSupabaseDataSource implements AdminDataSource {
  final SupabaseClient _supabase;

  AdminSupabaseDataSource({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  // ============================================================
  // SPECIALTIES
  // ============================================================

  @override
  Future<List<SpecialtyModel>> getSpecialties() async {
    try {
      final data = await _supabase
          .from('specialties')
          .select('id, name, is_active')
          .order('name');
      return (data as List)
          .map((e) => SpecialtyModel(
                id: e['id'] as String,
                name: e['name'] as String,
                isActive: e['is_active'] as bool,
              ))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar especialidades: $e');
    }
  }

  @override
  Future<SpecialtyModel> getSpecialtyById(String id) async {
    try {
      final data = await _supabase
          .from('specialties')
          .select('id, name, is_active')
          .eq('id', id)
          .single();
      return SpecialtyModel(
        id: data['id'] as String,
        name: data['name'] as String,
        isActive: data['is_active'] as bool,
      );
    } catch (e) {
      throw ServerException(message: 'Especialidade não encontrada: $e');
    }
  }

  @override
  Future<SpecialtyModel> createSpecialty(SpecialtyEntity specialty) async {
    try {
      final data = await _supabase
          .from('specialties')
          .insert({'name': specialty.name, 'is_active': specialty.isActive})
          .select('id, name, is_active')
          .single();
      return SpecialtyModel(
        id: data['id'] as String,
        name: data['name'] as String,
        isActive: data['is_active'] as bool,
      );
    } catch (e) {
      throw ServerException(message: 'Erro ao criar especialidade: $e');
    }
  }

  @override
  Future<SpecialtyModel> updateSpecialty(SpecialtyEntity specialty) async {
    try {
      final data = await _supabase
          .from('specialties')
          .update({'name': specialty.name, 'is_active': specialty.isActive})
          .eq('id', specialty.id)
          .select('id, name, is_active')
          .single();
      return SpecialtyModel(
        id: data['id'] as String,
        name: data['name'] as String,
        isActive: data['is_active'] as bool,
      );
    } catch (e) {
      throw ServerException(message: 'Erro ao atualizar especialidade: $e');
    }
  }

  @override
  Future<void> deleteSpecialty(String id) async {
    try {
      await _supabase.from('specialties').delete().eq('id', id);
    } catch (e) {
      throw ServerException(message: 'Erro ao excluir especialidade: $e');
    }
  }

  // ============================================================
  // PROFESSIONALS
  // ============================================================

  @override
  Future<List<ProfessionalModel>> getProfessionals() async {
    try {
      final data = await _supabase
          .from('professionals')
          .select(
              'id, name, specialty_id, available_days, avatar_url, avatar_bg_color, is_active, specialties(name)')
          .order('name');
      return (data as List).map((e) => _professionalFromRow(e)).toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar profissionais: $e');
    }
  }

  @override
  Future<ProfessionalModel> getProfessionalById(String id) async {
    try {
      final data = await _supabase
          .from('professionals')
          .select(
              'id, name, specialty_id, available_days, avatar_url, avatar_bg_color, is_active, specialties(name)')
          .eq('id', id)
          .single();
      return _professionalFromRow(data);
    } catch (e) {
      throw ServerException(message: 'Profissional não encontrado: $e');
    }
  }

  @override
  Future<ProfessionalModel> createProfessional(
      ProfessionalEntity professional) async {
    try {
      final days = professional.availableDays
          .split(',')
          .map((d) => d.trim())
          .where((d) => d.isNotEmpty)
          .toList();
      final data = await _supabase
          .from('professionals')
          .insert({
            'name': professional.name,
            'specialty_id': professional.specialtyId,
            'available_days': days,
            'avatar_url': professional.avatarUrl,
            'avatar_bg_color': professional.avatarBgColor,
            'whatsapp_encrypted': utf8.encode(professional.whatsappNumber),
            'is_active': professional.isActive,
          })
          .select(
              'id, name, specialty_id, available_days, avatar_url, avatar_bg_color, is_active, specialties(name)')
          .single();
      return _professionalFromRow(data);
    } catch (e) {
      throw ServerException(message: 'Erro ao criar profissional: $e');
    }
  }

  @override
  Future<ProfessionalModel> updateProfessional(
      ProfessionalEntity professional) async {
    try {
      final days = professional.availableDays
          .split(',')
          .map((d) => d.trim())
          .where((d) => d.isNotEmpty)
          .toList();
      final data = await _supabase
          .from('professionals')
          .update({
            'name': professional.name,
            'specialty_id': professional.specialtyId,
            'available_days': days,
            'avatar_url': professional.avatarUrl,
            'avatar_bg_color': professional.avatarBgColor,
            'is_active': professional.isActive,
          })
          .eq('id', professional.id)
          .select(
              'id, name, specialty_id, available_days, avatar_url, avatar_bg_color, is_active, specialties(name)')
          .single();
      return _professionalFromRow(data);
    } catch (e) {
      throw ServerException(message: 'Erro ao atualizar profissional: $e');
    }
  }

  @override
  Future<void> deleteProfessional(String id) async {
    try {
      await _supabase.from('professionals').delete().eq('id', id);
    } catch (e) {
      throw ServerException(message: 'Erro ao excluir profissional: $e');
    }
  }

  ProfessionalModel _professionalFromRow(Map<String, dynamic> e) {
    final days = (e['available_days'] as List<dynamic>?)
            ?.map((d) => d.toString())
            .join(', ') ??
        '';
    final specialtyName =
        (e['specialties'] as Map<String, dynamic>?)?['name'] as String? ?? '';
    return ProfessionalModel(
      id: e['id'] as String,
      name: e['name'] as String,
      specialtyId: e['specialty_id'] as String,
      specialtyName: specialtyName,
      availableDays: days,
      avatarUrl: e['avatar_url'] as String? ?? '',
      avatarBgColor: e['avatar_bg_color'] as int? ?? 0,
      whatsappNumber: '',
      isActive: e['is_active'] as bool,
    );
  }

  // ============================================================
  // PLANS
  // ============================================================

  @override
  Future<List<PlanAdminModel>> getPlans() async {
    try {
      final data = await _supabase
          .from('plans')
          .select(
              'id, name, subscription_type, price, discount_label, is_active, plan_benefits(title, sort_order)')
          .order('name');
      return (data as List).map((e) => _planFromRow(e)).toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar planos: $e');
    }
  }

  @override
  Future<PlanAdminModel> getPlanById(String id) async {
    try {
      final data = await _supabase
          .from('plans')
          .select(
              'id, name, subscription_type, price, discount_label, is_active, plan_benefits(title, sort_order)')
          .eq('id', id)
          .single();
      return _planFromRow(data);
    } catch (e) {
      throw ServerException(message: 'Plano não encontrado: $e');
    }
  }

  @override
  Future<PlanAdminModel> createPlan(PlanAdminEntity plan) async {
    try {
      final planData = await _supabase
          .from('plans')
          .insert({
            'name': plan.name,
            'subscription_type': plan.subscriptionType,
            'price': plan.price,
            'discount_label': plan.discountLabel,
            'is_active': plan.isActive,
          })
          .select('id')
          .single();
      final planId = planData['id'] as String;
      for (int i = 0; i < plan.benefits.length; i++) {
        await _supabase.from('plan_benefits').insert({
          'plan_id': planId,
          'title': plan.benefits[i],
          'description': plan.benefits[i],
          'sort_order': i,
        });
      }
      return getPlanById(planId);
    } catch (e) {
      throw ServerException(message: 'Erro ao criar plano: $e');
    }
  }

  @override
  Future<PlanAdminModel> updatePlan(PlanAdminEntity plan) async {
    try {
      await _supabase.from('plans').update({
        'name': plan.name,
        'subscription_type': plan.subscriptionType,
        'price': plan.price,
        'discount_label': plan.discountLabel,
        'is_active': plan.isActive,
      }).eq('id', plan.id);
      await _supabase.from('plan_benefits').delete().eq('plan_id', plan.id);
      for (int i = 0; i < plan.benefits.length; i++) {
        await _supabase.from('plan_benefits').insert({
          'plan_id': plan.id,
          'title': plan.benefits[i],
          'description': plan.benefits[i],
          'sort_order': i,
        });
      }
      return getPlanById(plan.id);
    } catch (e) {
      throw ServerException(message: 'Erro ao atualizar plano: $e');
    }
  }

  @override
  Future<void> deletePlan(String id) async {
    try {
      await _supabase.from('plans').delete().eq('id', id);
    } catch (e) {
      throw ServerException(message: 'Erro ao excluir plano: $e');
    }
  }

  PlanAdminModel _planFromRow(Map<String, dynamic> e) {
    final benefitsRaw = e['plan_benefits'] as List<dynamic>? ?? [];
    benefitsRaw.sort((a, b) => ((a['sort_order'] as int?) ?? 0)
        .compareTo((b['sort_order'] as int?) ?? 0));
    final benefits = benefitsRaw.map((b) => b['title'] as String).toList();
    return PlanAdminModel(
      id: e['id'] as String,
      name: e['name'] as String,
      subscriptionType: e['subscription_type'] as String,
      price: (e['price'] as num).toDouble(),
      discountLabel: e['discount_label'] as String?,
      benefits: benefits,
      isActive: e['is_active'] as bool,
    );
  }

  // ============================================================
  // USERS
  // ============================================================

  @override
  Future<List<UserAdminModel>> getUsers() async {
    try {
      final data = await _supabase
          .from('profiles')
          .select(
              'id, name, email, role, status, member_since, subscriptions(plan_id, badge_level, plan_level_status, activation_date, is_current, plans(name))')
          .order('name');
      return (data as List).map((e) => _userFromRow(e)).toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar usuários: $e');
    }
  }

  @override
  Future<UserAdminModel> getUserById(String id) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select(
              'id, name, email, role, status, member_since, subscriptions(plan_id, badge_level, plan_level_status, activation_date, is_current, plans(name))')
          .eq('id', id)
          .single();
      return _userFromRow(data);
    } catch (e) {
      throw ServerException(message: 'Usuário não encontrado: $e');
    }
  }

  @override
  Future<UserAdminModel> createUser(UserAdminEntity user) async {
    throw const ServerException(
        message: 'Criação de usuário deve ser feita via Supabase Auth.');
  }

  @override
  Future<UserAdminModel> updateUser(UserAdminEntity user) async {
    try {
      await _supabase.from('profiles').update({
        'name': user.name,
        'status': user.status,
        'role': user.role
      }).eq('id', user.id);
      return getUserById(user.id);
    } catch (e) {
      throw ServerException(message: 'Erro ao atualizar usuário: $e');
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      await _supabase.from('profiles').delete().eq('id', id);
    } catch (e) {
      throw ServerException(message: 'Erro ao excluir usuário: $e');
    }
  }

  UserAdminModel _userFromRow(Map<String, dynamic> e) {
    final subs = e['subscriptions'] as List<dynamic>?;
    final activeSub = subs?.firstWhere(
      (s) => s['is_current'] == true,
      orElse: () => null,
    ) as Map<String, dynamic>?;
    return UserAdminModel(
      id: e['id'] as String,
      name: e['name'] as String,
      email: e['email'] as String,
      cpf: '***.***.***-**',
      phone: '(**) *****-****',
      currentPlanId: activeSub?['plan_id'] as String?,
      planLevelName: activeSub?['badge_level'] as String? ?? 'sem plano',
      status: e['status'] as String,
      memberSince: e['member_since'] as String,
      planActivationDate: activeSub?['activation_date'] as String?,
      role: e['role'] as String? ?? 'user',
    );
  }

  // ============================================================
  // PAYMENTS
  // ============================================================

  @override
  Future<List<PaymentAdminModel>> getPayments() async {
    try {
      final data = await _supabase
          .from('payments')
          .select(
              'id, user_id, amount, method, status, receipt_number, paid_at, created_at, profiles(name), subscriptions(plans(name))')
          .order('created_at', ascending: false);
      return (data as List).map((e) => _paymentFromRow(e)).toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar pagamentos: $e');
    }
  }

  @override
  Future<PaymentAdminModel> getPaymentById(String id) async {
    try {
      final data = await _supabase
          .from('payments')
          .select(
              'id, user_id, amount, method, status, receipt_number, paid_at, created_at, profiles(name), subscriptions(plans(name))')
          .eq('id', id)
          .single();
      return _paymentFromRow(data);
    } catch (e) {
      throw ServerException(message: 'Pagamento não encontrado: $e');
    }
  }

  @override
  Future<PaymentAdminModel> createPayment(PaymentAdminEntity payment) async {
    try {
      final data = await _supabase
          .from('payments')
          .insert({
            'user_id': payment.userId,
            'amount': payment.amount,
            'method': payment.method,
            'status': payment.status,
            'receipt_number': payment.receiptNumber,
            'paid_at': payment.status == 'aprovado'
                ? DateTime.now().toIso8601String()
                : null,
          })
          .select('id')
          .single();
      return getPaymentById(data['id'] as String);
    } catch (e) {
      throw ServerException(message: 'Erro ao criar pagamento: $e');
    }
  }

  @override
  Future<PaymentAdminModel> updatePayment(PaymentAdminEntity payment) async {
    try {
      await _supabase
          .from('payments')
          .update({'status': payment.status}).eq('id', payment.id);
      return getPaymentById(payment.id);
    } catch (e) {
      throw ServerException(message: 'Erro ao atualizar pagamento: $e');
    }
  }

  @override
  Future<void> deletePayment(String id) async {
    try {
      await _supabase.from('payments').delete().eq('id', id);
    } catch (e) {
      throw ServerException(message: 'Erro ao excluir pagamento: $e');
    }
  }

  PaymentAdminModel _paymentFromRow(Map<String, dynamic> e) {
    final userName =
        (e['profiles'] as Map<String, dynamic>?)?['name'] as String? ?? '';
    final planName = ((e['subscriptions'] as Map<String, dynamic>?)?['plans']
            as Map<String, dynamic>?)?['name'] as String? ??
        '';
    return PaymentAdminModel(
      id: e['id'] as String,
      userId: e['user_id'] as String,
      userName: userName,
      planName: planName,
      amount: (e['amount'] as num).toDouble(),
      method: e['method'] as String,
      status: e['status'] as String,
      date: (e['paid_at'] ?? e['created_at']) as String,
      receiptNumber: e['receipt_number'] as String,
    );
  }

  // ============================================================
  // CONSULTATIONS
  // ============================================================

  @override
  Future<List<ConsultationAdminModel>> getConsultations() async {
    try {
      final data = await _supabase
          .from('consultations')
          .select(
              'id, title, subtitle, scheduled_date, status, user_id, professional_id, profiles(name), professionals(name)')
          .order('scheduled_date', ascending: false);
      return (data as List).map((e) => _consultationFromRow(e)).toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar consultas: $e');
    }
  }

  @override
  Future<ConsultationAdminModel> getConsultationById(String id) async {
    try {
      final data = await _supabase
          .from('consultations')
          .select(
              'id, title, subtitle, scheduled_date, status, user_id, professional_id, profiles(name), professionals(name)')
          .eq('id', id)
          .single();
      return _consultationFromRow(data);
    } catch (e) {
      throw ServerException(message: 'Consulta não encontrada: $e');
    }
  }

  @override
  Future<ConsultationAdminModel> createConsultation(
      ConsultationAdminEntity consultation) async {
    try {
      final data = await _supabase
          .from('consultations')
          .insert({
            'title': consultation.title,
            'subtitle': consultation.subtitle,
            'scheduled_date': consultation.date.toIso8601String(),
            'user_id': consultation.userId,
            'professional_id': consultation.professionalId,
            'status': 'agendada',
          })
          .select('id')
          .single();
      return getConsultationById(data['id'] as String);
    } catch (e) {
      throw ServerException(message: 'Erro ao criar consulta: $e');
    }
  }

  @override
  Future<ConsultationAdminModel> updateConsultation(
      ConsultationAdminEntity consultation) async {
    try {
      await _supabase.from('consultations').update({
        'title': consultation.title,
        'subtitle': consultation.subtitle,
        'scheduled_date': consultation.date.toIso8601String(),
        'professional_id': consultation.professionalId,
      }).eq('id', consultation.id);
      return getConsultationById(consultation.id);
    } catch (e) {
      throw ServerException(message: 'Erro ao atualizar consulta: $e');
    }
  }

  @override
  Future<void> deleteConsultation(String id) async {
    try {
      await _supabase.from('consultations').delete().eq('id', id);
    } catch (e) {
      throw ServerException(message: 'Erro ao excluir consulta: $e');
    }
  }

  ConsultationAdminModel _consultationFromRow(Map<String, dynamic> e) {
    return ConsultationAdminModel(
      id: e['id'] as String,
      title: e['title'] as String,
      subtitle: e['subtitle'] as String? ?? '',
      date: DateTime.parse(e['scheduled_date'] as String),
      professionalId: e['professional_id'] as String,
      professionalName:
          (e['professionals'] as Map<String, dynamic>?)?['name'] as String? ??
              '',
      userId: e['user_id'] as String,
      userName:
          (e['profiles'] as Map<String, dynamic>?)?['name'] as String? ?? '',
    );
  }

  // ============================================================
  // NOTIFICATION TEMPLATES
  // ============================================================

  @override
  Future<List<NotificationTemplateModel>> getNotifications() async {
    try {
      final data = await _supabase
          .from('notification_templates')
          .select('id, title, body, type, trigger_event, is_active')
          .order('title');
      return (data as List).map((e) => _notifFromRow(e)).toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar templates: $e');
    }
  }

  @override
  Future<NotificationTemplateModel> getNotificationById(String id) async {
    try {
      final data = await _supabase
          .from('notification_templates')
          .select('id, title, body, type, trigger_event, is_active')
          .eq('id', id)
          .single();
      return _notifFromRow(data);
    } catch (e) {
      throw ServerException(message: 'Template não encontrado: $e');
    }
  }

  @override
  Future<NotificationTemplateModel> createNotification(
      NotificationTemplateEntity notification) async {
    try {
      final data = await _supabase
          .from('notification_templates')
          .insert({
            'title': notification.title,
            'body': notification.body,
            'type': notification.type,
            'trigger_event': notification.triggerEvent,
            'is_active': notification.isActive,
          })
          .select('id')
          .single();
      return getNotificationById(data['id'] as String);
    } catch (e) {
      throw ServerException(message: 'Erro ao criar template: $e');
    }
  }

  @override
  Future<NotificationTemplateModel> updateNotification(
      NotificationTemplateEntity notification) async {
    try {
      await _supabase.from('notification_templates').update({
        'title': notification.title,
        'body': notification.body,
        'type': notification.type,
        'trigger_event': notification.triggerEvent,
        'is_active': notification.isActive,
      }).eq('id', notification.id);
      return getNotificationById(notification.id);
    } catch (e) {
      throw ServerException(message: 'Erro ao atualizar template: $e');
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    try {
      await _supabase.from('notification_templates').delete().eq('id', id);
    } catch (e) {
      throw ServerException(message: 'Erro ao excluir template: $e');
    }
  }

  NotificationTemplateModel _notifFromRow(Map<String, dynamic> e) {
    return NotificationTemplateModel(
      id: e['id'] as String,
      title: e['title'] as String,
      body: e['body'] as String,
      type: e['type'] as String,
      triggerEvent: e['trigger_event'] as String,
      isActive: e['is_active'] as bool,
    );
  }

  // ============================================================
  // DRAWS
  // ============================================================

  @override
  Future<List<DrawModel>> getDraws() async {
    try {
      final data = await _supabase
          .from('draws')
          .select('*, profiles(name)')
          .order('draw_date', ascending: false);
      return (data as List).map((e) => _drawFromRow(e)).toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar sorteios: $e');
    }
  }

  @override
  Future<DrawModel> getDrawById(String id) async {
    try {
      final data = await _supabase
          .from('draws')
          .select('*, profiles(name)')
          .eq('id', id)
          .single();
      return _drawFromRow(data);
    } catch (e) {
      throw ServerException(message: 'Sorteio não encontrado: $e');
    }
  }

  @override
  Future<DrawModel> createDraw(DrawEntity draw) async {
    try {
      final data = await _supabase
          .from('draws')
          .insert({
            'name': draw.name,
            'prize_name': draw.prizeName,
            'prize_description': draw.prizeDescription,
            'prize_image_url': draw.prizeImageUrl,
            'draw_date': draw.drawDate.toIso8601String(),
            'registration_start_date':
                draw.registrationStartDate?.toIso8601String(),
            'registration_end_date':
                draw.registrationEndDate?.toIso8601String(),
            'status': draw.status,
            'eligible_plan_levels': draw.eligiblePlanLevels,
            'rules': draw.rules,
          })
          .select('id')
          .single();
      return getDrawById(data['id'] as String);
    } catch (e) {
      throw ServerException(message: 'Erro ao criar sorteio: $e');
    }
  }

  @override
  Future<DrawModel> updateDraw(DrawEntity draw) async {
    try {
      await _supabase.from('draws').update({
        'name': draw.name,
        'prize_name': draw.prizeName,
        'prize_description': draw.prizeDescription,
        'prize_image_url': draw.prizeImageUrl,
        'draw_date': draw.drawDate.toIso8601String(),
        'registration_start_date':
            draw.registrationStartDate?.toIso8601String(),
        'registration_end_date': draw.registrationEndDate?.toIso8601String(),
        'status': draw.status,
        'eligible_plan_levels': draw.eligiblePlanLevels,
        'rules': draw.rules,
      }).eq('id', draw.id);
      return getDrawById(draw.id);
    } catch (e) {
      throw ServerException(message: 'Erro ao atualizar sorteio: $e');
    }
  }

  @override
  Future<void> deleteDraw(String id) async {
    try {
      await _supabase.from('draws').delete().eq('id', id);
    } catch (e) {
      throw ServerException(message: 'Erro ao excluir sorteio: $e');
    }
  }

  @override
  Future<DrawModel> executeDraw(String drawId) async {
    try {
      final participants = await _supabase
          .from('draw_participants')
          .select('user_id')
          .eq('draw_id', drawId);
      if ((participants as List).isEmpty) {
        throw const ServerException(message: 'Sem participantes no sorteio.');
      }
      final random = Random.secure();
      final winnerIndex = random.nextInt(participants.length);
      final winnerId = participants[winnerIndex]['user_id'] as String;
      final now = DateTime.now();
      final seedHash = sha256
          .convert(utf8.encode('${drawId}_${now.millisecondsSinceEpoch}'))
          .toString();
      final listHash =
          sha256.convert(utf8.encode(participants.toString())).toString();
      await _supabase.from('draws').update({
        'status': 'realizado',
        'winner_id': winnerId,
        'winner_index': winnerIndex,
        'draw_seed_hash': seedHash,
        'participant_list_hash': listHash,
        'executed_at': now.toIso8601String(),
        'participant_count': participants.length,
      }).eq('id', drawId);
      return getDrawById(drawId);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Erro ao executar sorteio: $e');
    }
  }

  DrawModel _drawFromRow(Map<String, dynamic> e) {
    return DrawModel(
      id: e['id'] as String,
      name: e['name'] as String,
      prizeName: e['prize_name'] as String,
      prizeDescription: e['prize_description'] as String?,
      prizeImageUrl: e['prize_image_url'] as String?,
      drawDate: DateTime.parse(e['draw_date'] as String),
      registrationStartDate: e['registration_start_date'] != null
          ? DateTime.parse(e['registration_start_date'] as String)
          : null,
      registrationEndDate: e['registration_end_date'] != null
          ? DateTime.parse(e['registration_end_date'] as String)
          : null,
      status: e['status'] as String,
      participantCount: e['participant_count'] as int? ?? 0,
      winnerId: e['winner_id'] as String?,
      winnerName: (e['profiles'] as Map<String, dynamic>?)?['name'] as String?,
      eligiblePlanLevels: (e['eligible_plan_levels'] as List<dynamic>?)
              ?.map((l) => l.toString())
              .toList() ??
          [],
      rules: e['rules'] as String?,
      drawSeedHash: e['draw_seed_hash'] as String?,
      participantListHash: e['participant_list_hash'] as String?,
      executedAt: e['executed_at'] != null
          ? DateTime.parse(e['executed_at'] as String)
          : null,
      winnerIndex: e['winner_index'] as int?,
    );
  }

  // ============================================================
  // COUPONS
  // ============================================================

  @override
  Future<List<CouponModel>> getCoupons() async {
    try {
      final data = await _supabase
          .from('coupons')
          .select(
              'id, code, description, discount_percentage, expiry_date, usage_limit, used_count, is_active')
          .order('created_at', ascending: false);
      return (data as List).map((e) => _couponFromRow(e)).toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar cupons: $e');
    }
  }

  @override
  Future<CouponModel> getCouponById(String id) async {
    try {
      final data = await _supabase
          .from('coupons')
          .select(
              'id, code, description, discount_percentage, expiry_date, usage_limit, used_count, is_active')
          .eq('id', id)
          .single();
      return _couponFromRow(data);
    } catch (e) {
      throw ServerException(message: 'Cupom não encontrado: $e');
    }
  }

  @override
  Future<CouponModel> createCoupon(CouponEntity coupon) async {
    try {
      final data = await _supabase
          .from('coupons')
          .insert({
            'code': coupon.code,
            'description': coupon.description,
            'discount_percentage': coupon.discountPercentage,
            'expiry_date': coupon.expiryDate.toIso8601String(),
            'usage_limit': coupon.usageLimit,
            'is_active': coupon.isActive,
          })
          .select('id')
          .single();
      return getCouponById(data['id'] as String);
    } catch (e) {
      throw ServerException(message: 'Erro ao criar cupom: $e');
    }
  }

  @override
  Future<CouponModel> updateCoupon(CouponEntity coupon) async {
    try {
      await _supabase.from('coupons').update({
        'description': coupon.description,
        'discount_percentage': coupon.discountPercentage,
        'expiry_date': coupon.expiryDate.toIso8601String(),
        'usage_limit': coupon.usageLimit,
        'is_active': coupon.isActive,
      }).eq('id', coupon.id);
      return getCouponById(coupon.id);
    } catch (e) {
      throw ServerException(message: 'Erro ao atualizar cupom: $e');
    }
  }

  @override
  Future<void> deleteCoupon(String id) async {
    try {
      await _supabase.from('coupons').delete().eq('id', id);
    } catch (e) {
      throw ServerException(message: 'Erro ao excluir cupom: $e');
    }
  }

  CouponModel _couponFromRow(Map<String, dynamic> e) {
    return CouponModel(
      id: e['id'] as String,
      code: e['code'] as String,
      description: e['description'] as String,
      discountPercentage: (e['discount_percentage'] as num).toDouble(),
      expiryDate: DateTime.parse(e['expiry_date'] as String),
      usageLimit: e['usage_limit'] as int,
      usedCount: e['used_count'] as int? ?? 0,
      isActive: e['is_active'] as bool,
    );
  }

  // ============================================================
  // CANCELLATION REASONS
  // ============================================================

  @override
  Future<List<CancellationReasonModel>> getCancellationReasons() async {
    try {
      final data = await _supabase
          .from('cancellation_reasons')
          .select('id, text, usage_count, is_active')
          .order('text');
      return (data as List)
          .map((e) => CancellationReasonModel(
                id: e['id'] as String,
                text: e['text'] as String,
                usageCount: e['usage_count'] as int? ?? 0,
                isActive: e['is_active'] as bool,
              ))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar motivos: $e');
    }
  }

  @override
  Future<CancellationReasonModel> getCancellationReasonById(String id) async {
    try {
      final data = await _supabase
          .from('cancellation_reasons')
          .select('id, text, usage_count, is_active')
          .eq('id', id)
          .single();
      return CancellationReasonModel(
        id: data['id'] as String,
        text: data['text'] as String,
        usageCount: data['usage_count'] as int? ?? 0,
        isActive: data['is_active'] as bool,
      );
    } catch (e) {
      throw ServerException(message: 'Motivo não encontrado: $e');
    }
  }

  @override
  Future<CancellationReasonModel> createCancellationReason(
      CancellationReasonEntity reason) async {
    try {
      final data = await _supabase
          .from('cancellation_reasons')
          .insert({'text': reason.text, 'is_active': reason.isActive})
          .select('id')
          .single();
      return getCancellationReasonById(data['id'] as String);
    } catch (e) {
      throw ServerException(message: 'Erro ao criar motivo: $e');
    }
  }

  @override
  Future<CancellationReasonModel> updateCancellationReason(
      CancellationReasonEntity reason) async {
    try {
      await _supabase
          .from('cancellation_reasons')
          .update({'text': reason.text, 'is_active': reason.isActive}).eq(
              'id', reason.id);
      return getCancellationReasonById(reason.id);
    } catch (e) {
      throw ServerException(message: 'Erro ao atualizar motivo: $e');
    }
  }

  @override
  Future<void> deleteCancellationReason(String id) async {
    try {
      await _supabase.from('cancellation_reasons').delete().eq('id', id);
    } catch (e) {
      throw ServerException(message: 'Erro ao excluir motivo: $e');
    }
  }

  // ============================================================
  // BADGES (admin config)
  // ============================================================

  @override
  Future<List<BadgeModel>> getBadges() async {
    try {
      final data = await _supabase
          .from('badges')
          .select(
              'id, level_name, display_name, badge_image_url, progress_color, progress_bg_color, sort_order, discount_percentage, max_consultations_per_month')
          .order('sort_order');
      return (data as List).map((e) => _badgeFromRow(e)).toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar badges: $e');
    }
  }

  @override
  Future<BadgeModel> getBadgeById(String id) async {
    try {
      final data = await _supabase
          .from('badges')
          .select(
              'id, level_name, display_name, badge_image_url, progress_color, progress_bg_color, sort_order, discount_percentage, max_consultations_per_month')
          .eq('id', id)
          .single();
      return _badgeFromRow(data);
    } catch (e) {
      throw ServerException(message: 'Badge não encontrado: $e');
    }
  }

  @override
  Future<BadgeModel> createBadge(BadgeEntity badge) async {
    try {
      final data = await _supabase
          .from('badges')
          .insert({
            'level_name': badge.levelName,
            'display_name': badge.displayName,
            'badge_image_url': badge.badgeImageUrl,
            'progress_color': badge.progressColor,
            'progress_bg_color': badge.progressBgColor,
            'sort_order': badge.sortOrder,
            'discount_percentage': badge.discountPercentage,
            'max_consultations_per_month': badge.maxConsultationsPerMonth,
          })
          .select('id')
          .single();
      return getBadgeById(data['id'] as String);
    } catch (e) {
      throw ServerException(message: 'Erro ao criar badge: $e');
    }
  }

  @override
  Future<BadgeModel> updateBadge(BadgeEntity badge) async {
    try {
      await _supabase.from('badges').update({
        'display_name': badge.displayName,
        'badge_image_url': badge.badgeImageUrl,
        'progress_color': badge.progressColor,
        'progress_bg_color': badge.progressBgColor,
        'sort_order': badge.sortOrder,
        'discount_percentage': badge.discountPercentage,
        'max_consultations_per_month': badge.maxConsultationsPerMonth,
      }).eq('id', badge.id);
      return getBadgeById(badge.id);
    } catch (e) {
      throw ServerException(message: 'Erro ao atualizar badge: $e');
    }
  }

  @override
  Future<void> deleteBadge(String id) async {
    try {
      await _supabase.from('badges').delete().eq('id', id);
    } catch (e) {
      throw ServerException(message: 'Erro ao excluir badge: $e');
    }
  }

  BadgeModel _badgeFromRow(Map<String, dynamic> e) {
    return BadgeModel(
      id: e['id'] as String,
      levelName: e['level_name'] as String,
      displayName: e['display_name'] as String,
      badgeImageUrl: e['badge_image_url'] as String? ?? '',
      progressColor: e['progress_color'] as int? ?? 0,
      progressBgColor: e['progress_bg_color'] as int? ?? 0,
      sortOrder: e['sort_order'] as int? ?? 0,
      discountPercentage: (e['discount_percentage'] as num?)?.toDouble() ?? 0,
      maxConsultationsPerMonth: e['max_consultations_per_month'] as int? ?? 0,
    );
  }
}
