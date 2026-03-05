import 'package:flutter/material.dart';

/// Notificador global de tema. Accesible desde cualquier widget.
/// Uso: themeNotifier.value = ThemeMode.dark;
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

bool get isDark => themeNotifier.value == ThemeMode.dark;