// Screen 10a — Photo upload (last onboarding step before Home).
// Spec: design-system.md §Profile Setup §Screen 10a
//
// Uses image_picker for camera/gallery on all platforms (web included).
// Photos are encoded as data: URLs and POSTed to /api/me/photos.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/onboarding_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/anm_widgets.dart';
import '../../widgets/app_loader.dart';

class PhotosView extends StatefulWidget {
  final VoidCallback onFinished;
  const PhotosView({super.key, required this.onFinished});

  @override
  State<PhotosView> createState() => _PhotosViewState();
}

class _PhotosViewState extends State<PhotosView> {
  // List of (id, dataUrl) loaded from / posted to backend.
  final List<({String id, String url, bool isMain})> _photos = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final list = await OnboardingService().getPhotos();
      if (!mounted) return;
      setState(() {
        _photos
          ..clear()
          ..addAll(list.map((p) => (
                id: p['id'] as String,
                url: p['url'] as String,
                isMain: p['is_main'] as bool? ?? false,
              )));
      });
    } catch (_) {
      // best-effort; ignore on first run (new user has zero photos).
    }
  }

  Future<void> _addPhoto(ImageSource source) async {
    if (_photos.length >= 3) return;
    final picker = ImagePicker();
    XFile? file;
    try {
      file = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
    } catch (e) {
      _showError('Không mở được trình chọn ảnh: $e');
      return;
    }
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final mime = _guessMime(file.name) ?? 'image/jpeg';
    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

    try {
      final res = await AppLoader.run(
        context,
        caption: 'Đang tải ảnh lên...',
        future: () => OnboardingService().postPhoto(
          dataUrl: dataUrl,
          isMain: _photos.isEmpty,
        ),
      );
      if (!mounted) return;
      setState(() {
        _photos.add((
          id: res['id'] as String,
          url: res['url'] as String,
          isMain: res['is_main'] as bool? ?? false,
        ));
      });
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deletePhoto(String id) async {
    try {
      await AppLoader.run(
        context,
        caption: 'Đang xoá ảnh...',
        future: () => OnboardingService().deletePhoto(id),
      );
      if (!mounted) return;
      setState(() => _photos.removeWhere((p) => p.id == id));
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _finish() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AppLoader.run(
        context,
        caption: 'Đang hoàn tất...',
        future: () => OnboardingService().finishOnboarding(),
      );
      if (!mounted) return;
      widget.onFinished();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.berry,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String? _guessMime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
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
                    const Eyebrow('BƯỚC CUỐI · MÔ TẢ BẢN THÂN'),
                    const SizedBox(height: 12),
                    ScreenTitle(
                      title: 'Show bản thân nào ✨',
                      subtitle:
                          'Tối đa 3 tấm — chọn những khoảnh khắc kể nhiều về bạn nhất. Mate ăn cùng sẽ thấy đầu tiên.',
                    ),
                    const SizedBox(height: 24),
                    _PhotoGrid(
                      photos: _photos,
                      onDelete: _deletePhoto,
                    ),
                    const SizedBox(height: 20),
                    _SourceRow(
                      enabled: _photos.length < 3,
                      onCamera: () => _addPhoto(ImageSource.camera),
                      onGallery: () => _addPhoto(ImageSource.gallery),
                    ),
                    const SizedBox(height: 24),
                    const _TipsBox(),
                  ],
                ),
              ),
            ),
            // Sticky footer
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: BoxDecoration(
                color: AppColors.mint,
                border: Border(top: BorderSide(color: AppColors.ink10)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_photos.length} / 3 ảnh',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink50,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnmCTA(
                    label: _busy
                        ? 'Đang hoàn tất...'
                        : _photos.isEmpty
                            ? 'Bỏ qua · Vào ứng dụng'
                            : 'Hoàn tất ✨',
                    onTap: _busy ? null : _finish,
                    background: AppColors.berry,
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

// ─── Photo grid ─────────────────────────────────────────────────────────────

class _PhotoGrid extends StatelessWidget {
  final List<({String id, String url, bool isMain})> photos;
  final ValueChanged<String> onDelete;

  const _PhotoGrid({
    required this.photos,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final p = i < photos.length ? photos[i] : null;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: p == null
                  ? _EmptySlot(label: i == 0 ? 'Ảnh chính' : 'Ảnh ${i + 1}')
                  : _FilledSlot(
                      url: p.url,
                      isMain: p.isMain,
                      onDelete: () => onDelete(p.id),
                    ),
            ),
          ),
        );
      }),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final String label;
  const _EmptySlot({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.wisteria.withOpacity(0.18),
            AppColors.mint,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.ink10,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink10,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.add,
                size: 22, color: AppColors.berry),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.ink70,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilledSlot extends StatelessWidget {
  final String url;
  final bool isMain;
  final VoidCallback onDelete;

  const _FilledSlot({
    required this.url,
    required this.isMain,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _renderImage(url),
        ),
        if (isMain)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.berry,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'MAIN',
                style: AppTextStyles.mono(
                  size: 9,
                  weight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _renderImage(String url) {
    // data: URL → decode bytes; http(s) → network.
    if (url.startsWith('data:')) {
      final comma = url.indexOf(',');
      if (comma > 0) {
        final b64 = url.substring(comma + 1);
        try {
          final bytes = base64Decode(b64);
          return Image.memory(bytes, fit: BoxFit.cover);
        } catch (_) {
          return Container(color: AppColors.ink10);
        }
      }
    }
    return Image.network(url, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(color: AppColors.ink10));
  }
}

// ─── Source row ─────────────────────────────────────────────────────────────

class _SourceRow extends StatelessWidget {
  final bool enabled;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _SourceRow({
    required this.enabled,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    // image_picker maps camera→gallery on web automatically, so a single
    // enabled gate (slots remaining) is enough.
    return Row(
      children: [
        Expanded(
          child: _SourceBtn(
            icon: Icons.camera_alt_outlined,
            label: 'Chụp mới',
            onTap: enabled ? onCamera : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SourceBtn(
            icon: Icons.photo_library_outlined,
            label: 'Thư viện',
            onTap: enabled ? onGallery : null,
          ),
        ),
      ],
    );
  }
}

class _SourceBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _SourceBtn({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: disabled ? AppColors.ink10 : AppColors.berry.withOpacity(0.35),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: disabled ? AppColors.ink30 : AppColors.berry,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: disabled ? AppColors.ink30 : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tips box ───────────────────────────────────────────────────────────────

class _TipsBox extends StatelessWidget {
  const _TipsBox();

  static const _tips = [
    'Một ảnh rõ mặt, ánh sáng tốt — không đeo khẩu trang.',
    'Một ảnh đang ăn / nấu / vibe quán bạn yêu.',
    'Một ảnh sở thích, du lịch, thú cưng...',
    'Tránh ảnh nhóm khó nhận mặt & ảnh có số điện thoại.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
              const Icon(Icons.tips_and_updates_outlined,
                  size: 16, color: AppColors.berry),
              const SizedBox(width: 6),
              Text('MẸO CHỌN ẢNH "ĂN MIẾT"',
                  style: AppTextStyles.eyebrow()),
            ],
          ),
          const SizedBox(height: 10),
          ..._tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.berry,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: AppColors.ink70,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
