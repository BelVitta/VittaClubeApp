/// Payload da carteirinha lido pelo validador (admin ou parceiro).
///
/// Titular: UUID de `profiles.id`.
/// Dependente: `vc:dep:<dependent-uuid>` para o scanner não perguntar quem é.
class LoyaltyCardPayload {
  static const dependentPrefix = 'vc:dep:';

  static String holder(String profileId) => profileId;

  static String dependent(String dependentId) => '$dependentPrefix$dependentId';

  static bool isDependentPayload(String raw) =>
      raw.trim().startsWith(dependentPrefix);

  static bool isAppointmentToken(String raw) =>
      raw.contains('.') && !isDependentPayload(raw);

  static String? parseDependentId(String raw) {
    final value = raw.trim();
    if (!value.startsWith(dependentPrefix)) return null;
    final id = value.substring(dependentPrefix.length);
    return id.isEmpty ? null : id;
  }
}
