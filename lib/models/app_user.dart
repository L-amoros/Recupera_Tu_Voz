class AppUser {
  final String token;
  final String userId;
  final String name;
  final String email;
  final bool hasVoice;

  const AppUser({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
    required this.hasVoice,
  });

  AppUser copyWith({bool? hasVoice, String? name}) => AppUser(
        token: token,
        userId: userId,
        name: name ?? this.name,
        email: email,
        hasVoice: hasVoice ?? this.hasVoice,
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'user_id': userId,
        'name': name,
        'email': email,
        'has_voice': hasVoice,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        token: j['token'] as String,
        userId: j['user_id'] as String,
        name: j['name'] as String? ?? '',
        email: j['email'] as String,
        hasVoice: j['has_voice'] as bool? ?? false,
      );
}
