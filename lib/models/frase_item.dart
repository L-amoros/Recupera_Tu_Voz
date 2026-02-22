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
        esPersonal: j['esPersonal'] as bool? ?? true,
      );

  String toJsonString() => jsonEncode(toJson());
  static FraseItem fromJsonString(String s) =>
      FraseItem.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

const frasesDefault = [
  FraseItem(texto: 'Hola, ¿cómo estás?',    categoria: 'Saludos'),
  FraseItem(texto: 'Buenos días',             categoria: 'Saludos'),
  FraseItem(texto: 'Buenas tardes',           categoria: 'Saludos'),
  FraseItem(texto: 'Hasta luego',             categoria: 'Saludos'),
  FraseItem(texto: 'Muchas gracias',          categoria: 'Saludos'),
  FraseItem(texto: 'Por favor',               categoria: 'Saludos'),
  FraseItem(texto: 'Necesito ayuda',          categoria: 'Necesidades'),
  FraseItem(texto: 'Tengo sed',               categoria: 'Necesidades'),
  FraseItem(texto: 'Tengo hambre',            categoria: 'Necesidades'),
  FraseItem(texto: 'Necesito ir al baño',     categoria: 'Necesidades'),
  FraseItem(texto: 'Me duele aquí',           categoria: 'Necesidades'),
  FraseItem(texto: 'Estoy cansado',           categoria: 'Necesidades'),
  FraseItem(texto: 'Sí',                      categoria: 'Respuestas'),
  FraseItem(texto: 'No',                      categoria: 'Respuestas'),
  FraseItem(texto: 'No lo sé',               categoria: 'Respuestas'),
  FraseItem(texto: 'Espera un momento',       categoria: 'Respuestas'),
  FraseItem(texto: 'Repite por favor',        categoria: 'Respuestas'),
  FraseItem(texto: 'No entiendo',             categoria: 'Respuestas'),
  FraseItem(texto: 'Llama a mi familia',      categoria: 'Urgente'),
  FraseItem(texto: 'Llama al médico',        categoria: 'Urgente'),
  FraseItem(texto: 'Es urgente',              categoria: 'Urgente'),
  FraseItem(texto: 'Necesito medicación',    categoria: 'Urgente'),
];

const categoriasAll = [
  'Todas', 'Saludos', 'Necesidades', 'Respuestas', 'Urgente', 'Mis frases'
];
