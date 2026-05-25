// Screen 09a — Gu ẩm thực (Tastes picker)
// Spec: design-system.md §Profile Setup §Screen 09a
//
// User picks ≥5 cuisine tags + ≥1 vibe tag. Live counter, CTA enables when met.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/onboarding_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/anm_widgets.dart';
import '../../widgets/app_loader.dart';
import 'photos_view.dart';

class TastesView extends StatefulWidget {
  final VoidCallback onFinished;
  const TastesView({super.key, required this.onFinished});

  @override
  State<TastesView> createState() => _TastesViewState();
}

class _TastesViewState extends State<TastesView> {
  static const _cuisines = [
    ('cay_3', '🌶️ Ăn cay cấp 3'),
    ('healthy', '🌿 Healthy'),
    ('beef', '🥩 Beef lover'),
    ('mi', '🍜 Mì các loại'),
    ('seafood', '🦐 Hải sản'),
    ('sweet', '🍰 Hảo ngọt'),
    ('chay', '🥗 Chay linh hoạt'),
    ('no_hanh', '🚫 Không hành'),
    ('bia', '🍻 Bia hơi'),
    ('caphe_den', '☕ Cà phê đen'),
    ('dimsum', '🥟 Dim sum'),
    ('sushi', '🍣 Sushi'),
  ];

  static const _vibes = [
    ('tam_toi_ben', 'Tám tới bến'),
    ('yen_tinh', 'Yên tĩnh thư giãn'),
    ('quan_moi', 'Khám phá quán mới'),
    ('via_he', 'Vỉa hè bụi bặm'),
    ('sang_chanh', 'Sang chảnh check-in'),
  ];

  final Set<String> _selectedCuisine = {};
  final Set<String> _selectedVibe = {};
  bool _busy = false;

  bool get _canSubmit =>
      _selectedCuisine.length >= 5 && _selectedVibe.isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit || _busy) return;
    setState(() => _busy = true);
    try {
      await AppLoader.run(
        context,
        caption: 'Đang lưu gu của bạn...',
        future: () => OnboardingService().putTastes(
          cuisineTags: _selectedCuisine.toList(),
          vibeTags: _selectedVibe.toList(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => PhotosView(onFinished: widget.onFinished),
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

  void _toggle(Set<String> bag, String key) {
    setState(() {
      if (bag.contains(key)) {
        bag.remove(key);
      } else {
        bag.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cuisineCount = _selectedCuisine.length;
    final vibeCount = _selectedVibe.length;
    final cuisineMet = cuisineCount >= 5;

    return Scaffold(
      backgroundColor: AppColors.mint,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('BƯỚC 5 / 5 · GU ẨM THỰC'),
                    const SizedBox(height: 12),
                    ScreenTitle(
                      title: 'Bạn ăn kiểu gì?',
                      subtitle:
                          'Chọn ít nhất 5 thẻ — để ĂnMates ghép bạn với những người ăn cùng vibe.',
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _cuisines
                          .map((c) => AnmChip(
                                label: c.$2,
                                active: _selectedCuisine.contains(c.$1),
                                color: AppColors.berry,
                                onTap: () => _toggle(_selectedCuisine, c.$1),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 28),
                    const _SectionLabel('VIBE BUỔI ĂN'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _vibes
                          .map((v) => AnmChip(
                                label: v.$2,
                                active: _selectedVibe.contains(v.$1),
                                color: AppColors.ocean,
                                onTap: () => _toggle(_selectedVibe, v.$1),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            // Sticky footer with counter + CTA
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: BoxDecoration(
                color: AppColors.mint,
                border: Border(top: BorderSide(color: AppColors.ink10)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _Counter(
                        label: 'Ẩm thực',
                        count: cuisineCount,
                        target: 5,
                        met: cuisineMet,
                      ),
                      const SizedBox(width: 12),
                      _Counter(
                        label: 'Vibe',
                        count: vibeCount,
                        target: 1,
                        met: vibeCount >= 1,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AnmCTA(
                    label: _busy ? 'Đang lưu...' : 'Tiếp tục →',
                    onTap: (_canSubmit && !_busy) ? _submit : null,
                    background: (_canSubmit && !_busy)
                        ? AppColors.berry
                        : AppColors.ink30,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: AppTextStyles.label());
}

class _Counter extends StatelessWidget {
  final String label;
  final int count;
  final int target;
  final bool met;

  const _Counter({
    required this.label,
    required this.count,
    required this.target,
    required this.met,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: met ? AppColors.berry.withOpacity(0.10) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: met ? AppColors.berry : AppColors.ink10,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              size: 18,
              color: met ? AppColors.berry : AppColors.ink30,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink70,
                ),
              ),
            ),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: met ? AppColors.berry : AppColors.ink,
              ),
              child: Text('$count / $target'),
            ),
          ],
        ),
      ),
    );
  }
}
