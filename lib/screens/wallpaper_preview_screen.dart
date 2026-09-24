import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/image_item.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_placeholder.dart';
import '../widgets/download_progress_dialog.dart';

enum WallpaperMode { lockScreen, homeScreen }

enum WallpaperTarget { homeScreen, lockScreen, both }

class WallpaperPreviewScreen extends StatefulWidget {
  final ImageItem item;

  const WallpaperPreviewScreen({
    super.key,
    required this.item,
  });

  @override
  State<WallpaperPreviewScreen> createState() => _WallpaperPreviewScreenState();
}

class _WallpaperPreviewScreenState extends State<WallpaperPreviewScreen> {
  WallpaperMode _mode = WallpaperMode.lockScreen;
  double _overlayDim = 0.15; // 0.0, 0.25, 0.50
  bool _hideControls = false;
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime time) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final dayName = days[time.weekday - 1];
    final monthName = months[time.month - 1];
    return '$dayName, ${time.day} $monthName';
  }

  void _showSettingModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: AppTheme.borderSubtle, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title and Photo thumbnail
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: widget.item.thumbUrl.isNotEmpty
                          ? widget.item.thumbUrl
                          : widget.item.regularUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Atur Sebagai Wallpaper',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(color: AppTheme.borderSubtle, height: 1),
              const SizedBox(height: 16),

              // Option 1: Layar Kunci
              _buildSettingOption(
                icon: Icons.lock_outline_rounded,
                title: 'Layar Kunci (Lock Screen)',
                subtitle: 'Terapkan foto ini khusus di layar kunci ponsel',
                onTap: () => _applyWallpaper(WallpaperTarget.lockScreen),
              ),

              const SizedBox(height: 10),

              // Option 2: Layar Utama
              _buildSettingOption(
                icon: Icons.home_outlined,
                title: 'Layar Utama (Home Screen)',
                subtitle: 'Terapkan foto ini di layar beranda ponsel Anda',
                onTap: () => _applyWallpaper(WallpaperTarget.homeScreen),
              ),

              const SizedBox(height: 10),

              // Option 3: Keduanya
              _buildSettingOption(
                icon: Icons.phone_android_rounded,
                title: 'Layar Utama & Kunci (Keduanya)',
                subtitle: 'Terapkan foto ini untuk semua layar ponsel',
                isHighlighted: true,
                onTap: () => _applyWallpaper(WallpaperTarget.both),
              ),

              const SizedBox(height: 16),
              const Divider(color: AppTheme.borderSubtle, height: 1),
              const SizedBox(height: 12),

              // Option 4: Unduh Resolusi Layar
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _simulateSaveWallpaper();
                },
                icon: const Icon(Icons.download_rounded, color: AppTheme.secondary, size: 18),
                label: const Text(
                  'Unduh File Foto Resolusi Penuh untuk Wallpaper',
                  style: TextStyle(color: AppTheme.secondary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isHighlighted
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted ? AppTheme.primaryLight : AppTheme.borderSubtle,
            width: isHighlighted ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? AppTheme.primary
                    : AppTheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isHighlighted ? Colors.white : AppTheme.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isHighlighted ? Colors.white : Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _applyWallpaper(WallpaperTarget target) {
    Navigator.pop(context); // Close bottom sheet

    // Show loading progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppTheme.secondary,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Menerapkan Wallpaper...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Menyesuaikan rasio foto dengan layar perangkat',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Simulate completion
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.pop(context); // Close progress dialog

      String targetText;
      switch (target) {
        case WallpaperTarget.lockScreen:
          targetText = 'Layar Kunci';
          break;
        case WallpaperTarget.homeScreen:
          targetText = 'Layar Utama';
          break;
        case WallpaperTarget.both:
          targetText = 'Layar Utama & Layar Kunci';
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.accentEmerald,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Wallpaper Berhasil Disetel!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Foto telah diterapkan pada $targetText.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _simulateSaveWallpaper() {
    DownloadProgressDialog.show(context, widget.item);
  }

  void _toggleDim() {
    setState(() {
      if (_overlayDim == 0.0) {
        _overlayDim = 0.20;
      } else if (_overlayDim == 0.20) {
        _overlayDim = 0.40;
      } else {
        _overlayDim = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. FULL-SCREEN PHOTO WALLPAPER (Pinch & Pan to adjust position)
          InteractiveViewer(
            minScale: 1.0,
            maxScale: 3.5,
            child: SizedBox.expand(
              child: CachedNetworkImage(
                imageUrl: widget.item.fullUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const ShimmerPlaceholder(height: double.infinity),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.surfaceElevated,
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.white24),
                  ),
                ),
              ),
            ),
          ),

          // 2. Optional Contrast / Dim Overlay
          if (_overlayDim > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withValues(alpha: _overlayDim),
                ),
              ),
            ),

          // 3. Tap to toggle UI controls
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                setState(() {
                  _hideControls = !_hideControls;
                });
              },
            ),
          ),

          // 4. PHONE SYSTEM MOCKUP LAYER (Lock Screen or Home Screen)
          IgnorePointer(
            child: SafeArea(
              child: _mode == WallpaperMode.lockScreen
                  ? _buildLockScreenMockup()
                  : _buildHomeScreenMockup(),
            ),
          ),

          // 5. TOP CONTROLS & MODE SELECTOR
          if (!_hideControls)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // Back button
                  _buildGlassButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: 'Kembali',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),

                  // Mode Selector: Lock Screen vs Home Screen
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildModeTab(
                              icon: Icons.lock_rounded,
                              label: 'Layar Kunci',
                              isSelected: _mode == WallpaperMode.lockScreen,
                              onTap: () => setState(() => _mode = WallpaperMode.lockScreen),
                            ),
                          ),
                          Expanded(
                            child: _buildModeTab(
                              icon: Icons.apps_rounded,
                              label: 'Layar Utama',
                              isSelected: _mode == WallpaperMode.homeScreen,
                              onTap: () => setState(() => _mode = WallpaperMode.homeScreen),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Brightness / Dim filter toggle
                  _buildGlassButton(
                    icon: _overlayDim == 0.0
                        ? Icons.brightness_high_rounded
                        : (_overlayDim < 0.3 ? Icons.brightness_medium_rounded : Icons.brightness_2_rounded),
                    tooltip: 'Atur Kecerahan: ${(_overlayDim * 100).toInt()}% redup',
                    onTap: _toggleDim,
                  ),
                ],
              ),
            ),

          // 6. BOTTOM ACTION BAR ("Terapkan Sebagai Wallpaper")
          if (!_hideControls)
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Instruction Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Text(
                      'Geser/Zoom foto untuk menyesuaikan • Ketuk layar untuk sembunyikan UI',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Apply Wallpaper Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showSettingModal,
                      icon: const Icon(Icons.wallpaper_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        'Atur / Terapkan Wallpaper',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 10,
                        shadowColor: AppTheme.primary.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                          side: const BorderSide(color: AppTheme.secondary, width: 1.2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }

  Widget _buildModeTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.white60,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LOCK SCREEN SIMULATION ---
  Widget _buildLockScreenMockup() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top clock area
        Column(
          children: [
            const SizedBox(height: 60),
            const Icon(
              Icons.lock_rounded,
              size: 20,
              color: Colors.white70,
              shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
            ),
            const SizedBox(height: 8),
            Text(
              _formatTime(_currentTime),
              style: const TextStyle(
                fontSize: 78,
                fontWeight: FontWeight.w200,
                color: Colors.white,
                letterSpacing: -2,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 18),
                ],
              ),
            ),
            Text(
              _formatDate(_currentTime),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 12),
                ],
              ),
            ),
          ],
        ),

        // Bottom lockscreen shortcuts
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 90),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white12),
                ),
                child: const Icon(Icons.flashlight_on_rounded, color: Colors.white, size: 24),
              ),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- HOME SCREEN SIMULATION ---
  Widget _buildHomeScreenMockup() {
    return Column(
      children: [
        const SizedBox(height: 65),

        // Search Bar Widget
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              children: [
                Icon(Icons.search_rounded, color: Colors.white70, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cari di Google atau ketik URL...',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
                Icon(Icons.mic_rounded, color: Colors.white70, size: 20),
              ],
            ),
          ),
        ),

        const SizedBox(height: 36),

        // App Icons Grid Row 1
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAppIcon(Icons.call_rounded, 'Telepon', const Color(0xFF34C759)),
              _buildAppIcon(Icons.message_rounded, 'Pesan', const Color(0xFF007AFF)),
              _buildAppIcon(Icons.public_rounded, 'Browser', const Color(0xFFFF9500)),
              _buildAppIcon(Icons.photo_library_rounded, 'Galeri', const Color(0xFFAF52DE)),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // App Icons Grid Row 2
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAppIcon(Icons.music_note_rounded, 'Musik', const Color(0xFFFF2D55)),
              _buildAppIcon(Icons.calendar_month_rounded, 'Kalender', const Color(0xFF5856D6)),
              _buildAppIcon(Icons.settings_rounded, 'Pengaturan', const Color(0xFF8E8E93)),
              _buildAppIcon(Icons.camera_alt_rounded, 'Kamera', const Color(0xFF5AC8FA)),
            ],
          ),
        ),

        const Spacer(),

        // Page Indicator Dots
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.circle, size: 6, color: Colors.white),
            SizedBox(width: 6),
            Icon(Icons.circle, size: 6, color: Colors.white30),
            SizedBox(width: 6),
            Icon(Icons.circle, size: 6, color: Colors.white30),
          ],
        ),

        const SizedBox(height: 16),

        // Bottom Dock with 4 apps
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDockIcon(Icons.call_rounded, const Color(0xFF34C759)),
                _buildDockIcon(Icons.message_rounded, const Color(0xFF007AFF)),
                _buildDockIcon(Icons.public_rounded, const Color(0xFFFF9500)),
                _buildDockIcon(Icons.camera_alt_rounded, const Color(0xFF5AC8FA)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 90),
      ],
    );
  }

  Widget _buildAppIcon(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
          ),
        ),
      ],
    );
  }

  Widget _buildDockIcon(IconData icon, Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: Colors.white, size: 26),
    );
  }
}
