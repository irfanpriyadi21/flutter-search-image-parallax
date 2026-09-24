import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/image_item.dart';

class ImageService extends ChangeNotifier {
  static final ImageService instance = ImageService._internal();
  ImageService._internal();

  static const String defaultPixabayApiKey = '17389955-eb167990fe4e1dae1ad3932a1';
  String _pixabayApiKey = defaultPixabayApiKey;
  http.Client _httpClient = http.Client();

  @visibleForTesting
  set httpClient(http.Client client) => _httpClient = client;

  final Set<String> _favoriteIds = {};
  final Map<String, ImageItem> _favoriteItemsMap = {};
  final Map<String, ImageItem> _cacheMap = {};
  bool _isInitialized = false;

  Set<String> get favoriteIds => _favoriteIds;
  String get pixabayApiKey => _pixabayApiKey;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString('pixabay_api_key');
      if (savedKey != null && savedKey.isNotEmpty) {
        _pixabayApiKey = savedKey;
      } else {
        _pixabayApiKey = defaultPixabayApiKey;
      }

      final favList = prefs.getStringList('favorite_images') ?? [];
      _favoriteIds.addAll(favList);

      final favJsonList = prefs.getStringList('favorite_items_json') ?? [];
      for (var jsonStr in favJsonList) {
        try {
          final item = ImageItem.fromJson(jsonStr);
          item.isFavorite = true;
          _favoriteItemsMap[item.id] = item;
          _cacheMap[item.id] = item;
        } catch (_) {}
      }

