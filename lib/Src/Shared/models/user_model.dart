class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.timezone = 'America/Sao_Paulo',
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String timezone;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      name: (json['name'] ?? json['username'] ?? '').toString(),
      email: (json['email'] ?? json['username'] ?? '').toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      timezone: json['timezone']?.toString() ?? 'America/Sao_Paulo',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'timezone': timezone,
      };
}
