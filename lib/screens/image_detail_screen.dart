import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/image_item.dart';
import '../services/image_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_placeholder.dart';
import '../widgets/download_progress_dialog.dart';
import 'wallpaper_preview_screen.dart';

class ImageDetailScreen extends StatefulWidget {
  final ImageItem item;

  const ImageDetailScreen({super.key, required this.item});

  @override
  State<ImageDetailScreen> createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends State<ImageDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  void _openWallpaperStudio() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            WallpaperPreviewScreen(item: widget.item),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    ImageService.instance.toggleFavorite(widget.item);
    setState(() {});
  }

  void _downloadImage() {
    DownloadProgressDialog.show(context, widget.item);
  }

  void _copyImageUrl() {
    Clipboard.setData(ClipboardData(text: widget.item.fullUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Row(
          children: [
            Icon(Icons.link_rounded, color: AppTheme.secondary, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tautan gambar berhasil disalin ke clipboard!',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Parallax calculation: background image moves at half speed of scrolling
    final parallaxTranslate = _scrollOffset * 0.45;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // 1. Parallax Header Background Image
          Positioned(
            top: -parallaxTranslate,
            left: 0,
            right: 0,
            height: 480,
            child: Hero(
              tag: 'image_${widget.item.id}',
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 3.5,
                child: CachedNetworkImage(
                  imageUrl: widget.item.fullUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const ShimmerPlaceholder(height: 480),
                  errorWidget: (context, url, error) => Container(
                    color: AppTheme.surfaceElevated,
                    child: const Icon(Icons.broken_image_rounded, size: 60, color: Colors.white24),
                  ),
                ),
              ),
            ),
          ),

          // 2. Gradient Overlay for Parallax Fade
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 480,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      AppTheme.background,
                    ],
                    stops: const [0.0, 0.35, 0.7, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // 3. Scrollable Foreground Details
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Transparent space to reveal the parallax image behind
              const SliverToBoxAdapter(
                child: SizedBox(height: 380),
              ),

              // Content Details Sheet
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    border: Border(
                      top: BorderSide(color: AppTheme.borderSubtle, width: 1.5),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Category & Parallax Depth Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primaryLight.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome, color: AppTheme.secondary, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  widget.item.category.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.aspect_ratio_rounded, size: 14, color: AppTheme.primaryLight),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.item.width.toInt()} x ${widget.item.height.toInt()} px',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primaryLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Title
                      Text(
                        widget.item.title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Description
                      Text(
                        widget.item.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons Row (Download, Set Wallpaper, Copy Link)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _downloadImage,
                              icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                              label: const Text(
                                'Download HD',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _openWallpaperStudio,
                              icon: const Icon(Icons.wallpaper_rounded, color: Colors.white, size: 18),
                              label: const Text(
                                'Set Wallpaper',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.surfaceElevated,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: AppTheme.secondary, width: 1.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _copyImageUrl,
                            icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.surfaceElevated,
                              padding: const EdgeInsets.all(14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: AppTheme.borderSubtle),
                              ),
                            ),
                            tooltip: 'Salin Tautan',
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Photographer Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: widget.item.photographerAvatar.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: widget.item.photographerAvatar,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) => const Icon(Icons.person, size: 28),
                                    )
                                  : Container(
                                      width: 48,
                                      height: 48,
                                      color: AppTheme.primary.withOpacity(0.3),
                                      child: const Icon(Icons.person, color: Colors.white),
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.item.photographer,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '@${widget.item.photographerUsername}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.primaryLight.withOpacity(0.3)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.verified_rounded, size: 14, color: AppTheme.primaryLight),
                                  SizedBox(width: 4),
                                  Text(
                                    'Creator',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.primaryLight,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Tags List
                      if (widget.item.tags.isNotEmpty) ...[
                        const Text(
                          'Tag Terkait',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.item.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.borderSubtle),
                              ),
                              child: Text(
                                '#$tag',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 4. Fixed Top App Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Right Actions: Favorite Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: IconButton(
                    icon: Icon(
                      widget.item.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: widget.item.isFavorite ? AppTheme.accentPink : Colors.white,
                      size: 22,
                    ),
                    onPressed: _toggleFavorite,
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
