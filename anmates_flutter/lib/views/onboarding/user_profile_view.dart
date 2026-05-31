import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/astrology.dart';
import '../../widgets/anm_widgets.dart';
import '../../widgets/horoscope_icons.dart';
import 'food_preferences_view.dart';

/// Screen 08 — Thông Tin Cá Nhân (step 3/5). Collects name, nickname, DOB and a
/// personality score, shows live astrology/numerology auto-detect, then persists
/// to the backend before advancing to Screen 09.
class UserProfileView extends StatefulWidget {
  /// Called when the WHOLE post-OTP onboarding flow completes (after Screen 09).
  final VoidCallback onComplete;

  const UserProfileView({super.key, required this.onComplete});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  static const _wheelBg = Color(0xFF5E2A4E); // deep plum DOB wheels (matches design)

  final _nameCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();

  int _day = 15;
  int _month = 6;
  int _year = 2000;
  bool _dobTouched = false;

  double _personality = 50;
  bool _saving = false;

  static const _minYear = 1960;
  static const _maxYear = 2009;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  DateTime get _dob => DateTime(_year, _month, _day);

  bool get _canContinue =>
      _nameCtrl.text.trim().isNotEmpty &&
      _nicknameCtrl.text.trim().isNotEmpty &&
      _dobTouched &&
      !_saving;

  String get _personalityLabel {
    final v = _personality.round();
    if (v <= 33) return 'Introvert';
    if (v <= 66) return 'Ambivert';
    return 'Extrovert';
  }

