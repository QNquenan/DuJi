import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'services/app_settings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  appSettings.load();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _lastThemeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _lastThemeMode = appSettings.value.themeMode;
    appSettings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    appSettings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    final mode = appSettings.value.themeMode;
    if (mode != _lastThemeMode) {
      _lastThemeMode = mode;
      setState(() {});
    }
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
            TargetPlatform.android: _NoPinkTransitionBuilder(),
            TargetPlatform.iOS: _NoPinkTransitionBuilder(),
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
        dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF2C2C2C)),
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
            TargetPlatform.android: _NoPinkTransitionBuilder(),
            TargetPlatform.iOS: _NoPinkTransitionBuilder(),
          },
        ),
      ),
      home: const HomePage(),
    );
  }
}

/// 自定义页面过渡 — SlideTransition + FadeTransition，GPU 合成
class _NoPinkTransitionBuilder extends PageTransitionsBuilder {
  const _NoPinkTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.3, curve: Curves.easeOut)),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }
}
