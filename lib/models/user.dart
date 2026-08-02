class User {
  final int id;
  final String email;
  final String name;
  final String? firstName;
  final String? lastName;
  final String? bloodType;
  final String? barangay;
  final String? phone;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.firstName,
    this.lastName,
    this.bloodType,
    this.barangay,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      bloodType: json['bloodType']?.toString(),
      barangay: json['barangay']?.toString(),
      phone: json['phone']?.toString(),
    );
  }

  String get displayName => name.isNotEmpty ? name : '$firstName $lastName'.trim();
}