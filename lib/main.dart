import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'services/app_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appSettings.load();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    appSettings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    appSettings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    // Only rebuild when theme actually changes
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '嘟迹',
      debugShowCheckedModeBanner: false,
      themeMode: appSettings.value.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Colors.black,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFF0F0F0),
          onPrimaryContainer: Colors.black,
          secondary: Color(0xFF616161),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFE0E0E0),
          onSecondaryContainer: Color(0xFF212121),
          surface: Colors.white,
          onSurface: Colors.black,
          surfaceContainerHighest: Color(0xFFF5F5F5),
          onSurfaceVariant: Color(0xFF616161),
          outline: Color(0xFFBDBDBD),
          outlineVariant: Color(0xFFE0E0E0),
          error: Color(0xFFD32F2F),
          onError: Colors.white,
        ),
        cardColor: Colors.white,
        dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        dividerColor: const Color(0xFFF0F0F0),
        canvasColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F5F5),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0.5,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Colors.white,
          onPrimary: Colors.black,
          primaryContainer: Color(0xFF424242),
          onPrimaryContainer: Colors.white,
          secondary: Color(0xFFBDBDBD),
          onSecondary: Colors.black,
          secondaryContainer: Color(0xFF616161),
          onSecondaryContainer: Color(0xFFE0E0E0),
          surface: Color(0xFF1E1E1E),
          onSurface: Colors.white,
          surfaceContainerHighest: Color(0xFF2C2C2C),
          onSurfaceVariant: Color(0xFFBDBDBD),
          outline: Color(0xFF616161),
          outlineVariant: Color(0xFF424242),
          error: Color(0xFFEF5350),
          onError: Colors.black,
        ),
        cardColor: const Color(0xFF1E1E1E),
        dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1E1E1E)),
        dividerColor: Colors.white12,
        canvasColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0.5,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const HomePage(),
    );
  }
}


