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
