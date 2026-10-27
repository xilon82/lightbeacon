// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LightBeacon';

  @override
  String get appTagline => 'Be seen. Even in the dark.';

  @override
  String get homeSubtitle => 'Choose how to be seen';

  @override
  String get homeTip =>
      'Hold the phone at chest height with the screen facing traffic.';

  @override
  String get modeTorchTitle => 'Steady torch';

  @override
  String get modeTorchSubtitle => 'Light up the path';

  @override
  String get modeStrobeTitle => 'Strobe';

  @override
  String get modeStrobeSubtitle => 'Flashing torch and screen';

  @override
  String get modeScreenTitle => 'Screen only';

  @override
  String get modeScreenSubtitle => 'Color and effects, no flash';

  @override
  String get modeSosTitle => 'SOS';

  @override
  String get modeSosSubtitle => 'Emergency signal';

  @override
  String get modeComboTitle => 'Road';

  @override
  String get modeComboSubtitle => 'Flash and screen together';

  @override
  String get navPresets => 'Presets';

  @override
  String get navSettings => 'Settings';

  @override
  String get beaconStop => 'Stop';

  @override
  String get beaconControls => 'Controls';

  @override
  String get beaconTapHint => 'Tap to show controls';

  @override
  String get beaconTorchUnavailable => 'Flash is not available on this device';

  @override
  String get beaconTorchError => 'Unable to control the flash';

  @override
  String get beaconJitterWarning => 'Unstable flashing: frequency reduced';

  @override
  String get beaconTimeoutReached => 'Turned off automatically';

  @override
  String get controlFrequency => 'Frequency';

  @override
  String controlFrequencyValue(String value) {
    return '$value Hz';
  }

  @override
  String get controlDuty => 'Pulse length';

  @override
  String controlDutyValue(String value) {
    return '$value%';
  }

  @override
  String get controlPattern => 'Pattern';

  @override
  String get controlEffect => 'Screen effect';

  @override
  String get controlPrimaryColor => 'Color';

  @override
  String get controlSecondaryColor => 'Second color';

  @override
  String get controlBrightness => 'Screen brightness';

  @override
  String controlBrightnessValue(String value) {
    return '$value%';
  }

  @override
  String get controlSync => 'Sync';

  @override
  String get controlTimeout => 'Auto turn-off';

  @override
  String get controlSectionFlash => 'Flashing';

  @override
  String get controlSectionScreen => 'Screen';

  @override
  String get controlSectionTiming => 'Timing';

  @override
  String get controlFrequencyDesc => 'How many flashes per second';

  @override
  String get controlDutyDesc => 'How long it stays on in each flash';

  @override
  String get controlPatternDesc => 'Shape of the flash';

  @override
  String get controlEffectDesc => 'How the color moves on screen';

  @override
  String get controlBrightnessDesc => 'Display brightness while in use';

  @override
  String get controlSyncDesc => 'How screen and flash alternate';

  @override
  String get controlTimeoutDesc => 'Turn off automatically after';

  @override
  String get controlTorchToggle => 'Flash';

  @override
  String get controlScreenToggle => 'Screen';

  @override
  String get controlTorchToggleDesc => 'Use the rear LED';

  @override
  String get controlScreenToggleDesc => 'Use the display as a colored light';

  @override
  String get hintSteadyTorch =>
      'The flash stays on steadily: frequency and pulse length do not apply.';

  @override
  String get hintSteadyScreen =>
      'With a steady flash, Strobe and Alternate have no cycle to follow: the screen stays a solid color.';

  @override
  String get hintTorchOff => 'Flash is off in this mode.';

  @override
  String get hintScreenOff => 'Screen is off in this mode.';

  @override
  String get hintSyncNeedsBoth =>
      'Only applies when both flash and screen are on and animated.';

  @override
  String get savePresetTitle => 'Save configuration';

  @override
  String get savePresetAction => 'Save as preset';

  @override
  String get savePresetNameLabel => 'Name';

  @override
  String get savePresetNameHint => 'e.g. Night road';

  @override
  String savePresetDefaultName(String date) {
    return 'Configuration $date';
  }

  @override
  String get savePresetSaved => 'Preset saved';

  @override
  String get savePresetEmptyName => 'Enter a name';

  @override
  String get savePresetSave => 'Save';

  @override
  String get patternSingle => 'Single';

  @override
  String get patternDouble => 'Double';

  @override
  String get patternTriple => 'Triple';

  @override
  String get patternSos => 'SOS';

  @override
  String get patternSteady => 'Steady';

  @override
  String get effectSolid => 'Solid';

  @override
  String get effectPulse => 'Pulse';

  @override
  String get effectStrobe => 'Strobe';

  @override
  String get effectAlternate => 'Alternate';

  @override
  String get effectSweep => 'Sweep';

  @override
  String get effectRainbow => 'Rainbow';

  @override
  String get syncInPhase => 'In phase';

  @override
  String get syncCounterPhase => 'Counter-phase';

  @override
  String get syncIndependent => 'Independent';

  @override
  String get colorWhite => 'White';

  @override
  String get colorAmber => 'Amber';

  @override
  String get colorRed => 'Red';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorCyan => 'Cyan';

  @override
  String get colorMagenta => 'Magenta';

  @override
  String get timeoutNone => 'Never';

  @override
  String timeoutMinutes(int count) {
    return '$count min';
  }

  @override
  String get presetsTitle => 'Presets';

  @override
  String get presetsBuiltIn => 'Built-in';

  @override
  String get presetsCustom => 'Custom';

  @override
  String get presetPedestrian => 'Pedestrian';

  @override
  String get presetPedestrianDesc => 'White 2 Hz, flash in phase';

  @override
  String get presetBike => 'Bike / scooter';

  @override
  String get presetBikeDesc => 'Pulsing amber, steady torch';

  @override
  String get presetBreakdown => 'Breakdown';

  @override
  String get presetBreakdownDesc => 'Alternating red and amber';

  @override
  String get presetEmergency => 'Emergency';

  @override
  String get presetEmergencyDesc => 'SOS on flash and screen';

  @override
  String get presetIlluminate => 'Illuminate';

  @override
  String get presetIlluminateDesc => 'Steady torch only';

  @override
  String get presetWorksite => 'Worksite';

  @override
  String get presetWorksiteDesc => 'Amber strobe, short pulse';

  @override
  String get presetCustom => 'Custom';

  @override
  String get presetApply => 'Apply';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsLanguageItalian => 'Italian';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsBrightnessCap => 'Brightness limit';

  @override
  String get settingsBrightnessCapDesc => 'Maximum allowed for the screen';

  @override
  String get settingsKeepAwake => 'Keep screen on';

  @override
  String get settingsKeepAwakeDesc =>
      'Prevent the display from sleeping while in use';

  @override
  String get settingsSafety => 'Safety notices';

  @override
  String get settingsSafetyDesc => 'Review photosensitivity and road use';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsReset => 'Reset settings';

  @override
  String get settingsResetConfirm => 'Reset all settings to their defaults?';

  @override
  String get safetyTitle => 'Before you start';

  @override
  String get safetyPhotosensitivityTitle => 'Photosensitivity';

  @override
  String get safetyPhotosensitivityBody =>
      'Rapid flashing can trigger seizures in people with photosensitive epilepsy. Never point the flash or the screen at anyone\'s eyes.';

  @override
  String get safetyRoadTitle => 'Road use';

  @override
  String get safetyRoadBody =>
      'LightBeacon is not a certified signalling device. It does not replace a reflective vest, position lights or road signs. Use it as a support, not as your only safety measure.';

  @override
  String get safetyLawTitle => 'Allowed colors';

  @override
  String get safetyLawBody =>
      'Flashing blue is reserved for emergency vehicles. LightBeacon does not offer blue among its colors.';

  @override
  String get safetyBatteryTitle => 'Battery and heat';

  @override
  String get safetyBatteryBody =>
      'Flash and screen at full power drain the battery and heat up the device. The app automatically lowers brightness when needed.';

  @override
  String get safetyAccept => 'I understand';

  @override
  String get warningHighFrequencyTitle => 'High frequency';

  @override
  String get warningHighFrequencyBody =>
      'Above 3 flashes per second the risk for photosensitive people increases. Continue?';

  @override
  String get warningContinue => 'Continue';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonClose => 'Close';

  @override
  String get commonReset => 'Reset';

  @override
  String get errorTorchUnavailable => 'This device has no usable flash.';

  @override
  String get errorTorchBusy => 'The flash is in use by another app.';

  @override
  String get errorGeneric => 'Something went wrong.';
}
