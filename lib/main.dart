import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '嘟迹',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.light,
        ),
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
      home: const HomePage(),
    );
  }
}

/// 自定义页面过渡 — 纯灰阶 SlideTransition，消除 Material 默认粉色
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
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    );
  }
}
