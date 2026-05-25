// AppLoader — global reusable loading primitive (3 modes).
// Spec: /memory/design-system.md §AppLoader
//
// Usage:
//   final id = AppLoader.show(context, mode: LoaderMode.overlay, caption: '...');
//   ... do async work ...
//   AppLoader.hide(id);
//
// Or wrap a future:
//   final result = await AppLoader.run(context,
//     mode: LoaderMode.overlay,
//     caption: 'Đang xác minh khuôn mặt...',
//     future: () => api.verifyFace(),
//   );

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum LoaderMode { splash, overlay, topBar }

class LoaderHandle {
  final String id;
  const LoaderHandle._(this.id);
}

/// Global registry of active loaders. Process-wide singleton.
class AppLoader {
  AppLoader._();
  static final _state = _LoaderState();

  /// Mount the host once near the root of the widget tree
  /// (e.g. wrap MaterialApp.builder).
  static Widget host({required Widget child}) =>
      _LoaderHost(state: _state, child: child);

  static LoaderHandle show(
    BuildContext context, {
    LoaderMode mode = LoaderMode.overlay,
    String? caption,
    bool determinate = false,
    double progress = 0.0,
  }) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _state.push(_LoaderToken(
      id: id,
      mode: mode,
      caption: caption,
      determinate: determinate,
      progress: progress,
      shownAt: DateTime.now(),
    ));
    return LoaderHandle._(id);
  }

  static void setProgress(LoaderHandle handle, double progress) {
    _state.updateProgress(handle.id, progress.clamp(0.0, 1.0));
  }

  static void hide(LoaderHandle handle) {
    _state.pop(handle.id);
  }

  /// Wrap an async future with an overlay loader. Returns the future result.
  /// Handles min-visible (600ms) and delay-on (300ms) to avoid flash/blink.
  static Future<T> run<T>(
    BuildContext context, {
    LoaderMode mode = LoaderMode.overlay,
    String? caption,
    required Future<T> Function() future,
  }) async {
    LoaderHandle? handle;
    final showTimer = Timer(const Duration(milliseconds: 300), () {
      handle = show(context, mode: mode, caption: caption);
    });
    try {
      final result = await future();
      return result;
    } finally {
      showTimer.cancel();
      if (handle != null) {
        // Min-visible 600ms after it actually showed.
        await Future.delayed(const Duration(milliseconds: 600));
        hide(handle!);
      }
    }
  }
}

// ─── Internal state ──────────────────────────────────────────────────────────

class _LoaderToken {
  final String id;
  final LoaderMode mode;
  final String? caption;
  final bool determinate;
  double progress;
  final DateTime shownAt;

  _LoaderToken({
    required this.id,
    required this.mode,
    this.caption,
    this.determinate = false,
    this.progress = 0.0,
    required this.shownAt,
  });
}

class _LoaderState extends ChangeNotifier {
  final List<_LoaderToken> _tokens = [];

  List<_LoaderToken> get tokens => List.unmodifiable(_tokens);

  _LoaderToken? get topOverlay {
    for (var i = _tokens.length - 1; i >= 0; i--) {
      if (_tokens[i].mode == LoaderMode.overlay) return _tokens[i];
    }
    return null;
  }

  bool get hasTopBar => _tokens.any((t) => t.mode == LoaderMode.topBar);

  double get topBarMaxProgress {
    double maxP = 0;
    bool hasIndeterminate = false;
    for (final t in _tokens) {
      if (t.mode != LoaderMode.topBar) continue;
      if (!t.determinate) {
        hasIndeterminate = true;
      } else if (t.progress > maxP) {
        maxP = t.progress;
      }
    }
    return hasIndeterminate ? -1 : maxP; // -1 = indeterminate
  }

  void push(_LoaderToken t) {
    _tokens.add(t);
    notifyListeners();
  }

  void pop(String id) {
    _tokens.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void updateProgress(String id, double p) {
    for (final t in _tokens) {
      if (t.id == id) {
        t.progress = p;
        notifyListeners();
        return;
      }
    }
  }
}

// ─── Host (mount near MaterialApp root) ─────────────────────────────────────

class _LoaderHost extends StatelessWidget {
  final _LoaderState state;
  final Widget child;
  const _LoaderHost({required this.state, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        AnimatedBuilder(
          animation: state,
          builder: (context, _) {
            final overlay = state.topOverlay;
            final showTopBar = state.hasTopBar;
            final topBarProgress = state.topBarMaxProgress;
            return Stack(
              children: [
                if (overlay != null)
                  _OverlayLoader(caption: overlay.caption),
                if (showTopBar)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: MediaQuery.of(context).viewPadding.top,
                    child: _TopBarLoader(progress: topBarProgress),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ─── Modes ───────────────────────────────────────────────────────────────────

class _OverlayLoader extends StatelessWidget {
  final String? caption;
  const _OverlayLoader({this.caption});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(caption ?? 'overlay'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, t, _) => Opacity(
        opacity: t,
        child: ColoredBox(
          color: AppColors.ink.withOpacity(0.45 * t),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              constraints: const BoxConstraints(maxWidth: 280),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SplashBar(width: 200),
                  if (caption != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      caption!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBarLoader extends StatefulWidget {
  final double progress; // -1 = indeterminate, 0..1 = determinate
  const _TopBarLoader({required this.progress});

  @override
  State<_TopBarLoader> createState() => _TopBarLoaderState();
}

class _TopBarLoaderState extends State<_TopBarLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: widget.progress < 0
          ? AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) => CustomPaint(
                painter: _IndeterminatePainter(_ctrl.value),
                child: const SizedBox.expand(),
              ),
            )
          : LayoutBuilder(
              builder: (context, box) {
                return Stack(children: [
                  Container(color: Colors.transparent),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: box.maxWidth * widget.progress,
                    color: AppColors.berry,
                  ),
                ]);
              },
            ),
    );
  }
}

class _IndeterminatePainter extends CustomPainter {
  final double t;
  _IndeterminatePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = AppColors.berry;
    final width = size.width * 0.3;
    final x = (size.width + width) * t - width;
    canvas.drawRect(Rect.fromLTWH(x, 0, width, size.height), p);
  }

  @override
  bool shouldRepaint(_IndeterminatePainter old) => old.t != t;
}

// ─── Splash-mode bar (shared) ────────────────────────────────────────────────

class _SplashBar extends StatefulWidget {
  final double width;
  const _SplashBar({required this.width});

  @override
  State<_SplashBar> createState() => _SplashBarState();
}

class _SplashBarState extends State<_SplashBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Container(
          color: AppColors.ink10,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => CustomPaint(
              painter: _SplashBarPainter(_ctrl.value),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashBarPainter extends CustomPainter {
  final double t;
  _SplashBarPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.wisteria, AppColors.berry],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final w = size.width * 0.45;
    final x = (size.width + w) * t - w;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, w, size.height),
        const Radius.circular(999),
      ),
      p,
    );
  }

  @override
  bool shouldRepaint(_SplashBarPainter old) => old.t != t;
}
