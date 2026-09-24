import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/image_item.dart';
import '../services/image_service.dart';
import '../theme/app_theme.dart';
import 'shimmer_placeholder.dart';

class ParallaxCard extends StatefulWidget {
  final ImageItem item;
  final VoidCallback? onTap;
  final double height;
  final bool showFullDetails;

  const ParallaxCard({
    super.key,
    required this.item,
    this.onTap,
    this.height = 260,
    this.showFullDetails = true,
  });

  @override
  State<ParallaxCard> createState() => _ParallaxCardState();
}

class _ParallaxCardState extends State<ParallaxCard>
    with SingleTickerProviderStateMixin {
  final GlobalKey _backgroundImageKey = GlobalKey();
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heartScale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _onFavoriteTap() {
    _heartController.forward(from: 0.0);
    ImageService.instance.toggleFavorite(widget.item);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scrollable = Scrollable.maybeOf(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Parallax Image Layer
            Hero(
              tag: 'image_${widget.item.id}',
              child: scrollable != null
                  ? Flow(
                      delegate: ParallaxFlowDelegate(
                        scrollable: scrollable,
                        listItemContext: context,
                        backgroundImageKey: _backgroundImageKey,
                      ),
                      children: [_buildImageWithConstraints()],
                    )
                  : _buildImageWithConstraints(),
            ),

            // 2. Cinematic Gradient Overlay
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.darkImageOverlay,
              ),
            ),

            // 3. Top Badges Row (Category & Favorite)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Category Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceGlass,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppTheme.primaryLight.withOpacity(0.4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.item.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Animated Like Button
                  GestureDetector(
                    onTap: _onFavoriteTap,
                    child: ScaleTransition(
                      scale: _heartScale,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.item.isFavorite
                              ? AppTheme.accentPink.withOpacity(0.25)
                              : AppTheme.surfaceGlass,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.item.isFavorite
                                ? AppTheme.accentPink.withOpacity(0.8)
                                : AppTheme.borderSubtle,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          widget.item.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: widget.item.isFavorite
                              ? AppTheme.accentPink
                              : Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. Bottom Content Info Layer
            Positioned(
              bottom: 16,
              left: 18,
              right: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    widget.item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Photographer & Meta Row
                  Row(
                    children: [
                      // Photographer Avatar / Icon
                      if (widget.item.photographerAvatar.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: widget.item.photographerAvatar,
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Icon(
                              Icons.person_rounded,
                              size: 14,
                              color: Colors.white70,
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.camera_alt_outlined,
                          size: 14,
                          color: AppTheme.secondary,
                        ),
                      const SizedBox(width: 8),

                      // Photographer Name
                      Expanded(
                        child: Text(
                          widget.item.photographer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      // Likes Counter
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            size: 10,
                            color: AppTheme.accentPink,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatNumber(widget.item.likes),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.75),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Parallax Depth Indicator Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.primaryLight.withOpacity(0.3),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.layers_outlined,
                              size: 11,
                              color: AppTheme.primaryLight,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'PARALLAX',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: AppTheme.primaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 5. Transparent Material Touch Ripple
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                splashColor: AppTheme.primaryLight.withOpacity(0.15),
                highlightColor: Colors.white.withOpacity(0.05),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWithConstraints() {
    return SizedBox(
      width: double.infinity,
      height: widget.height + 100.0,
      child: CachedNetworkImage(
        key: _backgroundImageKey,
        imageUrl: widget.item.regularUrl,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        placeholder: (context, url) =>
            ShimmerPlaceholder(height: widget.height + 100.0),
        errorWidget: (context, url, error) => Container(
          color: AppTheme.surfaceElevated,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image_rounded,
                color: AppTheme.textMuted,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                'Gagal memuat gambar',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}

class ParallaxFlowDelegate extends FlowDelegate {
  ParallaxFlowDelegate({
    required this.scrollable,
    required this.listItemContext,
    required this.backgroundImageKey,
  }) : super(repaint: scrollable.position);

  final ScrollableState scrollable;
  final BuildContext listItemContext;
  final GlobalKey backgroundImageKey;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    // Child image is 100px taller than the card to provide smooth vertical parallax travel without empty gaps
    return BoxConstraints.tightFor(
      width: constraints.maxWidth,
      height: constraints.maxHeight + 100.0,
    );
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    final scrollableBox = scrollable.context.findRenderObject() as RenderBox?;
    final listItemBox = listItemContext.findRenderObject() as RenderBox?;
    if (scrollableBox == null || listItemBox == null) return;

    final listItemOffset = listItemBox.localToGlobal(
      listItemBox.size.centerLeft(Offset.zero),
      ancestor: scrollableBox,
    );

    final viewportDimension = scrollable.position.viewportDimension;
    if (viewportDimension <= 0) return;

    final scrollFraction = (listItemOffset.dy / viewportDimension).clamp(
      0.0,
      1.0,
    );

    // Calculate vertical parallax offset so the image covers the card at all scroll positions
    final childHeight =
        context.getChildSize(0)?.height ?? (context.size.height + 100.0);
    final cardHeight = context.size.height;
    final maxParallaxOffset = childHeight - cardHeight;
    final yOffset = -scrollFraction * maxParallaxOffset;

    context.paintChild(
      0,
      transform: Transform.translate(offset: Offset(0.0, yOffset)).transform,
    );
  }

  @override
  bool shouldRepaint(ParallaxFlowDelegate oldDelegate) {
    return scrollable != oldDelegate.scrollable ||
        listItemContext != oldDelegate.listItemContext ||
        backgroundImageKey != oldDelegate.backgroundImageKey;
  }
}
