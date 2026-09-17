import '../../domain/entities/partner_entity.dart';
import '../../domain/entities/partner_service_entity.dart';
import '../models/partner_application_model.dart';
import '../models/partner_model.dart';
import '../models/partner_service_model.dart';
import '../models/partner_validation_model.dart';

abstract class ParceiroDataSource {
  // Partners
  Future<List<PartnerModel>> getPartners();
  Future<PartnerModel> getPartnerByProfileId(String profileId);
  Future<List<PartnerModel>> getAllPartners();
  Future<PartnerModel> updatePartner(PartnerEntity entity);
  Future<PartnerModel> regenerateCode(String partnerId);
  Future<Map<String, dynamic>> confirmPartnerValidation({
    required String holderUserId,
    required String memberName,
    String? dependentId,
    double? originalValue,
    String? planLevel,
  });

  // Partner Applications (candidaturas de "Seja Parceiro")
  Future<void> submitPartnerApplication({
    required String name,
    required String category,
    String? address,
    String? phone,
    required String email,
    String? userId,
  });
  Future<List<PartnerApplicationModel>> getPartnerApplications();
  Future<void> approvePartnerApplication(String id,
      {required String reviewerId});
  Future<void> rejectPartnerApplication(
    String id, {
    required String reviewerId,
    required String reason,
  });

  // Partner Services
  Future<List<PartnerServiceModel>> getServicesByPartnerId(String partnerId);
  Future<List<PartnerServiceModel>> getAllActiveServices();
  Future<PartnerServiceModel> createService(PartnerServiceEntity entity);
  Future<PartnerServiceModel> updateService(PartnerServiceEntity entity);
  Future<void> deleteService(String id);

  // Partner Validations
  Future<List<PartnerValidationModel>> getValidationsByPartnerId(
      String partnerId);
  Future<PartnerValidationModel> validateCheckin({
    required String userId,
    required String token,
    required String partnerCode,
    required String serviceId,
  });
  Future<String> generateToken(String userId);
}
