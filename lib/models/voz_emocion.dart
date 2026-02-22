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

  /// ElevenLabs voice_settings: (stability, style)
  (double, double) get elevenLabsParams {
    switch (this) {
      case VozEmocion.neutral:  return (0.55, 0.00);
      case VozEmocion.feliz:    return (0.30, 0.80);
      case VozEmocion.triste:   return (0.80, 0.20);
      case VozEmocion.enfadado: return (0.20, 0.90);
    }
  }

  /// Browser TTS fallback: (pitch, rate)
  (double, double) get browserTtsParams {
    switch (this) {
      case VozEmocion.neutral:  return (1.00, 0.50);
      case VozEmocion.feliz:    return (1.40, 0.60);
      case VozEmocion.triste:   return (0.70, 0.35);
      case VozEmocion.enfadado: return (0.85, 0.65);
    }
  }
}
