import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_beacon/core/theme/app_theme.dart';
import 'package:light_beacon/domain/models/beacon_config.dart';
import 'package:light_beacon/features/beacon/beacon_page.dart';
import 'package:light_beacon/l10n/l10n.dart';
import 'package:light_beacon/platform/foreground/foreground_controller.dart';
import 'package:light_beacon/platform/screen/screen_controller.dart';
import 'package:light_beacon/platform/torch/torch_controller.dart';
import 'package:light_beacon/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Harness {
  _Harness(this.container, this.torch, this.foreground);

  final ProviderContainer container;
  final NoopTorchController torch;
  final NoopForegroundController foreground;
}

Future<_Harness> _pumpBeacon(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final torch = NoopTorchController(availability: TorchAvailability.available);
  final foreground = NoopForegroundController();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      torchControllerProvider.overrideWithValue(torch),
      screenControllerProvider.overrideWithValue(NoopScreenController()),
      foregroundControllerProvider.overrideWithValue(foreground),
    ],
  );
  addTearDown(container.dispose);

  // The home screen starts the session before pushing the beacon page.
  container.read(beaconConfigProvider.notifier).loadMode(BeaconMode.strobe);
  await container
      .read(beaconSessionProvider.notifier)
      .start(container.read(beaconConfigProvider));

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

  return _Harness(container, torch, foreground);
}

void main() {
  testWidgets('losing window focus pauses the beacon and regaining resumes', (
    tester,
  ) async {
    final harness = await _pumpBeacon(tester);
    expect(harness.container.read(beaconSessionProvider).paused, isFalse);

    // The notification shade takes focus: the activity is still resumed, so
    // this is the only signal the beacon gets.
    harness.foreground.emit(focused: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(harness.container.read(beaconSessionProvider).paused, isTrue);
    // The torch is held steady, not released: the light must stay visible.
    expect(harness.torch.calls.last, isTrue);
    expect(find.text('Flash fisso'), findsOneWidget);

    // Nothing may toggle while paused, no matter how much time passes.
    final callsWhilePaused = harness.torch.calls.length;
    await tester.pump(const Duration(seconds: 2));
    expect(harness.torch.calls.length, callsWhilePaused);

    harness.foreground.emit(focused: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(harness.container.read(beaconSessionProvider).paused, isFalse);
    expect(harness.torch.calls.length, greaterThan(callsWhilePaused));

    // A running engine keeps a timer scheduled: stop before the test ends.
    await harness.container.read(beaconSessionProvider.notifier).stop();
    await tester.pump();
  });

  testWidgets('the pause can be turned off in settings', (tester) async {
    final harness = await _pumpBeacon(tester);
    await harness.container
        .read(settingsProvider.notifier)
        .setPauseWhenBackgrounded(false);
    await tester.pump();

    harness.foreground.emit(focused: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(harness.container.read(beaconSessionProvider).paused, isFalse);
    final calls = harness.torch.calls.length;
    await tester.pump(const Duration(seconds: 1));
    expect(harness.torch.calls.length, greaterThan(calls));

    await harness.container.read(beaconSessionProvider.notifier).stop();
    await tester.pump();
  });
}
