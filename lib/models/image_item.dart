import 'dart:convert';

class ImageItem {
  final String id;
  final String title;
  final String description;
  final String regularUrl;
  final String fullUrl;
  final String thumbUrl;
  final String photographer;
  final String photographerUsername;
  final String photographerAvatar;
  final int likes;
  final int views;
  final int downloads;
  final double width;
  final double height;
  final String category;
  final List<String> tags;
  final String primaryColorHex;
  final String cameraModel;
  final String focalLength;
  final String aperture;
  final String iso;
  bool isFavorite;

  ImageItem({
    required this.id,
    required this.title,
    required this.description,
    required this.regularUrl,
    required this.fullUrl,
    required this.thumbUrl,
    required this.photographer,
    required this.photographerUsername,
    required this.photographerAvatar,
    this.likes = 0,
    this.views = 0,
    this.downloads = 0,
    this.width = 1920,
    this.height = 1080,
    required this.category,
    this.tags = const [],
    this.primaryColorHex = '#3B82F6',
    this.cameraModel = 'Sony Alpha A7R V',
    this.focalLength = '35mm',
    this.aperture = 'f/1.8',
    this.iso = '100',
    this.isFavorite = false,
  });

  double get aspectRatio => width / (height == 0 ? 1 : height);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'regularUrl': regularUrl,
      'fullUrl': fullUrl,
      'thumbUrl': thumbUrl,
      'photographer': photographer,
      'photographerUsername': photographerUsername,
      'photographerAvatar': photographerAvatar,
      'likes': likes,
      'views': views,
      'downloads': downloads,
      'width': width,
      'height': height,
      'category': category,
      'tags': tags,
      'primaryColorHex': primaryColorHex,
      'cameraModel': cameraModel,
      'focalLength': focalLength,
      'aperture': aperture,
      'iso': iso,
      'isFavorite': isFavorite,
    };
  }

  factory ImageItem.fromMap(Map<String, dynamic> map) {
    return ImageItem(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Untitled Masterpiece',
      description: map['description'] ?? 'Captivating visual capture',
      regularUrl: map['regularUrl'] ?? '',
      fullUrl: map['fullUrl'] ?? map['regularUrl'] ?? '',
      thumbUrl: map['thumbUrl'] ?? map['regularUrl'] ?? '',
      photographer: map['photographer'] ?? 'Anonymous Artist',
      photographerUsername: map['photographerUsername'] ?? 'artist',
      photographerAvatar: map['photographerAvatar'] ?? '',
      likes: (map['likes'] is num) ? (map['likes'] as num).toInt() : 0,
      views: (map['views'] is num) ? (map['views'] as num).toInt() : 0,
      downloads: (map['downloads'] is num) ? (map['downloads'] as num).toInt() : 0,
      width: (map['width'] is num) ? (map['width'] as num).toDouble() : 1920.0,
      height: (map['height'] is num) ? (map['height'] as num).toDouble() : 1080.0,
      category: map['category'] ?? 'General',
      tags: List<String>.from(map['tags'] ?? []),
      primaryColorHex: map['primaryColorHex'] ?? '#3B82F6',
      cameraModel: map['cameraModel'] ?? 'Sony Alpha A7R V',
      focalLength: map['focalLength'] ?? '35mm',
      aperture: map['aperture'] ?? 'f/1.8',
      iso: map['iso'] ?? '100',
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  // Factory from Unsplash API response if used
  factory ImageItem.fromUnsplashJson(Map<String, dynamic> json) {
    final urls = json['urls'] as Map<String, dynamic>? ?? {};
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final profileImage = user['profile_image'] as Map<String, dynamic>? ?? {};
    final exif = json['exif'] as Map<String, dynamic>? ?? {};

    return ImageItem(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['alt_description'] != null && json['alt_description'].toString().isNotEmpty
          ? json['alt_description'].toString().capitalizeFirst()
          : (json['description'] != null && json['description'].toString().isNotEmpty
              ? json['description'].toString().capitalizeFirst()
              : 'Cinematic Visual'),
      description: json['description']?.toString() ?? json['alt_description']?.toString() ?? 'High definition photograph',
      regularUrl: urls['regular']?.toString() ?? '',
      fullUrl: urls['full']?.toString() ?? urls['regular']?.toString() ?? '',
      thumbUrl: urls['small']?.toString() ?? urls['thumb']?.toString() ?? '',
      photographer: user['name']?.toString() ?? 'Unknown Creator',
      photographerUsername: user['username']?.toString() ?? 'creator',
      photographerAvatar: profileImage['medium']?.toString() ?? profileImage['large']?.toString() ?? '',
      likes: (json['likes'] is num) ? (json['likes'] as num).toInt() : 0,
      views: (json['views'] is num) ? (json['views'] as num).toInt() : 0,
      downloads: (json['downloads'] is num) ? (json['downloads'] as num).toInt() : 0,
      width: (json['width'] is num) ? (json['width'] as num).toDouble() : 1920.0,
      height: (json['height'] is num) ? (json['height'] as num).toDouble() : 1080.0,
      category: 'Unsplash',
      tags: (json['tags'] is List)
          ? (json['tags'] as List).map((t) => t['title']?.toString() ?? '').where((s) => s.isNotEmpty).toList()
          : [],
      primaryColorHex: json['color']?.toString() ?? '#3B82F6',
      cameraModel: exif['model']?.toString() ?? 'Hasselblad 907X',
      focalLength: exif['focal_length'] != null ? '${exif['focal_length']}mm' : '45mm',
      aperture: exif['aperture'] != null ? 'f/${exif['aperture']}' : 'f/2.8',
      iso: exif['iso']?.toString() ?? '200',
      isFavorite: false,
    );
  }

  // Factory from Pixabay API response
  factory ImageItem.fromPixabayJson(Map<String, dynamic> json, {String defaultCategory = 'Pixabay'}) {
    final rawTags = json['tags']?.toString() ?? '';
    final tagList = rawTags
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    // Generate a sleek title from the first 2-3 tags
    String title = 'Visual Capture';
    if (tagList.isNotEmpty) {
      title = tagList.take(3).map((t) => t.capitalizeFirst()).join(' • ');
    }

    final webformatUrl = json['webformatURL']?.toString() ?? '';
    final largeImageUrl = json['largeImageURL']?.toString() ?? webformatUrl;
    final previewUrl = json['previewURL']?.toString() ?? webformatUrl;

    return ImageItem(
      id: 'pixabay_${json['id']}',
      title: title,
      description: 'Foto berkualitas tinggi oleh ${json['user'] ?? 'Creator'}. Tag: $rawTags',
      regularUrl: webformatUrl,
      fullUrl: largeImageUrl,
      thumbUrl: previewUrl,
      photographer: json['user']?.toString() ?? 'Pixabay Artist',
      photographerUsername: json['user']?.toString() ?? 'pixabay',
      photographerAvatar: json['userImageURL']?.toString() ?? '',
      likes: (json['likes'] is num) ? (json['likes'] as num).toInt() : 0,
      views: (json['views'] is num) ? (json['views'] as num).toInt() : 0,
      downloads: (json['downloads'] is num) ? (json['downloads'] as num).toInt() : 0,
      width: (json['imageWidth'] is num) ? (json['imageWidth'] as num).toDouble() : 1920.0,
      height: (json['imageHeight'] is num) ? (json['imageHeight'] as num).toDouble() : 1080.0,
      category: defaultCategory,
      tags: tagList,
      primaryColorHex: '#06B6D4',
      cameraModel: 'Sony Alpha A7 IV',
      focalLength: '35mm',
      aperture: 'f/2.0',
      iso: '100',
      isFavorite: false,
    );
  }

  String toJson() => json.encode(toMap());

  factory ImageItem.fromJson(String source) => ImageItem.fromMap(json.decode(source));
}

extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
