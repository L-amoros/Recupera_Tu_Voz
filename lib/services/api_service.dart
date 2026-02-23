import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';

// ── Cambia esta IP por la de tu PC en la red WiFi ─────────────────
// Windows: ipconfig → Dirección IPv4
// Mac/Linux: ifconfig → inet
const String kServerUrl = 'https://mirian-eriophyllous-serriedly.ngrok-free.dev'; //ngrok http 8880

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

// ─────────────────────────────────────────────────────────────────
// AUTH SERVICE
// ─────────────────────────────────────────────────────────────────
class AuthService {
  static const _keyUser = 'saved_user';

  Future<AppUser> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final res = await http
        .post(
      Uri.parse('$kServerUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'name': name.trim(),
      }),
    )
        .timeout(const Duration(seconds: 15));
    return _parseAuth(res);
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final res = await http
        .post(
      Uri.parse('$kServerUrl/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'username=${Uri.encodeComponent(email.trim())}'
          '&password=${Uri.encodeComponent(password)}',
    )
        .timeout(const Duration(seconds: 15));
    return _parseAuth(res);
  }

  Future<void> saveUser(AppUser user) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyUser, jsonEncode(user.toJson()));
  }

  Future<AppUser?> loadUser() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_keyUser);
    if (raw == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_keyUser);
  }

  AppUser _parseAuth(http.Response res) {
    if (res.statusCode == 200 || res.statusCode == 201) {
      return AppUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw ApiException(_extractDetail(res), statusCode: res.statusCode);
  }
}

// ─────────────────────────────────────────────────────────────────
// VOICE API SERVICE
// ─────────────────────────────────────────────────────────────────
class VoiceApiService {
  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  Future<Map<String, dynamic>> checkVoiceStatusFull(String token) async {
    try {
      final res = await http
          .get(Uri.parse('$kServerUrl/voice/status'),
          headers: _headers(token))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {'has_voice': false, 'num_references': 0};
  }

  Future<bool> checkVoiceStatus(String token) async {
    final d = await checkVoiceStatusFull(token);
    return d['has_voice'] as bool? ?? false;
  }

  /// REEMPLAZA todo — borra los anteriores y sube los nuevos.
  /// Usa /voice/upload-multiple (el backend borra antes de guardar).
  /// Llámalo desde el botón "Reemplazar todo".
  Future<int> uploadReplaceAudios({
    required String token,
    required List<({Uint8List bytes, String filename})> files,
  }) async {
    // 1. Borrar primero
    await deleteVoice(token);

    // 2. Subir los nuevos
    final request = http.MultipartRequest(
        'POST', Uri.parse('$kServerUrl/voice/upload-multiple'))
      ..headers['Authorization'] = 'Bearer $token';

    for (final f in files) {
      request.files.add(
          http.MultipartFile.fromBytes('files', f.bytes, filename: f.filename));
    }

    final streamed = await request.send().timeout(const Duration(seconds: 120));
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw ApiException(_extractDetail(res), statusCode: res.statusCode);
    }
    final d = jsonDecode(res.body) as Map<String, dynamic>;
    return d['num_references'] as int? ?? files.length;
  }

  /// ACUMULA — sube uno a uno sin borrar los anteriores.
  /// Usa /voice/upload (acumulativo).
  /// Llámalo desde el botón "Añadir más".
  Future<int> uploadAddAudios({
    required String token,
    required List<({Uint8List bytes, String filename})> files,
  }) async {
    int lastTotal = 0;
    for (final f in files) {
      final request =
      http.MultipartRequest('POST', Uri.parse('$kServerUrl/voice/upload'))
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
            http.MultipartFile.fromBytes('file', f.bytes, filename: f.filename));

      final streamed =
      await request.send().timeout(const Duration(seconds: 60));
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode != 200) {
        throw ApiException(_extractDetail(res), statusCode: res.statusCode);
      }
      final d = jsonDecode(res.body) as Map<String, dynamic>;
      lastTotal = d['num_references'] as int? ?? lastTotal + 1;
    }
    return lastTotal;
  }

  Future<Uint8List> synthesize({
    required String token,
    required String text,
    double speed = 1.0,
  }) async {
    final res = await http
        .post(
      Uri.parse('$kServerUrl/voice/tts'),
      headers: _headers(token),
      body: jsonEncode({'text': text, 'speed': speed}),
    )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode == 200) return res.bodyBytes;
    throw ApiException(_extractDetail(res), statusCode: res.statusCode);
  }

  Future<void> deleteVoice(String token) async {
    final res = await http
        .delete(Uri.parse('$kServerUrl/voice/'),
        headers: _headers(token))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw ApiException(_extractDetail(res), statusCode: res.statusCode);
    }
  }
}

String _extractDetail(http.Response res) {
  try {
    final b = jsonDecode(res.body) as Map<String, dynamic>;
    return b['detail'] as String? ?? 'Error ${res.statusCode}';
  } catch (_) {
    return 'Error ${res.statusCode}';
  }
}