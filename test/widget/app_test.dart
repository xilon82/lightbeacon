import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_beacon/app.dart';
import 'package:light_beacon/domain/models/app_settings.dart';
import 'package:light_beacon/domain/repositories/settings_repository.dart';
import 'package:light_beacon/features/home/home_page.dart';
import 'package:light_beacon/features/onboarding/safety_page.dart';
import 'package:light_beacon/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  required AppSettings settings,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repository = SettingsRepository(prefs);
  await repository.saveSettings(settings);

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const LightBeaconApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('shows the safety notice on first run', (tester) async {
    await _pumpApp(
      tester,
      settings: const AppSettings(localeCode: 'it'),
    );

    expect(find.byType(SafetyPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
    expect(find.text('Ho capito'), findsOneWidget);
  });

  testWidgets('accepting the safety notice reveals the home screen', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      settings: const AppSettings(localeCode: 'it'),
    );

    await tester.tap(find.text('Ho capito'));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Strobo'), findsOneWidget);
    expect(find.text('Torcia fissa'), findsOneWidget);
  });

  testWidgets('home screen is shown when safety was already acknowledged', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      settings: const AppSettings(safetyAcknowledged: true),
    );

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(SafetyPage), findsNothing);
  });

  testWidgets('English locale is honoured', (tester) async {
    await _pumpApp(
      tester,
      settings: const AppSettings(
        safetyAcknowledged: true,
        localeCode: 'en',
      ),
    );

    expect(find.text('Steady torch'), findsOneWidget);
    expect(find.text('Torcia fissa'), findsNothing);
  });

  testWidgets('every home card is reachable and labelled', (tester) async {
    await _pumpApp(
      tester,
      settings: const AppSettings(
        safetyAcknowledged: true,
        localeCode: 'it',
      ),
    );

    for (final label in [
      'Strobo',
      'Torcia fissa',
      'Solo schermo',
      'Strada',
      'SOS',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });
}
