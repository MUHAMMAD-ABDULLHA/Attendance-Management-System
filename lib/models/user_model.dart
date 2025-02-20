class UserModel {
  final String id;
  final String email;
  final String? profilePicture;

  UserModel({
    required this.id,
    required this.email,
    this.profilePicture,
  });

  factory UserModel.fromMap(Map<dynamic, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'],
      profilePicture: data['profilePicture'],
    );
  }
}