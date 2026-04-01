import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/property_provider.dart';
import 'screens/home_screen.dart';

// ─── Supabase credentials from .env file ────────────────────────────────────
// Make sure to update the .env file with your actual credentials
// ─────────────────────────────────────────────────────────────────────────────

String? _supabaseInitError;
Map<String, String> _envConfig = {};

// Logger that works in both debug and release mode
void _log(String message, {String level = 'INFO'}) {
  debugPrint('[$level] $message');
  if (kReleaseMode) {
    dev.log(message,
        name: 'PropertyTracker', level: level == 'ERROR' ? 1000 : 500);
  }
}

Future<Map<String, String>> _loadEnvFile() async {
  final config = <String, String>{};
  try {
    final content = await rootBundle.loadString('.env');
    final lines = content.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final parts = line.split('=');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.skip(1).join('=').trim();
        config[key] = value;
      }
    }
    _log('.env file loaded successfully: ${config.length} entries');
  } catch (e) {
    _log('Failed to load .env file: $e', level: 'ERROR');
  }
  return config;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  _envConfig = await _loadEnvFile();

  final supabaseUrl = _envConfig['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = _envConfig['SUPABASE_ANON_KEY'] ?? '';

  _log('SUPABASE_URL: ${supabaseUrl.isEmpty ? 'NOT SET' : 'SET'}');
  _log(
      'SUPABASE_ANON_KEY: ${supabaseAnonKey.isEmpty ? 'NOT SET' : 'SET (hidden)'}');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    _supabaseInitError =
        'Supabase credentials not found. Please check your .env file.';
    _log('$_supabaseInitError', level: 'ERROR');
  } else {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _log('Supabase initialized successfully');
    } catch (e) {
      _supabaseInitError = 'Failed to initialize Supabase: $e';
      _log('$_supabaseInitError', level: 'ERROR');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
      ],
      child: const PropertyTrackerApp(),
    ),
  );
}

class PropertyTrackerApp extends StatelessWidget {
  const PropertyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Show error screen if Supabase failed to initialize
    if (_supabaseInitError != null) {
      return MaterialApp(
        title: 'Property Tracker - Error',
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(),
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Supabase Configuration Error',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _supabaseInitError!,
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'To fix this:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text('1. Go to https://app.supabase.com'),
                          Text('2. Select your project'),
                          Text('3. Go to Settings → API'),
                          Text('4. Copy your Project URL and anon key'),
                          Text('5. Update the .env file with these values'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Property Tracker',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      home: const HomeScreen(),
    );
  }

  // Light mode theme with soft, natural colors
  ThemeData _buildLightTheme() {
    // Soft, natural color palette
    const Color primaryColor = Color(0xFF6B8E6B); // Sage green
    const Color secondaryColor = Color(0xFFD4A373); // Warm tan
// Soft mint
    const Color backgroundColor = Color(0xFFFAF9F6); // Off-white
    const Color surfaceColor = Color(0xFFFFFFFF); // White
    const Color errorColor = Color(0xFFE07A5F); // Terracotta
    const Color textPrimary = Color(0xFF2C3E50); // Dark slate
    const Color textSecondary = Color(0xFF7F8C8D); // Gray
    const Color dividerColor = Color(0xFFE8E8E8); // Light gray

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      // cardTheme: CardTheme(
      //   color: surfaceColor,
      //   elevation: 2,
      //   shadowColor: Colors.black..withAlpha(1),
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(16),
      //     side: BorderSide(color: dividerColor..withAlpha(5)),
      //   ),
      // ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textSecondary..withAlpha(6)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: backgroundColor,
        selectedColor: primaryColor,
        labelStyle: const TextStyle(color: textPrimary),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: dividerColor),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}
