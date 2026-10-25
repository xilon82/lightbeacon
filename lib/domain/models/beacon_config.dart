import 'dart:ui';

/// How the beacon is presented. Used by the home screen to build a config.
enum BeaconMode { torch, strobe, screen, sos, combo }

/// Shape of the flash inside one cycle.
enum FlashPattern { single, double, triple, sos, steady }

/// Visual effect drawn on the screen.
enum ScreenEffect { solid, pulse, strobe, alternate, sweep, rainbow }

/// How the screen follows the torch.
enum SyncMode { inPhase, counterPhase, independent }

/// Colors allowed by the app.
///
/// Blue is deliberately excluded: a flashing blue light is reserved for
/// emergency vehicles in most European countries, and imitating it is both
/// illegal and dangerous.
abstract final class BeaconPalette {
  static const white = Color(0xFFFFFFFF);
  static const amber = Color(0xFFFFB020);
  static const red = Color(0xFFE5484D);
  static const green = Color(0xFF3DD68C);
  static const cyan = Color(0xFF22D3EE);
  static const magenta = Color(0xFFE879F9);

  static const all = <Color>[white, amber, red, green, cyan, magenta];
}

/// Immutable description of what the beacon should do.
///
/// This is the single source of truth shared by the engine, the painter and
/// the persistence layer.
class BeaconConfig {
  const BeaconConfig({
    required this.pattern,
    required this.frequencyHz,
    required this.dutyCycle,
    required this.primaryColor,
    required this.secondaryColor,
    required this.effect,
    required this.brightness,
    required this.sync,
    required this.timeoutMinutes,
    required this.torchEnabled,
    required this.screenEnabled,
  });

  final FlashPattern pattern;
  final double frequencyHz;
  final double dutyCycle;
  final Color primaryColor;
  final Color secondaryColor;
  final ScreenEffect effect;
  final double brightness;
  final SyncMode sync;

  /// 0 means "never turn off automatically".
  final int timeoutMinutes;

  final bool torchEnabled;
  final bool screenEnabled;

  /// Duration of one full flash cycle.
  ///
  /// SOS uses a fixed 7 s cycle so the Morse timing stays recognisable
  /// regardless of the frequency slider.
  Duration get cycleDuration {
    if (pattern == FlashPattern.sos) return const Duration(seconds: 7);
    final hz = frequencyHz.clamp(0.5, 10.0);
    return Duration(microseconds: (1000000 / hz).round());
  }

  /// True when the frequency slider has no effect on the current pattern.
  bool get frequencyLocked => pattern == FlashPattern.sos;

  /// True when the torch actually blinks, so frequency and duty apply.
  bool get torchFlashing =>
      torchEnabled && pattern != FlashPattern.steady;

  /// True when the screen effect changes over time, so sync applies.
  bool get screenAnimated =>
      screenEnabled && effect != ScreenEffect.solid;

  /// True when the screen/torch relationship is meaningful at all.
  bool get syncRelevant => torchFlashing && screenAnimated;

  BeaconConfig copyWith({
    FlashPattern? pattern,
    double? frequencyHz,
    double? dutyCycle,
    Color? primaryColor,
    Color? secondaryColor,
    ScreenEffect? effect,
    double? brightness,
    SyncMode? sync,
    int? timeoutMinutes,
    bool? torchEnabled,
    bool? screenEnabled,
  }) {
    return BeaconConfig(
      pattern: pattern ?? this.pattern,
      frequencyHz: frequencyHz ?? this.frequencyHz,
      dutyCycle: dutyCycle ?? this.dutyCycle,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      effect: effect ?? this.effect,
      brightness: brightness ?? this.brightness,
      sync: sync ?? this.sync,
      timeoutMinutes: timeoutMinutes ?? this.timeoutMinutes,
      torchEnabled: torchEnabled ?? this.torchEnabled,
      screenEnabled: screenEnabled ?? this.screenEnabled,
    );
  }

