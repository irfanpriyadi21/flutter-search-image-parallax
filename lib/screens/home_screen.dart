import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/image_item.dart';
import '../services/image_service.dart';
import '../theme/app_theme.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/parallax_3d_card.dart';
import '../widgets/parallax_card.dart';
import '../widgets/parallax_carousel.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/shimmer_placeholder.dart';
import 'favorites_screen.dart';
import 'image_detail_screen.dart';

enum ViewMode { feedParallax, grid3D }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  List<ImageItem> _images = [];
  List<ImageItem> _featuredImages = [];
  bool _isLoading = true;
  String _currentQuery = '';
  String _selectedCategory = 'All';
  String _selectedOrientation = 'all';
  String _selectedSort = 'popular';
  ViewMode _viewMode = ViewMode.feedParallax;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await ImageService.instance.fetchImages(
      query: _currentQuery,
      category: _selectedCategory,
      orientation: _selectedOrientation,
      sort: _selectedSort,
    );

    // Also get featured images for the top horizontal carousel
    final featured = await ImageService.instance.fetchImages(category: 'All');

    // Apply sorting
    if (_selectedSort == 'latest') {
      results.sort((a, b) => b.id.compareTo(a.id));
    } else {
      results.sort((a, b) => b.likes.compareTo(a.likes));
    }

    if (mounted) {
      setState(() {
        _images = results;
        _featuredImages = featured.take(6).toList();
        _isLoading = false;
      });
    }
  }

  void _onQueryChanged(String query) {
    _currentQuery = query;
    _loadData();
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadData();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterSheet(
        currentOrientation: _selectedOrientation,
        currentSort: _selectedSort,
        onApply: (orientation, sort) {
          setState(() {
            _selectedOrientation = orientation;
            _selectedSort = sort;
          });
          _loadData();
        },
      ),
    );
  }

  bool get _hasActiveFilters =>
      _selectedOrientation != 'all' || _selectedSort != 'popular';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          backgroundColor: AppTheme.surfaceElevated,
          onRefresh: _loadData,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // 1. Top Custom App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Row(
                    children: [
                      // App Logo & Branding (Responsive with Expanded)
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: AppTheme.glowingShadow,
                              ),
                              child: const Icon(
                                Icons.auto_awesome_motion_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) => AppTheme
                                        .primaryGradient
                                        .createShader(bounds),
                                    child: const Text(
                                      'Image Parallax',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.4,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Visual Depth Explorer',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: AppTheme.textSecondary,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Right Controls: Mode Toggle & Favorites
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // View Mode Toggle (Feed vs 3D Tilt Grid)
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(12),
                                  ),
                                  onTap: () => setState(
                                    () => _viewMode = ViewMode.feedParallax,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    child: Icon(
                                      Icons.view_agenda_rounded,
                                      size: 18,
                                      color: _viewMode == ViewMode.feedParallax
                                          ? AppTheme.secondary
                                          : AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 16,
                                  color: AppTheme.borderSubtle,
                                ),
                                InkWell(
                                  borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(12),
                                  ),
                                  onTap: () => setState(
                                    () => _viewMode = ViewMode.grid3D,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    child: Icon(
                                      Icons.grid_view_rounded,
                                      size: 18,
                                      color: _viewMode == ViewMode.grid3D
                                          ? AppTheme.secondary
                                          : AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Favorites Button with dynamic badge
                          AnimatedBuilder(
                            animation: ImageService.instance,
                            builder: (context, _) {
                              final favCount =
                                  ImageService.instance.favoriteIds.length;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceElevated,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.borderSubtle,
                                      ),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const FavoritesScreen(),
                                          ),
                                        ).then((_) => setState(() {}));
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.favorite_rounded,
                                          color: AppTheme.accentPink,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (favCount > 0)
                                    Positioned(
                                      top: -3,
                                      right: -3,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.accentPink,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          '$favCount',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Search & Filter Bar
              SliverToBoxAdapter(
                child: SearchBarWidget(
                  currentQuery: _currentQuery,
                  selectedCategory: _selectedCategory,
                  onQueryChanged: _onQueryChanged,
                  onCategoryChanged: _onCategoryChanged,
                  onOpenFilter: _openFilterSheet,
                  hasActiveFilters: _hasActiveFilters,
                ),
              ),

              // 3. Horizontal Parallax Carousel (Featured, only when search is empty)
              if (_currentQuery.isEmpty &&
                  _selectedCategory == 'All' &&
                  _featuredImages.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: ParallaxCarousel(
                      items: _featuredImages,
                      onItemSelected: (item) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ImageDetailScreen(item: item),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    ),
                  ),
                ),

              // 4. Section Title & Active Result Count
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                _currentQuery.isNotEmpty
                                    ? 'Hasil untuk "$_currentQuery"'
                                    : (_selectedCategory == 'All'
                                          ? 'Galeri Parallax'
                                          : 'Koleksi $_selectedCategory'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.borderSubtle,
                                ),
                              ),
                              child: Text(
                                '${_images.length}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_hasActiveFilters || _currentQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentQuery = '';
                              _selectedCategory = 'All';
                              _selectedOrientation = 'all';
                              _selectedSort = 'popular';
                            });
                            _loadData();
                          },
                          child: const Text(
                            'Reset Filter',
                            style: TextStyle(
                              color: AppTheme.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 5. Loading Skeleton
              if (_isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: List.generate(
                        3,
                        (index) => const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: ShimmerPlaceholder(height: 280),
                        ),
                      ),
                    ),
                  ),
                )
              // 6. Empty State
              else if (_images.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 48,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: const Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Gambar Tidak Ditemukan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Coba kata kunci lain atau ubah kategori pilihan Anda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _currentQuery = '';
                              _selectedCategory = 'All';
                            });
                            _loadData();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Tampilkan Semua Gambar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              // 7A. Feed Mode (Vertical Parallax Cards with FlowDelegate)
              else if (_viewMode == ViewMode.feedParallax)
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = _images[index];
                    return ParallaxCard(
                      item: item,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ImageDetailScreen(item: item),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    );
                  }, childCount: _images.length),
                )
              // 7B. 3D Tilt Grid Mode (Interactive Perspective Parallax Grid)
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  sliver: SliverMasonryGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    itemBuilder: (context, index) {
                      final item = _images[index];
                      // Alternate heights for aesthetic masonry feel
                      final height = (index % 3 == 0)
                          ? 290.0
                          : (index % 2 == 0 ? 250.0 : 270.0);
                      return Parallax3DCard(
                        item: item,
                        height: height,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ImageDetailScreen(item: item),
                            ),
                          ).then((_) => setState(() {}));
                        },
                      );
                    },
                    childCount: _images.length,
                  ),
                ),

              // Bottom Padding
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}
