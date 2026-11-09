import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_beacon/core/theme/app_theme.dart';
import 'package:light_beacon/domain/models/active_source.dart';
import 'package:light_beacon/domain/models/beacon_config.dart';
import 'package:light_beacon/domain/repositories/built_in_presets.dart';
import 'package:light_beacon/features/beacon/config_actions.dart';
import 'package:light_beacon/l10n/l10n.dart';
import 'package:light_beacon/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ConfigActions()),
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  testWidgets('with no source only "save as preset" is offered', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Salva come preset'), findsOneWidget);
    expect(find.text('Salva modalità'), findsNothing);
    expect(find.text('Ripristina default'), findsNothing);
  });

  testWidgets('an untouched mode offers only "save as preset"', (tester) async {
    final container = await _pump(tester);
    container
        .read(activeSourceProvider.notifier)
        .set(const ActiveSource.mode(BeaconMode.strobe));
    await tester.pump();

    expect(find.text('Salva modalità'), findsNothing);
    expect(find.text('Ripristina default'), findsNothing);
    expect(find.text('Salva come preset'), findsOneWidget);
  });

  testWidgets('a modified mode offers save, reset and save as preset', (
    tester,
  ) async {
    final container = await _pump(tester);
    final config = container.read(beaconConfigProvider.notifier);

    // A stored override is what makes "restore default" meaningful.
    config.loadMode(BeaconMode.strobe);
    config.apply(
      BeaconConfig.forMode(BeaconMode.strobe).copyWith(frequencyHz: 4),
    );
    config.saveOverMode();
    config.apply(
      BeaconConfig.forMode(BeaconMode.strobe).copyWith(frequencyHz: 6),
    );
    await tester.pump();

    expect(find.text('Salva modalità'), findsOneWidget);
    expect(find.text('Ripristina default'), findsOneWidget);
    expect(find.text('Salva come preset'), findsOneWidget);
    expect(find.text('Configurazione modificata'), findsOneWidget);
  });

  testWidgets('a modified preset offers overwrite and save as new', (
    tester,
  ) async {
    final container = await _pump(tester);
    final config = container.read(beaconConfigProvider.notifier);

    config.loadPreset(BuiltInPresets.pedestrian);
    config.apply(BeaconConfig.forMode(BeaconMode.sos));
    await tester.pump();

    expect(find.text('Salva'), findsOneWidget);
    expect(find.text('Salva come nuovo'), findsOneWidget);
    expect(find.text('Salva modalità'), findsNothing);
    expect(find.text('Ripristina default'), findsNothing);
  });

  testWidgets('saving a mode keeps the configuration and clears the hint', (
    tester,
  ) async {
    final container = await _pump(tester);
    final config = container.read(beaconConfigProvider.notifier);

    config.loadMode(BeaconMode.strobe);
    config.apply(
      BeaconConfig.forMode(BeaconMode.strobe).copyWith(frequencyHz: 4),
    );
    await tester.pump();

    await tester.tap(find.text('Salva modalità'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      container.read(modeOverridesProvider)[BeaconMode.strobe]?.frequencyHz,
      4,
    );
    expect(find.text('Configurazione modificata'), findsNothing);
  });
}
