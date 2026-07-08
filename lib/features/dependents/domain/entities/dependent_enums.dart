enum DependentStatus {
  active,
  inactive;

  static DependentStatus fromDb(String value) {
    return value == 'inactive' ? inactive : active;
  }

  String get dbValue => this == active ? 'active' : 'inactive';
}

enum BeneficiaryType {
  holder,
  dependent;

  static BeneficiaryType fromDb(String value) {
    return value == 'dependent' ? dependent : holder;
  }

  String get dbValue => this == holder ? 'holder' : 'dependent';
}

enum DependentAppointmentStatus {
  scheduled,
  used,
  cancelled,
  expired;

  static DependentAppointmentStatus fromDb(String value) {
    switch (value) {
      case 'utilizado':
        return used;
      case 'cancelado':
        return cancelled;
      case 'expirado':
        return expired;
      case 'agendado':
      default:
        return scheduled;
    }
  }

  String get dbValue {
    switch (this) {
      case scheduled:
        return 'agendado';
      case used:
        return 'utilizado';
      case cancelled:
        return 'cancelado';
      case expired:
        return 'expirado';
    }
  }
}

enum QrValidationDecision {
  approved,
  refused,
  replay,
  quotaExhausted,
  overdueHolder,
  inactiveDependent,
  invalidToken,
  expiredAppointment,
}
