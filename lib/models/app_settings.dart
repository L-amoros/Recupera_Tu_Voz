class AppSettings {
  final String idioma;
  final double velocidad;
  final double volumen;
  final bool temaOscuro;

  const AppSettings({
    this.idioma = 'Español',
    this.velocidad = 0.5,
    this.volumen = 1.0,
    this.temaOscuro = true,
  });

  AppSettings copyWith({String? idioma, double? velocidad, double? volumen, bool? temaOscuro}) =>
      AppSettings(
        idioma: idioma ?? this.idioma,
        velocidad: velocidad ?? this.velocidad,
        volumen: volumen ?? this.volumen,
        temaOscuro: temaOscuro ?? this.temaOscuro,
      );

  Map<String, dynamic> toJson() => {
    'idioma': idioma, 'velocidad': velocidad,
    'volumen': volumen, 'tema_oscuro': temaOscuro,
  };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    idioma: j['idioma'] as String? ?? 'Español',
    velocidad: (j['velocidad'] as num?)?.toDouble() ?? 0.5,
    volumen: (j['volumen'] as num?)?.toDouble() ?? 1.0,
    temaOscuro: j['tema_oscuro'] as bool? ?? true,
  );
}