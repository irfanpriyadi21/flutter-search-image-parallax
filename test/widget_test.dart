import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:image_parallax_search/models/image_item.dart';
import 'package:image_parallax_search/screens/wallpaper_preview_screen.dart';
import 'package:image_parallax_search/services/image_service.dart';
import 'package:image_parallax_search/widgets/download_progress_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ImageService fetchImages returns Pixabay results with configured key', () async {
    final mockResponse = json.encode({
      'total': 1,
      'totalHits': 1,
      'hits': [
        {
          'id': 3082832,
          'tags': 'nature, waters, lake',
          'webformatURL': 'https://pixabay.com/get/sample_640.jpg',
          'largeImageURL': 'https://pixabay.com/get/sample_1280.jpg',
          'previewURL': 'https://cdn.pixabay.com/sample_150.jpg',
          'imageWidth': 5757,
          'imageHeight': 3238,
          'user': 'jplenio',
          'userImageURL': 'https://cdn.pixabay.com/user/avatar.jpg',
          'likes': 5813,
          'views': 7433169,
          'downloads': 4753767,
        }
      ]
    });

    ImageService.instance.httpClient = MockClient((request) async {
      expect(request.url.host, 'pixabay.com');
      expect(request.url.queryParameters['key'], '17389955-eb167990fe4e1dae1ad3932a1');
      return http.Response(mockResponse, 200);
    });

    final images = await ImageService.instance.fetchImages();
    expect(images.isNotEmpty, isTrue);
    expect(images.first.id, 'pixabay_3082832');
    expect(images.first.photographer, 'jplenio');
    expect(images.first.regularUrl.startsWith('http'), isTrue);

    // Reset client to standard
    ImageService.instance.httpClient = http.Client();
  });

  test('ImageItem model serialization and aspect ratio', () {
    final item = ImageItem(
      id: 'test-1',
      title: 'Neon Nights',
      description: 'Futuristic city',
      regularUrl: 'https://images.unsplash.com/test',
      fullUrl: 'https://images.unsplash.com/test-full',
      thumbUrl: 'https://images.unsplash.com/test-thumb',
      photographer: 'Alex',
      photographerUsername: 'alex',
      photographerAvatar: '',
      category: 'Cyberpunk',
      width: 1920,
      height: 1080,
    );

    expect(item.aspectRatio, closeTo(1.77, 0.01));
    final jsonMap = item.toMap();
    final restored = ImageItem.fromMap(jsonMap);
    expect(restored.id, 'test-1');
    expect(restored.title, 'Neon Nights');
    expect(restored.category, 'Cyberpunk');
  });

  test('Favorite toggle updates state', () async {
    final item = ImageItem(
      id: 'fav-test',
      title: 'Aurora',
      description: 'Northern lights',
      regularUrl: '',
      fullUrl: '',
      thumbUrl: '',
      photographer: 'Vincent',
      photographerUsername: 'vincent',
      photographerAvatar: '',
      category: 'Space',
    );

    expect(ImageService.instance.isFavorite('fav-test'), isFalse);
    await ImageService.instance.toggleFavorite(item);
    expect(ImageService.instance.isFavorite('fav-test'), isTrue);
    await ImageService.instance.toggleFavorite(item);
    expect(ImageService.instance.isFavorite('fav-test'), isFalse);
  });

  test('ImageItem fromPixabayJson parsing', () {
    final pixabayJson = {
      'id': 3082832,
      'tags': 'nature, waters, lake, island',
      'webformatURL': 'https://pixabay.com/get/sample_640.jpg',
      'largeImageURL': 'https://pixabay.com/get/sample_1280.jpg',
      'previewURL': 'https://cdn.pixabay.com/sample_150.jpg',
      'imageWidth': 5757,
      'imageHeight': 3238,
      'user': 'jplenio',
      'userImageURL': 'https://cdn.pixabay.com/user/avatar.jpg',
      'likes': 5813,
      'views': 7433169,
      'downloads': 4753767,
    };

    final item = ImageItem.fromPixabayJson(pixabayJson, defaultCategory: 'Nature');
    expect(item.id, 'pixabay_3082832');
    expect(item.photographer, 'jplenio');
    expect(item.category, 'Nature');
    expect(item.tags.contains('nature'), isTrue);
    expect(item.regularUrl, 'https://pixabay.com/get/sample_640.jpg');
    expect(item.fullUrl, 'https://pixabay.com/get/sample_1280.jpg');
    expect(item.width, 5757.0);
    expect(item.height, 3238.0);
  });

  testWidgets('WallpaperPreviewScreen pumps and renders lock screen & home screen mode', (tester) async {
    final item = ImageItem(
      id: 'wp-test',
      title: 'Neon Skyline',
      description: 'Futuristic city night',
      regularUrl: '',
      fullUrl: '',
      thumbUrl: '',
      photographer: 'Artist',
      photographerUsername: 'artist',
      photographerAvatar: '',
      category: 'Cyberpunk',
    );

    // Pump screen inside MaterialApp
    await tester.pumpWidget(
      MaterialApp(
        home: WallpaperPreviewScreen(item: item),
      ),
    );

    // Initial state is Lock Screen
    expect(find.text('Layar Kunci'), findsOneWidget);
    expect(find.text('Layar Utama'), findsOneWidget);
    expect(find.text('Atur / Terapkan Wallpaper'), findsOneWidget);

    // Tap Layar Utama mode
    await tester.tap(find.text('Layar Utama'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Home Screen widgets are shown
    expect(find.text('Telepon'), findsWidgets);
    expect(find.text('Pesan'), findsWidgets);
  });

  testWidgets('DownloadProgressDialog renders progress dialog and dismisses on cancel', (tester) async {
    final item = ImageItem(
      id: 'dl-test',
      title: 'Neon Tokyo',
      description: 'Cyberpunk rain',
      regularUrl: '',
      fullUrl: '',
      thumbUrl: '',
      photographer: 'Kenji',
      photographerUsername: 'kenji',
      photographerAvatar: '',
      category: 'Cyberpunk',
      width: 3840,
      height: 2160,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => DownloadProgressDialog.show(context, item),
                child: const Text('Start Download'),
              );
            },
          ),
        ),
      ),
    );

    // Tap button to open download dialog
    await tester.tap(find.text('Start Download'));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify dialog elements
    expect(find.text('Mengunduh Gambar HD'), findsOneWidget);
    expect(find.text('Neon Tokyo'), findsOneWidget);
    expect(find.textContaining('3840 x 2160 px'), findsOneWidget);

    // Advance time slightly to test progress update
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LinearProgressIndicator), findsNothing); // Using Custom FractionallySizedBox

    // Cancel download
    final closeButton = find.byIcon(Icons.close_rounded);
    expect(closeButton, findsOneWidget);
    await tester.tap(closeButton);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify dialog is closed and snackbar appears
    expect(find.text('Pengunduhan dibatalkan.'), findsOneWidget);
  });
}
