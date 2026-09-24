import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/image_item.dart';
import '../services/image_service.dart';
import '../theme/app_theme.dart';
import 'shimmer_placeholder.dart';

class Parallax3DCard extends StatefulWidget {
  final ImageItem item;
  final VoidCallback? onTap;
  final double height;

  const Parallax3DCard({
    super.key,
    required this.item,
    this.onTap,
    this.height = 260,
  });

  @override
  State<Parallax3DCard> createState() => _Parallax3DCardState();
}

class _Parallax3DCardState extends State<Parallax3DCard> with SingleTickerProviderStateMixin {
  double _rotateX = 0.0;
  double _rotateY = 0.0;
  late AnimationController _resetController;
  late Animation<double> _animRotateX;
  late Animation<double> _animRotateY;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (size.width == 0 || size.height == 0) return;
    final dx = details.localPosition.dx - (size.width / 2);
    final dy = details.localPosition.dy - (size.height / 2);

    final normalizedX = (dx / (size.width / 2)).clamp(-1.0, 1.0);
    final normalizedY = (dy / (size.height / 2)).clamp(-1.0, 1.0);

    setState(() {
      _rotateY = normalizedX * 0.25; // max tilt angle in radians
      _rotateX = -normalizedY * 0.25;
    });
  }

  void _resetOrientation() {
    _animRotateX = Tween<double>(begin: _rotateX, end: 0.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    );
    _animRotateY = Tween<double>(begin: _rotateY, end: 0.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    );

    _resetController.reset();
    _resetController.forward();
    _resetController.addListener(() {
      setState(() {
        _rotateX = _animRotateX.value;
        _rotateY = _animRotateY.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0018) // 3D perspective factor
      ..rotateX(_rotateX)
      ..rotateY(_rotateY);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardSize = Size(constraints.maxWidth, widget.height);

        return GestureDetector(
          onTap: widget.onTap,
          onPanUpdate: (details) => _onPanUpdate(details, cardSize),
          onPanEnd: (_) => _resetOrientation(),
          onPanCancel: () => _resetOrientation(),
          child: MouseRegion(
            onHover: (event) {
              final dx = event.localPosition.dx - (cardSize.width / 2);
              final dy = event.localPosition.dy - (cardSize.height / 2);
              final nx = (dx / (cardSize.width / 2)).clamp(-1.0, 1.0);
              final ny = (dy / (cardSize.height / 2)).clamp(-1.0, 1.0);
              setState(() {
                _rotateY = nx * 0.25;
                _rotateX = -ny * 0.25;
              });
            },
            onExit: (_) => _resetOrientation(),
            child: Transform(
              alignment: FractionalOffset.center,
              transform: matrix,
              child: Container(
                height: widget.height,
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.2),
                      blurRadius: 16,
                      offset: Offset(-_rotateY * 30, _rotateX * 30 + 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Scaled Background Image with counter parallax offset
                      Transform.translate(
                        offset: Offset(_rotateY * 25, -_rotateX * 25),
                        child: Transform.scale(
                          scale: 1.15,
                          child: CachedNetworkImage(
                            imageUrl: widget.item.regularUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const ShimmerPlaceholder(),
                            errorWidget: (context, url, error) => Container(
                              color: AppTheme.surfaceElevated,
                              child: const Icon(Icons.broken_image_rounded, color: Colors.white24),
                            ),
                          ),
                        ),
                      ),

                      // 2. Specular Light Glint Shader
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(-1.0 + _rotateY * 2, -1.0 - _rotateX * 2),
                              end: Alignment(1.0 + _rotateY * 2, 1.0 - _rotateX * 2),
                              colors: [
                                Colors.white.withOpacity(0.18),
                                Colors.transparent,
                                Colors.black.withOpacity(0.65),
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // 3. Floating 3D Foreground Elements
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Transform.translate(
                          offset: Offset(-_rotateY * 35, _rotateX * 35),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceGlass,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.view_in_ar_rounded, size: 12, color: AppTheme.secondary),
                                const SizedBox(width: 4),
                                Text(
                                  widget.item.category.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 4. Floating Favorite Button
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Transform.translate(
                          offset: Offset(-_rotateY * 35, _rotateX * 35),
                          child: GestureDetector(
                            onTap: () {
                              ImageService.instance.toggleFavorite(widget.item);
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: widget.item.isFavorite
                                    ? AppTheme.accentPink.withOpacity(0.3)
                                    : AppTheme.surfaceGlass,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: widget.item.isFavorite
                                      ? AppTheme.accentPink
                                      : AppTheme.borderSubtle,
                                ),
                              ),
                              child: Icon(
                                widget.item.isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 16,
                                color: widget.item.isFavorite
                                    ? AppTheme.accentPink
                                    : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 5. Floating Bottom Title & Photographer Label
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Transform.translate(
                          offset: Offset(-_rotateY * 40, _rotateX * 40),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceGlass,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.borderSubtle),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.item.photographer,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
