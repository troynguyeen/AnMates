import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../firebase_options.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/anm_logo.dart';
import '../../widgets/anm_widgets.dart';
import 'otp_view.dart';

// Dev bypass — must match backend DEV_BYPASS_SECRET. Override via:
//   flutter run --dart-define=DEV_BYPASS_SECRET=...
const _devBypassSecret =
    String.fromEnvironment('DEV_BYPASS_SECRET', defaultValue: 'dev-local-2026');
const _devTestPhone = '+84999000001';
const _devTestName = 'Dev User';

bool _firebaseReady = false;

Future<void> _ensureFirebase() async {
  if (!_firebaseReady) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _firebaseReady = true;
  }
}

class PhoneInputView extends StatefulWidget {
  final VoidCallback onAuthenticated;
  const PhoneInputView({super.key, required this.onAuthenticated});

  @override
  State<PhoneInputView> createState() => _PhoneInputViewState();
}

class _PhoneInputViewState extends State<PhoneInputView> {
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _phoneCtrl.text.trim().length >= 9 && _nameCtrl.text.trim().isNotEmpty;

  String _normalizePhone(String raw) {
    raw = raw.replaceAll(RegExp(r'\s+'), '');
    if (raw.startsWith('0')) return '+84${raw.substring(1)}';
    if (raw.startsWith('+')) return raw;
    return '+84$raw';
  }

  Future<void> _sendOtp() async {
    if (!_canSubmit || _loading) return;
    setState(() => _loading = true);
    final phone = _normalizePhone(_phoneCtrl.text.trim());
    try {
      await _ensureFirebase();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Firebase: ${e.runtimeType}: $e');
      return;
    }
    if (kIsWeb) {
      await _sendOtpWeb(phone);
    } else {
      await _sendOtpMobile(phone);
    }
  }

  // ── Web flow: Firebase tự tạo invisible reCAPTCHA → ConfirmationResult ────
  Future<void> _sendOtpWeb(String phone) async {
    try {
      final confirmationResult =
          await FirebaseAuth.instance.signInWithPhoneNumber(phone);
      if (!mounted) return;
      setState(() => _loading = false);
      _goToOtp(phone, verificationId: '', confirmationResult: confirmationResult);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(_friendlyError(e.code));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Lỗi: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // ── Mobile flow: verifyPhoneNumber → verificationId ───────────────────────
  Future<void> _sendOtpMobile(String phone) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 90),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final uc =
              await FirebaseAuth.instance.signInWithCredential(credential);
          final idToken = await uc.user?.getIdToken();
          if (idToken != null && mounted) {
            _goToOtp(phone, verificationId: '', autoIdToken: idToken);
          }
        } catch (_) {}
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        setState(() => _loading = false);
        _showError(_friendlyError(e.code));
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;
        setState(() => _loading = false);
        _goToOtp(phone, verificationId: verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  void _goToOtp(String phone,
      {required String verificationId,
      String? autoIdToken,
      ConfirmationResult? confirmationResult}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpView(
          phone: phone,
          name: _nameCtrl.text.trim(),
          verificationId: verificationId,
          autoIdToken: autoIdToken,
          confirmationResult: confirmationResult,
          onVerified: widget.onAuthenticated,
        ),
      ),
    );
  }

  Future<void> _devSkipOtp() async {
    if (_loading) return;
    setState(() => _loading = true);
    final name =
        _nameCtrl.text.trim().isEmpty ? _devTestName : _nameCtrl.text.trim();
    try {
      await AuthService().devLogin(
        secret: _devBypassSecret,
        phone: _devTestPhone,
        name: name,
      );
      if (!mounted) return;
      widget.onAuthenticated();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Dev bypass: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.berry,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Số điện thoại không hợp lệ.';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Thử lại sau vài phút.';
      case 'quota-exceeded':
        return 'Hạn mức SMS đã hết. Liên hệ hỗ trợ.';
      default:
        return 'Không gửi được OTP ($code).';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.mint, Colors.white],
            stops: [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ListenableBuilder(
              listenable: Listenable.merge([_phoneCtrl, _nameCtrl]),
              builder: (context, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const LogoMark(size: 64, float: true),
                    const SizedBox(height: 24),
                    ScreenTitle(
                      title: 'Va Mates, ăn miết.',
                      subtitle:
                          'Nhập SĐT để đăng ký hoặc đăng nhập — không cần mật khẩu.',
                      align: TextAlign.center,
                    ),
                    const SizedBox(height: 36),
                    _InputField(
                      controller: _nameCtrl,
                      hint: 'Tên của bạn',
                      icon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 12),
                    _PhoneField(controller: _phoneCtrl),
                    const SizedBox(height: 20),
                    AnmCTA(
                      label: _loading ? 'Đang gửi mã…' : 'Gửi mã OTP',
                      onTap: (_canSubmit && !_loading) ? _sendOtp : null,
                      background: (_canSubmit && !_loading)
                          ? AppColors.berry
                          : AppColors.ink30,
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: 12),
                      _DevModeButton(
                        loading: _loading,
                        onTap: _loading ? null : _devSkipOtp,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Tiếp tục đồng nghĩa với việc bạn đồng ý với\nĐiều khoản dịch vụ và Chính sách quyền riêng tư của ĂnMates.',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        color: AppColors.ink50,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Dev-only bypass button (only when kDebugMode) ───────────────────────────
class _DevModeButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onTap;
  const _DevModeButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF8A1F);
    return Semantics(
      identifier: 'dev_mode_skip_otp',
      button: true,
      label: 'Dev Mode skip OTP',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('dev_mode_skip_otp'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: orange.withOpacity(0.55), width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bug_report_outlined,
                    size: 18, color: orange.withOpacity(loading ? 0.5 : 1)),
                const SizedBox(width: 8),
                Text(
                  loading ? 'Đang đăng nhập dev…' : 'Dev Mode (skip OTP)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: orange.withOpacity(loading ? 0.5 : 1),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Phone field với prefix +84 ───────────────────────────────────────────────
class _PhoneField extends StatefulWidget {
  final TextEditingController controller;
  const _PhoneField({required this.controller});

  @override
  State<_PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<_PhoneField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _focused ? AppColors.berry : AppColors.ink10,
            width: _focused ? 1.5 : 1,
          ),
          boxShadow: [
            if (_focused)
              BoxShadow(
                color: AppColors.berry.withOpacity(0.12),
                blurRadius: 14,
                offset: const Offset(0, 4),
              )
            else
              const BoxShadow(
                  color: AppColors.ink10,
                  blurRadius: 6,
                  offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '🇻🇳 +84',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink70,
                ),
              ),
            ),
            Container(width: 1, height: 24, color: AppColors.ink10),
            Expanded(
              child: TextField(
                controller: widget.controller,
                keyboardType: TextInputType.phone,
                inputFormatters: kIsWeb
                    ? null
                    : [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
                decoration: InputDecoration(
                  hintText: '912 345 678',
                  hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 15, color: AppColors.ink30),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 18, horizontal: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Generic input field ──────────────────────────────────────────────────────
class _InputField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _focused ? AppColors.berry : AppColors.ink10,
            width: _focused ? 1.5 : 1,
          ),
          boxShadow: [
            if (_focused)
              BoxShadow(
                color: AppColors.berry.withOpacity(0.12),
                blurRadius: 14,
                offset: const Offset(0, 4),
              )
            else
              const BoxShadow(
                  color: AppColors.ink10,
                  blurRadius: 6,
                  offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(widget.icon, size: 20, color: AppColors.ink50),
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                keyboardType: widget.keyboardType,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 15, color: AppColors.ink30),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
