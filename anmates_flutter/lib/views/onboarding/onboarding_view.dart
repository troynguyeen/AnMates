import 'dart:math' as math;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/anm_logo.dart';
import '../../widgets/anm_widgets.dart';
import '../auth/phone_input_view.dart';
import '../main_tab_view.dart';

class OnboardingView extends StatefulWidget {
  final VoidCallback? onFinished;

  const OnboardingView({super.key, this.onFinished});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 3;

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _navigateAway();
    }
  }

  void _skip() {
    _navigateAway();
  }

  void _navigateAway() {
    if (widget.onFinished != null) {
      widget.onFinished!();
    } else {
      // Capture NavigatorState BEFORE pushReplacement disposes this State —
      // otherwise the onAuthenticated callback fires against an unmounted
      // context and silently no-ops.
      final navigator = Navigator.of(context);
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => PhoneInputView(
            onAuthenticated: () => navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainTabView()),
              (_) => false,
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ScrollConfiguration(
            // Enable horizontal swipe via touch + mouse + trackpad + stylus
            // (Flutter web disables mouse drag on scroll widgets by default).
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: const {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
              scrollbars: false,
            ),
            child: PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: const [_Step1Page(), _Step2Page(), _Step3Page()],
            ),
          ),
          // Top bar overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const LogoMark(size: 32),
                  GestureDetector(
                    onTap: _skip,
                    child: Text(
                      'Bỏ qua',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom controls overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomControls(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onNext: _nextPage,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom controls (dots + button) ─────────────────────────────────────────
class _BottomControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onNext;

  const _BottomControls({
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dot indicators
          Row(
            children: List.generate(totalPages, (i) {
              final active = i == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                margin: const EdgeInsets.only(right: 6),
                width: active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: active ? AppColors.berry : AppColors.ink30,
                ),
              );
            }),
          ),
          // CTA button
          GestureDetector(
            onTap: onNext,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.berry, AppColors.berryDeep],
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.berry.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                currentPage == totalPages - 1 ? 'Bắt đầu →' : 'Tiếp tục →',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared step layout ───────────────────────────────────────────────────────
class _StepLayout extends StatelessWidget {
  final Color backgroundColor;
  final String eyebrow;
  final String title;
  final String body;
  final Widget illustration;
  /// Override heading color — default Caviar Ink; use AppColors.ocean for social-proof screen.
  final Color titleColor;

  const _StepLayout({
    required this.backgroundColor,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.illustration,
    this.titleColor = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive scaling — small iPhones (≤375pt: SE/mini) get tighter spacing
    // and smaller title; larger devices (Pro Max) keep generous spacing.
    final media = MediaQuery.of(context);
    final w = media.size.width;
    final h = media.size.height;
    final isCompact = w <= 380 || h <= 700;

    final illustrationTopPad = isCompact ? 56.0 : 88.0;
    final bottomPad = isCompact ? 100.0 : 120.0;
    final titleSize = isCompact ? 28.0 : 32.0;
    final bodySize = isCompact ? 14.0 : 15.0;
    final horizontalPad = isCompact ? 22.0 : 28.0;

    return Container(
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration area
          Expanded(
            flex: 5,
            child: Padding(
              padding: EdgeInsets.only(
                top: illustrationTopPad,
                left: 16,
                right: 16,
              ),
              child: Center(child: illustration),
            ),
          ),
          // Text area
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPad,
              0,
              horizontalPad,
              bottomPad,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(eyebrow),
                SizedBox(height: isCompact ? 8 : 10),
                // H1: Plus Jakarta Sans w700 lh1.2 per design-system.md
                // titleColor: default AppColors.ink; AppColors.ocean for Screen 03 Social Proof
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    height: 1.2,
                    letterSpacing: -1.0,
                  ),
                ),
                SizedBox(height: isCompact ? 10 : 12),
                Text(
                  body,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: bodySize,
                    color: AppColors.ink70,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 1 ───────────────────────────────────────────────────────────────────
class _Step1Page extends StatelessWidget {
  const _Step1Page();

  @override
  Widget build(BuildContext context) {
    return _StepLayout(
      backgroundColor: AppColors.mint,
      eyebrow: '01 · Chọn quán trước',
      title: 'Hôm nay ăn gì?\nChạm là ra ngay.',
      body:
          'Khám phá theo Genre & Vibe — lẩu sùng sục, cafe khuất hẻm, quán nướng xì xèo... Bookmark vào Wishlist để tính sau.',
      illustration: const _Step1Illustration(),
    );
  }
}

enum _FoodKind { lau, cafe, nuong, vat }

class _Step1Illustration extends StatelessWidget {
  const _Step1Illustration();

  static const _cards = <_CardSpec>[
    _CardSpec(
      label: 'LẨU',
      display: 'Lẩu',
      kind: _FoodKind.lau,
      angleDeg: -8.0,
      top: 0.0,
      left: 14.0,
      accent: AppColors.berry,
      delayMs: 0,
    ),
    _CardSpec(
      label: 'CAFE CHILL',
      display: 'Cafe chill',
      kind: _FoodKind.cafe,
      angleDeg: 6.0,
      top: 6.0,
      left: 148.0,
      accent: AppColors.wisteriaDeep,
      delayMs: 90,
    ),
    _CardSpec(
      label: 'ĐỒ NƯỚNG',
      display: 'Đồ nướng',
      kind: _FoodKind.nuong,
      angleDeg: -4.0,
      top: 170.0,
      left: 24.0,
      accent: AppColors.berryDeep,
      delayMs: 180,
    ),
    _CardSpec(
      label: 'ĂN VẶT',
      display: 'ăn vặt',
      kind: _FoodKind.vat,
      angleDeg: 10.0,
      top: 162.0,
      left: 158.0,
      accent: AppColors.ocean,
      delayMs: 270,
    ),
  ];

  // Intrinsic dimensions of the polaroid stage — FittedBox scales it down
  // on small screens (iPhone 11/12/13 logical width 375pt).
  static const double _stageW = 300;
  static const double _stageH = 340;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: _stageW,
        height: _stageH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Sparkle accent (top-right, near Cafe chill card)
            const Positioned(
              top: -8,
              right: 6,
              child: Sparkle(size: 26, color: AppColors.berry, animated: true),
            ),
            for (int i = 0; i < _cards.length; i++)
              Positioned(
                top: _cards[i].top,
                left: _cards[i].left,
                child: _FoodCard(spec: _cards[i]),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardSpec {
  final String label;
  final String display;
  final _FoodKind kind;
  final double angleDeg;
  final double top;
  final double left;
  final Color accent;
  final int delayMs;

  const _CardSpec({
    required this.label,
    required this.display,
    required this.kind,
    required this.angleDeg,
    required this.top,
    required this.left,
    required this.accent,
    required this.delayMs,
  });
}

class _FoodCard extends StatefulWidget {
  final _CardSpec spec;

  const _FoodCard({required this.spec});

  @override
  State<_FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<_FoodCard> with TickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;

  late final AnimationController _floatCtrl;
  late final Animation<double> _floatAnim;

  late final AnimationController _enterCtrl;
  late final Animation<double> _enterScale;
  late final Animation<double> _enterFade;
  late final Animation<double> _enterOffset;

  @override
  void initState() {
    super.initState();

    // Ambient float (out-of-sync per card)
    final floatMs = 2200 + (widget.spec.label.hashCode.abs() % 800);
    _floatCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: floatMs),
    );
    _floatAnim = Tween<double>(
      begin: -4.0,
      end: 4.0,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    // Staggered drop-in entry
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _enterScale = Tween<double>(
      begin: 0.72,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.elasticOut));
    _enterFade = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _enterOffset = Tween<double>(
      begin: 36.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.spec.delayMs), () {
      if (!mounted) return;
      _enterCtrl.forward().then((_) {
        final floatDelay = (widget.spec.label.length * 90) % 600;
        Future.delayed(Duration(milliseconds: floatDelay), () {
          if (mounted) _floatCtrl.repeat(reverse: true);
        });
      });
    });
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Slightly straighten when hovered (snap to upright reads as "selecting")
    final liveAngleDeg = _hovered
        ? widget.spec.angleDeg * 0.35
        : widget.spec.angleDeg;
    final scale = _pressed
        ? 0.94
        : _hovered
        ? 1.08
        : 1.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_floatCtrl, _enterCtrl]),
      builder: (_, child) {
        return Opacity(
          opacity: _enterFade.value,
          child: Transform.translate(
            offset: Offset(0, _floatAnim.value + _enterOffset.value),
            child: Transform.scale(scale: _enterScale.value, child: child),
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedRotation(
            turns: liveAngleDeg / 360,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutBack,
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: 122,
                height: 156,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: widget.spec.accent.withValues(
                        alpha: _hovered ? 0.42 : 0.18,
                      ),
                      blurRadius: _hovered ? 28 : 16,
                      offset: Offset(0, _hovered ? 14 : 8),
                    ),
                  ],
                  border: Border.all(
                    color: _hovered
                        ? widget.spec.accent.withValues(alpha: 0.45)
                        : AppColors.ink10,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Column(
                    children: [
                      // Polaroid photo area — illustrated food asset
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AnimatedScale(
                                scale: _hovered ? 1.08 : 1.0,
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOut,
                                child: Image.asset(
                                  _assetFor(widget.spec.kind),
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.medium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Polaroid caption (formal label)
                      Text(
                        widget.spec.display,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Food kind → asset path ──────────────────────────────────────────────────
String _assetFor(_FoodKind kind) {
  switch (kind) {
    case _FoodKind.lau:
      return 'assets/food/lau.png';
    case _FoodKind.cafe:
      return 'assets/food/cafe.png';
    case _FoodKind.nuong:
      return 'assets/food/nuong.png';
    case _FoodKind.vat:
      return 'assets/food/vat.png';
  }
}

// ─── Step 2 ───────────────────────────────────────────────────────────────────
class _Step2Page extends StatelessWidget {
  const _Step2Page();

  @override
  Widget build(BuildContext context) {
    return _StepLayout(
      // Design spec: Berry Tint #FAF1F5 bg + Ocean Twilight heading
      backgroundColor: AppColors.berryTint,
      titleColor: AppColors.ocean,
      eyebrow: '02 · Match cùng quán',
      title: 'Ai cũng đang\nthèm quán này?',
      body:
          '15 người quanh đây cũng vừa chọn quán giống bạn. Quét phải để gửi lời mời đi ăn cùng — không phải hẹn hò.',
      illustration: const _Step2Illustration(),
    );
  }
}

// ─── Mock mate profiles (Screen 03 Social Proof) ────────────────────────────
class _MateProfile {
  final String name;
  final int age;
  final List<String> chips;
  /// Realistic face photo via pravatar.cc (deterministic by img= param).
  final String avatarUrl;
  const _MateProfile(this.name, this.age, this.chips, this.avatarUrl);
}

const _kMates = [
  _MateProfile('Vy',   24, ['🌶️ Cay 3',   '💬 Tám'],      'https://i.pravatar.cc/400?img=47'),
  _MateProfile('Minh', 22, ['🍜 Mì cay',  '🎮 Gaming'],    'https://i.pravatar.cc/400?img=12'),
  _MateProfile('Linh', 26, ['☕ Cafe',     '📚 Sách'],      'https://i.pravatar.cc/400?img=48'),
  _MateProfile('Nam',  25, ['🍖 Nướng',   '🏃 Chạy bộ'],   'https://i.pravatar.cc/400?img=15'),
  _MateProfile('Hà',   23, ['🌮 Ăn vặt',  '🎵 Nhạc'],      'https://i.pravatar.cc/400?img=49'),
  _MateProfile('Tuấn', 27, ['🍣 Sushi',   '📷 Ảnh'],       'https://i.pravatar.cc/400?img=16'),
];

// ─── Screen 03 Illustration — Tinder-style swipeable card stack ──────────────
class _Step2Illustration extends StatefulWidget {
  const _Step2Illustration();

  @override
  State<_Step2Illustration> createState() => _Step2IllustrationState();
}

class _Step2IllustrationState extends State<_Step2Illustration>
    with TickerProviderStateMixin {
  // Entry: fade + slide-up (plays once on mount)
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;
  // Ambient float (whole stack bobs up/down)
  late final AnimationController _floatCtrl;
  late final Animation<double> _floatAnim;
  // Heart badge pulse
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  // Swipe-out: tap front card → flies right, back cards promote
  late final AnimationController _swipeCtrl;

  int _topIdx = 0; // current front-card index into _kMates
  bool _isSwiping = false;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _entryFade =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
            begin: const Offset(0, 0.14), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entryCtrl, curve: Curves.easeOutCubic));

    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000));
    _floatAnim = Tween<double>(begin: -7.0, end: 7.0).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.14).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _swipeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));

    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      _entryCtrl.forward();
      _floatCtrl.repeat(reverse: true);
      _pulseCtrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    _swipeCtrl.dispose();
    super.dispose();
  }

  Future<void> _swipeRight() async {
    if (_isSwiping) return;
    setState(() => _isSwiping = true);
    _floatCtrl.stop(); // freeze float while card flies
    await _swipeCtrl.forward();
    if (!mounted) return;
    setState(() {
      _topIdx = (_topIdx + 1) % _kMates.length;
      _isSwiping = false;
    });
    _swipeCtrl.reset();
    _floatCtrl.repeat(reverse: true); // resume float
  }

  // Linear interpolation helper
  static double _l(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entryFade,
      child: SlideTransition(
        position: _entrySlide,
        child: AnimatedBuilder(
          animation: Listenable.merge([_floatCtrl, _swipeCtrl, _pulseCtrl]),
          builder: (_, _) {
            final t  = _swipeCtrl.value; // 0 → 1 during swipe
            final te = Curves.easeIn.transform(t); // gentle acceleration for natural feel
            final float = _isSwiping ? 0.0 : _floatAnim.value;

            // Profiles visible at each layer
            final frontP = _kMates[_topIdx % _kMates.length];
            final midP   = _kMates[(_topIdx + 1) % _kMates.length];
            final backP  = _kMates[(_topIdx + 2) % _kMates.length];

            // ── Back card: back_pos → mid_pos as t goes 0→1
            final backAngle = _l(-9, 5, t) * math.pi / 180;
            final backTop   = _l(18, 10, t);
            final backLeft  = _l(0, 12, t);
            final backAlpha = _l(0.50, 0.75, t);

            // ── Mid card: mid_pos → front_pos
            final midAngle = _l(5, 0, t) * math.pi / 180;
            final midTop   = _l(10, 0, t);
            final midLeft  = _l(12, 20, t);
            final midAlpha = _l(0.75, 1.0, t);

            // ── Front card: translate right + rotate CW + fade near end
            final frontDx    = _l(0, 430, te);
            final frontAngle = _l(0, 22, t) * math.pi / 180;
            final frontAlpha = t < 0.55
                ? 1.0
                : _l(1.0, 0.0, (t - 0.55) / 0.45);

            return Transform.translate(
              offset: Offset(0, float),
              child: SizedBox(
                width: 240,
                height: 310,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── Back card ─────────────────────────────────────────────
                    Positioned(
                      top: backTop,
                      left: backLeft,
                      child: Transform.rotate(
                        angle: backAngle,
                        child: Opacity(
                          opacity: backAlpha.clamp(0.0, 1.0),
                          child: _MateProfileCard(profile: backP),
                        ),
                      ),
                    ),
                    // ── Mid card ──────────────────────────────────────────────
                    Positioned(
                      top: midTop,
                      left: midLeft,
                      child: Transform.rotate(
                        angle: midAngle,
                        child: Opacity(
                          opacity: midAlpha.clamp(0.0, 1.0),
                          child: _MateProfileCard(profile: midP),
                        ),
                      ),
                    ),
                    // ── Front card — tap to swipe right ───────────────────────
                    Positioned(
                      top: 0,
                      left: 20 + frontDx,
                      child: GestureDetector(
                        onTap: _swipeRight,
                        onHorizontalDragEnd: (d) {
                          if ((d.primaryVelocity ?? 0) > 80) _swipeRight();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Transform.rotate(
                          angle: frontAngle,
                          child: Opacity(
                            opacity: frontAlpha.clamp(0.0, 1.0),
                            child: _MateProfileCard(profile: frontP),
                          ),
                        ),
                      ),
                    ),
                    // ── Pulsing heart badge (top-right) ──────────────────────
                    Positioned(
                      top: -14,
                      right: 0,
                      child: Transform.scale(
                        scale: _pulseAnim.value,
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.berry, AppColors.berryDeep],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.berry.withValues(alpha: 0.45),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.favorite,
                              color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Mate profile card (photo area + name + chips) ───────────────────────────
class _MateProfileCard extends StatelessWidget {
  final _MateProfile profile;
  const _MateProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 196,
      height: 268,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.berry.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          const BoxShadow(
            color: AppColors.ink10,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photo area — realistic avatar via pravatar.cc ─────────────
          Expanded(
            flex: 11,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                profile.avatarUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                filterQuality: FilterQuality.medium,
                // Shows diagonal-stripe placeholder while image loads
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(painter: _DiagonalStripesPainter()),
                      Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.wisteria.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                // Falls back to diagonal stripes on network error
                errorBuilder: (_, _, _) => Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(painter: _DiagonalStripesPainter()),
                    Center(
                      child: Text(
                        profile.name.toUpperCase(),
                        style: AppTextStyles.mono(
                          size: 11,
                          weight: FontWeight.w600,
                          color: AppColors.wisteria.withValues(alpha: 0.8),
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Info area ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.name}, ${profile.age}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    for (int i = 0; i < profile.chips.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      _InfoChip(profile.chips[i]),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small info chip inside profile card ─────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.berry.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: AppColors.berry.withValues(alpha: 0.18), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.beVietnamPro(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.ink70,
        ),
      ),
    );
  }
}

// ─── Diagonal stripe painter (photo placeholder) ─────────────────────────────
class _DiagonalStripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.berryTint,
    );
    // Diagonal stripes
    final stripePaint = Paint()
      ..color = AppColors.wisteria.withValues(alpha: 0.20)
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke;
    final span = size.width + size.height;
    for (double x = -size.height; x < span; x += 32) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_DiagonalStripesPainter _) => false;
}

// ─── Step 3 ───────────────────────────────────────────────────────────────────
class _Step3Page extends StatelessWidget {
  const _Step3Page();

  @override
  Widget build(BuildContext context) {
    return _StepLayout(
      backgroundColor: const Color(0xFFF2EEFB),
      eyebrow: '03 · Nồi lẩu tự sôi',
      title: 'Trò chuyện đủ\nấm, mới chốt kèo.',
      body:
          'Vibe check từng bước — từ chat đến bữa ăn thật. Điểm tin cậy minh bạch, không sến, không lo.',
      illustration: const _Step3Illustration(),
    );
  }
}

class _Step3Illustration extends StatelessWidget {
  const _Step3Illustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 220,
      child: Column(
        children: [
          // Hotpot illustration
          _HotpotWidget(),
          const SizedBox(height: 20),
          // Vibe progress bar at 72%
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _VibeBarSimple(percent: 72),
          ),
        ],
      ),
    );
  }
}

class _HotpotWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 120,
      child: CustomPaint(painter: _HotpotPainter()),
    );
  }
}

class _HotpotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Pot body (ocean)
    final potPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.ocean, AppColors.oceanDeep],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(w * 0.1, h * 0.3, w * 0.8, h * 0.65));
    final potPath = Path()
      ..moveTo(w * 0.1, h * 0.38)
      ..lineTo(w * 0.9, h * 0.38)
      ..lineTo(w * 0.82, h * 0.92)
      ..quadraticBezierTo(w * 0.5, h, w * 0.18, h * 0.92)
      ..close();
    canvas.drawPath(potPath, potPaint);

    // Lid (berry)
    final lidPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.berry, AppColors.berryDeep],
      ).createShader(Rect.fromLTWH(w * 0.05, h * 0.2, w * 0.9, h * 0.2));
    final lidPath = Path()
      ..moveTo(w * 0.05, h * 0.38)
      ..quadraticBezierTo(w * 0.5, h * 0.22, w * 0.95, h * 0.38)
      ..lineTo(w * 0.9, h * 0.38)
      ..quadraticBezierTo(w * 0.5, h * 0.26, w * 0.1, h * 0.38)
      ..close();
    canvas.drawPath(lidPath, lidPaint);

    // Handle knob
    final knobPaint = Paint()
      ..color = AppColors.mint
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.2), 10, knobPaint);

    // Steam lines (wisteria)
    final steamPaint = Paint()
      ..color = AppColors.wisteria.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final steams = [0.35, 0.5, 0.65];
    for (final x in steams) {
      final path = Path()
        ..moveTo(w * x, h * 0.15)
        ..cubicTo(
          w * (x - 0.04),
          h * 0.08,
          w * (x + 0.04),
          h * 0.04,
          w * x,
          h * -0.02,
        );
      canvas.drawPath(path, steamPaint);
    }

    // Left handle
    final handlePaint = Paint()
      ..color = AppColors.oceanDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(w * -0.04, h * 0.38, w * 0.18, h * 0.22),
      3.14159 / 2,
      -3.14159,
      false,
      handlePaint,
    );
    // Right handle
    canvas.drawArc(
      Rect.fromLTWH(w * 0.86, h * 0.38, w * 0.18, h * 0.22),
      3.14159 / 2,
      3.14159,
      false,
      handlePaint,
    );
  }

  @override
  bool shouldRepaint(_HotpotPainter old) => false;
}

class _VibeBarSimple extends StatelessWidget {
  final int percent;
  const _VibeBarSimple({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.wisteria.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('VIBE CHECK', style: AppTextStyles.eyebrow()),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$percent',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.berry,
                      ),
                    ),
                    TextSpan(
                      text: '/100',
                      style: AppTextStyles.mono(
                        size: 11,
                        color: AppColors.ink50,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 8,
              color: AppColors.ink10,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percent / 100,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.ocean,
                        AppColors.wisteria,
                        AppColors.berry,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
