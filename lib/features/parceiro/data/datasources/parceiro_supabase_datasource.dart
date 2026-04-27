import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/partner_entity.dart';
import '../../domain/entities/partner_service_entity.dart';
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
          .select('id, profile_id, name, category, code, address, logo_url, is_active')
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
          .select('id, profile_id, name, category, code, address, logo_url, is_active')
          .eq('profile_id', profileId)
          .single();
      return _partnerFromRow(data);
    } catch (e) {
      throw ServerException(message: 'Parceiro não encontrado: $e');
    }
  }

  @override
  Future<PartnerModel> updatePartner(PartnerEntity entity) async {
    try {
      await _supabase
          .from('partners')
          .update({
            'name': entity.name,
            'address': entity.address,
            'logo_url': entity.logoUrl,
            'is_active': entity.isActive,
          })
          .eq('id', entity.id);
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
          .select('id, profile_id, name, category, code, address, logo_url, is_active')
          .single();
      return _partnerFromRow(data);
    } catch (e) {
      throw ServerException(message: 'Erro ao gerar novo código: $e');
    }
  }

  PartnerModel _partnerFromRow(Map<String, dynamic> e) {
    return PartnerModel(
      id: e['id'] as String,
      profileId: e['profile_id'] as String,
      name: e['name'] as String,
      category: e['category'] as String,
      code: e['code'] as String,
      address: e['address'] as String? ?? '',
      phone: '',
      logoUrl: e['logo_url'] as String? ?? '',
      isActive: e['is_active'] as bool? ?? true,
    );
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
          .select('id, partner_id, name, description, original_price, discounted_price, is_active')
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
          .select('id, partner_id, name, description, original_price, discounted_price, is_active')
          .eq('is_active', true)
          .order('name');
      return (data as List).map((e) => _serviceFromRow(e)).toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar serviços: $e');
    }
  }

  @override
  Future<PartnerServiceModel> createService(
      PartnerServiceEntity entity) async {
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
          .select('id, partner_id, name, description, original_price, discounted_price, is_active')
          .single();
      return _serviceFromRow(data);
    } catch (e) {
      throw ServerException(message: 'Erro ao criar serviço: $e');
    }
  }

  @override
  Future<PartnerServiceModel> updateService(
      PartnerServiceEntity entity) async {
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
          .select('id, partner_id, name, description, original_price, discounted_price, is_active')
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
          .select('id, partner_id, user_id, user_name, user_badge_level, discount_applied, service_id, service_name, validated_at')
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
          .select('id, partner_id, user_id, user_name, user_badge_level, discount_applied, service_id, service_name, validated_at')
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
    return String.fromCharCodes(
        Iterable.generate(8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  PartnerValidationModel _validationFromRow(Map<String, dynamic> e) {
    return PartnerValidationModel(
      id: e['id'] as String,
      partnerId: e['partner_id'] as String,
      userId: e['user_id'] as String,
      userName: e['user_name'] as String,
      userBadgeLevel: e['user_badge_level'] as String? ?? 'bronze',
      discountApplied: (e['discount_applied'] as num?)?.toDouble() ?? 0,
      serviceId: e['service_id'] as String,
      serviceName: e['service_name'] as String,
      validatedAt: DateTime.parse(e['validated_at'] as String),
    );
  }

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
        Iterable.generate(8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }
}
