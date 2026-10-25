/// User preferences that are not part of a beacon configuration.
class AppSettings {
  const AppSettings({
    this.localeCode,
    this.safetyAcknowledged = false,
    this.brightnessCap = 0.8,
    this.keepAwake = true,
  });

  /// `null` follows the system language. Otherwise `it` or `en`.
  final String? localeCode;

  /// Whether the user has seen and accepted the safety notice.
  final bool safetyAcknowledged;

  /// Upper bound for the screen brightness slider (0.1 - 1.0).
  final double brightnessCap;

  /// Keep the display awake while the beacon is running.
  final bool keepAwake;

  AppSettings copyWith({
    String? localeCode,
    bool clearLocale = false,
    bool? safetyAcknowledged,
    double? brightnessCap,
    bool? keepAwake,
  }) {
    return AppSettings(
      localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
      safetyAcknowledged: safetyAcknowledged ?? this.safetyAcknowledged,
      brightnessCap: brightnessCap ?? this.brightnessCap,
      keepAwake: keepAwake ?? this.keepAwake,
    );
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'localeCode': localeCode,
    'safetyAcknowledged': safetyAcknowledged,
    'brightnessCap': brightnessCap,
    'keepAwake': keepAwake,
  };

  factory AppSettings.fromJson(Map<String, Object?> json) {
    final rawLocale = json['localeCode'];
    return AppSettings(
      localeCode: rawLocale is String && rawLocale.isNotEmpty ? rawLocale : null,
      safetyAcknowledged: json['safetyAcknowledged'] as bool? ?? false,
      brightnessCap: (json['brightnessCap'] as num?)?.toDouble().clamp(0.1, 1.0) ??
          0.8,
      keepAwake: json['keepAwake'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.localeCode == localeCode &&
        other.safetyAcknowledged == safetyAcknowledged &&
        other.brightnessCap == brightnessCap &&
        other.keepAwake == keepAwake;
  }

  @override
  int get hashCode =>
      Object.hash(localeCode, safetyAcknowledged, brightnessCap, keepAwake);
}
