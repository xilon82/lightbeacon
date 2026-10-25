import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/beacon_config.dart';
import '../../l10n/l10n.dart';

/// Localized labels for the enums used by the beacon configuration.
abstract final class BeaconLabels {
  static String pattern(BuildContext context, FlashPattern pattern) {
    final l10n = context.l10n;
    return switch (pattern) {
      FlashPattern.single => l10n.patternSingle,
      FlashPattern.double => l10n.patternDouble,
      FlashPattern.triple => l10n.patternTriple,
      FlashPattern.sos => l10n.patternSos,
      FlashPattern.steady => l10n.patternSteady,
    };
  }

  static String effect(BuildContext context, ScreenEffect effect) {
    final l10n = context.l10n;
    return switch (effect) {
      ScreenEffect.solid => l10n.effectSolid,
      ScreenEffect.pulse => l10n.effectPulse,
      ScreenEffect.strobe => l10n.effectStrobe,
      ScreenEffect.alternate => l10n.effectAlternate,
      ScreenEffect.sweep => l10n.effectSweep,
      ScreenEffect.rainbow => l10n.effectRainbow,
    };
  }

  static String sync(BuildContext context, SyncMode sync) {
    final l10n = context.l10n;
    return switch (sync) {
      SyncMode.inPhase => l10n.syncInPhase,
      SyncMode.counterPhase => l10n.syncCounterPhase,
      SyncMode.independent => l10n.syncIndependent,
    };
  }

  static String color(BuildContext context, Color color) {
    final l10n = context.l10n;
    if (color == BeaconPalette.white) return l10n.colorWhite;
    if (color == BeaconPalette.amber) return l10n.colorAmber;
    if (color == BeaconPalette.red) return l10n.colorRed;
    if (color == BeaconPalette.green) return l10n.colorGreen;
    if (color == BeaconPalette.cyan) return l10n.colorCyan;
    if (color == BeaconPalette.magenta) return l10n.colorMagenta;
    return l10n.colorWhite;
  }

  static String timeout(BuildContext context, int minutes) {
    final l10n = context.l10n;
    return minutes <= 0 ? l10n.timeoutNone : l10n.timeoutMinutes(minutes);
  }

  static String presetName(BuildContext context, String? nameKey, String? customName) {
    if (customName != null && customName.isNotEmpty) return customName;
    final l10n = context.l10n;
    return switch (nameKey) {
      'presetPedestrian' => l10n.presetPedestrian,
      'presetBike' => l10n.presetBike,
      'presetBreakdown' => l10n.presetBreakdown,
      'presetEmergency' => l10n.presetEmergency,
      'presetIlluminate' => l10n.presetIlluminate,
      'presetWorksite' => l10n.presetWorksite,
      _ => l10n.presetCustom,
    };
  }

  static String presetDescription(BuildContext context, String? nameKey) {
    final l10n = context.l10n;
    return switch (nameKey) {
      'presetPedestrian' => l10n.presetPedestrianDesc,
      'presetBike' => l10n.presetBikeDesc,
      'presetBreakdown' => l10n.presetBreakdownDesc,
      'presetEmergency' => l10n.presetEmergencyDesc,
      'presetIlluminate' => l10n.presetIlluminateDesc,
      'presetWorksite' => l10n.presetWorksiteDesc,
      _ => '',
    };
  }
}

/// Small colored dot used in the color picker and preset rows.
class ColorDot extends StatelessWidget {
  const ColorDot({
    super.key,
    required this.color,
    this.selected = false,
    this.size = 40,
  });

  final Color color;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppTheme.textPrimary : AppTheme.outline,
          width: selected ? 3 : 1,
        ),
      ),
    );
  }
}
