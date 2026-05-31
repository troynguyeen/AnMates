import 'api_client.dart';
import 'auth_service.dart';

/// Persists post-OTP onboarding data (Screens 08 + 09) to the Go backend.
class ProfileService {
  static final ProfileService _instance = ProfileService._();
  ProfileService._();
  factory ProfileService() => _instance;

  /// Screen 08 — PATCH /profile/onboarding.
  /// [birthDate] is sent as "YYYY-MM-DD" (or omitted when null).
  Future<Map<String, dynamic>> saveOnboardingProfile({
    required String name,
    required String nickname,
    DateTime? birthDate,
    int? personalityScore,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'nickname': nickname.trim(),
      'birth_date': ?(birthDate == null ? null : _formatDate(birthDate)),
      'personality_score': ?personalityScore,
    };
    final data = await ApiClient().patch(
      '/api/v1/profile/onboarding',
      body: body,
    );
    return (data as Map).cast<String, dynamic>();
  }

  /// Screen 09 — PATCH /profile/preferences. Marks onboarding complete server-
  /// side and mirrors that locally so routing skips onboarding next time.
  Future<Map<String, dynamic>> savePreferences({
    required List<String> foodTags,
    required List<String> vibeTags,
  }) async {
    final data = await ApiClient().patch(
      '/api/v1/profile/preferences',
      body: {'food_tags': foodTags, 'vibe_tags': vibeTags},
    );
    final map = (data as Map).cast<String, dynamic>();
    final done = map['onboarding_done'] as bool? ?? true;
    await AuthService().setOnboardingDone(done);
    return map; // ignore: unnecessary_cast
  }

  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-$mm-$dd';
  }
}
