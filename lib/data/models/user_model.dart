/// Data transfer object for the application user.
/// Maintains alignment with the backend `users` table schema.
class UserModel {
  final int? userId;
  final String phoneNumber;
  final String? email;
  final String? fullName;
  final String? profilePictureUrl;
  final String? authProvider;
  final String? role;

  const UserModel({
    this.userId,
    required this.phoneNumber,
    this.email,
    this.fullName,
    this.profilePictureUrl,
    this.authProvider,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as int?,
      phoneNumber: json['phone_number'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
      authProvider: json['auth_provider'] as String?,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'phone_number': phoneNumber,
      'email': email,
      'full_name': fullName,
      'profile_picture_url': profilePictureUrl,
      'auth_provider': authProvider,
      'role': role,
    };
  }
}
