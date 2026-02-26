import 'package:recipe_finder/features/auth/domain/entities/auth_entity.dart';

class AuthApiModel{
  final String? id;
  final String fullName;
  final String email;
  //final String? phoneNumber;
  final String username;
  final String? password;
  final String? profilePicture; 

  AuthApiModel({
    this.id,
    required this.fullName,
    required this.email,
    //this.phoneNumber, 
    required this.username,
    this.password,
    this.profilePicture,
  });

  Map<String, dynamic> toJson(){
    final nameParts = _splitName(fullName);
    return{
      "firstName": nameParts.$1,
      "lastName": nameParts.$2,
      "email": email,
      "username": username,
      "password": password,
      "confirmPassword": password,
    };
  }

  factory AuthApiModel.fromJson(Map<String,dynamic> json){
    final email = (json['email'] ?? '') as String;
    final firstName = (json['firstName'] ?? '').toString().trim();
    final lastName = (json['lastName'] ?? '').toString().trim();
    final fallbackName = (json['name'] ?? '').toString().trim();
    final fallbackUsername = (json['username'] ?? '').toString().trim();
    final computedFullName = [firstName, lastName]
        .where((part) => part.isNotEmpty)
        .join(' ');
    final resolvedFullName = computedFullName.isNotEmpty
        ? computedFullName
        : (fallbackName.isNotEmpty
            ? fallbackName
            : (fallbackUsername.isNotEmpty
                ? fallbackUsername
                : (email.isNotEmpty ? email.split('@').first : '')));
    return AuthApiModel(
      id: json['_id'] as String?,
      fullName: resolvedFullName,
      email: email,
      username: fallbackUsername.isNotEmpty
          ? fallbackUsername
          : (email.isNotEmpty ? email.split('@').first : ''),
      profilePicture: (json['image'] ?? json['profilePicture']) as String?,
    );
  }

  AuthEntity toEntity(){
    return AuthEntity(
      authId: id,
      fullName: fullName,
      email: email,
      //phoneNumber: phoneNumber,
      username: username,
      profilePicture: profilePicture);
  }

  factory AuthApiModel.fromEntity(AuthEntity entity){
    return AuthApiModel(
      fullName:entity.fullName,
      email: entity.email,
      //phoneNumber: entity.phoneNumber,
      username: entity.username,  
      password: entity.password,
      profilePicture: entity.profilePicture);
  }

  static List<AuthEntity> toEntityList(List<AuthApiModel> models){
    return models.map((model)=>model.toEntity()).toList();
  }

  static (String, String) _splitName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return ('', '');
    }
    if (parts.length == 1) {
      return (parts.first, '');
    }
    return (parts.first, parts.sublist(1).join(' '));
  }

}