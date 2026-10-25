import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_beacon/core/theme/app_theme.dart';
import 'package:light_beacon/domain/models/beacon_config.dart';
import 'package:light_beacon/features/beacon/beacon_page.dart';
import 'package:light_beacon/features/beacon/control_sheet.dart';
import 'package:light_beacon/l10n/l10n.dart';
import 'package:light_beacon/platform/screen/screen_controller.dart';
import 'package:light_beacon/platform/torch/torch_controller.dart';
import 'package:light_beacon/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pumpBeacon(
  WidgetTester tester, {
  BeaconConfig? config,
}) async {
  // Tall viewport so the whole control sheet fits without scrolling.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      torchControllerProvider.overrideWithValue(
        NoopTorchController(availability: TorchAvailability.available),
      ),
      screenControllerProvider.overrideWithValue(NoopScreenController()),
    ],
  );
  addTearDown(container.dispose);

  if (config != null) {
    container.read(beaconConfigProvider.notifier).apply(config);
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BeaconPage(),
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  testWidgets('beacon page paints the effect and shows the stop button', (
    tester,
  ) async {
    await _pumpBeacon(tester);

    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('Ferma'), findsOneWidget);
  });

  testWidgets('tapping the screen toggles the HUD', (tester) async {
    await _pumpBeacon(tester);
    expect(find.text('Ferma'), findsOneWidget);

    await tester.tapAt(const Offset(200, 300));
    await tester.pump();

    expect(find.text('Ferma'), findsNothing);

    await tester.tapAt(const Offset(200, 300));
    await tester.pump();

    expect(find.text('Ferma'), findsOneWidget);
  });

  testWidgets('stop button ends the session', (tester) async {
    final container = await _pumpBeacon(tester);
    await container.read(beaconSessionProvider.notifier).start(
      container.read(beaconConfigProvider),
    );
    await tester.pump();

    expect(container.read(beaconSessionProvider).running, isTrue);

    await tester.tap(find.text('Ferma'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(container.read(beaconSessionProvider).running, isFalse);
  });

  testWidgets('control sheet exposes the main controls', (tester) async {
    await _pumpBeacon(tester);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ControlSheet), findsOneWidget);

    for (final label in [
      'Frequenza',
      'Pattern',
      'Effetto schermo',
      'Sincronia',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('steady torch hides frequency and duty with an explanation', (
    tester,
  ) async {
    await _pumpBeacon(
      tester,
      config: BeaconConfig.forMode(BeaconMode.torch),
    );

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Frequenza'), findsNothing);
    expect(find.text('Durata impulso'), findsNothing);
    expect(
      find.text(
        'Il flash resta acceso fisso: frequenza e durata non si applicano.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('saving a preset from the control sheet persists it', (
    tester,
  ) async {
    final container = await _pumpBeacon(tester);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Salva come preset'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Salva configurazione'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Strada di notte');
    await tester.tap(find.text('Salva'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final presets = container.read(presetsProvider);
    expect(presets, hasLength(1));
    expect(presets.single.customName, 'Strada di notte');
    expect(presets.single.config, container.read(beaconConfigProvider));
  });

  testWidgets('saving a preset rejects an empty name', (tester) async {
    final container = await _pumpBeacon(tester);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Salva come preset'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Salva'));
    await tester.pump();

    expect(find.text('Inserisci un nome'), findsOneWidget);
    expect(container.read(presetsProvider), isEmpty);
  });

  testWidgets('screen-only mode hides the flash controls', (tester) async {
    await _pumpBeacon(
      tester,
      config: BeaconConfig.forMode(BeaconMode.screen),
    );

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Flash disattivato in questa modalità.'), findsOneWidget);
    expect(find.text('Pattern'), findsNothing);
  });

  testWidgets('changing the pattern updates the shared config', (
    tester,
  ) async {
    final container = await _pumpBeacon(tester);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Triplo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      container.read(beaconConfigProvider).pattern,
      FlashPattern.triple,
    );
  });

  testWidgets('screen-only config keeps painting without a torch', (
    tester,
  ) async {
    final container = await _pumpBeacon(
      tester,
      config: BeaconConfig.forMode(BeaconMode.screen),
    );

    expect(container.read(beaconConfigProvider).torchEnabled, isFalse);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('Ferma'), findsOneWidget);
  });
}
