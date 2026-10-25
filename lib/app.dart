import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_page.dart';
import 'features/onboarding/safety_page.dart';
import 'l10n/l10n.dart';
import 'providers/providers.dart';

class LightBeaconApp extends ConsumerWidget {
  const LightBeaconApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final locale = settings.localeCode == null
        ? null
        : Locale(settings.localeCode!);

    return MaterialApp(
      title: 'LightBeacon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: settings.safetyAcknowledged
          ? const HomePage()
          : const SafetyPage(),
    );
  }
}
