import 'beacon_config.dart';

/// A named beacon configuration.
///
/// Built-in presets carry a [nameKey] that the UI resolves through
/// `AppLocalizations`; user presets carry a [customName] instead.
class Preset {
  const Preset({
    required this.id,
    required this.config,
    this.nameKey,
    this.customName,
    this.isBuiltIn = false,
  });

  final String id;
  final String? nameKey;
  final String? customName;
  final BeaconConfig config;
  final bool isBuiltIn;

  Preset copyWith({
    String? customName,
    bool clearCustomName = false,
    BeaconConfig? config,
  }) {
    return Preset(
      id: id,
      nameKey: nameKey,
      customName: clearCustomName ? null : (customName ?? this.customName),
      config: config ?? this.config,
      isBuiltIn: isBuiltIn,
    );
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'id': id,
    'nameKey': nameKey,
    'customName': customName,
    'config': config.toJson(),
  };

  factory Preset.fromJson(Map<String, Object?> json) {
    final rawConfig = json['config'];
    return Preset(
      id: json['id'] as String? ?? 'custom',
      nameKey: json['nameKey'] as String?,
      customName: json['customName'] as String?,
      config: rawConfig is Map<String, Object?>
          ? BeaconConfig.fromJson(rawConfig)
          : BeaconConfig.forMode(BeaconMode.strobe),
      isBuiltIn: false,
    );
  }
}

/// What the user changed about a built-in preset.
///
/// Built-ins stay immutable in [BuiltInPresets]: the changes live here, so the
/// factory list remains the source of truth for "restore" and for the factory
/// reset.
class PresetOverride {
  const PresetOverride({required this.config, this.customName});

  final BeaconConfig config;
  final String? customName;

  Map<String, Object?> toJson() => {
    'config': config.toJson(),
    'customName': customName,
  };

  factory PresetOverride.fromJson(Map<String, Object?> json) {
    final rawConfig = json['config'];
    return PresetOverride(
      config: rawConfig is Map<String, Object?>
          ? BeaconConfig.fromJson(rawConfig)
          : BeaconConfig.forMode(BeaconMode.strobe),
      customName: json['customName'] as String?,
    );
  }
}
