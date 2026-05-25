// Screen 08 — Profile setup with auto-derive reveal moment.
// Spec: design-system.md §Profile Setup §Screen 08
//
// User enters: name, nickname, DOB (day/month/year), personality slider.
// When DOB is complete, the auto-derive section reveals (zodiac, ngu hanh,
// numerology) with sparkles. User can toggle whether to show derived publicly.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/onboarding_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/anm_logo.dart';
import '../../widgets/anm_widgets.dart';
import '../../widgets/app_loader.dart';
import 'tastes_view.dart';

class ProfileSetupView extends StatefulWidget {
  final VoidCallback onFinished;
  const ProfileSetupView({super.key, required this.onFinished});

  @override
  State<ProfileSetupView> createState() => _ProfileSetupViewState();
}

class _ProfileSetupViewState extends State<ProfileSetupView> {
  final _nameCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _dayCtrl = TextEditingController();
  final _monthCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  int _personality = 50;
  bool _showDerivedPublic = true;
  bool _busy = false;

  // Cached derive output (computed locally; server re-derives for storage).
  _Derived? _derived;

  @override
  void initState() {
    super.initState();
    for (final c in [_nameCtrl, _nicknameCtrl, _dayCtrl, _monthCtrl, _yearCtrl]) {
      c.addListener(_recompute);
    }
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _nicknameCtrl, _dayCtrl, _monthCtrl, _yearCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _recompute() {
    final d = int.tryParse(_dayCtrl.text);
    final m = int.tryParse(_monthCtrl.text);
    final y = int.tryParse(_yearCtrl.text);
    if (d == null || m == null || y == null) {
      if (_derived != null) setState(() => _derived = null);
      return;
    }
    if (d < 1 || d > 31 || m < 1 || m > 12 || y < 1900 || y > DateTime.now().year) {
      if (_derived != null) setState(() => _derived = null);
      return;
    }
    final DateTime dt;
    try {
      dt = DateTime(y, m, d);
    } catch (_) {
      if (_derived != null) setState(() => _derived = null);
      return;
    }
    // DateTime constructor silently wraps invalid values (Feb 30 → Mar 2);
    // detect the wrap to reject impossible dates.
    if (dt.day != d || dt.month != m) {
      if (_derived != null) setState(() => _derived = null);
      return;
    }
    final next = _Derived.from(dt);
    if (_derived == null || !_derived!.eq(next)) {
      setState(() => _derived = next);
    }
  }

  bool get _canSubmit =>
      _nameCtrl.text.trim().isNotEmpty &&
      _nicknameCtrl.text.trim().isNotEmpty &&
      _derived != null;

  String? get _dobIso {
    final d = int.tryParse(_dayCtrl.text);
    final m = int.tryParse(_monthCtrl.text);
    final y = int.tryParse(_yearCtrl.text);
    if (d == null || m == null || y == null) return null;
    return '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!_canSubmit || _busy) return;
    setState(() => _busy = true);
    try {
      await AppLoader.run(
        context,
        caption: 'Đang lưu hồ sơ...',
        future: () => OnboardingService().putProfileFull(
          name: _nameCtrl.text.trim(),
          nickname: _nicknameCtrl.text.trim(),
          dobIso: _dobIso,
          personalityScore: _personality,
          showDerivedPublic: _showDerivedPublic,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => TastesView(onFinished: widget.onFinished),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mint,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('BƯỚC 4 / 5 · THÔNG TIN CÁ NHÂN'),
              const SizedBox(height: 12),
              ScreenTitle(
                title: 'Bạn là ai\ntrên bàn ăn?',
                subtitle:
                    'Chỉ ĂnMates dùng để ghép Mate hợp vía — không bao giờ public số tử vi của bạn.',
              ),
              const SizedBox(height: 28),

              _FieldLabel('TÊN ĐẦY ĐỦ'),
              _PlainInput(controller: _nameCtrl, hint: 'Nguyễn Thảo Vy'),
              const SizedBox(height: 16),

              _FieldLabel('GỌI THÂN MẬT'),
              _PlainInput(
                controller: _nicknameCtrl,
                hint: 'Vy',
                helper: 'Mates sẽ thấy tên này trong chat',
              ),
              const SizedBox(height: 16),

              _FieldLabel('NGÀY THÁNG NĂM SINH'),
              Row(
                children: [
                  Expanded(
                    child: _PlainInput(
                      controller: _dayCtrl,
                      hint: 'NGÀY',
                      keyboardType: TextInputType.number,
                      maxLen: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PlainInput(
                      controller: _monthCtrl,
                      hint: 'THÁNG',
                      keyboardType: TextInputType.number,
                      maxLen: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _PlainInput(
                      controller: _yearCtrl,
                      hint: 'NĂM',
                      keyboardType: TextInputType.number,
                      maxLen: 4,
                    ),
                  ),
                ],
              ),

              // Auto-derive reveal section
              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _derived == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: _DerivedCard(
                          derived: _derived!,
                          show: _showDerivedPublic,
                          onToggle: (v) =>
                              setState(() => _showDerivedPublic = v),
                        ),
                      ),
              ),

              const SizedBox(height: 24),
              _FieldLabel('TÍNH CÁCH BÀN ĂN'),
              const SizedBox(height: 6),
              _PersonalitySlider(
                value: _personality,
                onChanged: (v) => setState(() => _personality = v),
              ),

              const SizedBox(height: 28),
              Row(
                children: [
                  const Icon(Icons.lock_rounded,
                      size: 14, color: AppColors.ink50),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'ĂnMates lưu mã hoá · không bán cho bên thứ ba',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        color: AppColors.ink50,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AnmCTA(
                label: _busy ? 'Đang lưu...' : 'Hoàn tất ✨',
                onTap: (_canSubmit && !_busy) ? _submit : null,
                background:
                    (_canSubmit && !_busy) ? AppColors.berry : AppColors.ink30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Local "derived" model (just for live preview) ───────────────────────────

class _Derived {
  final String zodiac;
  final String nguHanh;
  final String numerology;

  _Derived({required this.zodiac, required this.nguHanh, required this.numerology});

  bool eq(_Derived o) =>
      o.zodiac == zodiac && o.nguHanh == nguHanh && o.numerology == numerology;

  static _Derived from(DateTime t) {
    return _Derived(
      zodiac: _zodiac(t),
      nguHanh: _nguHanh(t),
      numerology: _numerology(t),
    );
  }

  static String _zodiac(DateTime t) {
    final m = t.month, d = t.day;
    if ((m == 3 && d >= 21) || (m == 4 && d <= 19)) return 'Bạch Dương';
    if ((m == 4 && d >= 20) || (m == 5 && d <= 20)) return 'Kim Ngưu';
    if ((m == 5 && d >= 21) || (m == 6 && d <= 20)) return 'Song Tử';
    if ((m == 6 && d >= 21) || (m == 7 && d <= 22)) return 'Cự Giải';
    if ((m == 7 && d >= 23) || (m == 8 && d <= 22)) return 'Sư Tử';
    if ((m == 8 && d >= 23) || (m == 9 && d <= 22)) return 'Xử Nữ';
    if ((m == 9 && d >= 23) || (m == 10 && d <= 22)) return 'Thiên Bình';
    if ((m == 10 && d >= 23) || (m == 11 && d <= 21)) return 'Bọ Cạp';
    if ((m == 11 && d >= 22) || (m == 12 && d <= 21)) return 'Nhân Mã';
    if ((m == 12 && d >= 22) || (m == 1 && d <= 19)) return 'Ma Kết';
    if ((m == 1 && d >= 20) || (m == 2 && d <= 18)) return 'Bảo Bình';
    return 'Song Ngư';
  }

  static const _elements = [
    'Hải Trung Kim',
    'Hải Trung Kim',
    'Lư Trung Hỏa',
    'Lư Trung Hỏa',
    'Đại Lâm Mộc',
    'Đại Lâm Mộc',
    'Lộ Bàng Thổ',
    'Lộ Bàng Thổ',
    'Kiếm Phong Kim',
    'Kiếm Phong Kim',
    'Sơn Đầu Hỏa',
    'Sơn Đầu Hỏa',
    'Giản Hạ Thủy',
    'Giản Hạ Thủy',
    'Thành Đầu Thổ',
    'Thành Đầu Thổ',
    'Bạch Lạp Kim',
    'Bạch Lạp Kim',
    'Dương Liễu Mộc',
    'Dương Liễu Mộc',
    'Tuyền Trung Thủy',
    'Tuyền Trung Thủy',
    'Ốc Thượng Thổ',
    'Ốc Thượng Thổ',
    'Tích Lịch Hỏa',
    'Tích Lịch Hỏa',
    'Tùng Bách Mộc',
    'Tùng Bách Mộc',
    'Trường Lưu Thủy',
    'Trường Lưu Thủy',
    'Sa Trung Kim',
    'Sa Trung Kim',
    'Sơn Hạ Hỏa',
    'Sơn Hạ Hỏa',
    'Bình Địa Mộc',
    'Bình Địa Mộc',
    'Bích Thượng Thổ',
    'Bích Thượng Thổ',
    'Kim Bạc Kim',
    'Kim Bạc Kim',
    'Phú Đăng Hỏa',
    'Phú Đăng Hỏa',
    'Thiên Hà Thủy',
    'Thiên Hà Thủy',
    'Đại Trạch Thổ',
    'Đại Trạch Thổ',
    'Thoa Xuyến Kim',
    'Thoa Xuyến Kim',
    'Tang Đố Mộc',
    'Tang Đố Mộc',
    'Đại Khê Thủy',
    'Đại Khê Thủy',
    'Sa Trung Thổ',
    'Sa Trung Thổ',
    'Thiên Thượng Hỏa',
    'Thiên Thượng Hỏa',
    'Thạch Lựu Mộc',
    'Thạch Lựu Mộc',
    'Đại Hải Thủy',
    'Đại Hải Thủy',
  ];

  static String _nguHanh(DateTime t) {
    final idx = ((t.year - 1924) % 60 + 60) % 60;
    return _elements[idx];
  }

  static String _numerology(DateTime t) {
    final digits = <int>[];
    for (final n in [t.year, t.month, t.day]) {
      var x = n;
      while (x > 0) {
        digits.add(x % 10);
        x ~/= 10;
      }
    }
    var sum = digits.fold<int>(0, (s, d) => s + d);
    int reduce(int n) {
      while (n > 9 && n != 11 && n != 22 && n != 33) {
        var s = 0;
        var x = n;
        while (x > 0) {
          s += x % 10;
          x ~/= 10;
        }
        n = s;
      }
      return n;
    }

    final life = reduce(sum);
    const labels = {
      1: 'Tiên phong',
      2: 'Hài hoà',
      3: 'Sáng tạo',
      4: 'Kiên định',
      5: 'Tự do · Phiêu lưu',
      6: 'Ân cần',
      7: 'Nội tâm',
      8: 'Quyết đoán',
      9: 'Vị tha',
      11: 'Trực giác',
      22: 'Kiến tạo',
      33: 'Bậc thầy',
    };
    return 'Số $life · ${labels[life] ?? 'Đặc biệt'}';
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: AppTextStyles.label()),
      );
}

class _PlainInput extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String? helper;
  final TextInputType keyboardType;
  final int? maxLen;

  const _PlainInput({
    required this.controller,
    required this.hint,
    this.helper,
    this.keyboardType = TextInputType.text,
    this.maxLen,
  });

  @override
  State<_PlainInput> createState() => _PlainInputState();
}

class _PlainInputState extends State<_PlainInput> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Focus(
          onFocusChange: (f) => setState(() => _focused = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _focused ? AppColors.berry : AppColors.ink10,
                width: _focused ? 1.5 : 1,
              ),
            ),
            child: TextField(
              controller: widget.controller,
              keyboardType: widget.keyboardType,
              maxLength: widget.maxLen,
              inputFormatters: widget.keyboardType == TextInputType.number
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : null,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: AppColors.ink30,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
              ),
            ),
          ),
        ),
        if (widget.helper != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.helper!,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              color: AppColors.ink50,
            ),
          ),
        ],
      ],
    );
  }
}

