import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/rate_limit.dart';
import '../../domain/entities/partner_entity.dart';
import '../../domain/entities/partner_service_entity.dart';
import '../models/partner_application_model.dart';
import '../models/partner_model.dart';
import '../models/partner_service_model.dart';
import '../models/partner_validation_model.dart';
import 'parceiro_datasource.dart';

class ParceiroSupabaseDataSource implements ParceiroDataSource {
  final SupabaseClient _supabase;

  ParceiroSupabaseDataSource({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  // ============================================================
  // PARTNERS
  // ============================================================

  @override
  Future<List<PartnerModel>> getPartners() async {
    try {
      final data = await _supabase
          .from('partners')
          .select(
              'id, profile_id, name, category, code, address, logo_url, is_active, discount_percentage')
          .eq('is_active', true)
          .order('name');
      return (data as List).map((e) => _partnerFromRow(e)).toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar parceiros: $e');
    }
  }

  @override
  Future<PartnerModel> getPartnerByProfileId(String profileId) async {
    try {
      final data = await _supabase
          .from('partners')
          .select(
              'id, profile_id, name, category, code, address, logo_url, is_active, discount_percentage')
          .eq('profile_id', profileId)
          .single();
      return _partnerFromRow(data);
    } catch (e) {
      throw ServerException(message: 'Parceiro não encontrado: $e');
    }
  }

  @override
  Future<List<PartnerModel>> getAllPartners() async {
    try {
      final data = await _supabase
          .from('partners')
          .select(
              'id, profile_id, name, category, code, address, logo_url, is_active, discount_percentage')
          .order('name');
      return (data as List).map((e) => _partnerFromRow(e)).toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar parceiros: $e');
    }
  }

  @override
  Future<PartnerModel> updatePartner(PartnerEntity entity) async {
    try {
      await _supabase.from('partners').update({
        'name': entity.name,
        'address': entity.address,
        'logo_url': entity.logoUrl,
        'is_active': entity.isActive,
        'discount_percentage': entity.discountPercentage,
        'category': entity.category,
      }).eq('id', entity.id);
      return getPartnerByProfileId(entity.profileId);
    } catch (e) {
      throw ServerException(message: 'Erro ao atualizar parceiro: $e');
    }
  }

  @override
  Future<PartnerModel> regenerateCode(String partnerId) async {
    try {
      final code = _generateCode();
      final data = await _supabase
          .from('partners')
          .update({'code': code})
          .eq('id', partnerId)
          .select(
              'id, profile_id, name, category, code, address, logo_url, is_active, discount_percentage')
          .single();
      return _partnerFromRow(data);
    } catch (e) {
      throw ServerException(message: 'Erro ao gerar novo código: $e');
    }
  }

  // ============================================================
  // PARTNER APPLICATIONS
  // ============================================================

  @override
  Future<void> submitPartnerApplication({
    required String name,
    required String category,
    String? address,
    String? phone,
    required String email,
    String? userId,
  }) async {
    try {
      await _supabase.from('partner_applications').insert({
        'user_id': userId,
        'name': name,
        'category': category,
        'address': address,
        'phone': phone,
        'email': email,
      });
    } catch (e) {
      throw ServerException(message: 'Erro ao enviar candidatura: $e');
    }
  }

  @override
  Future<List<PartnerApplicationModel>> getPartnerApplications() async {
    try {
      final data = await _supabase
          .from('partner_applications')
          .select(
              'id, user_id, name, category, address, phone, email, status, created_at, reviewed_at, rejection_reason')
          .order('created_at', ascending: false);
      return (data as List)
          .map((e) =>
              PartnerApplicationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar candidaturas: $e');
    }
  }

  @override
  Future<void> approvePartnerApplication(
    String id, {
    required String reviewerId,
  }) async {
    try {
      final application = await _supabase
          .from('partner_applications')
          .select(
              'user_id, name, category, address, proposed_discount_percentage')
          .eq('id', id)
          .single();
      final userId = application['user_id'] as String?;

      if (userId != null) {
        await _supabase
            .from('profiles')
            .update({'role': 'parceiro'}).eq('id', userId);
        await _supabase.from('partners').insert({
          'profile_id': userId,
          'name': application['name'],
          'category': application['category'],
          'code': _generateCode(),
          'address': application['address'],
          'discount_percentage':
              (application['proposed_discount_percentage'] as num?)
                      ?.toDouble() ??
                  0,
        });
      }

      await _supabase.from('partner_applications').update({
        'status': 'approved',
        'reviewed_at': DateTime.now().toIso8601String(),
        'reviewed_by': reviewerId,
      }).eq('id', id);
    } catch (e) {
      throw ServerException(message: 'Erro ao aprovar candidatura: $e');
    }
  }

  @override
  Future<void> rejectPartnerApplication(
    String id, {
    required String reviewerId,
    required String reason,
  }) async {
    try {
      await _supabase.from('partner_applications').update({
        'status': 'rejected',
        'rejection_reason': reason,
        'reviewed_at': DateTime.now().toIso8601String(),
        'reviewed_by': reviewerId,
      }).eq('id', id);
    } catch (e) {
      throw ServerException(message: 'Erro ao rejeitar candidatura: $e');
    }
  }

  PartnerModel _partnerFromRow(Map<String, dynamic> e) {
    return PartnerModel.fromJson(e);
  }

  // ============================================================
  // PARTNER SERVICES
  // ============================================================

  @override
  Future<List<PartnerServiceModel>> getServicesByPartnerId(
      String partnerId) async {
    try {
      final data = await _supabase
          .from('partner_services')
          .select(
              'id, partner_id, name, description, original_price, discounted_price, is_active')
          .eq('partner_id', partnerId)
          .eq('is_active', true)
          .order('name');
      return (data as List).map((e) => _serviceFromRow(e)).toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar serviços: $e');
    }
  }

  @override
  Future<List<PartnerServiceModel>> getAllActiveServices() async {
    try {
      final data = await _supabase
          .from('partner_services')
          .select(
              'id, partner_id, name, description, original_price, discounted_price, is_active')
          .eq('is_active', true)
          .order('name');
      return (data as List).map((e) => _serviceFromRow(e)).toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar serviços: $e');
    }
  }

  @override
  Future<PartnerServiceModel> createService(PartnerServiceEntity entity) async {
    try {
      final data = await _supabase
          .from('partner_services')
          .insert({
            'partner_id': entity.partnerId,
            'name': entity.name,
            'description': entity.description,
            'original_price': entity.originalPrice,
            'discounted_price': entity.discountedPrice,
            'is_active': entity.isActive,
          })
          .select(
              'id, partner_id, name, description, original_price, discounted_price, is_active')
          .single();
      return _serviceFromRow(data);
    } catch (e) {
      throw ServerException(message: 'Erro ao criar serviço: $e');
    }
  }

  @override
  Future<PartnerServiceModel> updateService(PartnerServiceEntity entity) async {
    try {
      final data = await _supabase
          .from('partner_services')
          .update({
            'name': entity.name,
            'description': entity.description,
            'original_price': entity.originalPrice,
            'discounted_price': entity.discountedPrice,
            'is_active': entity.isActive,
          })
          .eq('id', entity.id)
          .select(
              'id, partner_id, name, description, original_price, discounted_price, is_active')
          .single();
      return _serviceFromRow(data);
    } catch (e) {
      throw ServerException(message: 'Erro ao atualizar serviço: $e');
    }
  }

  @override
  Future<void> deleteService(String id) async {
    try {
      await _supabase.from('partner_services').delete().eq('id', id);
    } catch (e) {
      throw ServerException(message: 'Erro ao excluir serviço: $e');
    }
  }

  PartnerServiceModel _serviceFromRow(Map<String, dynamic> e) {
    return PartnerServiceModel(
      id: e['id'] as String,
      partnerId: e['partner_id'] as String,
      name: e['name'] as String,
      description: e['description'] as String? ?? '',
      originalPrice: (e['original_price'] as num).toDouble(),
      discountedPrice: (e['discounted_price'] as num).toDouble(),
      isActive: e['is_active'] as bool? ?? true,
    );
  }

  // ============================================================
  // PARTNER VALIDATIONS
  // ============================================================

  @override
  Future<List<PartnerValidationModel>> getValidationsByPartnerId(
      String partnerId) async {
    try {
      final data = await _supabase
          .from('partner_validations')
          .select(
              'id, partner_id, user_id, user_name, user_badge_level, discount_applied, service_id, service_name, validated_at, discount_percentage, original_value, savings_amount, beneficiary_type, dependent_id')
          .eq('partner_id', partnerId)
          .order('validated_at', ascending: false);
      return (data as List).map((e) => _validationFromRow(e)).toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar validações: $e');
    }
  }

  @override
  Future<PartnerValidationModel> validateCheckin({
    required String userId,
    required String token,
    required String partnerCode,
    required String serviceId,
  }) async {
    try {
      final partner = await _supabase
          .from('partners')
          .select('id')
          .eq('code', partnerCode)
          .single();
      final partnerId = partner['id'] as String;

      final profile = await _supabase
          .from('profiles')
          .select('name')
          .eq('id', userId)
          .single();
      final progress = await _supabase
          .from('badge_progress')
          .select('current_badge_level')
          .eq('user_id', userId)
          .maybeSingle();
      final badgeLevel =
          progress?['current_badge_level'] as String? ?? 'bronze';

      final service = await _supabase
          .from('partner_services')
          .select('name, discounted_price, original_price')
          .eq('id', serviceId)
          .single();
      final discountApplied = (service['original_price'] as num).toDouble() -
          (service['discounted_price'] as num).toDouble();

      final data = await _supabase
          .from('partner_validations')
          .insert({
            'partner_id': partnerId,
            'user_id': userId,
            'service_id': serviceId,
            'user_name': profile['name'] as String,
            'user_badge_level': badgeLevel,
            'discount_applied': discountApplied,
            'service_name': service['name'] as String,
          })
          .select(
              'id, partner_id, user_id, user_name, user_badge_level, discount_applied, service_id, service_name, validated_at')
          .single();
      return _validationFromRow(data);
    } catch (e) {
      throw ServerException(message: 'Erro ao validar check-in: $e');
    }
  }

  @override
  Future<String> generateToken(String userId) async {
    // Token temporário: UUID curto, válido por 5 min no cliente
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(Iterable.generate(
        8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  PartnerValidationModel _validationFromRow(Map<String, dynamic> e) {
    return PartnerValidationModel.fromJson(e);
  }

  @override
  Future<Map<String, dynamic>> confirmPartnerValidation({
    required String holderUserId,
    required String memberName,
    String? dependentId,
    double? originalValue,
    String? planLevel,
  }) async {
    try {
      final result = await _supabase.rpc('confirm_partner_validation', params: {
        'p_holder_user_id': holderUserId,
        'p_member_name': memberName,
        'p_dependent_id': dependentId,
        'p_original_value': originalValue,
        'p_plan_level': planLevel,
      });
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      throw ServerException(
        message: RateLimitMessages.messageOrNull(e) ??
            'Erro ao confirmar validação: $e',
      );
    }
  }

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(Iterable.generate(
        8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }
}
