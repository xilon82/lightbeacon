import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In it, this message translates to:
  /// **'LightBeacon'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In it, this message translates to:
  /// **'Fatti vedere. Anche al buio.'**
  String get appTagline;

  /// No description provided for @homeSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Scegli come farti vedere'**
  String get homeSubtitle;

  /// No description provided for @homeTip.
  ///
  /// In it, this message translates to:
  /// **'Tieni il telefono all\'altezza del petto, con lo schermo verso il traffico.'**
  String get homeTip;

  /// No description provided for @modeTorchTitle.
  ///
  /// In it, this message translates to:
  /// **'Torcia fissa'**
  String get modeTorchTitle;

  /// No description provided for @modeTorchSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Illumina il cammino'**
  String get modeTorchSubtitle;

  /// No description provided for @modeStrobeTitle.
  ///
  /// In it, this message translates to:
  /// **'Strobo'**
  String get modeStrobeTitle;

  /// No description provided for @modeStrobeSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Flash e schermo lampeggianti'**
  String get modeStrobeSubtitle;

  /// No description provided for @modeScreenTitle.
  ///
  /// In it, this message translates to:
  /// **'Solo schermo'**
  String get modeScreenTitle;

  /// No description provided for @modeScreenSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Colore ed effetti, senza flash'**
  String get modeScreenSubtitle;

  /// No description provided for @modeSosTitle.
  ///
  /// In it, this message translates to:
  /// **'SOS'**
  String get modeSosTitle;

  /// No description provided for @modeSosSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Segnale di emergenza'**
  String get modeSosSubtitle;

  /// No description provided for @modeComboTitle.
  ///
  /// In it, this message translates to:
  /// **'Strada'**
  String get modeComboTitle;

  /// No description provided for @modeComboSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Flash e schermo insieme'**
  String get modeComboSubtitle;

  /// No description provided for @navPresets.
  ///
  /// In it, this message translates to:
  /// **'Preset'**
  String get navPresets;

  /// No description provided for @navSettings.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get navSettings;

  /// No description provided for @beaconStop.
  ///
  /// In it, this message translates to:
  /// **'Ferma'**
  String get beaconStop;

  /// No description provided for @beaconControls.
  ///
  /// In it, this message translates to:
  /// **'Controlli'**
  String get beaconControls;

  /// No description provided for @beaconTapHint.
  ///
  /// In it, this message translates to:
  /// **'Tocca per mostrare i controlli'**
  String get beaconTapHint;

  /// No description provided for @beaconTorchUnavailable.
  ///
  /// In it, this message translates to:
  /// **'Flash non disponibile su questo dispositivo'**
  String get beaconTorchUnavailable;

  /// No description provided for @beaconTorchError.
  ///
  /// In it, this message translates to:
  /// **'Impossibile controllare il flash'**
  String get beaconTorchError;

  /// No description provided for @beaconJitterWarning.
  ///
  /// In it, this message translates to:
  /// **'Lampeggio instabile: frequenza ridotta'**
  String get beaconJitterWarning;

  /// No description provided for @beaconTimeoutReached.
  ///
  /// In it, this message translates to:
  /// **'Spegnimento automatico'**
  String get beaconTimeoutReached;

  /// No description provided for @controlFrequency.
  ///
  /// In it, this message translates to:
  /// **'Frequenza'**
  String get controlFrequency;

  /// No description provided for @controlFrequencyValue.
  ///
  /// In it, this message translates to:
  /// **'{value} Hz'**
  String controlFrequencyValue(String value);

  /// No description provided for @controlDuty.
  ///
  /// In it, this message translates to:
  /// **'Durata impulso'**
  String get controlDuty;

  /// No description provided for @controlDutyValue.
  ///
  /// In it, this message translates to:
  /// **'{value}%'**
  String controlDutyValue(String value);

  /// No description provided for @controlPattern.
  ///
  /// In it, this message translates to:
  /// **'Pattern'**
  String get controlPattern;

  /// No description provided for @controlEffect.
  ///
  /// In it, this message translates to:
  /// **'Effetto schermo'**
  String get controlEffect;

  /// No description provided for @controlPrimaryColor.
  ///
  /// In it, this message translates to:
  /// **'Colore'**
  String get controlPrimaryColor;

  /// No description provided for @controlSecondaryColor.
  ///
  /// In it, this message translates to:
  /// **'Secondo colore'**
  String get controlSecondaryColor;

  /// No description provided for @controlBrightness.
  ///
  /// In it, this message translates to:
  /// **'Luminosità schermo'**
  String get controlBrightness;

  /// No description provided for @controlBrightnessValue.
  ///
  /// In it, this message translates to:
  /// **'{value}%'**
  String controlBrightnessValue(String value);

  /// No description provided for @controlSync.
  ///
  /// In it, this message translates to:
  /// **'Sincronia'**
  String get controlSync;

  /// No description provided for @controlTimeout.
  ///
  /// In it, this message translates to:
  /// **'Spegnimento automatico'**
  String get controlTimeout;

  /// No description provided for @controlSectionFlash.
  ///
  /// In it, this message translates to:
  /// **'Lampeggio'**
  String get controlSectionFlash;

  /// No description provided for @controlSectionScreen.
  ///
  /// In it, this message translates to:
  /// **'Schermo'**
  String get controlSectionScreen;

  /// No description provided for @controlSectionTiming.
  ///
  /// In it, this message translates to:
  /// **'Tempi'**
  String get controlSectionTiming;

  /// No description provided for @controlFrequencyDesc.
  ///
  /// In it, this message translates to:
  /// **'Quanti lampeggi al secondo'**
  String get controlFrequencyDesc;

  /// No description provided for @controlDutyDesc.
  ///
  /// In it, this message translates to:
  /// **'Quanto resta acceso in ogni lampeggio'**
  String get controlDutyDesc;

  /// No description provided for @controlPatternDesc.
  ///
  /// In it, this message translates to:
  /// **'Forma del lampeggio'**
  String get controlPatternDesc;

  /// No description provided for @controlEffectDesc.
  ///
  /// In it, this message translates to:
  /// **'Come si muove il colore sullo schermo'**
  String get controlEffectDesc;

  /// No description provided for @controlBrightnessDesc.
  ///
  /// In it, this message translates to:
  /// **'Luminosità del display durante l\'uso'**
  String get controlBrightnessDesc;

  /// No description provided for @controlSyncDesc.
  ///
  /// In it, this message translates to:
  /// **'Come schermo e flash si alternano'**
  String get controlSyncDesc;

  /// No description provided for @controlTimeoutDesc.
  ///
  /// In it, this message translates to:
  /// **'Spegnimento automatico dopo'**
  String get controlTimeoutDesc;

  /// No description provided for @controlTorchToggle.
  ///
  /// In it, this message translates to:
  /// **'Flash'**
  String get controlTorchToggle;

  /// No description provided for @controlScreenToggle.
  ///
  /// In it, this message translates to:
  /// **'Schermo'**
  String get controlScreenToggle;

  /// No description provided for @controlTorchToggleDesc.
  ///
  /// In it, this message translates to:
  /// **'Usa il LED posteriore'**
  String get controlTorchToggleDesc;

  /// No description provided for @controlScreenToggleDesc.
  ///
  /// In it, this message translates to:
  /// **'Usa il display come luce colorata'**
  String get controlScreenToggleDesc;

  /// No description provided for @hintSteadyTorch.
  ///
  /// In it, this message translates to:
  /// **'Il flash resta acceso fisso: frequenza e durata non si applicano.'**
  String get hintSteadyTorch;

  /// No description provided for @hintSteadyScreen.
  ///
  /// In it, this message translates to:
  /// **'Con il flash fisso Strobo e Alternato non hanno un ciclo da seguire: lo schermo resta di un colore pieno.'**
  String get hintSteadyScreen;

  /// No description provided for @hintTorchOff.
  ///
  /// In it, this message translates to:
  /// **'Flash disattivato in questa modalità.'**
  String get hintTorchOff;

  /// No description provided for @hintScreenOff.
  ///
  /// In it, this message translates to:
  /// **'Schermo disattivato in questa modalità.'**
  String get hintScreenOff;

  /// No description provided for @hintSyncNeedsBoth.
  ///
  /// In it, this message translates to:
  /// **'Si applica solo con flash e schermo entrambi attivi e animati.'**
  String get hintSyncNeedsBoth;

  /// No description provided for @savePresetTitle.
  ///
  /// In it, this message translates to:
  /// **'Salva configurazione'**
  String get savePresetTitle;

  /// No description provided for @savePresetAction.
  ///
  /// In it, this message translates to:
  /// **'Salva come preset'**
  String get savePresetAction;

  /// No description provided for @savePresetNameLabel.
  ///
  /// In it, this message translates to:
  /// **'Nome'**
  String get savePresetNameLabel;

  /// No description provided for @savePresetNameHint.
  ///
  /// In it, this message translates to:
  /// **'Es. Strada di notte'**
  String get savePresetNameHint;

  /// No description provided for @savePresetDefaultName.
  ///
  /// In it, this message translates to:
  /// **'Configurazione {date}'**
  String savePresetDefaultName(String date);

  /// No description provided for @savePresetSaved.
  ///
  /// In it, this message translates to:
  /// **'Preset salvato'**
  String get savePresetSaved;

  /// No description provided for @savePresetEmptyName.
  ///
  /// In it, this message translates to:
  /// **'Inserisci un nome'**
  String get savePresetEmptyName;

  /// No description provided for @savePresetSave.
  ///
  /// In it, this message translates to:
  /// **'Salva'**
  String get savePresetSave;

  /// No description provided for @patternSingle.
  ///
  /// In it, this message translates to:
  /// **'Singolo'**
  String get patternSingle;

  /// No description provided for @patternDouble.
  ///
  /// In it, this message translates to:
  /// **'Doppio'**
  String get patternDouble;

  /// No description provided for @patternTriple.
  ///
  /// In it, this message translates to:
  /// **'Triplo'**
  String get patternTriple;

  /// No description provided for @patternSos.
  ///
  /// In it, this message translates to:
  /// **'SOS'**
  String get patternSos;

  /// No description provided for @patternSteady.
  ///
  /// In it, this message translates to:
  /// **'Fisso'**
  String get patternSteady;

  /// No description provided for @effectSolid.
  ///
  /// In it, this message translates to:
  /// **'Pieno'**
  String get effectSolid;

  /// No description provided for @effectPulse.
  ///
  /// In it, this message translates to:
  /// **'Pulsazione'**
  String get effectPulse;

  /// No description provided for @effectStrobe.
  ///
  /// In it, this message translates to:
  /// **'Strobo'**
  String get effectStrobe;

  /// No description provided for @effectAlternate.
  ///
  /// In it, this message translates to:
  /// **'Alternato'**
  String get effectAlternate;

  /// No description provided for @effectSweep.
  ///
  /// In it, this message translates to:
  /// **'Scansione'**
  String get effectSweep;

  /// No description provided for @effectRainbow.
  ///
  /// In it, this message translates to:
  /// **'Arcobaleno'**
  String get effectRainbow;

  /// No description provided for @syncInPhase.
  ///
  /// In it, this message translates to:
  /// **'In fase'**
  String get syncInPhase;

  /// No description provided for @syncCounterPhase.
  ///
  /// In it, this message translates to:
  /// **'Controfase'**
  String get syncCounterPhase;

  /// No description provided for @syncIndependent.
  ///
  /// In it, this message translates to:
  /// **'Indipendente'**
  String get syncIndependent;

  /// No description provided for @colorWhite.
  ///
  /// In it, this message translates to:
  /// **'Bianco'**
  String get colorWhite;

  /// No description provided for @colorAmber.
  ///
  /// In it, this message translates to:
  /// **'Ambra'**
  String get colorAmber;

  /// No description provided for @colorRed.
  ///
  /// In it, this message translates to:
  /// **'Rosso'**
  String get colorRed;

  /// No description provided for @colorGreen.
  ///
  /// In it, this message translates to:
  /// **'Verde'**
  String get colorGreen;

  /// No description provided for @colorCyan.
  ///
  /// In it, this message translates to:
  /// **'Ciano'**
  String get colorCyan;

  /// No description provided for @colorMagenta.
  ///
  /// In it, this message translates to:
  /// **'Magenta'**
  String get colorMagenta;

  /// No description provided for @timeoutNone.
  ///
  /// In it, this message translates to:
  /// **'Mai'**
  String get timeoutNone;

  /// No description provided for @timeoutMinutes.
  ///
  /// In it, this message translates to:
  /// **'{count} min'**
  String timeoutMinutes(int count);

  /// No description provided for @presetsTitle.
  ///
  /// In it, this message translates to:
  /// **'Preset'**
  String get presetsTitle;

  /// No description provided for @presetsBuiltIn.
  ///
  /// In it, this message translates to:
  /// **'Predefiniti'**
  String get presetsBuiltIn;

  /// No description provided for @presetsCustom.
  ///
  /// In it, this message translates to:
  /// **'Personalizzati'**
  String get presetsCustom;

  /// No description provided for @presetPedestrian.
  ///
  /// In it, this message translates to:
  /// **'Pedone'**
  String get presetPedestrian;

  /// No description provided for @presetPedestrianDesc.
  ///
  /// In it, this message translates to:
  /// **'Bianco 2 Hz, flash in fase'**
  String get presetPedestrianDesc;

  /// No description provided for @presetBike.
  ///
  /// In it, this message translates to:
  /// **'Bici / monopattino'**
  String get presetBike;

  /// No description provided for @presetBikeDesc.
  ///
  /// In it, this message translates to:
  /// **'Ambra pulsante, torcia fissa'**
  String get presetBikeDesc;

  /// No description provided for @presetBreakdown.
  ///
  /// In it, this message translates to:
  /// **'Auto in panne'**
  String get presetBreakdown;

  /// No description provided for @presetBreakdownDesc.
  ///
  /// In it, this message translates to:
  /// **'Rosso e ambra alternati'**
  String get presetBreakdownDesc;

  /// No description provided for @presetEmergency.
  ///
  /// In it, this message translates to:
  /// **'Emergenza'**
  String get presetEmergency;

  /// No description provided for @presetEmergencyDesc.
  ///
  /// In it, this message translates to:
  /// **'SOS su flash e schermo'**
  String get presetEmergencyDesc;

  /// No description provided for @presetIlluminate.
  ///
  /// In it, this message translates to:
  /// **'Illuminazione'**
  String get presetIlluminate;

  /// No description provided for @presetIlluminateDesc.
  ///
  /// In it, this message translates to:
  /// **'Solo torcia fissa'**
  String get presetIlluminateDesc;

  /// No description provided for @presetWorksite.
  ///
  /// In it, this message translates to:
  /// **'Cantiere'**
  String get presetWorksite;

  /// No description provided for @presetWorksiteDesc.
  ///
  /// In it, this message translates to:
  /// **'Ambra strobo, impulso corto'**
  String get presetWorksiteDesc;

  /// No description provided for @presetCustom.
  ///
  /// In it, this message translates to:
  /// **'Personalizzato'**
  String get presetCustom;

  /// No description provided for @presetApply.
  ///
  /// In it, this message translates to:
  /// **'Applica'**
  String get presetApply;

  /// No description provided for @settingsTitle.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In it, this message translates to:
  /// **'Lingua'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In it, this message translates to:
  /// **'Sistema'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageItalian.
  ///
  /// In it, this message translates to:
  /// **'Italiano'**
  String get settingsLanguageItalian;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In it, this message translates to:
  /// **'Inglese'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsBrightnessCap.
  ///
  /// In it, this message translates to:
  /// **'Limite luminosità'**
  String get settingsBrightnessCap;

  /// No description provided for @settingsBrightnessCapDesc.
  ///
  /// In it, this message translates to:
  /// **'Massimo consentito per lo schermo'**
  String get settingsBrightnessCapDesc;

  /// No description provided for @settingsKeepAwake.
  ///
  /// In it, this message translates to:
  /// **'Mantieni schermo acceso'**
  String get settingsKeepAwake;

  /// No description provided for @settingsKeepAwakeDesc.
  ///
  /// In it, this message translates to:
  /// **'Evita che il display si spenga durante l\'uso'**
  String get settingsKeepAwakeDesc;

  /// No description provided for @settingsSafety.
  ///
  /// In it, this message translates to:
  /// **'Avvisi di sicurezza'**
  String get settingsSafety;

  /// No description provided for @settingsSafetyDesc.
  ///
  /// In it, this message translates to:
  /// **'Rivedi fotosensibilità e uso stradale'**
  String get settingsSafetyDesc;

  /// No description provided for @settingsAbout.
  ///
  /// In it, this message translates to:
  /// **'Informazioni'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In it, this message translates to:
  /// **'Versione {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsReset.
  ///
  /// In it, this message translates to:
  /// **'Ripristina impostazioni'**
  String get settingsReset;

  /// No description provided for @settingsResetConfirm.
  ///
  /// In it, this message translates to:
  /// **'Ripristinare tutte le impostazioni ai valori predefiniti?'**
  String get settingsResetConfirm;

  /// No description provided for @safetyTitle.
  ///
  /// In it, this message translates to:
  /// **'Prima di iniziare'**
  String get safetyTitle;

  /// No description provided for @safetyPhotosensitivityTitle.
  ///
  /// In it, this message translates to:
  /// **'Fotosensibilità'**
  String get safetyPhotosensitivityTitle;

  /// No description provided for @safetyPhotosensitivityBody.
  ///
  /// In it, this message translates to:
  /// **'Il lampeggio rapido può causare crisi epilettiche in persone fotosensibili. Non puntare il flash o lo schermo verso gli occhi di qualcuno.'**
  String get safetyPhotosensitivityBody;

  /// No description provided for @safetyRoadTitle.
  ///
  /// In it, this message translates to:
  /// **'Uso sulla strada'**
  String get safetyRoadTitle;

  /// No description provided for @safetyRoadBody.
  ///
  /// In it, this message translates to:
  /// **'LightBeacon non è un dispositivo di segnalazione omologato. Non sostituisce giubbotto riflettente, luci di posizione o segnaletica. Usalo come supporto, non come unica misura di sicurezza.'**
  String get safetyRoadBody;

  /// No description provided for @safetyLawTitle.
  ///
  /// In it, this message translates to:
  /// **'Colori consentiti'**
  String get safetyLawTitle;

  /// No description provided for @safetyLawBody.
  ///
  /// In it, this message translates to:
  /// **'Il lampeggio blu è riservato ai veicoli di emergenza. LightBeacon non include il blu tra i colori disponibili.'**
  String get safetyLawBody;

  /// No description provided for @safetyBatteryTitle.
  ///
  /// In it, this message translates to:
  /// **'Batteria e calore'**
  String get safetyBatteryTitle;

  /// No description provided for @safetyBatteryBody.
  ///
  /// In it, this message translates to:
  /// **'Flash e schermo al massimo consumano molta batteria e scaldano il dispositivo. L\'app riduce automaticamente la luminosità se necessario.'**
  String get safetyBatteryBody;

  /// No description provided for @safetyAccept.
  ///
  /// In it, this message translates to:
  /// **'Ho capito'**
  String get safetyAccept;

  /// No description provided for @warningHighFrequencyTitle.
  ///
  /// In it, this message translates to:
  /// **'Frequenza elevata'**
  String get warningHighFrequencyTitle;

  /// No description provided for @warningHighFrequencyBody.
  ///
  /// In it, this message translates to:
  /// **'Oltre 3 lampeggi al secondo il rischio per le persone fotosensibili aumenta. Continuare?'**
  String get warningHighFrequencyBody;

  /// No description provided for @warningContinue.
  ///
  /// In it, this message translates to:
  /// **'Continua'**
  String get warningContinue;

  /// No description provided for @commonCancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get commonCancel;

  /// No description provided for @commonOk.
  ///
  /// In it, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonClose.
  ///
  /// In it, this message translates to:
  /// **'Chiudi'**
  String get commonClose;

  /// No description provided for @commonReset.
  ///
  /// In it, this message translates to:
  /// **'Ripristina'**
  String get commonReset;

  /// No description provided for @errorTorchUnavailable.
  ///
  /// In it, this message translates to:
  /// **'Questo dispositivo non ha un flash utilizzabile.'**
  String get errorTorchUnavailable;

  /// No description provided for @errorTorchBusy.
  ///
  /// In it, this message translates to:
  /// **'Il flash è in uso da un\'altra app.'**
  String get errorTorchBusy;

  /// No description provided for @errorGeneric.
  ///
  /// In it, this message translates to:
  /// **'Si è verificato un errore.'**
  String get errorGeneric;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
