// Screen 07 — Face verify (Phase 1 stub liveness)
// Spec: design-system.md §Auth Flow §Screen 07
//
// Phase 1 simplification: no real camera/liveness ML. UI simulates the 4
// liveness steps with an animated progress ring + step prompts, then calls
// /api/me/face-verify with a liveness_score of 1.0 to register the verification
// server-side. Real on-device liveness (Apple Vision / ML Kit) is Phase 2.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/onboarding_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/anm_logo.dart';
import '../../widgets/anm_widgets.dart';
import '../../widgets/app_loader.dart';
import 'profile_setup_view.dart';

class FaceVerifyView extends StatefulWidget {
  final VoidCallback onFinished;
  const FaceVerifyView({super.key, required this.onFinished});

  @override
  State<FaceVerifyView> createState() => _FaceVerifyViewState();
}

class _FaceVerifyViewState extends State<FaceVerifyView>
    with TickerProviderStateMixin {
  static const _steps = [
    ('Nhìn thẳng vào camera', 0.0, 0.25),
    ('Chớp mắt 2 lần', 0.25, 0.50),
    ('Quay đầu chầm chậm sang trái', 0.50, 0.75),
    ('Quay đầu chầm chậm sang phải', 0.75, 1.00),
  ];

  late final AnimationController _ringCtrl;
  int _stepIndex = -1; // -1 = not started
  bool _completed = false;
  bool _busy = false;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _ringCtrl.dispose();
    super.dispose();
  }

  void _start() {
    if (_stepIndex >= 0) return;
    setState(() => _stepIndex = 0);
    _runStep(0);
  }

  void _runStep(int i) {
    final to = _steps[i].$3;
    _ringCtrl.animateTo(to, duration: const Duration(milliseconds: 1200));
    _stepTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      if (i + 1 < _steps.length) {
        setState(() => _stepIndex = i + 1);
        _runStep(i + 1);
      } else {
        _onComplete();
      }
    });
  }

  Future<void> _onComplete() async {
    if (!mounted) return;
    setState(() {
      _completed = true;
      _busy = true;
    });
    try {
      await AppLoader.run(
        context,
        caption: 'Đang xử lý xác minh...',
        future: () => OnboardingService().faceVerify(livenessScore: 1.0),
      );
      if (!mounted) return;
      // Chain to the next step. onFinished (= goHome) is threaded through
      // every subsequent step so the last one (PhotosView) can land the user.
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ProfileSetupView(onFinished: widget.onFinished),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.berry,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  String get _currentInstruction {
    if (_stepIndex < 0) return 'Sẵn sàng xác minh?';
    if (_stepIndex >= _steps.length) return 'Xác minh thành công ✨';
    return _steps[_stepIndex].$1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mint,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('BƯỚC 3 / 5 · XÁC MINH KHUÔN MẶT'),
              const SizedBox(height: 12),
              ScreenTitle(
                title: 'Nét tin cậy\nlà nét đẹp nhất.',
                subtitle:
                    'ĂnMates chỉ dùng selfie để xác minh người thật. Không lưu hình, không bán dữ liệu.',
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: _CameraFrame(
                    ring: _ringCtrl,
                    completed: _completed,
                    started: _stepIndex >= 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.ink10),
                ),
                child: Row(
                  children: [
                    Icon(
                      _completed
                          ? Icons.check_circle_rounded
                          : _stepIndex < 0
                              ? Icons.face_retouching_natural
                              : Icons.face,
                      color: _completed ? Colors.green : AppColors.berry,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _currentInstruction,
                          key: ValueKey(_currentInstruction),
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AnmCTA(
                label: _stepIndex < 0
                    ? 'Bắt đầu xác minh'
                    : _completed
                        ? 'Đang xử lý...'
                        : 'Đang xác minh...',
                onTap: _stepIndex < 0 && !_busy ? _start : null,
                background: _stepIndex < 0 && !_busy
                    ? AppColors.berry
                    : AppColors.ink30,
              ),
              const SizedBox(height: 8),
              Text(
                'Để mặt trong khung — đừng đeo khẩu trang.',
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: AppColors.ink50,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Camera frame with progress ring ────────────────────────────────────────

class _CameraFrame extends StatelessWidget {
  final AnimationController ring;
  final bool completed;
  final bool started;
  const _CameraFrame({
    required this.ring,
    required this.completed,
    required this.started,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ring,
      builder: (context, _) {
        final progress = ring.value;
        return SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(240, 240),
                painter: _RingPainter(
                  progress: progress,
                  active: started && !completed,
                ),
              ),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [AppColors.wisteria, AppColors.berry],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.berry
                          .withOpacity(0.25 + 0.4 * progress),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: completed
                        ? const Icon(
                            Icons.check_rounded,
                            key: ValueKey('done'),
                            color: Colors.white,
                            size: 96,
                          )
                        : Icon(
                            Icons.face_retouching_natural,
                            key: const ValueKey('face'),
                            color: Colors.white.withOpacity(0.85),
                            size: 80,
                          ),
                  ),
                ),
              ),
              if (completed)
                Positioned.fill(
                  child: IgnorePointer(
                    child: _CompletionSparkleBurst(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final bool active;
  _RingPainter({required this.progress, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 6;
    final track = Paint()
      ..color = AppColors.ink10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, track);

    if (progress <= 0) return;
    final fill = Paint()
      ..shader = const SweepGradient(
        colors: [AppColors.wisteria, AppColors.berry],
      ).createShader(Rect.fromCircle(center: c, radius: r))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.active != active;
}

// Decorative sparkles around the camera when verification completes.
class _CompletionSparkleBurst extends StatefulWidget {
  @override
  State<_CompletionSparkleBurst> createState() =>
      _CompletionSparkleBurstState();
}

class _CompletionSparkleBurstState extends State<_CompletionSparkleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return Stack(
          children: List.generate(8, (i) {
            final angle = (i / 8) * 2 * math.pi;
            final radius = 130 * t;
            final opacity = (1 - t).clamp(0.0, 1.0);
            return Positioned(
              left: 120 + radius * math.cos(angle) - 8,
              top: 120 + radius * math.sin(angle) - 8,
              child: Opacity(
                opacity: opacity,
                child: const Sparkle(size: 16, color: Colors.white),
              ),
            );
          }),
        );
      },
    );
  }
}

