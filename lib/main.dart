import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/products_screen.dart';
import 'theme_notifier.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    themeNotifier.addListener(_onThemeChange);
  }

  void _onThemeChange() => setState(() {});

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = themeNotifier.value == ThemeMode.dark;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp(
      title: 'Shop App',
      debugShowCheckedModeBanner: false,
      themeMode: themeNotifier.value,

      // ── Light theme ──────────────────────────────────────────────
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFEEF1FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5667F6),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        extensions: const [AppColors.light],
      ),

      // ── Dark theme ───────────────────────────────────────────────
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1117),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5667F6),
          brightness: Brightness.dark,
          surface: const Color(0xFF1A1D27),
        ),
        useMaterial3: true,
        extensions: const [AppColors.dark],
      ),

      home: const ProductsScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// AppColors ThemeExtension — úsalo en cualquier widget con:
//   context.appColors.bg, context.appColors.card, etc.
// ═══════════════════════════════════════════════════════════════════

class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color card;
  final Color text;
  final Color subtext;
  final Color divider;
  final Color inputBg;

  const AppColors({
    required this.bg,
    required this.card,
    required this.text,
    required this.subtext,
    required this.divider,
    required this.inputBg,
  });

  static const light = AppColors(
    bg: Color(0xFFEEF1FB),
    card: Colors.white,
    text: Color(0xFF1B1E3D),
    subtext: Color(0xFF8A8FAE),
    divider: Color(0xFFE8EAFB),
    inputBg: Colors.white,
  );

  static const dark = AppColors(
    bg: Color(0xFF0F1117),
    card: Color(0xFF1A1D27),
    text: Color(0xFFECEEF8),
    subtext: Color(0xFF636880),
    divider: Color(0xFF252836),
    inputBg: Color(0xFF1A1D27),
  );

  @override
  AppColors copyWith({
    Color? bg, Color? card, Color? text,
    Color? subtext, Color? divider, Color? inputBg,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      text: text ?? this.text,
      subtext: subtext ?? this.subtext,
      divider: divider ?? this.divider,
      inputBg: inputBg ?? this.inputBg,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      card: Color.lerp(card, other.card, t)!,
      text: Color.lerp(text, other.text, t)!,
      subtext: Color.lerp(subtext, other.subtext, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      inputBg: Color.lerp(inputBg, other.inputBg, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}