import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_beacon/core/theme/app_theme.dart';
import 'package:light_beacon/domain/models/beacon_config.dart';
import 'package:light_beacon/features/presets/presets_page.dart';
import 'package:light_beacon/l10n/l10n.dart';
import 'package:light_beacon/platform/screen/screen_controller.dart';
import 'package:light_beacon/platform/torch/torch_controller.dart';
import 'package:light_beacon/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pumpPresets(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      torchControllerProvider.overrideWithValue(NoopTorchController()),
      screenControllerProvider.overrideWithValue(NoopScreenController()),
    ],
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
        home: const PresetsPage(),
      ),
    ),
  );
  await tester.pump();
  return container;
}

/// Opens the ⋮ menu of the row that shows [name].
Future<void> _openMenu(WidgetTester tester, String name) async {
  final tile = find.ancestor(
    of: find.text(name),
    matching: find.byType(InkWell),
  );
  await tester.tap(
    find.descendant(of: tile, matching: find.byIcon(Icons.more_vert)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a built-in preset can be deleted like a custom one', (
    tester,
  ) async {
    final container = await _pumpPresets(tester);
    expect(find.text('Cantiere'), findsOneWidget);

    await _openMenu(tester, 'Cantiere');
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Elimina'));
    await tester.pumpAndSettle();

    expect(find.text('Cantiere'), findsNothing);
    expect(container.read(presetsProvider).byId('worksite'), isNull);
  });

  testWidgets('a built-in preset can be renamed', (tester) async {
    final container = await _pumpPresets(tester);

    await _openMenu(tester, 'Pedone');
    await tester.tap(find.text('Rinomina'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Mio pedone');
    await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
    await tester.pumpAndSettle();

    expect(find.text('Mio pedone'), findsOneWidget);
    expect(
      container.read(presetsProvider).byId('pedestrian')?.customName,
      'Mio pedone',
    );
  });

  testWidgets('a preset can be overwritten with the current configuration', (
    tester,
  ) async {
    final container = await _pumpPresets(tester);
    final wanted = BeaconConfig.forMode(BeaconMode.sos);
    container.read(beaconConfigProvider.notifier).apply(wanted);
    await tester.pump();

    await _openMenu(tester, 'Pedone');
    await tester.tap(find.text('Sovrascrivi con la configurazione attuale'));
    await tester.pumpAndSettle();

    expect(container.read(presetsProvider).byId('pedestrian')?.config, wanted);
    expect(container.read(presetsProvider).isOverridden('pedestrian'), isTrue);
    expect(find.text('Modificato'), findsWidgets);
  });

  testWidgets('an overridden built-in can be restored', (tester) async {
    final container = await _pumpPresets(tester);
    await container
        .read(presetsProvider.notifier)
        .overwrite('pedestrian', BeaconConfig.forMode(BeaconMode.sos));
    await tester.pump();

    await _openMenu(tester, 'Pedone');
    await tester.tap(find.text('Ripristina originale'));
    await tester.pumpAndSettle();

    expect(container.read(presetsProvider).isOverridden('pedestrian'), isFalse);
    expect(find.text('Modificato'), findsNothing);
  });
}
