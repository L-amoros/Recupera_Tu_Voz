class AppUser {
  final String token;
  final String userId;
  final String name;
  final String email;
  final String? picture;
  final bool hasVoice;
  final int numReferences;

  const AppUser({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
    this.picture,
    required this.hasVoice,
    this.numReferences = 0,
  });

  AppUser copyWith({bool? hasVoice, String? name, int? numReferences}) => AppUser(
    token: token,
    userId: userId,
    name: name ?? this.name,
    email: email,
    picture: picture,
    hasVoice: hasVoice ?? this.hasVoice,
    numReferences: numReferences ?? this.numReferences,
  );

  Map<String, dynamic> toJson() => {
    'token': token,
    'user_id': userId,
    'name': name,
    'email': email,
    'picture': picture,
    'has_voice': hasVoice,
    'num_references': numReferences,
  };
  /// Serialización sin el token (para SharedPreferences).
  Map<String, dynamic> toJsonWithoutToken() => {
    'user_id': userId,
    'name': name,
    'email': email,
    'picture': picture,
    'has_voice': hasVoice,
    'num_references': numReferences,
  };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    token: j['token'] as String,
    userId: j['user_id'] as String,
    name: j['name'] as String? ?? '',
    email: j['email'] as String,
    picture: j['picture'] as String?,
    hasVoice: j['has_voice'] as bool? ?? false,
    numReferences: j['num_references'] as int? ?? 0,
  );
}