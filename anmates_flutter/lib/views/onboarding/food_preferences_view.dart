import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/anm_widgets.dart';

/// Screen 09 — Gú Ẩm Thực (step 4/5). Multi-select food + vibe tags, requires at
/// least 5 food tags, then persists preferences (which marks onboarding done).
class FoodPreferencesView extends StatefulWidget {
  /// Called once preferences are saved — finishes the onboarding flow.
  final VoidCallback onComplete;

  const FoodPreferencesView({super.key, required this.onComplete});

  @override
  State<FoodPreferencesView> createState() => _FoodPreferencesViewState();
}

class _FoodPreferencesViewState extends State<FoodPreferencesView> {
  static const _minFood = 5;

  // value (persisted) → label (shown). Emoji prefixed in label.
  static const _foodTags = <String, String>{
    'spicy': '🌶️ Ăn cay cấp 3',
    'healthy': '🥗 Healthy',
    'beef': '🥩 Beef lover',
    'noodles': '🍜 Mì các loại',
    'seafood': '🦐 Hải sản',
    'sweet': '🍰 Hảo ngọt',
    'vegan': '🌱 Chay linh hoạt',
    'street': '🍢 Không hành',
    'beer': '🍺 Bia hơi',
    'coffee': '☕ Cà phê đen',
    'dimsum': '🥟 Dim sum',
    'sushi': '🍣 Sushi',
  };

  static const _vibeTags = <String, String>{
    'party': 'Tám tới bến',
    'quiet': 'Yên tĩnh thư giãn',
    'explore': 'Khám phá quán mới',
    'street_vibe': 'Vỉa hè bụi bặm',
    'fancy': 'Sang chảnh check-in',
  };

  final Set<String> _selectedFood = {};
  final Set<String> _selectedVibe = {};
  bool _saving = false;

  bool get _canContinue => _selectedFood.length >= _minFood && !_saving;

  Future<void> _continue() async {
    if (!_canContinue) return;
    setState(() => _saving = true);
    try {
      await ProfileService().savePreferences(
        foodTags: _selectedFood.toList(),
        vibeTags: _selectedVibe.toList(),
      );
      if (!mounted) return;
      widget.onComplete();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(title: 'GÚ ẨM THỰC', step: 4, total: 5),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('GÚ ẨM THỰC'),
                    const SizedBox(height: 8),
                    Text(
                      'Bạn ăn kiểu gì?',
                      style: AppTextStyles.display(
                        size: 28,
                        weight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chọn ít nhất 5 thẻ — để ĂnMates ghép bạn với những '
                      'người ăn cùng vibe.',
                      style: AppTextStyles.body(
                        size: 14,
                        color: AppColors.ink70,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _foodTags.entries.map((e) {
                        final selected = _selectedFood.contains(e.key);
                        return _PrefChip(
                          label: e.value,
                          selected: selected,
                          onTap: () => setState(() {
                            selected
                                ? _selectedFood.remove(e.key)
                                : _selectedFood.add(e.key);
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'VIBE BUỔI ĂN',
                      style: AppTextStyles.mono(
                        size: 10,
                        weight: FontWeight.w700,
                        color: AppColors.berry,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _vibeTags.entries.map((e) {
                        final selected = _selectedVibe.contains(e.key);
                        return _PrefChip(
                          label: e.value,
                          selected: selected,
                          onTap: () => setState(() {
                            selected
                                ? _selectedVibe.remove(e.key)
                                : _selectedVibe.add(e.key);
                          }),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            _BottomBar(
              count: _selectedFood.length,
              total: _minFood,
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

// ─── Selectable preference chip (berry selected / white unselected) ──────────
class _PrefChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PrefChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.berry : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.berry : AppColors.ink10,
            width: 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.berry.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

// ─── Top bar (back + title + progress) ───────────────────────────────────────
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

// ─── Bottom bar (counter + CTA) ──────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int count;
  final int total;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;
  const _BottomBar({
    required this.count,
    required this.total,
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
      child: Row(
        children: [
          Text(
            '$count/$total đã chọn',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: count >= total ? AppColors.berry : AppColors.ink50,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: AnmCTA(
              label: loading ? 'Đang lưu…' : 'Tiếp tục  →',
              onTap: enabled ? onTap : null,
              background: enabled ? AppColors.berry : AppColors.ink30,
            ),
          ),
        ],
      ),
    );
  }
}
