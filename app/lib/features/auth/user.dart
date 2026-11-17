/// The signed-in user, as returned by the API (`user` in /auth/* and /me).
class User {
  const User({
    required this.id,
    required this.fullName,
    required this.docType,
    required this.docNumber,
    required this.email,
    this.phone,
  });

  final String id;
  final String fullName;
  final String docType;
  final String docNumber;
  final String email;
  final String? phone;

  /// First name for greetings («Hola, Ana»).
  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      fullName: json['full_name'] as String,
      docType: json['doc_type'] as String,
      docNumber: json['doc_number'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
    );
  }
}

/// Document types accepted by the API, with the text shown to the user.
const docTypeLabels = {
  'CC': 'Cédula de ciudadanía (CC)',
  'CE': 'Cédula de extranjería (CE)',
  'PAS': 'Pasaporte (PAS)',
};
