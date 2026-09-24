import 'package:flutter/material.dart';
import '../services/image_service.dart';
import '../theme/app_theme.dart';
import '../widgets/parallax_card.dart';
import 'image_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _searchFilter = '';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ImageService.instance,
      builder: (context, _) {
        var favorites = ImageService.instance.getFavorites();

        if (_searchFilter.isNotEmpty) {
          favorites = favorites.where((img) {
            final q = _searchFilter.toLowerCase();
            return img.title.toLowerCase().contains(q) ||
                img.category.toLowerCase().contains(q) ||
                img.photographer.toLowerCase().contains(q);
          }).toList();
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                const Icon(Icons.favorite_rounded, color: AppTheme.accentPink, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Koleksi Favorit',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPink.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${favorites.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentPink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: favorites.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Search inside favorites
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: TextField(
                          onChanged: (val) => setState(() => _searchFilter = val),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Cari dalam favorit...',
                            hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),

                    // Parallax Feed of Favorites
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: favorites.length,
                        itemBuilder: (context, index) {
                          final item = favorites[index];
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
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
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
                Icons.favorite_border_rounded,
                size: 56,
                color: AppTheme.accentPink,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum Ada Foto Favorit',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ketuk ikon hati pada gambar yang Anda sukai untuk menyimpannya ke koleksi ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.explore_rounded, color: Colors.white, size: 18),
              label: const Text(
                'Jelajahi Galeri',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
