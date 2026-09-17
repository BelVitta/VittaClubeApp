class PixAutomaticBillingAddress {
  final String zipcode;
  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;

  const PixAutomaticBillingAddress({
    required this.zipcode,
    required this.street,
    required this.number,
    this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
  });

  bool get isComplete =>
      zipcode.isNotEmpty &&
      street.isNotEmpty &&
      number.isNotEmpty &&
      neighborhood.isNotEmpty &&
      city.isNotEmpty &&
      state.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'zipcode': zipcode,
        'street': street,
        'number': number,
        if (complement != null) 'complement': complement,
        'neighborhood': neighborhood,
        'city': city,
        'state': state,
      };

  factory PixAutomaticBillingAddress.fromJson(Map<String, dynamic> json) {
    return PixAutomaticBillingAddress(
      zipcode: json['zipcode'] as String,
      street: json['street'] as String,
      number: json['number'] as String,
      complement: json['complement'] as String?,
      neighborhood: json['neighborhood'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
    );
  }
}

class PixAutomaticBillingProfile {
  final String name;
  final String taxId;
  final String email;
  final String phone;
  final PixAutomaticBillingAddress address;

  const PixAutomaticBillingProfile({
    required this.name,
    required this.taxId,
    required this.email,
    required this.phone,
    required this.address,
  });

  bool get isComplete =>
      name.isNotEmpty &&
      taxId.isNotEmpty &&
      email.isNotEmpty &&
      phone.isNotEmpty &&
      address.isComplete;

  Map<String, dynamic> toJson() => {
        'name': name,
        'tax_id': taxId,
        'email': email,
        'phone': phone,
        'address': address.toJson(),
      };

  factory PixAutomaticBillingProfile.fromJson(Map<String, dynamic> json) {
    return PixAutomaticBillingProfile(
      name: json['name'] as String,
      taxId: json['tax_id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      address: PixAutomaticBillingAddress.fromJson(
        json['address'] as Map<String, dynamic>,
      ),
    );
  }
}

class PixAutomaticCustomer {
  final String name;
  final String taxId;
  final String email;
  final String phone;
  final PixAutomaticBillingAddress address;

  const PixAutomaticCustomer({
    required this.name,
    required this.taxId,
    required this.email,
    required this.phone,
    required this.address,
  });

  bool get isComplete =>
      name.isNotEmpty &&
      taxId.isNotEmpty &&
      email.isNotEmpty &&
      phone.isNotEmpty &&
      address.isComplete;

  Map<String, dynamic> toJson() => {
        'name': name,
        'tax_id': taxId,
        'email': email,
        'phone': phone,
        'address': address.toJson(),
      };
}
