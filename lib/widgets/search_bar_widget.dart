import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SearchBarWidget extends StatefulWidget {
  final String currentQuery;
  final String selectedCategory;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onOpenFilter;
  final bool hasActiveFilters;

  const SearchBarWidget({
    super.key,
    required this.currentQuery,
    required this.selectedCategory,
    required this.onQueryChanged,
    required this.onCategoryChanged,
    required this.onOpenFilter,
    this.hasActiveFilters = false,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _textController;
  Timer? _debounce;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.explore_rounded},
    {'name': 'Cyberpunk', 'icon': Icons.bolt_rounded},
    {'name': 'Nature', 'icon': Icons.forest_rounded},
    {'name': 'Space', 'icon': Icons.public_rounded},
    {'name': 'Architecture', 'icon': Icons.apartment_rounded},
    {'name': 'Anime', 'icon': Icons.auto_awesome_rounded},
    {'name': 'Minimalist', 'icon': Icons.crop_square_rounded},
    {'name': 'Vehicles', 'icon': Icons.directions_car_filled_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.currentQuery);
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void didUpdateWidget(covariant SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentQuery != widget.currentQuery &&
        _textController.text != widget.currentQuery) {
      _textController.text = widget.currentQuery;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      widget.onQueryChanged(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input Box
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isFocused
                    ? AppTheme.primaryLight
                    : AppTheme.borderSubtle,
                width: _isFocused ? 1.5 : 1.0,
              ),
              boxShadow: _isFocused ? AppTheme.glowingShadow : [],
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(
                  Icons.search_rounded,
                  color: _isFocused ? AppTheme.primaryLight : AppTheme.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari foto, panorama, cyberpunk...',
                      hintStyle: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 14,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
                if (_textController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white70),
                    onPressed: () {
                      _textController.clear();
                      widget.onQueryChanged('');
                      setState(() {});
                    },
                  ),
                // Filter Button with Indicator
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.tune_rounded,
                        color: widget.hasActiveFilters ? AppTheme.secondary : Colors.white70,
                        size: 21,
                      ),
                      onPressed: widget.onOpenFilter,
                    ),
                    if (widget.hasActiveFilters)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Horizontal Category Pills
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = widget.selectedCategory.toLowerCase() == cat['name'].toString().toLowerCase();

              return GestureDetector(
                onTap: () => widget.onCategoryChanged(cat['name']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.primaryGradient : null,
                    color: isSelected ? null : AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : AppTheme.borderSubtle,
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat['icon'] as IconData,
                        size: 15,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat['name'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
