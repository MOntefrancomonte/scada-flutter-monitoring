import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeCubit extends Cubit<ThemeData> {
  ThemeCubit() : super(_themeForColor(_meterColors['Todos']!));

  // Paleta por medidor (puedes elegir otros tonos/shades)
  static final Map<String, Color> _meterColors = {
    'Todos': Colors.green.shade700,
    'Agua': Colors.blue.shade700,
    'AguaR': Colors.lightBlueAccent.shade700,
    'Diesel': Colors.brown.shade600,
    'gLP': Colors.orange.shade700,
  };

  // Permite que otros lean la paleta si lo deseas
  static Color colorForKey(String key) => _meterColors[key] ?? _meterColors['Todos']!;

  static ThemeData _themeForColor(Color seed) {
    final scheme = ColorScheme.fromSeed(seedColor: seed);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.grey[50],
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(backgroundColor: scheme.primary, elevation: 2),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      // agrega otras personalizaciones si deseas (textTheme, inputDecorationTheme, etc.)
    );
  }

  void setThemeForMeter(String key) {
    final color = _meterColors[key] ?? _meterColors['Todos']!;
    emit(_themeForColor(color));
  }
}
