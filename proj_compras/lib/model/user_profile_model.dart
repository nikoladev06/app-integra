class UserProfile {
  final String uid;
  final String nomeCompleto;
  final String email;
  final String username;
  final String universidade;
  final String curso;
  final String profileImage;
  final DateTime criadoEm;

  UserProfile({
    required this.uid,
    required this.nomeCompleto,
    required this.email,
    required this.username,
    required this.universidade,
    required this.curso,
    required this.profileImage,
    required this.criadoEm,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] ?? '',
      nomeCompleto: json['nomeCompleto'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      universidade: json['universidade'] ?? '',
      curso: json['curso'] ?? '',
      profileImage: json['profileImage'] ?? '',
      criadoEm: json['criadoEm'] != null
          ? DateTime.parse(json['criadoEm'].toDate().toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'nomeCompleto': nomeCompleto,
      'email': email,
      'username': username,
      'universidade': universidade,
      'curso': curso,
      'profileImage': profileImage,
      'criadoEm': criadoEm,
    };
  }
}