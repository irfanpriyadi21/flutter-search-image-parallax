import 'package:flutter/material.dart';
import '../services/image_service.dart';
import '../theme/app_theme.dart';

class FilterSheet extends StatefulWidget {
  final String currentOrientation;
  final String currentSort;
  final Function(String orientation, String sort) onApply;

  const FilterSheet({
    super.key,
    required this.currentOrientation,
    required this.currentSort,
    required this.onApply,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late String _orientation;
  late String _sort;
  late TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    _orientation = widget.currentOrientation;
    _sort = widget.currentSort;
    _apiKeyController = TextEditingController(
      text: ImageService.instance.pixabayApiKey,
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppTheme.borderSubtle, width: 1.5)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter & Pengaturan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _orientation = 'all';
                      _sort = 'popular';
                    });
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: AppTheme.secondary),
                  ),
                ),
              ],
            ),
            const Divider(color: AppTheme.borderSubtle, height: 24),

            // Orientation Section
            const Text(
              'Orientasi Gambar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildChoiceChip(
                  label: 'Semua',
                  icon: Icons.grid_view_rounded,
                  isSelected: _orientation == 'all',
                  onTap: () => setState(() => _orientation = 'all'),
                ),
                const SizedBox(width: 10),
                _buildChoiceChip(
                  label: 'Landscape',
                  icon: Icons.stay_current_landscape_rounded,
                  isSelected: _orientation == 'landscape',
                  onTap: () => setState(() => _orientation = 'landscape'),
                ),
                const SizedBox(width: 10),
                _buildChoiceChip(
                  label: 'Portrait',
                  icon: Icons.stay_current_portrait_rounded,
                  isSelected: _orientation == 'portrait',
                  onTap: () => setState(() => _orientation = 'portrait'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sort Section
            const Text(
              'Urutkan Berdasarkan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildChoiceChip(
                  label: 'Terpopuler',
                  icon: Icons.trending_up_rounded,
                  isSelected: _sort == 'popular',
                  onTap: () => setState(() => _sort = 'popular'),
                ),
                const SizedBox(width: 10),
                _buildChoiceChip(
                  label: 'Terbaru',
                  icon: Icons.fiber_new_rounded,
                  isSelected: _sort == 'latest',
                  onTap: () => setState(() => _sort = 'latest'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Unsplash API Key Section (Optional)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.api_rounded, color: AppTheme.secondary, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Pixabay API Key (Aktif)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Terkoneksi langsung ke Pixabay API untuk mencari jutaan gambar berkualitas tinggi dengan efek parallax.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _apiKeyController,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Masukkan API Key Pixabay...',
                      hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      suffixIcon: _apiKeyController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () => setState(() => _apiKeyController.clear()),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ImageService.instance.setPixabayApiKey(_apiKeyController.text);
                  widget.onApply(_orientation, _sort);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      'Terapkan Filter',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.primaryGradient : null,
            color: isSelected ? null : AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppTheme.borderSubtle,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
