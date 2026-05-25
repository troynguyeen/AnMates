import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/anm_widgets.dart';

class OtpView extends StatefulWidget {
  final String phone;
  final String name;
  final String verificationId;       // mobile only
  final String? autoIdToken;         // Android auto-verify
  final ConfirmationResult? confirmationResult; // web only
  final VoidCallback onVerified;

  const OtpView({
    super.key,
    required this.phone,
    required this.name,
    required this.verificationId,
    this.autoIdToken,
    this.confirmationResult,
    required this.onVerified,
  });

  @override
  State<OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> {
  final List<String> _digits = ['', '', '', '', '', ''];
  bool _loading = false;
  int _secondsLeft = 90;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Nếu Android auto-verify xong trước khi vào màn này
    if (widget.autoIdToken != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _verifyWithBackend(widget.autoIdToken!);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 90);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
        }
      });
    });
  }

  void _onKeyTap(String key) {
    if (_loading) return;
    setState(() {
      if (key == '⌫') {
        for (int i = _digits.length - 1; i >= 0; i--) {
          if (_digits[i].isNotEmpty) { _digits[i] = ''; break; }
        }
      } else {
        for (int i = 0; i < _digits.length; i++) {
          if (_digits[i].isEmpty) { _digits[i] = key; break; }
        }
      }
    });

    if (_digits.every((d) => d.isNotEmpty)) {
      _submitOtp(_digits.join());
    }
  }

  Future<void> _submitOtp(String code) async {
    setState(() => _loading = true);
    try {
      UserCredential uc;
      if (kIsWeb && widget.confirmationResult != null) {
        // Web: dùng ConfirmationResult từ signInWithPhoneNumber
        uc = await widget.confirmationResult!.confirm(code);
      } else {
        // Mobile: dùng PhoneAuthCredential
        final credential = PhoneAuthProvider.credential(
          verificationId: widget.verificationId,
          smsCode: code,
        );
        uc = await FirebaseAuth.instance.signInWithCredential(credential);
      }
      final idToken = await uc.user?.getIdToken();
      if (idToken == null) throw Exception('Không lấy được Firebase token');
      await _verifyWithBackend(idToken);
    } on FirebaseAuthException catch (e) {
      _showError(_friendlyError(e.code));
      setState(() {
        _loading = false;
        for (int i = 0; i < _digits.length; i++) _digits[i] = '';
      });
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
      setState(() {
        _loading = false;
        for (int i = 0; i < _digits.length; i++) _digits[i] = '';
      });
    }
  }

  Future<void> _verifyWithBackend(String idToken) async {
    try {
      await AuthService().phoneVerify(idToken, name: widget.name);
      if (mounted) widget.onVerified();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
      setState(() {
        _loading = false;
        for (int i = 0; i < _digits.length; i++) _digits[i] = '';
      });
    }
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0 || _loading) return;
    setState(() => _loading = true);

    if (kIsWeb) {
      // Web: gọi lại signInWithPhoneNumber
      try {
        final newResult =
            await FirebaseAuth.instance.signInWithPhoneNumber(widget.phone);
        if (!mounted) return;
        setState(() => _loading = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OtpView(
              phone: widget.phone,
              name: widget.name,
              verificationId: '',
              confirmationResult: newResult,
              onVerified: widget.onVerified,
            ),
          ),
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        setState(() => _loading = false);
        _showError(_friendlyError(e.code));
      }
      return;
    }

    // Mobile
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phone,
      timeout: const Duration(seconds: 90),
      verificationCompleted: (credential) async {
        final uc = await FirebaseAuth.instance.signInWithCredential(credential);
        final idToken = await uc.user?.getIdToken();
        if (idToken != null) await _verifyWithBackend(idToken);
      },
      verificationFailed: (e) {
        if (!mounted) return;
        setState(() => _loading = false);
        _showError(_friendlyError(e.code));
      },
      codeSent: (newVerificationId, _) {
        if (!mounted) return;
        setState(() => _loading = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OtpView(
              phone: widget.phone,
              name: widget.name,
              verificationId: newVerificationId,
              onVerified: widget.onVerified,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (_) {},
    );
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
      case 'invalid-verification-code':
        return 'Mã OTP không đúng. Thử lại.';
      case 'session-expired':
        return 'Mã OTP đã hết hạn. Gửi lại.';
      default:
        return 'Lỗi xác thực ($code).';
    }
  }

  int get _activeIndex => _digits.indexWhere((d) => d.isEmpty);

  String get _timerText {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mint,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: GestureDetector(
                onTap: _loading ? null : () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.ink10,
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: const Icon(Icons.arrow_back,
                      size: 20, color: AppColors.ink),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('BƯỚC 2 / 5'),
                  const SizedBox(height: 10),
                  ScreenTitle(
                    title: 'Nhập mã 6 số',
                    subtitle:
                        'Vừa gửi tới ${widget.phone}. Mã có hiệu lực 90 giây.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // OTP digit boxes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (i) => _OtpBox(
                    digit: _digits[i],
                    isActive: !_loading && i == _activeIndex,
                    isLoading: _loading && i < 6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Resend
            Center(
              child: GestureDetector(
                onTap: _secondsLeft == 0 ? _resend : null,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Chưa nhận được? ',
                        style: GoogleFonts.beVietnamPro(
                            fontSize: 13, color: AppColors.ink50),
                      ),
                      TextSpan(
                        text: _secondsLeft > 0
                            ? 'Gửi lại ($_timerText)'
                            : 'Gửi lại',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _secondsLeft > 0
                              ? AppColors.ink30
                              : AppColors.berry,
                          decoration: _secondsLeft == 0
                              ? TextDecoration.underline
                              : TextDecoration.none,
                          decorationColor: AppColors.berry,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 32),
                  child: CircularProgressIndicator(color: AppColors.berry),
                ),
              )
            else ...[
              _NumericKeypad(onKeyTap: _onKeyTap),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── OTP Digit Box ────────────────────────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  final String digit;
  final bool isActive;
  final bool isLoading;

  const _OtpBox(
      {required this.digit, required this.isActive, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLoading
              ? AppColors.berry.withOpacity(0.4)
              : isActive
                  ? AppColors.berry
                  : AppColors.ink10,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.berry.withOpacity(0.22),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                    color: AppColors.ink10,
                    blurRadius: 4,
                    offset: const Offset(0, 2)),
              ],
      ),
      child: Center(
        child: digit.isNotEmpty
            ? Text(
                digit,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              )
            : isActive
                ? Container(
                    width: 2,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.berry,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}

// ─── Custom Numeric Keypad ────────────────────────────────────────────────────
class _NumericKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyTap;
  const _NumericKeypad({required this.onKeyTap});

  static const _keys = [
    '1', '2', '3',
    '4', '5', '6',
    '7', '8', '9',
    '',  '0', '⌫',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 1.6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 10,
        children: _keys
            .map((key) => _KeyButton(
                  keyLabel: key,
                  onTap: key.isEmpty ? null : () => onKeyTap(key),
                ))
            .toList(),
      ),
    );
  }
}

class _KeyButton extends StatefulWidget {
  final String keyLabel;
  final VoidCallback? onTap;
  const _KeyButton({required this.keyLabel, this.onTap});

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.keyLabel.isEmpty) return const SizedBox.shrink();
    final isBackspace = widget.keyLabel == '⌫';
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        decoration: BoxDecoration(
          color: _pressed ? AppColors.berry.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: AppColors.ink10,
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Center(
          child: isBackspace
              ? Icon(Icons.backspace_outlined,
                  size: 22, color: AppColors.ink70)
              : Text(
                  widget.keyLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
        ),
      ),
    );
  }
}
