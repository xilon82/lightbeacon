// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'LightBeacon';

  @override
  String get appTagline => 'Fatti vedere. Anche al buio.';

  @override
  String get homeSubtitle => 'Scegli come farti vedere';

  @override
  String get homeTip =>
      'Tieni il telefono all\'altezza del petto, con lo schermo verso il traffico.';

  @override
  String get modeTorchTitle => 'Torcia fissa';

  @override
  String get modeTorchSubtitle => 'Illumina il cammino';

  @override
  String get modeStrobeTitle => 'Strobo';

  @override
  String get modeStrobeSubtitle => 'Flash e schermo lampeggianti';

  @override
  String get modeScreenTitle => 'Solo schermo';

  @override
  String get modeScreenSubtitle => 'Colore ed effetti, senza flash';

  @override
  String get modeSosTitle => 'SOS';

  @override
  String get modeSosSubtitle => 'Segnale di emergenza';

  @override
  String get modeComboTitle => 'Strada';

  @override
  String get modeComboSubtitle => 'Flash e schermo insieme';

  @override
  String get navPresets => 'Preset';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get beaconStop => 'Ferma';

  @override
  String get beaconControls => 'Controlli';

  @override
  String get beaconTapHint => 'Tocca per mostrare i controlli';

  @override
  String get beaconTorchUnavailable =>
      'Flash non disponibile su questo dispositivo';

  @override
  String get beaconTorchError => 'Impossibile controllare il flash';

  @override
  String get beaconJitterWarning => 'Lampeggio instabile: frequenza ridotta';

  @override
  String get beaconTimeoutReached => 'Spegnimento automatico';

  @override
  String get controlFrequency => 'Frequenza';

  @override
  String controlFrequencyValue(String value) {
    return '$value Hz';
  }

  @override
  String get controlDuty => 'Durata impulso';

  @override
  String controlDutyValue(String value) {
    return '$value%';
  }

  @override
  String get controlPattern => 'Pattern';

  @override
  String get controlEffect => 'Effetto schermo';

  @override
  String get controlPrimaryColor => 'Colore';

  @override
  String get controlSecondaryColor => 'Secondo colore';

  @override
  String get controlBrightness => 'Luminosità schermo';

  @override
  String controlBrightnessValue(String value) {
    return '$value%';
  }

  @override
  String get controlSync => 'Sincronia';

  @override
  String get controlTimeout => 'Spegnimento automatico';

  @override
  String get controlSectionFlash => 'Lampeggio';

  @override
  String get controlSectionScreen => 'Schermo';

  @override
  String get controlSectionTiming => 'Tempi';

  @override
  String get controlFrequencyDesc => 'Quanti lampeggi al secondo';

  @override
  String get controlDutyDesc => 'Quanto resta acceso in ogni lampeggio';

  @override
  String get controlPatternDesc => 'Forma del lampeggio';

  @override
  String get controlEffectDesc => 'Come si muove il colore sullo schermo';

  @override
  String get controlBrightnessDesc => 'Luminosità del display durante l\'uso';

  @override
  String get controlSyncDesc => 'Come schermo e flash si alternano';

  @override
  String get controlTimeoutDesc => 'Spegnimento automatico dopo';

  @override
  String get controlTorchToggle => 'Flash';

  @override
  String get controlScreenToggle => 'Schermo';

  @override
  String get controlTorchToggleDesc => 'Usa il LED posteriore';

  @override
  String get controlScreenToggleDesc => 'Usa il display come luce colorata';

  @override
  String get hintSteadyTorch =>
      'Il flash resta acceso fisso: frequenza e durata non si applicano.';

  @override
  String get hintSteadyScreen =>
      'Con il flash fisso Strobo e Alternato non hanno un ciclo da seguire: lo schermo resta di un colore pieno.';

  @override
  String get hintTorchOff => 'Flash disattivato in questa modalità.';

  @override
  String get hintScreenOff => 'Schermo disattivato in questa modalità.';

  @override
  String get hintSyncNeedsBoth =>
      'Si applica solo con flash e schermo entrambi attivi e animati.';

  @override
  String get savePresetTitle => 'Salva configurazione';

  @override
  String get savePresetAction => 'Salva come preset';

  @override
  String get savePresetNameLabel => 'Nome';

  @override
  String get savePresetNameHint => 'Es. Strada di notte';

  @override
  String savePresetDefaultName(String date) {
    return 'Configurazione $date';
  }

  @override
  String get savePresetSaved => 'Preset salvato';

  @override
  String get savePresetEmptyName => 'Inserisci un nome';

  @override
  String get savePresetSave => 'Salva';

  @override
  String get patternSingle => 'Singolo';

  @override
  String get patternDouble => 'Doppio';

  @override
  String get patternTriple => 'Triplo';

  @override
  String get patternSos => 'SOS';

  @override
  String get patternSteady => 'Fisso';

  @override
  String get effectSolid => 'Pieno';

  @override
  String get effectPulse => 'Pulsazione';

  @override
  String get effectStrobe => 'Strobo';

  @override
  String get effectAlternate => 'Alternato';

  @override
  String get effectSweep => 'Scansione';

  @override
  String get effectRainbow => 'Arcobaleno';

  @override
  String get syncInPhase => 'In fase';

  @override
  String get syncCounterPhase => 'Controfase';

  @override
  String get syncIndependent => 'Indipendente';

  @override
  String get colorWhite => 'Bianco';

  @override
  String get colorAmber => 'Ambra';

  @override
  String get colorRed => 'Rosso';

  @override
  String get colorGreen => 'Verde';

  @override
  String get colorCyan => 'Ciano';

  @override
  String get colorMagenta => 'Magenta';

  @override
  String get timeoutNone => 'Mai';

  @override
  String timeoutMinutes(int count) {
    return '$count min';
  }

  @override
  String get presetsTitle => 'Preset';

  @override
  String get presetsBuiltIn => 'Predefiniti';

  @override
  String get presetsCustom => 'Personalizzati';

  @override
  String get presetPedestrian => 'Pedone';

  @override
  String get presetPedestrianDesc => 'Bianco 2 Hz, flash in fase';

  @override
  String get presetBike => 'Bici / monopattino';

  @override
  String get presetBikeDesc => 'Ambra pulsante, torcia fissa';

  @override
  String get presetBreakdown => 'Auto in panne';

  @override
  String get presetBreakdownDesc => 'Rosso e ambra alternati';

  @override
  String get presetEmergency => 'Emergenza';

  @override
  String get presetEmergencyDesc => 'SOS su flash e schermo';

  @override
  String get presetIlluminate => 'Illuminazione';

  @override
  String get presetIlluminateDesc => 'Solo torcia fissa';

  @override
  String get presetWorksite => 'Cantiere';

  @override
  String get presetWorksiteDesc => 'Ambra strobo, impulso corto';

  @override
  String get presetCustom => 'Personalizzato';

  @override
  String get presetApply => 'Applica';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsLanguageSystem => 'Sistema';

  @override
  String get settingsLanguageItalian => 'Italiano';

  @override
  String get settingsLanguageEnglish => 'Inglese';

  @override
  String get settingsBrightnessCap => 'Limite luminosità';

  @override
  String get settingsBrightnessCapDesc => 'Massimo consentito per lo schermo';

  @override
  String get settingsKeepAwake => 'Mantieni schermo acceso';

  @override
  String get settingsKeepAwakeDesc =>
      'Evita che il display si spenga durante l\'uso';

  @override
  String get settingsSafety => 'Avvisi di sicurezza';

  @override
  String get settingsSafetyDesc => 'Rivedi fotosensibilità e uso stradale';

  @override
  String get settingsAbout => 'Informazioni';

  @override
  String settingsVersion(String version) {
    return 'Versione $version';
  }

  @override
  String get settingsReset => 'Ripristina impostazioni';

  @override
  String get settingsResetConfirm =>
      'Ripristinare tutte le impostazioni ai valori predefiniti?';

  @override
  String get safetyTitle => 'Prima di iniziare';

  @override
  String get safetyPhotosensitivityTitle => 'Fotosensibilità';

  @override
  String get safetyPhotosensitivityBody =>
      'Il lampeggio rapido può causare crisi epilettiche in persone fotosensibili. Non puntare il flash o lo schermo verso gli occhi di qualcuno.';

  @override
  String get safetyRoadTitle => 'Uso sulla strada';

  @override
  String get safetyRoadBody =>
      'LightBeacon non è un dispositivo di segnalazione omologato. Non sostituisce giubbotto riflettente, luci di posizione o segnaletica. Usalo come supporto, non come unica misura di sicurezza.';

  @override
  String get safetyLawTitle => 'Colori consentiti';

  @override
  String get safetyLawBody =>
      'Il lampeggio blu è riservato ai veicoli di emergenza. LightBeacon non include il blu tra i colori disponibili.';

  @override
  String get safetyBatteryTitle => 'Batteria e calore';

  @override
  String get safetyBatteryBody =>
      'Flash e schermo al massimo consumano molta batteria e scaldano il dispositivo. L\'app riduce automaticamente la luminosità se necessario.';

  @override
  String get safetyAccept => 'Ho capito';

  @override
  String get warningHighFrequencyTitle => 'Frequenza elevata';

  @override
  String get warningHighFrequencyBody =>
      'Oltre 3 lampeggi al secondo il rischio per le persone fotosensibili aumenta. Continuare?';

  @override
  String get warningContinue => 'Continua';

  @override
  String get commonCancel => 'Annulla';

  @override
  String get commonOk => 'OK';

  @override
  String get commonClose => 'Chiudi';

  @override
  String get commonReset => 'Ripristina';

  @override
  String get errorTorchUnavailable =>
      'Questo dispositivo non ha un flash utilizzabile.';

  @override
  String get errorTorchBusy => 'Il flash è in uso da un\'altra app.';

  @override
  String get errorGeneric => 'Si è verificato un errore.';
}
