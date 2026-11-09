import 'beacon_config.dart';

/// Where the configuration currently loaded in the beacon comes from.
///
/// Editing a running beacon must know its starting point: saving "over" it
/// means overwriting that mode or that preset, while "save as new" always
/// creates a preset. A configuration with no source can only be saved as new.
class ActiveSource {
  const ActiveSource.mode(BeaconMode this.mode) : presetId = null;

  const ActiveSource.preset(String this.presetId) : mode = null;

  final BeaconMode? mode;
  final String? presetId;

  bool get isMode => mode != null;

  bool get isPreset => presetId != null;

  /// Stable identity: mode name or preset id.
  String get id => mode?.name ?? presetId ?? '';

  Map<String, Object?> toJson() => {
    'type': isMode ? 'mode' : 'preset',
    'id': id,
  };

  /// Returns `null` for anything unreadable.
  ///
  /// A stale source (a preset deleted in another session, an enum renamed in a
  /// future version) is not an error: the UI simply stops offering "save over"
  /// and falls back to "save as new".
  static ActiveSource? fromJson(Map<String, Object?> json) {
    final rawId = json['id'];
    if (rawId is! String || rawId.isEmpty) return null;
    switch (json['type']) {
      case 'mode':
        for (final mode in BeaconMode.values) {
          if (mode.name == rawId) return ActiveSource.mode(mode);
        }
        return null;
      case 'preset':
        return ActiveSource.preset(rawId);
      default:
        return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ActiveSource && other.isMode == isMode && other.id == id;

  @override
  int get hashCode => Object.hash(isMode, id);

  @override
  String toString() =>
      isMode ? 'ActiveSource.mode($id)' : 'ActiveSource.preset($id)';
}
