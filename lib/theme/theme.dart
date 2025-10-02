import 'package:flutter/material.dart';

// light mode
ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    surface: const Color.fromARGB(255, 248, 243, 235),
    primary: const Color.fromARGB(255, 242, 224, 195),
    secondary: Colors.grey.shade400,
    inversePrimary: Colors.grey.shade800,
  ),
);

// dark mode
ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    surface: const Color.fromARGB(255, 28, 28, 28),
    primary: const Color.fromARGB(255, 44, 43, 43),
    secondary: const Color.fromARGB(255, 165, 165, 165),
    inversePrimary: const Color.fromARGB(255, 210, 209, 209),
  ),
);

// auth pages theme
ThemeData authTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(

    surface: Color(0xFFF8F3EB),       
    primary: Color(0xFFFCBF49),       
    
    primaryContainer: Color(0xFFF97432), // button
    
    inversePrimary: Color(0xFF3F414E), // dark text
    secondary: Colors.black54,        // label text
    
    tertiary: Color(0xFF1656F7),        // links
    
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Colors.black,
    onError: Colors.white,
    error: Colors.red,
  ),
);

ThemeData quizTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF5F5F7), // Light grey page background
  colorScheme: ColorScheme.light(
    primary: const Color(0xFFF97432),
    onPrimary: Colors.white,
    surface: Colors.white,
    surfaceContainerLowest: const Color(0xFFF5F5F7),
    
    onSurface: const Color(0xFF3F414E),
    secondary: Colors.grey.shade600, 
    
    outline: Colors.grey.shade300,

    errorContainer: const Color(0xFFFEEAEC),   // "Again" chip background
    onErrorContainer: const Color(0xFFDC3545), // "Again" chip text
    tertiaryContainer: const Color(0xFFFFF3E0),  // "Hard" chip background
    onTertiaryContainer: const Color(0xFFE67E22), // "Hard" chip text
    secondaryContainer: const Color(0xFFFFF8E1), // "Medium" chip background
    onSecondaryContainer: const Color(0xFFF1C40F), // "Medium" chip text
    primaryContainer: const Color(0xFFE8F5E9),   // "Easy" chip background
    onPrimaryContainer: const Color(0xFF28A745),  // "Easy" chip text
  ),
);

// Dynamic quiz theme that adapts to current theme
ThemeData getQuizTheme(BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  if (isDarkMode) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1E1E1E), // Dark grey page background
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFFF97432),
        onPrimary: Colors.white,
        surface: const Color(0xFF2D2D30), // Dark card background
        surfaceContainerHighest: const Color(0xFF3E3E42), // Progress bar background
        onSurface: const Color(0xFFE8E6E3), // Light text on dark surface
        secondary: Colors.grey.shade400,          
        outline: Colors.grey.shade600,     
        errorContainer: const Color(0xFF3F1518),   // "Again" chip background (dark red)
        onErrorContainer: const Color(0xFFFF6B6B), // "Again" chip text (light red)
        tertiaryContainer: const Color(0xFF3D2914),  // "Hard" chip background (dark orange)
        onTertiaryContainer: const Color(0xFFFFB74D), // "Hard" chip text (light orange)
        secondaryContainer: const Color(0xFF3D3617), // "Medium" chip background (dark yellow)
        onSecondaryContainer: const Color(0xFFFFF176), // "Medium" chip text (light yellow)
        primaryContainer: const Color(0xFF1B2F1C),   // "Easy" chip background (dark green)
        onPrimaryContainer: const Color(0xFF81C784),  // "Easy" chip text (light green)
      ),
    );
  } else {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F7), // Light grey page background
      colorScheme: ColorScheme.light(
        primary: const Color(0xFFF97432),
        onPrimary: Colors.white,
        surface: Colors.white,
        surfaceContainerHighest: const Color(0xFFF5F5F7),         
        onSurface: const Color(0xFF3F414E),
        secondary: Colors.grey.shade600,          
        outline: Colors.grey.shade300,     
        errorContainer: const Color(0xFFFEEAEC),   // "Again" chip background
        onErrorContainer: const Color(0xFFDC3545), // "Again" chip text
        tertiaryContainer: const Color(0xFFFFF3E0),  // "Hard" chip background
        onTertiaryContainer: const Color(0xFFE67E22), // "Hard" chip text
        secondaryContainer: const Color(0xFFFFF8E1), // "Medium" chip background
        onSecondaryContainer: const Color(0xFFF1C40F), // "Medium" chip text
        primaryContainer: const Color(0xFFE8F5E9),   // "Easy" chip background
        onPrimaryContainer: const Color(0xFF28A745),  // "Easy" chip text
      ),
    );
  }
}