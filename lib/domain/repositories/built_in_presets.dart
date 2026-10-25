import '../models/beacon_config.dart';
import '../models/preset.dart';

/// Built-in presets.
///
/// Names are localization keys resolved by the UI, so the list itself stays
/// language-agnostic.
abstract final class BuiltInPresets {
  static const pedestrian = Preset(
    id: 'pedestrian',
    nameKey: 'presetPedestrian',
    isBuiltIn: true,
    config: BeaconConfig(
      pattern: FlashPattern.single,
      frequencyHz: 2,
      dutyCycle: 0.4,
      primaryColor: BeaconPalette.white,
      secondaryColor: BeaconPalette.amber,
      effect: ScreenEffect.strobe,
      brightness: 0.85,
      sync: SyncMode.inPhase,
      timeoutMinutes: 0,
      torchEnabled: true,
      screenEnabled: true,
    ),
  );

  static const bike = Preset(
    id: 'bike',
    nameKey: 'presetBike',
    isBuiltIn: true,
    config: BeaconConfig(
      pattern: FlashPattern.steady,
      frequencyHz: 1.5,
      dutyCycle: 0.5,
      primaryColor: BeaconPalette.amber,
      secondaryColor: BeaconPalette.amber,
      effect: ScreenEffect.pulse,
      brightness: 0.8,
      sync: SyncMode.independent,
      timeoutMinutes: 0,
      torchEnabled: true,
      screenEnabled: true,
    ),
  );

  static const breakdown = Preset(
    id: 'breakdown',
    nameKey: 'presetBreakdown',
    isBuiltIn: true,
    config: BeaconConfig(
      pattern: FlashPattern.double,
      frequencyHz: 1,
      dutyCycle: 0.35,
      primaryColor: BeaconPalette.red,
      secondaryColor: BeaconPalette.amber,
      effect: ScreenEffect.alternate,
      brightness: 0.85,
      sync: SyncMode.inPhase,
      timeoutMinutes: 0,
      torchEnabled: true,
      screenEnabled: true,
    ),
  );

  static const emergency = Preset(
    id: 'emergency',
    nameKey: 'presetEmergency',
    isBuiltIn: true,
    config: BeaconConfig(
      pattern: FlashPattern.sos,
      frequencyHz: 1,
      dutyCycle: 0.5,
      primaryColor: BeaconPalette.white,
      secondaryColor: BeaconPalette.red,
      effect: ScreenEffect.strobe,
      brightness: 1.0,
      sync: SyncMode.inPhase,
      timeoutMinutes: 0,
      torchEnabled: true,
      screenEnabled: true,
    ),
  );

  static const illuminate = Preset(
    id: 'illuminate',
    nameKey: 'presetIlluminate',
    isBuiltIn: true,
    config: BeaconConfig(
      pattern: FlashPattern.steady,
      frequencyHz: 1,
      dutyCycle: 0.5,
      primaryColor: BeaconPalette.white,
      secondaryColor: BeaconPalette.white,
      effect: ScreenEffect.solid,
      brightness: 0.3,
      sync: SyncMode.independent,
      timeoutMinutes: 0,
      torchEnabled: true,
      screenEnabled: false,
    ),
  );

  static const worksite = Preset(
    id: 'worksite',
    nameKey: 'presetWorksite',
    isBuiltIn: true,
    config: BeaconConfig(
      pattern: FlashPattern.single,
      frequencyHz: 1,
      dutyCycle: 0.3,
      primaryColor: BeaconPalette.amber,
      secondaryColor: BeaconPalette.amber,
      effect: ScreenEffect.strobe,
      brightness: 0.8,
      sync: SyncMode.inPhase,
      timeoutMinutes: 0,
      torchEnabled: true,
      screenEnabled: true,
    ),
  );

  static const all = <Preset>[
    pedestrian,
    bike,
    breakdown,
    emergency,
    illuminate,
    worksite,
  ];
}
