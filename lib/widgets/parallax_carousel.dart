import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/image_item.dart';
import '../theme/app_theme.dart';
import 'shimmer_placeholder.dart';

class ParallaxCarousel extends StatefulWidget {
  final List<ImageItem> items;
  final Function(ImageItem) onItemSelected;

  const ParallaxCarousel({
    super.key,
    required this.items,
    required this.onItemSelected,
  });

  @override
  State<ParallaxCarousel> createState() => _ParallaxCarouselState();
}

class _ParallaxCarouselState extends State<ParallaxCarousel> {
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.84);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Featured Parallax 3D',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.swipe_left_rounded,
                      size: 14,
                      color: AppTheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Swipe',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Carousel Slider
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final delta = index - _currentPage;
              final percent = (1 - (delta.abs() * 0.25)).clamp(0.0, 1.0);
              final scale = 0.90 + (percent * 0.10);
              // Parallax horizontal offset: internal image moves in opposite direction of page swipe
              final parallaxOffset = delta * 75.0;

              return Transform.scale(
                scale: scale,
                child: GestureDetector(
                  onTap: () => widget.onItemSelected(item),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: delta.abs() < 0.5
                            ? AppTheme.primaryLight.withOpacity(0.5)
                            : AppTheme.borderSubtle,
                        width: delta.abs() < 0.5 ? 1.5 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: delta.abs() < 0.5
                              ? AppTheme.primary.withOpacity(0.3)
                              : Colors.black.withOpacity(0.3),
                          blurRadius: delta.abs() < 0.5 ? 20 : 10,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // 1. Horizontally Offset Background Image (Parallax)
                          Positioned(
                            left: -40 + parallaxOffset,
                            right: -40 - parallaxOffset,
                            top: 0,
                            bottom: 0,
                            child: CachedNetworkImage(
                              imageUrl: item.regularUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const ShimmerPlaceholder(),
                              errorWidget: (context, url, error) => Container(
                                color: AppTheme.surfaceElevated,
                                child: const Icon(
                                  Icons.image_not_supported_rounded,
                                  color: Colors.white30,
                                ),
                              ),
                            ),
                          ),

                          // 2. Gradient Overlay for Text Readability
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                  Colors.black.withOpacity(0.85),
                                ],
                                stops: const [0.3, 0.6, 1.0],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),

                          // 3. Top Glowing Tag
                          Positioned(
                            top: 14,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceGlass,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.secondary.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 13,
                                    color: AppTheme.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.category.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 4. Bottom Information Layer
                          Positioned(
                            bottom: 16,
                            left: 16,
                            right: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person_pin_rounded,
                                      size: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        item.photographer,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.75),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Explore',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Indicator Dots
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(math.min(widget.items.length, 6), (
                index,
              ) {
                final isSelected = (_currentPage.round() == index);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isSelected ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryLight
                        : AppTheme.textMuted.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
