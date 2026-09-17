import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/rate_limit.dart';
import '../../domain/entities/dependent_enums.dart';
import 'dependents_datasource.dart';

class DependentsSupabaseDataSource
    implements
        DependentsDataSource,
        DependentAppointmentDataSource,
        QrValidationDataSource,
        MemberQrValidationDataSource {
  SupabaseClient get _client => SupabaseConfig.client;

  @override
  Future<Map<String, dynamic>> createDependent({
    required String holderUserId,
    required String name,
    required String cpf,
    required DateTime birthDate,
    required String relationship,
  }) async {
    try {
      final row = await _client
          .from('dependents')
          .insert({
            'holder_user_id': holderUserId,
            'name': name,
            'cpf': cpf,
            'birth_date': birthDate.toIso8601String().split('T').first,
            'relationship': relationship,
          })
          .select()
          .single();
      return Map<String, dynamic>.from(row);
    } catch (e) {
      throw ServerException(message: 'Erro ao cadastrar dependente: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getDependents({
    required String holderUserId,
    String? status,
  }) async {
    try {
      var query = _client
          .from('dependents')
          .select()
          .eq('holder_user_id', holderUserId);
      if (status != null) {
        query = query.eq('status', status);
      }
      final rows = await query.order('created_at');
      return rows.map((row) => Map<String, dynamic>.from(row)).toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao listar dependentes: $e');
    }
  }

  @override
  Future<void> deactivateDependent({
    required String holderUserId,
    required String dependentId,
  }) async {
    try {
      await _client
          .from('dependents')
          .update({
            'status': 'inactive',
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', dependentId)
          .eq('holder_user_id', holderUserId);
    } catch (e) {
      throw ServerException(message: 'Erro ao inativar dependente: $e');
    }
  }

  @override
  Future<int> countActiveDependents({required String holderUserId}) async {
    try {
      // Conta pending+active — um cadastro pendente já ocupa vaga no limite,
      // pra não deixar fila de cadastros duplicados aguardando aprovação.
      final rows = await _client
          .from('dependents')
          .select('id')
          .eq('holder_user_id', holderUserId)
          .inFilter('status', ['active', 'pending']);
      return rows.length;
    } catch (e) {
      throw ServerException(message: 'Erro ao contar dependentes: $e');
    }
  }

  @override
  Future<bool> activeCpfExists(String cpf) async {
    try {
      final rows = await _client
          .from('dependents')
          .select('id')
          .eq('cpf', cpf)
          .inFilter('status', ['active', 'pending']).limit(1);
      return rows.isNotEmpty;
    } catch (e) {
      throw ServerException(message: 'Erro ao validar CPF do dependente: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingDependents() async {
    try {
      final rows = await _client
          .from('dependents')
          .select()
          .eq('status', 'pending')
          .order('created_at');
      final list = rows.map((r) => Map<String, dynamic>.from(r)).toList();
      if (list.isEmpty) return list;

      final holderIds =
          list.map((r) => r['holder_user_id'] as String).toSet().toList();
      final holders = await _client
          .from('profiles')
          .select('id, name, email')
          .inFilter('id', holderIds);
      final holderMap = {
        for (final h in holders) h['id'] as String: h,
      };
      for (final row in list) {
        final holder = holderMap[row['holder_user_id']];
        row['holder_name'] = holder?['name'];
        row['holder_email'] = holder?['email'];
      }
      return list;
    } catch (e) {
      throw ServerException(
          message: 'Erro ao listar dependentes pendentes: $e');
    }
  }

  @override
  Future<void> updateDependentStatus({
    required String dependentId,
    required String status,
    String? rejectionReason,
  }) async {
    try {
      await _client.from('dependents').update({
        'status': status,
        'rejection_reason': rejectionReason,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', dependentId);
    } catch (e) {
      throw ServerException(
          message: 'Erro ao atualizar status do dependente: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> createAppointment({
    required String holderUserId,
    required BeneficiaryType beneficiaryType,
    String? beneficiaryId,
    String? establishmentId,
    required DateTime scheduledAt,
    required String qrToken,
  }) async {
    try {
      final row = await _client
          .from('dependent_appointments')
          .insert({
            'holder_user_id': holderUserId,
            'beneficiary_type': beneficiaryType.dbValue,
            'beneficiary_id': beneficiaryId,
            'establishment_id': establishmentId,
            'scheduled_at': scheduledAt.toIso8601String(),
            'qr_token': qrToken,
          })
          .select()
          .single();
      return Map<String, dynamic>.from(row);
    } catch (e) {
      throw ServerException(message: 'Erro ao criar agendamento: $e');
    }
  }

  @override
  Future<void> cancelAppointment({
    required String holderUserId,
    required String appointmentId,
  }) async {
    try {
      await _client
          .from('dependent_appointments')
          .update({
            'status': 'cancelado',
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', appointmentId)
          .eq('holder_user_id', holderUserId)
          .eq('status', 'agendado');
    } catch (e) {
      throw ServerException(message: 'Erro ao cancelar agendamento: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUsageRecords({
    required String holderUserId,
    required BeneficiaryType beneficiaryType,
    String? beneficiaryId,
    required String cycleReference,
  }) async {
    try {
      var query = _client
          .from('usage_records')
          .select()
          .eq('holder_user_id', holderUserId)
          .eq('beneficiary_type', beneficiaryType.dbValue)
          .eq('cycle_reference', cycleReference);
      query = beneficiaryId == null
          ? query.isFilter('beneficiary_id', null)
          : query.eq('beneficiary_id', beneficiaryId);
      final rows = await query.order('used_at');
      return rows.map((row) => Map<String, dynamic>.from(row)).toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar usos do ciclo: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> validateQr({
    required String qrToken,
    required String actorUserId,
    String? establishmentId,
  }) async {
    try {
      final result = await _client.rpc('validate_dependent_qr', params: {
        'p_qr_token': qrToken,
        'p_actor_user_id': actorUserId,
        'p_establishment_id': establishmentId,
      });
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      throw ServerException(
        message: RateLimitMessages.messageOrNull(e) ?? 'Erro ao validar QR: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> validateMemberQr({
    required String identifier,
    required String actorUserId,
  }) async {
    try {
      final raw = identifier.trim();
      final result = await _client.rpc('validate_loyalty_card', params: {
        'p_payload': raw,
        'p_actor_user_id': actorUserId,
      });
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      throw ServerException(
        message: RateLimitMessages.messageOrNull(e) ??
            'Erro ao validar QR do membro: $e',
      );
    }
  }
}
