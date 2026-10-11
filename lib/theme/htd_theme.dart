import 'package:flutter/material.dart';

/// Caribbean Sun Mode: high-contrast palette for outdoor use on budget LCD
/// screens (< 350 nits). Tested against direct sunlight at noon in Port-au-Prince.
const Color kSunBackground = Color(0xFFFFFFFF);
const Color kSunCardSurface = Color(0xFFFFFFFF);
const Color kSunBorder = Color(0xFF0A0A0A);
const Color kSunHeaderText = Color(0xFF000000);
const Color kSunBodyText = Color(0xFF1A1A1A);
const Color kSunSecondaryText = Color(0xFF343A40);
const Color kSunDivider = Color(0xFFDEE2E6);
const Color kSunYellowText = Color(0xFF8B6914); // for text on white
const Color kSunRedText = Color(0xFFC92A2A); // for text on white
const Color kSunSuccess = Color(0xFF198754);
const Color kBrandYellow = Color(0xFFFCC419); // unchanged
const Color kBrandRed = Color(0xFFE03131); // unchanged

/// Night Mode: original dark palette, unchanged from current design.
const Color kNightBackground = Color(0xFF0A0A0A);
const Color kNightCardSurface = Color(0xFF141414);
const Color kNightBorder = Color(0xFF2A2A2A);
const Color kNightHeaderText = Color(0xFFFFFFFF);
const Color kNightBodyText = Color(0xFFE9ECEF);
const Color kNightSecondaryText = Color(0xFFADB5BD);
const Color kNightDivider = Color(0xFF2A2A2A);

ThemeData buildSunTheme() {
  return ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: kSunBackground,
    cardColor: kSunCardSurface,
    dividerColor: kSunDivider,
    colorScheme: const ColorScheme.light(
      primary: kBrandRed,
      secondary: kBrandYellow,
      surface: kSunCardSurface,
      onSurface: kSunBodyText,
      error: kBrandRed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kSunBackground,
      foregroundColor: kSunHeaderText,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: kSunHeaderText, fontWeight: FontWeight.w900),
      headlineMedium: TextStyle(color: kSunHeaderText, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(color: kSunBodyText),
      bodyMedium: TextStyle(color: kSunBodyText),
      bodySmall: TextStyle(color: kSunSecondaryText),
      labelSmall: TextStyle(color: kSunSecondaryText),
    ),
  );
}

ThemeData buildNightTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kNightBackground,
    cardColor: kNightCardSurface,
    dividerColor: kNightDivider,
    colorScheme: const ColorScheme.dark(
      primary: kBrandYellow,
      secondary: kBrandRed,
      surface: kNightCardSurface,
      onSurface: kNightBodyText,
      error: kBrandRed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kNightBackground,
      foregroundColor: kNightHeaderText,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: kNightHeaderText, fontWeight: FontWeight.w900),
      headlineMedium: TextStyle(color: kNightHeaderText, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(color: kNightBodyText),
      bodyMedium: TextStyle(color: kNightBodyText),
      bodySmall: TextStyle(color: kNightSecondaryText),
      labelSmall: TextStyle(color: kNightSecondaryText),
    ),
  );
}
