/// User preferences that are not part of a beacon configuration.
class AppSettings {
  const AppSettings({
    this.localeCode,
    this.safetyAcknowledged = false,
    this.brightnessCap = 0.8,
    this.keepAwake = true,
    this.pauseWhenBackgrounded = true,
  });

  /// `null` follows the system language. Otherwise `it` or `en`.
  final String? localeCode;

  /// Whether the user has seen and accepted the safety notice.
  final bool safetyAcknowledged;

  /// Upper bound for the screen brightness slider (0.1 - 1.0).
  final double brightnessCap;

  /// Keep the display awake while the beacon is running.
  final bool keepAwake;

  /// Pause the beacon while the app is not visible.
  ///
  /// The system posts a notification every time the torch changes state, so a
  /// flashing torch makes the notification shade churn. Pausing while another
  /// window has focus keeps the shade still; the beacon restarts on return.
  final bool pauseWhenBackgrounded;

  AppSettings copyWith({
    String? localeCode,
    bool clearLocale = false,
    bool? safetyAcknowledged,
    double? brightnessCap,
    bool? keepAwake,
    bool? pauseWhenBackgrounded,
  }) {
    return AppSettings(
      localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
      safetyAcknowledged: safetyAcknowledged ?? this.safetyAcknowledged,
      brightnessCap: brightnessCap ?? this.brightnessCap,
      keepAwake: keepAwake ?? this.keepAwake,
      pauseWhenBackgrounded:
          pauseWhenBackgrounded ?? this.pauseWhenBackgrounded,
    );
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'localeCode': localeCode,
    'safetyAcknowledged': safetyAcknowledged,
    'brightnessCap': brightnessCap,
    'keepAwake': keepAwake,
    'pauseWhenBackgrounded': pauseWhenBackgrounded,
  };

  factory AppSettings.fromJson(Map<String, Object?> json) {
    final rawLocale = json['localeCode'];
    return AppSettings(
      localeCode: rawLocale is String && rawLocale.isNotEmpty
          ? rawLocale
          : null,
      safetyAcknowledged: json['safetyAcknowledged'] as bool? ?? false,
      brightnessCap:
          (json['brightnessCap'] as num?)?.toDouble().clamp(0.1, 1.0) ?? 0.8,
      keepAwake: json['keepAwake'] as bool? ?? true,
      pauseWhenBackgrounded: json['pauseWhenBackgrounded'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.localeCode == localeCode &&
        other.safetyAcknowledged == safetyAcknowledged &&
        other.brightnessCap == brightnessCap &&
        other.keepAwake == keepAwake &&
        other.pauseWhenBackgrounded == pauseWhenBackgrounded;
  }

  @override
  int get hashCode => Object.hash(
    localeCode,
    safetyAcknowledged,
    brightnessCap,
    keepAwake,
    pauseWhenBackgrounded,
  );
}
