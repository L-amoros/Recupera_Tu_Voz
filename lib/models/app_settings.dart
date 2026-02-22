class AppSettings {
  final String idioma;
  final double velocidad;
  final double volumen;

  const AppSettings({
    this.idioma = 'Español',
    this.velocidad = 0.5,
    this.volumen = 1.0,
  });

  AppSettings copyWith({
    String? idioma,
    double? velocidad,
    double? volumen,
  }) =>
      AppSettings(
        idioma: idioma ?? this.idioma,
        velocidad: velocidad ?? this.velocidad,
        volumen: volumen ?? this.volumen,
      );

  Map<String, dynamic> toJson() => {
        'idioma': idioma,
        'velocidad': velocidad,
        'volumen': volumen,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        idioma: j['idioma'] as String? ?? 'Español',
        velocidad: (j['velocidad'] as num?)?.toDouble() ?? 0.5,
        volumen: (j['volumen'] as num?)?.toDouble() ?? 1.0,
      );
}