      // Prepopulate cache with curated images
      for (var img in _curatedImages) {
        _cacheMap[img.id] = img;
        if (_favoriteIds.contains(img.id)) {
          img.isFavorite = true;
          _favoriteItemsMap[img.id] = img;
        }
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing ImageService: $e');
    }
  }

  Future<void> setPixabayApiKey(String? key) async {
    _pixabayApiKey = (key == null || key.trim().isEmpty) ? defaultPixabayApiKey : key.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pixabay_api_key', _pixabayApiKey);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving Pixabay API key: $e');
    }
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);

  Future<void> toggleFavorite(ImageItem item) async {
    if (_favoriteIds.contains(item.id)) {
      _favoriteIds.remove(item.id);
      _favoriteItemsMap.remove(item.id);
      item.isFavorite = false;
    } else {
      _favoriteIds.add(item.id);
      item.isFavorite = true;
      _favoriteItemsMap[item.id] = item;
    }
    _cacheMap[item.id] = item;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_images', _favoriteIds.toList());
      final favJsonList = _favoriteItemsMap.values.map((i) => i.toJson()).toList();
      await prefs.setStringList('favorite_items_json', favJsonList);
    } catch (e) {
      debugPrint('Error saving favorite: $e');
    }
  }

  List<ImageItem> getFavorites() {
    return _favoriteItemsMap.values.toList();
  }

  Future<List<ImageItem>> fetchImages({
    String query = '',
    String category = 'All',
    String orientation = 'all', // all, landscape, portrait
    String sort = 'popular', // popular, latest
    int page = 1,
    int perPage = 24,
  }) async {
    // 1. Try fetching directly from Pixabay API using the configured key
    if (_pixabayApiKey.isNotEmpty) {
      try {
        final results = await _fetchFromPixabay(
          query: query,
          category: category,
          page: page,
          perPage: perPage,
          orientation: orientation,
          sort: sort,
        );
        if (results.isNotEmpty) {
          for (var item in results) {
            item.isFavorite = _favoriteIds.contains(item.id);
            _cacheMap[item.id] = item;
          }
          return results;
        }
      } catch (e) {
        debugPrint('Pixabay fetch error, falling back to curated dataset: $e');
      }
    }

    // 2. Fallback to curated dataset if offline or network failure
    await Future.delayed(const Duration(milliseconds: 250));

    var filtered = List<ImageItem>.from(_curatedImages);

    // Filter by Category
    if (category != 'All') {
      filtered = filtered.where((item) =>
        item.category.toLowerCase() == category.toLowerCase() ||
        item.tags.any((t) => t.toLowerCase() == category.toLowerCase())
      ).toList();
    }

    // Filter by Query
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      filtered = filtered.where((item) {
        final inTitle = item.title.toLowerCase().contains(q);
        final inDesc = item.description.toLowerCase().contains(q);
        final inPhotographer = item.photographer.toLowerCase().contains(q);
        final inTags = item.tags.any((t) => t.toLowerCase().contains(q));
        final inCategory = item.category.toLowerCase().contains(q);
        return inTitle || inDesc || inPhotographer || inTags || inCategory;
      }).toList();
    }

    // Filter by Orientation
    if (orientation == 'landscape') {
      filtered = filtered.where((item) => item.width >= item.height).toList();
    } else if (orientation == 'portrait') {
      filtered = filtered.where((item) => item.height > item.width).toList();
    }

    // Mark favorite status
    for (var item in filtered) {
      item.isFavorite = _favoriteIds.contains(item.id);
      _cacheMap[item.id] = item;
    }

    return filtered;
  }

  Future<List<ImageItem>> _fetchFromPixabay({
    required String query,
    required String category,
    required int page,
    required int perPage,
    required String orientation,
    required String sort,
  }) async {
    // Generate intelligent search keyword for Pixabay
    String searchTerm = query.trim();
    if (searchTerm.isEmpty) {
      if (category == 'All') {
        searchTerm = 'wallpaper nature landscape';
      } else if (category.toLowerCase() == 'cyberpunk') {
        searchTerm = 'cyberpunk neon city';
      } else if (category.toLowerCase() == 'anime') {
        searchTerm = 'anime scenery fantasy';
      } else if (category.toLowerCase() == 'space') {
        searchTerm = 'galaxy nebula cosmos';
      } else if (category.toLowerCase() == 'vehicles') {
        searchTerm = 'supercar automotive';
      } else if (category.toLowerCase() == 'minimalist') {
        searchTerm = 'minimalist architecture';
      } else {
        searchTerm = category;
      }
    }

    final queryParams = <String, String>{
      'key': _pixabayApiKey,
      'q': searchTerm,
      'image_type': 'photo',
      'safesearch': 'true',
      'per_page': perPage.clamp(3, 200).toString(),
      'page': page.toString(),
      'order': sort == 'latest' ? 'latest' : 'popular',
    };

    if (orientation == 'landscape') {
      queryParams['orientation'] = 'horizontal';
    } else if (orientation == 'portrait') {
      queryParams['orientation'] = 'vertical';
    }

    // Optional Pixabay native category filter
    final pixabayCat = _mapCategoryToPixabay(category);
    if (pixabayCat != null) {
      queryParams['category'] = pixabayCat;
    }

    final uri = Uri.https('pixabay.com', '/api/', queryParams);
    final response = await _httpClient.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final hits = data['hits'] as List<dynamic>? ?? [];
      final results = hits.map((hit) {
        return ImageItem.fromPixabayJson(
          hit as Map<String, dynamic>,
          defaultCategory: category == 'All' ? 'Pixabay' : category,
        );
      }).toList();
      return results;
    } else {
      throw Exception('Failed to fetch from Pixabay: ${response.statusCode}');
    }
  }

  String? _mapCategoryToPixabay(String category) {
    switch (category.toLowerCase()) {
      case 'nature':
        return 'nature';
      case 'space':
        return 'science';
      case 'architecture':
        return 'buildings';
      case 'vehicles':
        return 'transportation';
      case 'minimalist':
        return 'backgrounds';
      default:
        return null;
    }
  }

  // Curated High Definition Photography Dataset with Real CDN URLs (Offline Fallback)
  final List<ImageItem> _curatedImages = [
    ImageItem(
      id: 'p-cyber-1',
      title: 'Neon Tokyo Odyssey',
      description: 'Shinjuku rain reflections with holographic advertisements and vibrant electric hues.',
      regularUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?auto=format&fit=crop&w=1200&q=80',
      fullUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?auto=format&fit=crop&w=2400&q=95',
      thumbUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?auto=format&fit=crop&w=400&q=60',
      photographer: 'Aleksandar Pasaric',
      photographerUsername: 'aleksandar_p',
      photographerAvatar: 'https://images.unsplash.com/profile-1550066929949-cfae0ce677ec?auto=format&fit=crop&w=150&q=80',
      likes: 14820,
      views: 94200,
      downloads: 12400,
      width: 1200,
      height: 1600,
      category: 'Cyberpunk',
      tags: ['Cyberpunk', 'Neon', 'Tokyo', 'Night', 'City', 'Rain'],
      primaryColorHex: '#E11D48',
      cameraModel: 'Sony A7S III',
      focalLength: '24mm',
      aperture: 'f/1.4',
      iso: '800',
    ),
    ImageItem(
      id: 'p-nature-1',
      title: 'Dolomites Alpine Sunrise',
      description: 'Golden morning light illuminating jagged limestone peaks above misty pine valleys.',
      regularUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80',
      fullUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=2560&q=95',
      thumbUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=60',
      photographer: 'Bailey Zindel',
      photographerUsername: 'baileyzindel',
      photographerAvatar: 'https://images.unsplash.com/profile-1506743900-b3fb?auto=format&fit=crop&w=150&q=80',
      likes: 28940,
      views: 184500,
      downloads: 41200,
      width: 1920,
      height: 1080,
      category: 'Nature',
      tags: ['Nature', 'Mountains', 'Sunrise', 'Landscape', 'Dolomites', 'Alps'],
      primaryColorHex: '#F59E0B',
      cameraModel: 'Nikon Z9',
      focalLength: '16mm',
      aperture: 'f/8.0',
      iso: '64',
    ),
    ImageItem(
      id: 'p-space-1',
      title: 'Cosmic Stellar Nebula',
      description: 'Deep cosmic stellar nursery glowing with interstellar dust and ionized stellar gas clouds.',
      regularUrl: 'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?auto=format&fit=crop&w=1200&q=80',
      fullUrl: 'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?auto=format&fit=crop&w=2560&q=95',
      thumbUrl: 'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?auto=format&fit=crop&w=400&q=60',
      photographer: 'NASA Space Observatory',
      photographerUsername: 'nasa',
      photographerAvatar: 'https://images.unsplash.com/profile-1446481870805-a0f3a48c0f86?auto=format&fit=crop&w=150&q=80',
      likes: 42100,
      views: 310200,
      downloads: 78500,
      width: 1200,
      height: 1500,
      category: 'Space',
      tags: ['Space', 'Nebula', 'Stars', 'Cosmos', 'Universe', 'Astronomy'],
      primaryColorHex: '#6366F1',
      cameraModel: 'Hubble Space Telescope',
      focalLength: 'Wide Field 3',
      aperture: 'f/12.8',
      iso: 'Astrophotography',
    ),
    ImageItem(
      id: 'p-arch-1',
      title: 'Vortex of Modernity',
      description: 'Abstract spiral concrete architecture playing with dramatic geometric shadows.',
      regularUrl: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=1200&q=80',
      fullUrl: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=2400&q=95',
      thumbUrl: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=400&q=60',
      photographer: 'Simone Hutsch',
      photographerUsername: 'heysupersimi',
      photographerAvatar: 'https://images.unsplash.com/profile-1500000000000-simi?auto=format&fit=crop&w=150&q=80',
      likes: 19400,
      views: 112000,
      downloads: 24500,
      width: 1200,
      height: 1400,
      category: 'Architecture',
      tags: ['Architecture', 'Minimal', 'Geometry', 'Building', 'Design', 'Concrete'],
      primaryColorHex: '#06B6D4',
      cameraModel: 'Canon EOS R5',
      focalLength: '50mm',
      aperture: 'f/5.6',
      iso: '100',
    ),
    ImageItem(
      id: 'p-cyber-2',
      title: 'Cyberpunk Alley Cyber Grid',
      description: 'Futuristic street neon banners echoing in futuristic cyberpunk metropolis.',
      regularUrl: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?auto=format&fit=crop&w=1200&q=80',
      fullUrl: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?auto=format&fit=crop&w=2400&q=95',
      thumbUrl: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?auto=format&fit=crop&w=400&q=60',
      photographer: 'Florian Wehde',
      photographerUsername: 'florianwehde',
      photographerAvatar: 'https://images.unsplash.com/profile-1514565000000?auto=format&fit=crop&w=150&q=80',
      likes: 16750,
      views: 98700,
      downloads: 21300,
      width: 1200,
      height: 1600,
      category: 'Cyberpunk',
      tags: ['Cyberpunk', 'Neon', 'Street', 'Night', 'City', 'Retro'],
      primaryColorHex: '#8B5CF6',
      cameraModel: 'Fujifilm X-T4',
      focalLength: '35mm',
      aperture: 'f/1.4',
      iso: '1600',
    ),
    ImageItem(
      id: 'p-nature-2',
      title: 'Emerald Forest Mist',
      description: 'Lush temperate rainforest canopy bathed in ethereal foggy morning sunbeams.',
      regularUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=1200&q=80',
      fullUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=2560&q=95',
      thumbUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=400&q=60',
      photographer: 'Sebastian Unrau',
      photographerUsername: 'sebastian_unrau',
      photographerAvatar: 'https://images.unsplash.com/profile-1448370000000?auto=format&fit=crop&w=150&q=80',
      likes: 35600,
      views: 240000,
      downloads: 58000,
      width: 1920,
      height: 1200,
      category: 'Nature',
      tags: ['Nature', 'Forest', 'Mist', 'Trees', 'Green', 'Peaceful'],
      primaryColorHex: '#10B981',
      cameraModel: 'Sony A7R IV',
      focalLength: '70mm',
      aperture: 'f/4.0',
      iso: '200',
    ),
    ImageItem(
      id: 'p-anime-1',
      title: 'Twilight Dreamscape Horizon',
      description: 'Pastel dream clouds drifting over serene coastal horizon under twilight stars.',
      regularUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=1200&q=80',
      fullUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=2400&q=95',
      thumbUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=400&q=60',
      photographer: 'Ken Cheung',
      photographerUsername: 'kencheung',
      photographerAvatar: 'https://images.unsplash.com/profile-1518700000000?auto=format&fit=crop&w=150&q=80',
      likes: 22100,
      views: 145000,
      downloads: 33400,
      width: 1200,
      height: 1500,
      category: 'Anime',
      tags: ['Anime', 'Dreamy', 'Sky', 'Clouds', 'Sunset', 'Aesthetic'],
      primaryColorHex: '#EC4899',
      cameraModel: 'Leica Q2',
      focalLength: '28mm',
      aperture: 'f/2.8',
      iso: '100',
    ),
    ImageItem(
      id: 'p-veh-1',
      title: 'Supercar Stealth Silhouette',
      description: 'Aerodynamic carbon fiber contours glinting under cinematic studio rim light.',
      regularUrl: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=1200&q=80',
      fullUrl: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=2560&q=95',
      thumbUrl: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=400&q=60',
      photographer: 'Campbell',
      photographerUsername: 'campbell33',
      photographerAvatar: 'https://images.unsplash.com/profile-1503370000000?auto=format&fit=crop&w=150&q=80',
      likes: 31200,
      views: 215000,
      downloads: 48900,
      width: 1920,
      height: 1080,
      category: 'Vehicles',
      tags: ['Vehicles', 'Supercar', 'Porsche', 'Speed', 'Black', 'Design'],
      primaryColorHex: '#E2E8F0',
      cameraModel: 'Hasselblad H6D-100c',
      focalLength: '100mm',
      aperture: 'f/8.0',
      iso: '50',
    ),
    ImageItem(
      id: 'p-minimal-1',
      title: 'Geometric Solitude',
      description: 'Pure architectural minimalist lines casting sharp graphic shadows on warm stucco.',
      regularUrl: 'https://images.unsplash.com/photo-1494438639946-1ebd1d20bf85?auto=format&fit=crop&w=1200&q=80',
      fullUrl: 'https://images.unsplash.com/photo-1494438639946-1ebd1d20bf85?auto=format&fit=crop&w=2400&q=95',
      thumbUrl: 'https://images.unsplash.com/photo-1494438639946-1ebd1d20bf85?auto=format&fit=crop&w=400&q=60',
      photographer: 'Geordanna Cordero',
      photographerUsername: 'geordannacordero',
      photographerAvatar: 'https://images.unsplash.com/profile-1494430000000?auto=format&fit=crop&w=150&q=80',
      likes: 17800,
      views: 89000,
      downloads: 19000,
      width: 1200,
      height: 1500,
      category: 'Minimalist',
      tags: ['Minimalist', 'Shadow', 'Lines', 'Clean', 'Architecture', 'Abstract'],
      primaryColorHex: '#EAB308',
      cameraModel: 'Sony A7C',
      focalLength: '40mm',
      aperture: 'f/5.6',
      iso: '100',
    ),
    ImageItem(
      id: 'p-space-2',
      title: 'Aurora Borealis over Glacial Lake',
      description: 'Luminescent magnetic dancing ribbons over snow-capped Scandinavian peaks.',
      regularUrl: 'https://images.unsplash.com/photo-1517411032315-54ef2cb783bb?auto=format&fit=crop&w=1200&q=80',
      fullUrl: 'https://images.unsplash.com/photo-1517411032315-54ef2cb783bb?auto=format&fit=crop&w=2560&q=95',
      thumbUrl: 'https://images.unsplash.com/photo-1517411032315-54ef2cb783bb?auto=format&fit=crop&w=400&q=60',
      photographer: 'Vincent Guth',
      photographerUsername: 'vincentguth',
      photographerAvatar: 'https://images.unsplash.com/profile-1517400000000?auto=format&fit=crop&w=150&q=80',
      likes: 38700,
      views: 295000,
      downloads: 65400,
      width: 1920,
      height: 1280,
      category: 'Space',
      tags: ['Space', 'Aurora', 'Northern Lights', 'Night', 'Norway', 'Winter'],
      primaryColorHex: '#10B981',
      cameraModel: 'Sony A7S III',
      focalLength: '14mm',
      aperture: 'f/1.8',
      iso: '3200',
    ),
    ImageItem(
      id: 'p-nature-3',
      title: 'Thunderous Waterfall Gorge',
      description: 'Pristine glacial torrent cascading into a turquoise volcanic amphitheater.',
      regularUrl: 'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?auto=format&fit=crop&w=1200&q=80',
      fullUrl: 'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?auto=format&fit=crop&w=2400&q=95',
      thumbUrl: 'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?auto=format&fit=crop&w=400&q=60',
      photographer: 'Dave Hoefler',
      photographerUsername: 'davehoefler',
      photographerAvatar: 'https://images.unsplash.com/profile-1432400000000?auto=format&fit=crop&w=150&q=80',
      likes: 24500,
      views: 168000,
      downloads: 38200,
      width: 1200,
      height: 1600,
      category: 'Nature',
      tags: ['Nature', 'Waterfall', 'Water', 'Rocks', 'Iceland', 'Powerful'],
      primaryColorHex: '#0284C7',
      cameraModel: 'Canon 5D Mark IV',
      focalLength: '24mm',
      aperture: 'f/11',
      iso: '100',
    ),
    ImageItem(
      id: 'p-arch-2',
      title: 'Golden Hour Glass Skyscraper',
      description: 'Curvilinear glass panels mirroring dramatic sunset clouds across the skyline.',
      regularUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80',
      fullUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=2560&q=95',
      thumbUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=400&q=60',
      photographer: 'Samson',
      photographerUsername: 'samson',
      photographerAvatar: 'https://images.unsplash.com/profile-1486400000000?auto=format&fit=crop&w=150&q=80',
      likes: 21900,
      views: 139000,
      downloads: 29800,
      width: 1920,
      height: 1080,
      category: 'Architecture',
      tags: ['Architecture', 'City', 'Skyscraper', 'Glass', 'Reflection', 'Sunset'],
      primaryColorHex: '#3B82F6',
      cameraModel: 'Fujifilm GFX 100',
      focalLength: '23mm',
      aperture: 'f/8.0',
      iso: '100',
    ),
    ImageItem(
      id: 'p-cyber-3',
      title: 'Neon Cyber Punk Android',
      description: 'Luminescent cybernetic face illuminated by holographic fiber-optic glow.',
      regularUrl: 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?auto=format&fit=crop&w=1200&q=80',
      fullUrl: 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?auto=format&fit=crop&w=2400&q=95',
      thumbUrl: 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?auto=format&fit=crop&w=400&q=60',
      photographer: 'Avel Chuklanov',
      photographerUsername: 'avelc',
      photographerAvatar: 'https://images.unsplash.com/profile-1607600000000?auto=format&fit=crop&w=150&q=80',
      likes: 47200,
      views: 382000,
      downloads: 89400,
      width: 1200,
      height: 1500,
      category: 'Cyberpunk',
      tags: ['Cyberpunk', 'Futuristic', 'Neon', 'Sci-Fi', 'AI', 'Portrait'],
      primaryColorHex: '#8B5CF6',
      cameraModel: 'Sony A1',
      focalLength: '85mm',
      aperture: 'f/1.4',
      iso: '400',
    ),
    ImageItem(
      id: 'p-anime-2',
      title: 'Cherry Blossom Sunset Path',
      description: 'Petals falling like soft snow over traditional lanterns at twilight in Kyoto.',
      regularUrl: 'https://images.unsplash.com/photo-1528164344705-475426879c0d?auto=format&fit=crop&w=1200&q=80',
      fullUrl: 'https://images.unsplash.com/photo-1528164344705-475426879c0d?auto=format&fit=crop&w=2400&q=95',
      thumbUrl: 'https://images.unsplash.com/photo-1528164344705-475426879c0d?auto=format&fit=crop&w=400&q=60',
      photographer: 'Sora Sagano',
      photographerUsername: 'sagano',
      photographerAvatar: 'https://images.unsplash.com/profile-1528160000000?auto=format&fit=crop&w=150&q=80',
      likes: 33800,
      views: 220000,
      downloads: 51200,
      width: 1200,
      height: 1600,
      category: 'Anime',
      tags: ['Anime', 'Japan', 'Cherry Blossom', 'Sakura', 'Kyoto', 'Spring'],
      primaryColorHex: '#F43F5E',
      cameraModel: 'Nikon D850',
      focalLength: '50mm',
      aperture: 'f/1.8',
      iso: '200',
    ),
  ];
}
