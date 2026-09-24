import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'services/image_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Info: .env file not found or couldn't be loaded: $e");
  }

  // Set system UI overlay style for dark immersive aesthetic
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize service & preferences
  await ImageService.instance.initialize();

  runApp(const ParallaxImageApp());
}

class ParallaxImageApp extends StatelessWidget {
  const ParallaxImageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Parallax',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
