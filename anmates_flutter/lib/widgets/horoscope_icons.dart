import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Horoscope / numerology icon library for the onboarding auto-detect cards.
///
/// One cohesive, dependency-free icon set covering the three categories shown on
/// Screen 08 (Thông Tin Cá Nhân):
///   • Cung Hoàng Đạo  — 12 western zodiac signs (Unicode astrological glyphs)
///   • Mệnh Ngũ Hành   — 5 elements (Kim/Mộc/Thủy/Hỏa/Thổ) with traditional colors
///   • Thần Số Học     — life-path number 1–9 rendered as a numeral badge
///
/// Each icon is a self-contained badge: a soft tinted rounded square with the
/// symbol centered, so the three cards read as one designed family.

// ─── Zodiac ──────────────────────────────────────────────────────────────────

/// Unicode astrological glyph for each Vietnamese zodiac name.
const Map<String, String> _zodiacGlyphs = {
  'Bạch Dương': '♈', // Aries
  'Kim Ngưu': '♉', // Taurus
  'Song Tử': '♊', // Gemini
  'Cự Giải': '♋', // Cancer
  'Sư Tử': '♌', // Leo
  'Xử Nữ': '♍', // Virgo
  'Thiên Bình': '♎', // Libra
  'Bọ Cạp': '♏', // Scorpio
  'Nhân Mã': '♐', // Sagittarius
  'Ma Kết': '♑', // Capricorn
  'Bảo Bình': '♒', // Aquarius
  'Song Ngư': '♓', // Pisces
};

String zodiacGlyph(String viName) => _zodiacGlyphs[viName] ?? '✦';

// ─── Ngũ Hành (Five Elements) ────────────────────────────────────────────────

/// Visual spec for one of the five elements: a Material icon + traditional color.
typedef ElementVisual = ({IconData icon, Color color});

const Map<String, ElementVisual> _elementVisuals = {
  // Kim (Metal) — gold/amber, gem
  'Kim': (icon: Icons.diamond_outlined, color: Color(0xFFCAA53D)),
  // Mộc (Wood) — green, foliage
  'Mộc': (icon: Icons.park_outlined, color: Color(0xFF3FA66A)),
  // Thủy (Water) — blue, droplet
  'Thủy': (icon: Icons.water_drop_outlined, color: Color(0xFF2D9CDB)),
  // Hỏa (Fire) — red/orange, flame
  'Hỏa': (icon: Icons.local_fire_department_outlined, color: Color(0xFFE8553C)),
  // Thổ (Earth) — brown, terrain
  'Thổ': (icon: Icons.terrain_outlined, color: Color(0xFFB07A3C)),
};

/// Extracts the element word (Kim/Mộc/Thủy/Hỏa/Thổ) from a Nạp Âm name such as
/// "Bạch Lạp Kim" → "Kim".
String elementOf(String napAmName) {
  for (final key in _elementVisuals.keys) {
    if (napAmName.endsWith(key)) return key;
  }
  return 'Thổ';
}

ElementVisual elementVisual(String element) =>
    _elementVisuals[element] ?? _elementVisuals['Thổ']!;

// ─── Badge widgets ───────────────────────────────────────────────────────────

/// Shared rounded-square badge holding any centered child.
class _IconBadge extends StatelessWidget {
  final Widget child;
  final Color tint;
  final double size;
  const _IconBadge({
    required this.child,
    required this.tint,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

/// Zodiac badge — Unicode glyph tinted berry.
class ZodiacIcon extends StatelessWidget {
  final String viName;
  final double size;
  const ZodiacIcon({super.key, required this.viName, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return _IconBadge(
      tint: AppColors.berry,
      size: size,
      child: Text(
        zodiacGlyph(viName),
        style: TextStyle(
          fontSize: size * 0.56,
          color: AppColors.berry,
          height: 1.0,
        ),
      ),
    );
  }
}

/// Ngũ Hành badge — element Material icon in its traditional color.
class NguHanhIcon extends StatelessWidget {
  final String element; // Kim/Mộc/Thủy/Hỏa/Thổ
  final double size;
  const NguHanhIcon({super.key, required this.element, this.size = 34});

  @override
  Widget build(BuildContext context) {
    final v = elementVisual(element);
    return _IconBadge(
      tint: v.color,
      size: size,
      child: Icon(v.icon, size: size * 0.52, color: v.color),
    );
  }
}

/// Thần Số Học badge — the life-path numeral in a gradient circle.
class ThanSoIcon extends StatelessWidget {
  final int number;
  final double size;
  const ThanSoIcon({super.key, required this.number, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.wisteria, AppColors.berry],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: size * 0.5,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }
}
