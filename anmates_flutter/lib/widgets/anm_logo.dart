import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── 4-point sparkle (brand motif) ──────────────────────────────────────────
class Sparkle extends StatelessWidget {
  final double size;
  final Color color;

  const Sparkle({super.key, this.size = 24, this.color = AppColors.berry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SparklePainter(color)),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;
  _SparklePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final path = Path();
    // 4-point star: M12 0 C12.8 8 16 11.2 24 12 C16 12.8 12.8 16 12 24...
    // scaled to [0,size]
    final s = size.width / 24;
    path.moveTo(cx, 0);
    path.cubicTo(cx + 0.8 * s, 8 * s, cx + 4 * s, cy - 0.8 * s, size.width, cy);
    path.cubicTo(cx + 4 * s, cy + 0.8 * s, cx + 0.8 * s, cy + 4 * s, cx, size.height);
    path.cubicTo(cx - 0.8 * s, cy + 4 * s, cx - 4 * s, cy + 0.8 * s, 0, cy);
    path.cubicTo(cx - 4 * s, cy - 0.8 * s, cx - 0.8 * s, 8 * s, cx, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.color != color;
}

// ─── Logo Mark ────────────────────────────────────────────────────────────────
// Location pin: circular dining-table head with crossed chopsticks + heart tip
class LogoMark extends StatelessWidget {
  final double size;
  final Color fill;
  final Color accent;

  const LogoMark({
    super.key,
    this.size = 96,
    this.fill = AppColors.berry,
    this.accent = AppColors.mint,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.18,
      child: CustomPaint(painter: _LogoPainter(fill, accent)),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color fill;
  final Color accent;
  _LogoPainter(this.fill, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sx = w / 100.0;
    final sy = h / 118.0;

    // Pin body gradient
    final pinPaint = Paint()
      ..shader = LinearGradient(
        colors: [fill, AppColors.berryDeep],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final pin = Path()
      ..moveTo(50 * sx, 4 * sy)
      ..cubicTo(75 * sx, 4 * sy, 92 * sx, 22 * sy, 92 * sx, 47 * sy)
      ..cubicTo(92 * sx, 60 * sy, 84 * sx, 70 * sy, 75 * sx, 78 * sy)
      ..cubicTo(68 * sx, 84 * sy, 60 * sx, 92 * sy, 54 * sx, 104 * sy)
      ..cubicTo(52 * sx, 108 * sy, 48 * sx, 108 * sy, 46 * sx, 104 * sy)
      ..cubicTo(40 * sx, 92 * sy, 32 * sx, 84 * sy, 25 * sx, 78 * sy)
      ..cubicTo(16 * sx, 70 * sy, 8 * sx, 60 * sy, 8 * sx, 47 * sy)
      ..cubicTo(8 * sx, 22 * sy, 25 * sx, 4 * sy, 50 * sx, 4 * sy)
      ..close();
    canvas.drawPath(pin, pinPaint);

    // Dining table circle
    final tablePaint = Paint()..color = accent..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(50 * sx, 44 * sy), 22 * sy, tablePaint);

    // Table border
    final borderPaint = Paint()
      ..color = AppColors.ink10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(50 * sx, 44 * sy), 22 * sy, borderPaint);

    // Crossed chopsticks
    final chopstickPaint = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(50 * sx, 44 * sy);
    canvas.rotate(28 * 3.14159 / 180);
    final stick1 = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 3 * sx, height: 44 * sy),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(stick1, chopstickPaint);
    canvas.restore();

    canvas.save();
    canvas.translate(50 * sx, 44 * sy);
    canvas.rotate(-28 * 3.14159 / 180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 3 * sx, height: 44 * sy),
        const Radius.circular(1.5),
      ),
      chopstickPaint,
    );
    canvas.restore();

    // Heart at intersection
    final heartPaint = Paint()..color = AppColors.berry..style = PaintingStyle.fill;
    final heart = Path();
    final hx = 50 * sx;
    final hy = 47 * sy;
    final hs = sx;
    heart.moveTo(hx, hy);
    heart.cubicTo(hx - 2 * hs, hy - 3 * hs, hx - 6 * hs, hy - 3 * hs, hx - 6 * hs, hy);
    heart.cubicTo(hx - 6 * hs, hy + 3 * hs, hx - 3 * hs, hy + 5 * hs, hx, hy + 8 * hs);
    heart.cubicTo(hx + 3 * hs, hy + 5 * hs, hx + 6 * hs, hy + 3 * hs, hx + 6 * hs, hy);
    heart.cubicTo(hx + 6 * hs, hy - 3 * hs, hx + 2 * hs, hy - 3 * hs, hx, hy);
    heart.close();
    canvas.drawPath(heart, heartPaint);

    // Sparkle at pin tip
    final sparklePaint = Paint()..color = accent..style = PaintingStyle.fill;
    final spx = 50 * sx;
    final spy = 88 * sy;
    final ss = sx;
    final sparkPath = Path()
      ..moveTo(spx, spy)
      ..cubicTo(spx + 0.4 * ss, spy + 4 * ss, spx + 1.8 * ss, spy + 5.6 * ss, spx + 5.6 * ss, spy + 6 * ss)
      ..cubicTo(spx + 1.8 * ss, spy + 6.4 * ss, spx + 0.4 * ss, spy + 7.8 * ss, spx, spy + 11.6 * ss)
      ..cubicTo(spx - 0.4 * ss, spy + 7.8 * ss, spx - 1.8 * ss, spy + 6.4 * ss, spx - 5.6 * ss, spy + 6 * ss)
      ..cubicTo(spx - 1.8 * ss, spy + 5.6 * ss, spx - 0.4 * ss, spy + 4 * ss, spx, spy)
      ..close();
    canvas.drawPath(sparkPath, sparklePaint);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.fill != fill || old.accent != accent;
}

// ─── Wordmark ─────────────────────────────────────────────────────────────────
class AnMatesWordmark extends StatelessWidget {
  final double size;
  final Color color;
  final Color accent;

  const AnMatesWordmark({
    super.key,
    this.size = 36,
    this.color = AppColors.ink,
    this.accent = AppColors.berry,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Ăn',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              package: 'google_fonts',
              fontSize: size,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: 'Mates',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              package: 'google_fonts',
              fontSize: size,
              fontWeight: FontWeight.w800,
              color: accent,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
