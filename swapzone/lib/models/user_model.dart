class UserModel {
  final String userId;
  final String name;
  final String email;
  final String phoneno;
  final String role;
  final String token;
  final String dob;
  final String gender;
  final String profileImage;
  final String street;
  final String city;
  final String state;
  final String pincode;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phoneno,
    required this.role,
    required this.token,
    required this.dob,
    required this.gender,
    required this.profileImage,
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final address = json['address'] ?? {};
    return UserModel(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneno: json['phoneno'] ?? '',
      role: json['role'] ?? '',
      token: json['token'] ?? '',
      dob: json['dob'] ?? '',
      gender: json['gender'] ?? '',
      profileImage: json['profileImage'] ?? '',
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
    );
  }
}
