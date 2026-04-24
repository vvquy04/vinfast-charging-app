/// Data transfer object for the application user.
/// Maintains alignment with the backend `users` table schema and AuthResponse.
class UserModel {
  final int? userId;
  final String phoneNumber;
  final String? email;
  final String? fullName;
  final String? gender;
  final String? dateOfBirth; // ISO format from backend: YYYY-MM-DD
  final String? avatarUrl;
  final String? vehicleModel;
  final String? connectorType;

  const UserModel({
    this.userId,
    required this.phoneNumber,
    this.email,
    this.fullName,
    this.gender,
    this.dateOfBirth,
    this.avatarUrl,
    this.vehicleModel,
    this.connectorType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? json['user_id'] as int?,
      phoneNumber: json['phoneNumber'] ?? json['phone_number'] as String,
      email: json['email'] as String?,
      fullName: json['fullName'] ?? json['full_name'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['dateOfBirth'] ?? json['date_of_birth'] as String?,
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'] as String?,
      vehicleModel: json['vehicleModel'] ?? json['vehicle_model'] as String?,
      connectorType: json['connectorType'] ?? json['connector_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'phoneNumber': phoneNumber,
      'email': email,
      'fullName': fullName,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'avatarUrl': avatarUrl,
      'vehicleModel': vehicleModel,
      'connectorType': connectorType,
    };
  }
}
