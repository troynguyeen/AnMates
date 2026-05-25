// OnboardingService — calls Phase 1 onboarding endpoints.
// All endpoints require Authorization Bearer JWT (set by AuthService).

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.88.80:8080',
);

class OnboardingService {
  static final OnboardingService _i = OnboardingService._();
  OnboardingService._();
  factory OnboardingService() => _i;

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _parse(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return Future.value(body['data'] as Map<String, dynamic>? ?? {});
    }
    final msg = (body['error'] as Map<String, dynamic>?)?['message'] ??
        'request failed';
    throw Exception(msg);
  }

  Future<dynamic> _parseAny(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return Future.value(body['data']);
    }
    final msg = (body['error'] as Map<String, dynamic>?)?['message'] ??
        'request failed';
    throw Exception(msg);
  }

  // ─── Face verify (stub liveness in Phase 1) ────────────────────────────
  Future<Map<String, dynamic>> faceVerify({double livenessScore = 1.0}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/me/face-verify'),
      headers: await _headers(),
      body: jsonEncode({'liveness_score': livenessScore}),
    );
    return _parse(res);
  }

  // ─── Profile (extended) ────────────────────────────────────────────────
  Future<Map<String, dynamic>> putProfileFull({
    String? name,
    String? nickname,
    String? dobIso, // YYYY-MM-DD
    int? personalityScore,
    bool? showDerivedPublic,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (nickname != null) body['nickname'] = nickname;
    if (dobIso != null) body['dob'] = dobIso;
    if (personalityScore != null) body['personality_score'] = personalityScore;
    if (showDerivedPublic != null) {
      body['show_derived_public'] = showDerivedPublic;
    }
    final res = await http.put(
      Uri.parse('$_baseUrl/api/me/profile-full'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  // ─── Tastes ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getTastes() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/api/me/tastes'),
      headers: await _headers(),
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> putTastes({
    required List<String> cuisineTags,
    required List<String> vibeTags,
  }) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/api/me/tastes'),
      headers: await _headers(),
      body: jsonEncode({
        'cuisine_tags': cuisineTags,
        'vibe_tags': vibeTags,
      }),
    );
    return _parse(res);
  }

  // ─── Photos ────────────────────────────────────────────────────────────
  Future<List<dynamic>> getPhotos() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/api/me/photos'),
      headers: await _headers(),
    );
    final data = await _parseAny(res);
    return (data as List<dynamic>?) ?? [];
  }

  /// Posts a photo. `dataUrl` is a `data:image/...;base64,...` URL.
  Future<Map<String, dynamic>> postPhoto({
    required String dataUrl,
    bool isMain = false,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/me/photos'),
      headers: await _headers(),
      body: jsonEncode({'url': dataUrl, 'is_main': isMain}),
    );
    return _parse(res);
  }

  Future<void> deletePhoto(String id) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/api/me/photos/$id'),
      headers: await _headers(),
    );
    await _parseAny(res);
  }

  // ─── Finish ────────────────────────────────────────────────────────────
  Future<void> finishOnboarding() async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/me/onboarding/finish'),
      headers: await _headers(),
    );
    await _parseAny(res);
  }
}
