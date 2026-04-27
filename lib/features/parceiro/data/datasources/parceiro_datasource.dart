import '../../domain/entities/partner_entity.dart';
import '../../domain/entities/partner_service_entity.dart';
import '../models/partner_model.dart';
import '../models/partner_service_model.dart';
import '../models/partner_validation_model.dart';

abstract class ParceiroDataSource {
  // Partners
  Future<List<PartnerModel>> getPartners();
  Future<PartnerModel> getPartnerByProfileId(String profileId);
  Future<PartnerModel> updatePartner(PartnerEntity entity);
  Future<PartnerModel> regenerateCode(String partnerId);

  // Partner Services
  Future<List<PartnerServiceModel>> getServicesByPartnerId(String partnerId);
  Future<List<PartnerServiceModel>> getAllActiveServices();
  Future<PartnerServiceModel> createService(PartnerServiceEntity entity);
  Future<PartnerServiceModel> updateService(PartnerServiceEntity entity);
  Future<void> deleteService(String id);

  // Partner Validations
  Future<List<PartnerValidationModel>> getValidationsByPartnerId(String partnerId);
  Future<PartnerValidationModel> validateCheckin({
    required String userId,
    required String token,
    required String partnerCode,
    required String serviceId,
  });
  Future<String> generateToken(String userId);
}
