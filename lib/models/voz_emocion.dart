enum VozEmocion { neutral, feliz, triste, enfadado }

extension VozEmocionExt on VozEmocion {
  String get label {
    switch (this) {
      case VozEmocion.neutral:  return 'Neutral';
      case VozEmocion.feliz:    return 'Feliz';
      case VozEmocion.triste:   return 'Triste';
      case VozEmocion.enfadado: return 'Enfadado';
    }
  }

  String get emoji {
    switch (this) {
      case VozEmocion.neutral:  return '😐';
      case VozEmocion.feliz:    return '😊';
      case VozEmocion.triste:   return '😢';
      case VozEmocion.enfadado: return '😠';
    }
  }


  /// Browser TTS fallback: (pitch, rate)
  (double, double) get browserTtsParams {
    switch (this) {
      case VozEmocion.neutral:  return (1.00, 0.50);
      case VozEmocion.feliz:    return (1.25, 0.62);
      case VozEmocion.triste:   return (0.85, 0.30);
      case VozEmocion.enfadado: return (0.95, 0.70);
    }
  }
}