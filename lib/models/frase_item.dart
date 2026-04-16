import 'dart:convert';

class FraseItem {
  final String texto;
  final String categoria;
  final bool esPersonal;

  const FraseItem({
    required this.texto,
    required this.categoria,
    this.esPersonal = false,
  });

  Map<String, dynamic> toJson() => {
    'texto': texto,
    'categoria': categoria,
    'esPersonal': esPersonal,
  };

  factory FraseItem.fromJson(Map<String, dynamic> j) => FraseItem(
    texto: j['texto'] as String,
    categoria: j['categoria'] as String,
    esPersonal: j['esPersonal'] as bool? ?? false,
  );

  String toJsonString() => jsonEncode(toJson());
  static FraseItem fromJsonString(String s) =>
      FraseItem.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

const categoriasAll = [
  'Todas', 'Mis frases', 'Saludos', 'Necesidades', 'Respuestas', 'Urgente'
];