class _DerivedCard extends StatelessWidget {
  final _Derived derived;
  final bool show;
  final ValueChanged<bool> onToggle;

  const _DerivedCard({
    required this.derived,
    required this.show,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.wisteria.withOpacity(0.18),
            AppColors.berry.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.wisteria.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Sparkle(
                  size: 14, color: AppColors.berry, animated: true),
              const SizedBox(width: 8),
              Text(
                'ĂN MATES TỰ NHẬN DIỆN',
                style: AppTextStyles.eyebrow(),
              ),
              const Spacer(),
              const Sparkle(
                  size: 12, color: AppColors.wisteriaDeep, animated: true),
            ],
          ),
          const SizedBox(height: 14),
          _DerivedRow(label: 'CUNG HOÀNG ĐẠO', value: derived.zodiac),
          const SizedBox(height: 10),
          _DerivedRow(label: 'MỆNH NGŨ HÀNH', value: derived.nguHanh),
          const SizedBox(height: 10),
          _DerivedRow(label: 'THẦN SỐ HỌC', value: derived.numerology),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  show
                      ? 'Hiển thị trên profile public'
                      : 'Ẩn khỏi profile public',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink70,
                  ),
                ),
              ),
              Switch(
                value: show,
                onChanged: onToggle,
                activeThumbColor: AppColors.berry,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DerivedRow extends StatelessWidget {
  final String label;
  final String value;
  const _DerivedRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: AppTextStyles.label()),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _PersonalitySlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _PersonalitySlider({required this.value, required this.onChanged});

  String get _label {
    if (value < 33) return 'Introvert · $value';
    if (value < 66) return 'Ambivert · $value';
    return 'Extrovert · $value';
  }

  String get _ctx {
    if (value < 33) return 'Tám 1-1';
    if (value < 66) return 'Cân bằng';
    return 'Bàn 6+';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Text(
                _ctx,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.berry,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.berry,
              inactiveTrackColor: AppColors.ink10,
              thumbColor: AppColors.berry,
              overlayColor: AppColors.berry.withOpacity(0.15),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Introvert', style: AppTextStyles.label()),
                Text('Extrovert', style: AppTextStyles.label()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
