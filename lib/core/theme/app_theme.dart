import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';

class AppTheme {
  AppTheme(this.mode, this.fontFamily);
  final AppThemeMode mode;
  final String fontFamily;

  static const _bgDark = Color(0xFF0E0D15);
  static const _cardDark = Color(0xFF181624);
  static const _accentPurple = Color(0xFF7B61FF);

  ThemeData _xPlatformDarkTheme() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: _accentPurple,
      brightness: Brightness.dark,
      surface: _bgDark,
      primary: _accentPurple,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: baseScheme,
      scaffoldBackgroundColor: _bgDark,
      fontFamily: fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: _bgDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: _cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _cardDark,
        surfaceTintColor: Colors.transparent,
        indicatorColor: _accentPurple.withValues(alpha: 0.22),
      ),
      extensions: const <ThemeExtension<dynamic>>{ConnectionButtonTheme.light},
    );
  }

  ThemeData lightTheme(ColorScheme? lightColorScheme) => _xPlatformDarkTheme();

  ThemeData darkTheme(ColorScheme? darkColorScheme) => _xPlatformDarkTheme();

  CupertinoThemeData cupertinoThemeData(bool sysDark, ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) {
    const def = CupertinoThemeData(brightness: Brightness.dark);
    final defaultMaterialTheme = _xPlatformDarkTheme();
    return MaterialBasedCupertinoThemeData(
      materialTheme: defaultMaterialTheme.copyWith(
        cupertinoOverrideTheme: def.copyWith(
          textTheme: CupertinoTextThemeData(
            textStyle: def.textTheme.textStyle.copyWith(fontFamily: fontFamily),
            actionTextStyle: def.textTheme.actionTextStyle.copyWith(fontFamily: fontFamily),
            navActionTextStyle: def.textTheme.navActionTextStyle.copyWith(fontFamily: fontFamily),
            navTitleTextStyle: def.textTheme.navTitleTextStyle.copyWith(fontFamily: fontFamily),
            navLargeTitleTextStyle: def.textTheme.navLargeTitleTextStyle.copyWith(fontFamily: fontFamily),
            pickerTextStyle: def.textTheme.pickerTextStyle.copyWith(fontFamily: fontFamily),
            dateTimePickerTextStyle: def.textTheme.dateTimePickerTextStyle.copyWith(fontFamily: fontFamily),
            tabLabelTextStyle: def.textTheme.tabLabelTextStyle.copyWith(fontFamily: fontFamily),
          ),
          barBackgroundColor: _cardDark,
          scaffoldBackgroundColor: _bgDark,
        ),
      ),
    );
  }
}