  /// Sensible starting point for each home-screen card.
  factory BeaconConfig.forMode(BeaconMode mode) {
    switch (mode) {
      case BeaconMode.torch:
        return const BeaconConfig(
          pattern: FlashPattern.steady,
          frequencyHz: 1,
          dutyCycle: 0.5,
          primaryColor: BeaconPalette.white,
          secondaryColor: BeaconPalette.amber,
          effect: ScreenEffect.solid,
          brightness: 0.8,
          sync: SyncMode.inPhase,
          timeoutMinutes: 0,
          torchEnabled: true,
          screenEnabled: false,
        );
      case BeaconMode.strobe:
        return const BeaconConfig(
          pattern: FlashPattern.single,
          frequencyHz: 2,
          dutyCycle: 0.4,
          primaryColor: BeaconPalette.white,
          secondaryColor: BeaconPalette.amber,
          effect: ScreenEffect.strobe,
          brightness: 0.8,
          sync: SyncMode.inPhase,
          timeoutMinutes: 0,
          torchEnabled: true,
          screenEnabled: true,
        );
      case BeaconMode.screen:
        return const BeaconConfig(
          pattern: FlashPattern.single,
          frequencyHz: 1.5,
          dutyCycle: 0.5,
          primaryColor: BeaconPalette.amber,
          secondaryColor: BeaconPalette.red,
          effect: ScreenEffect.pulse,
          brightness: 0.8,
          sync: SyncMode.independent,
          timeoutMinutes: 0,
          torchEnabled: false,
          screenEnabled: true,
        );
      case BeaconMode.sos:
        return const BeaconConfig(
          pattern: FlashPattern.sos,
          frequencyHz: 1,
          dutyCycle: 0.5,
          primaryColor: BeaconPalette.white,
          secondaryColor: BeaconPalette.red,
          effect: ScreenEffect.strobe,
          brightness: 0.9,
          sync: SyncMode.inPhase,
          timeoutMinutes: 0,
          torchEnabled: true,
          screenEnabled: true,
        );
      case BeaconMode.combo:
        return const BeaconConfig(
          pattern: FlashPattern.steady,
          frequencyHz: 1.5,
          dutyCycle: 0.5,
          primaryColor: BeaconPalette.amber,
          secondaryColor: BeaconPalette.red,
          effect: ScreenEffect.pulse,
          brightness: 0.8,
          sync: SyncMode.independent,
          timeoutMinutes: 0,
          torchEnabled: true,
          screenEnabled: true,
        );
    }
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'pattern': pattern.name,
    'frequencyHz': frequencyHz,
    'dutyCycle': dutyCycle,
    'primaryColor': primaryColor.toARGB32(),
    'secondaryColor': secondaryColor.toARGB32(),
    'effect': effect.name,
    'brightness': brightness,
    'sync': sync.name,
    'timeoutMinutes': timeoutMinutes,
    'torchEnabled': torchEnabled,
    'screenEnabled': screenEnabled,
  };

  factory BeaconConfig.fromJson(Map<String, Object?> json) {
    return BeaconConfig(
      pattern: _enumByName(json['pattern'], FlashPattern.values, FlashPattern.single),
      frequencyHz: _asDouble(json['frequencyHz'], 2).clamp(0.5, 10.0),
      dutyCycle: _asDouble(json['dutyCycle'], 0.5).clamp(0.05, 0.95),
      primaryColor: Color(_asInt(json['primaryColor'], 0xFFFFFFFF)),
      secondaryColor: Color(_asInt(json['secondaryColor'], 0xFFFFB020)),
      effect: _enumByName(json['effect'], ScreenEffect.values, ScreenEffect.strobe),
      brightness: _asDouble(json['brightness'], 0.8).clamp(0.1, 1.0),
      sync: _enumByName(json['sync'], SyncMode.values, SyncMode.inPhase),
      timeoutMinutes: _asInt(json['timeoutMinutes'], 0),
      torchEnabled: json['torchEnabled'] as bool? ?? true,
      screenEnabled: json['screenEnabled'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BeaconConfig &&
        other.pattern == pattern &&
        other.frequencyHz == frequencyHz &&
        other.dutyCycle == dutyCycle &&
        other.primaryColor == primaryColor &&
        other.secondaryColor == secondaryColor &&
        other.effect == effect &&
        other.brightness == brightness &&
        other.sync == sync &&
        other.timeoutMinutes == timeoutMinutes &&
        other.torchEnabled == torchEnabled &&
        other.screenEnabled == screenEnabled;
  }

  @override
  int get hashCode => Object.hash(
    pattern,
    frequencyHz,
    dutyCycle,
    primaryColor,
    secondaryColor,
    effect,
    brightness,
    sync,
    timeoutMinutes,
    torchEnabled,
    screenEnabled,
  );
}

T _enumByName<T extends Enum>(Object? raw, List<T> values, T fallback) {
  if (raw is String) {
    for (final value in values) {
      if (value.name == raw) return value;
    }
  }
  return fallback;
}

double _asDouble(Object? raw, double fallback) =>
    raw is num ? raw.toDouble() : fallback;

int _asInt(Object? raw, int fallback) => raw is num ? raw.toInt() : fallback;