  Future<void> _continue() async {
    if (!_canContinue) return;
    setState(() => _saving = true);
    try {
      await ProfileService().saveOnboardingProfile(
        name: _nameCtrl.text.trim(),
        nickname: _nicknameCtrl.text.trim(),
        birthDate: _dob,
        personalityScore: _personality.round(),
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FoodPreferencesView(onComplete: widget.onComplete),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.berry,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(title: 'THÔNG TIN CÁ NHÂN', step: 3, total: 5),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([_nameCtrl, _nicknameCtrl]),
                builder: (context, _) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Eyebrow('THÔNG TIN CÁ NHÂN'),
                        const SizedBox(height: 8),
                        Text(
                          'Bạn là ai trên bàn ăn?',
                          style: AppTextStyles.display(
                            size: 28,
                            weight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chỉ ĂnMates dùng để ghép Mate hợp vía — không bao '
                          'giờ public số tử vi của bạn.',
                          style: AppTextStyles.body(
                            size: 14,
                            color: AppColors.ink70,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _FieldLabel('TÊN ĐẦY ĐỦ'),
                        const SizedBox(height: 8),
                        _TextField(
                          controller: _nameCtrl,
                          hint: 'Nguyễn Thảo Vy',
                        ),
                        const SizedBox(height: 18),
                        _FieldLabel('GỌI THÂN MẬT'),
                        const SizedBox(height: 8),
                        _TextField(
                          controller: _nicknameCtrl,
                          hint: 'Vy',
                          helper: 'Mates sẽ thấy tên này trong chat',
                        ),
                        const SizedBox(height: 24),
                        _FieldLabel('NGÀY THÁNG NĂM SINH'),
                        const SizedBox(height: 10),
                        _DobWheels(
                          day: _day,
                          month: _month,
                          year: _year,
                          minYear: _minYear,
                          maxYear: _maxYear,
                          background: _wheelBg,
                          onChanged: (d, m, y) {
                            setState(() {
                              _day = d;
                              _month = m;
                              _year = y;
                              _dobTouched = true;
                            });
                          },
                        ),
                        const SizedBox(height: 18),
                        AnimatedOpacity(
                          opacity: _dobTouched ? 1 : 0,
                          duration: const Duration(milliseconds: 320),
                          child: _dobTouched
                              ? _AutoDetect(dob: _dob)
                              : const SizedBox(height: 0),
                        ),
                        const SizedBox(height: 24),
                        _PersonalitySection(
                          value: _personality,
                          label: _personalityLabel,
                          onChanged: (v) => setState(() => _personality = v),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            _BottomCta(
              loading: _saving,
              enabled: _canContinue,
              onTap: _continue,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared top bar (back + title + progress) ────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  final int step;
  final int total;
  const _TopBar({required this.title, required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink10,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.mono(
                    size: 11,
                    weight: FontWeight.w700,
                    color: AppColors.ink50,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: step / total,
                    minHeight: 5,
                    backgroundColor: AppColors.ink10,
                    valueColor: const AlwaysStoppedAnimation(AppColors.berry),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$step/$total',
            style: AppTextStyles.mono(
              size: 12,
              weight: FontWeight.w700,
              color: AppColors.ink50,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.mono(
      size: 10,
      weight: FontWeight.w700,
      color: AppColors.berry,
      letterSpacing: 1.6,
    ),
  );
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? helper;
  const _TextField({required this.controller, required this.hint, this.helper});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.ink30,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.berry, width: 1.4),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.berry.withValues(alpha: 0.45),
                width: 1.4,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.berry, width: 1.8),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper!,
            style: AppTextStyles.body(size: 12, color: AppColors.ink50),
          ),
        ],
      ],
    );
  }
}

// ─── DOB wheel pickers ───────────────────────────────────────────────────────
class _DobWheels extends StatelessWidget {
  final int day, month, year, minYear, maxYear;
  final Color background;
  final void Function(int day, int month, int year) onChanged;

  const _DobWheels({
    required this.day,
    required this.month,
    required this.year,
    required this.minYear,
    required this.maxYear,
    required this.background,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _WheelCard(
            label: 'NGÀY',
            background: background,
            count: 31,
            selectedIndex: day - 1,
            itemLabel: (i) => (i + 1).toString().padLeft(2, '0'),
            onSelected: (i) => onChanged(i + 1, month, year),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _WheelCard(
            label: 'THÁNG',
            background: background,
            count: 12,
            selectedIndex: month - 1,
            itemLabel: (i) => (i + 1).toString().padLeft(2, '0'),
            onSelected: (i) => onChanged(day, i + 1, year),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _WheelCard(
            label: 'NĂM',
            background: background,
            count: maxYear - minYear + 1,
            selectedIndex: year - minYear,
            itemLabel: (i) => (minYear + i).toString(),
            onSelected: (i) => onChanged(day, month, minYear + i),
          ),
        ),
      ],
    );
  }
}

class _WheelCard extends StatefulWidget {
  final String label;
  final Color background;
  final int count;
  final int selectedIndex;
  final String Function(int index) itemLabel;
  final ValueChanged<int> onSelected;

  const _WheelCard({
    required this.label,
    required this.background,
    required this.count,
    required this.selectedIndex,
    required this.itemLabel,
    required this.onSelected,
  });

  @override
  State<_WheelCard> createState() => _WheelCardState();
}

class _WheelCardState extends State<_WheelCard> {
  late final FixedExtentScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = FixedExtentScrollController(initialItem: widget.selectedIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.wisteria, AppColors.berry],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            widget.label,
            style: AppTextStyles.mono(
              size: 9,
              weight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.65),
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: ListWheelScrollView.useDelegate(
              controller: _ctrl,
              itemExtent: 30,
              useMagnifier: true,
              magnification: 1.45,
              overAndUnderCenterOpacity: 0.38,
              perspective: 0.003,
              diameterRatio: 1.5,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: widget.onSelected,
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: widget.count,
                builder: (context, i) => Center(
                  child: Text(
                    widget.itemLabel(i),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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

// ─── Auto-detect (zodiac / nạp âm / numerology) ──────────────────────────────
class _AutoDetect extends StatelessWidget {
  final DateTime dob;
  const _AutoDetect({required this.dob});

  @override
  Widget build(BuildContext context) {
    final z = zodiacSign(dob);
    final lp = lifePathNumber(dob);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.berryTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.berry.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 14,
                color: AppColors.berry,
              ),
              const SizedBox(width: 6),
              Text(
                'ĂN MATES TỰ NHẬN DIỆN',
                style: AppTextStyles.mono(
                  size: 10,
                  weight: FontWeight.w700,
                  color: AppColors.berry,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _DetectCard(
                    icon: ZodiacIcon(viName: z.vi),
                    label: 'CUNG HOÀNG ĐẠO',
                    labelColor: AppColors.berry,
                    value: z.vi,
                    sub: '${z.en} · ${z.range}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DetectCard(
                    icon: NguHanhIcon(element: elementOf(napAm(dob.year))),
                    label: 'MỆNH NGŨ HÀNH',
                    labelColor: elementVisual(elementOf(napAm(dob.year))).color,
                    value: napAm(dob.year),
                    sub: '${canChi(dob.year)} · ${dob.year}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DetectCard(
                    icon: ThanSoIcon(number: lp),
                    label: 'THẦN SỐ HỌC',
                    labelColor: AppColors.wisteria,
                    value: 'Số $lp',
                    sub: lifePathLabel(lp),
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

class _DetectCard extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color labelColor;
  final String value;
  final String sub;
  const _DetectCard({
    required this.icon,
    required this.label,
    required this.labelColor,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.mono(
              size: 7.5,
              weight: FontWeight.w700,
              color: labelColor,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          icon,
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(
              size: 9.5,
              color: AppColors.ink50,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom "+" thumb ────────────────────────────────────────────────────────
class _PlusThumbShape extends SliderComponentShape {
  const _PlusThumbShape();
  static const _r = 12.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_r + 3);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    double value = 0,
    double textScaleFactor = 1.0,
    Size sizeWithOverflow = Size.zero,
  }) {
    final canvas = context.canvas;

    // Drop shadow
    canvas.drawCircle(
      center + const Offset(0, 4),
      _r,
      Paint()
        ..color = AppColors.berry.withValues(alpha: 0.40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    // White border ring
    canvas.drawCircle(center, _r + 2.5, Paint()..color = Colors.white);

    // Berry fill
    canvas.drawCircle(center, _r, Paint()..color = AppColors.berry);

    // Fork & knife icon
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.restaurant.codePoint),
        style: TextStyle(
          fontSize: 14,
          height: 1.0,
          color: Colors.white,
          fontFamily: Icons.restaurant.fontFamily,
          package: Icons.restaurant.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }
}

// ─── Personality slider ───────────────────────────────────────────────────────
class _PersonalitySection extends StatelessWidget {
  final double value;
  final String label;
  final ValueChanged<double> onChanged;

  const _PersonalitySection({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  // Badge color tracks the gradient: ocean left → berry right
  Color get _badgeColor {
    if (value <= 33) return AppColors.ocean;
    return AppColors.berry;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.berry.withValues(alpha: 0.18),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.restaurant_rounded,
                    size: 13,
                    color: AppColors.berry,
                  ),
                  const SizedBox(width: 5),
                  _FieldLabel('TÍNH CÁCH BÀN ĂN'),
                ],
              ),
              // Animated pill badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _badgeColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$label · ${value.round()}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Gradient track + custom thumb
          SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Gradient bar drawn slightly inside the thumb margins
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 19),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.ocean,    // Introvert  ←
                          AppColors.wisteria, // Ambivert center
                          AppColors.berry,    // Extrovert  →
                        ],
                      ),
                    ),
                  ),
                ),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 8,
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    overlayColor: AppColors.berry.withValues(alpha: 0.12),
                    thumbShape: const _PlusThumbShape(),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 20),
                  ),
                  child: Slider(
                    value: value,
                    min: 0,
                    max: 100,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Zone labels — color + weight animate with active zone
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ZoneLabel(
                icon: Icons.nights_stay_rounded,
                title: 'Introvert',
                sub: 'Tám 1-1',
                active: label == 'Introvert',
                activeColor: AppColors.ocean,
              ),
              _ZoneLabel(
                icon: Icons.brightness_medium_rounded,
                title: 'Ambivert',
                sub: 'Cân bằng',
                active: label == 'Ambivert',
                activeColor: AppColors.berry,
                center: true,
              ),
              _ZoneLabel(
                icon: Icons.wb_sunny_rounded,
                title: 'Extrovert',
                sub: 'Bàn 6+',
                active: label == 'Extrovert',
                activeColor: AppColors.berry,
                end: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ZoneLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final bool active;
  final Color activeColor;
  final bool center;
  final bool end;

  const _ZoneLabel({
    required this.icon,
    required this.title,
    required this.sub,
    required this.active,
    required this.activeColor,
    this.center = false,
    this.end = false,
  });

  @override
  Widget build(BuildContext context) {
    final cross = center
        ? CrossAxisAlignment.center
        : end
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start;
    final align = center
        ? TextAlign.center
        : end
            ? TextAlign.right
            : TextAlign.left;
    return Column(
      crossAxisAlignment: cross,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          child: Icon(
            icon,
            size: active ? 18 : 15,
            color: active ? activeColor : AppColors.ink30,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 240),
          style: GoogleFonts.plusJakartaSans(
            fontSize: active ? 12 : 10.5,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            color: active ? activeColor : AppColors.ink30,
          ),
          child: Text(title, textAlign: align),
        ),
        const SizedBox(height: 2),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 240),
          style: AppTextStyles.body(
            size: 9,
            color:
                active ? activeColor.withValues(alpha: 0.62) : AppColors.ink30,
          ),
          child: Text(sub, textAlign: align),
        ),
      ],
    );
  }
}

// ─── Bottom CTA ──────────────────────────────────────────────────────────────
class _BottomCta extends StatelessWidget {
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;
  const _BottomCta({
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.ink10, width: 0.5)),
      ),
      child: AnmCTA(
        label: loading ? 'Đang lưu…' : 'Tiếp tục  →',
        onTap: enabled ? onTap : null,
        background: enabled ? AppColors.berry : AppColors.ink30,
      ),
    );
  }
}
