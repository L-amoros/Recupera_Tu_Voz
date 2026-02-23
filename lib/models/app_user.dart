class AppUser {
  final String token;
  final String userId;
  final String name;
  final String email;
  final bool hasVoice;
  final int numReferences; // ← nuevo: cuántas muestras tiene guardadas

  const AppUser({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
    required this.hasVoice,
    this.numReferences = 0,
  });

  AppUser copyWith({bool? hasVoice, String? name, int? numReferences}) =>
      AppUser(
        token: token,
        userId: userId,
        name: name ?? this.name,
        email: email,
        hasVoice: hasVoice ?? this.hasVoice,
        numReferences: numReferences ?? this.numReferences,
      );

  Map<String, dynamic> toJson() => {
    'token': token,
    'user_id': userId,
    'name': name,
    'email': email,
    'has_voice': hasVoice,
    'num_references': numReferences,
  };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    token: j['token'] as String,
    userId: j['user_id'] as String,
    name: j['name'] as String? ?? '',
    email: j['email'] as String,
    hasVoice: j['has_voice'] as bool? ?? false,
    numReferences: j['num_references'] as int? ?? 0,
  );
}