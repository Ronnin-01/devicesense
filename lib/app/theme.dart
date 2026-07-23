import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue);
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: Colors.blue,
    );
  }
}
