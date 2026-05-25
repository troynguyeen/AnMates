import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/anm_logo.dart';
import '../../widgets/anm_widgets.dart';

class DiscoverView extends StatefulWidget {
  const DiscoverView({super.key});

  @override
  State<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView> {
  final Set<String> _activeVibes = {'❄️ Máy lạnh'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mint,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const SizedBox(height: 12),
                _buildSearchBar(),
                const SizedBox(height: 24),
                _buildGenreSection(),
                const SizedBox(height: 24),
                _buildVibeSection(),
                const SizedBox(height: 24),
                _buildHotNearbySection(),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnmTabBar(activeIndex: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          LogoMark(size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📍 QUẬN 1, TP.HCM',
                  style: AppTextStyles.mono(
                    size: 10,
                    weight: FontWeight.w600,
                    color: AppColors.ink50,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hôm nay ăn gì, Vy?',
                  style: AppTextStyles.body(
                    size: 15,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          TrustRing(score: 96, size: 42),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Text('🔍', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tìm quán, món, vibe…',
                style: AppTextStyles.body(
                  size: 14,
                  color: AppColors.ink50,
                ),
              ),
            ),
            const Text('🎙️', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Eyebrow('BẠN THÈM GENRE GÌ?'),
              const Spacer(),
              Text(
                'Xem tất cả',
                style: AppTextStyles.body(
                  size: 12,
                  weight: FontWeight.w600,
                  color: AppColors.berry,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _GenreCard(
                label: 'Lẩu sùng sục',
                emoji: '🍲',
                gradient: const LinearGradient(
                  colors: [AppColors.berry, AppColors.berryDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              const SizedBox(width: 10),
              _GenreCard(
                label: 'Nướng xì xèo',
                emoji: '🥩',
                gradient: const LinearGradient(
                  colors: [AppColors.wisteria, AppColors.wisteriaDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              const SizedBox(width: 10),
              _GenreCard(
                label: 'Cafe chill',
                emoji: '☕',
                gradient: const LinearGradient(
                  colors: [AppColors.ocean, AppColors.oceanDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              const SizedBox(width: 10),
              _GenreCard(
                label: 'Ăn vặt phố',
                emoji: '🍢',
                gradient: LinearGradient(
                  colors: [AppColors.glaucous, AppColors.glaucous.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVibeSection() {
    final vibes = [
      '❄️ Máy lạnh',
      '🌿 Vỉa hè',
      '🔇 Khuất hẻm',
      '✨ Sang chảnh',
      '🌙 Ngồi khuya',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Eyebrow('… HAY MUỐN VIBE NÀO?'),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: vibes.map((v) {
              final active = _activeVibes.contains(v);
              return AnmChip(
                label: v,
                active: active,
                color: AppColors.ocean,
                onTap: () {
                  setState(() {
                    if (active) {
                      _activeVibes.remove(v);
                    } else {
                      _activeVibes.add(v);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHotNearbySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Eyebrow('HOT QUANH BẠN · 18:00'),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _RestaurantRow(
                name: 'Tiệm mì Ramen Q1',
                tag: '🍜 Mì · Lẩu',
                dist: '0.4km',
                peopleCraving: 15,
                hot: false,
              ),
              const SizedBox(height: 10),
              _RestaurantRow(
                name: 'Bò tơ nướng đá tảng',
                tag: '🥩 Nướng · Bia',
                dist: '1.2km',
                peopleCraving: 8,
                hot: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GenreCard extends StatelessWidget {
  final String label;
  final String emoji;
  final LinearGradient gradient;

  const _GenreCard({
    required this.label,
    required this.emoji,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 90,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 10,
            top: 10,
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantRow extends StatelessWidget {
  final String name;
  final String tag;
  final String dist;
  final int peopleCraving;
  final bool hot;

  const _RestaurantRow({
    required this.name,
    required this.tag,
    required this.dist,
    required this.peopleCraving,
    required this.hot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          PhotoSlot(width: 68, height: 68, radius: 14, label: '📸'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTextStyles.body(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hot)
                      Text('🔥', style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$tag · $dist',
                  style: AppTextStyles.body(
                    size: 12,
                    color: AppColors.ink50,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.berry,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$peopleCraving người đang thèm',
                    style: AppTextStyles.mono(
                      size: 9,
                      weight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ink10, width: 1),
            ),
            child: const Center(
              child: Text('→', style: TextStyle(fontSize: 16, color: AppColors.ink)),
            ),
          ),
        ],
      ),
    );
  }
}
