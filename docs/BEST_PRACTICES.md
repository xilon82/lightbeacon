# Best practice per tecnologia — stato e debiti

Questo file **registra** dove il repository si discosta dalle best practice
delle tecnologie che usa, e cosa si è deciso di fare. Non duplica i vincoli
operativi (stanno in [`.clinerules`](../.clinerules)), la mappa tecnica
([`AGENTS.md`](../AGENTS.md)) né la documentazione utente
([`README.md`](../README.md)).

Come si usa: quando aggiungi una tecnologia, una riga per ogni pratica che
conta; quando scopri uno scostamento, non lo correggi in silenzio — lo scrivi
qui con la decisione presa. Le voci chiuse si cancellano, non si accumulano.

Legenda: ✅ rispettato · ⚠️ parziale o scelta consapevole da rivalutare ·
❌ da fare.

---

## Flutter e Dart (3.41.2 / 3.11.0)

| Pratica | Stato | Evidenza | Azione |
|---|---|---|---|
| `flutter analyze` pulito | ✅ | `No issues found!` | niente |
| `flutter_lints` come base | ✅ | `analysis_options.yaml` include `package:flutter_lints/flutter.yaml` | valutare regole extra (`prefer_single_quotes`) solo se si riformatta |
| Codice formattato con `dart format` | ✅ | `dart format --output=none --set-exit-if-changed lib test` pulito (stile *tall* di Dart 3.11); step "Verify formatting" in CI | niente |
| Immutabilità e `const` | ✅ | modelli `const`/`final` con `copyWith`; widget `const` dove possibile | niente |
| API non deprecate | ✅ | `withValues(alpha:)`, `MediaQuery.disableAnimationsOf`, `PopScope.onPopInvokedWithResult`, `WidgetStateProperty`, `Color.toARGB32()` | niente |
| Lifecycle corretto | ✅ | `Ticker` creato in `initState`, `dispose()` chiamato; `mounted`/`ref.mounted` dopo ogni `await` | niente |
| Nessun `print` nel codice applicativo | ✅ | `print` solo in `tools/generate_icons.py` (CLI) | niente |
| Accessibilità | ⚠️ | `Semantics` sulle etichette colore, target ≥ 56 dp (`AppTheme.minTouchTarget`), rispetto di `disableAnimations` | **D4**: prova TalkBack su device non registrata |

---

## Riverpod 3.3

| Pratica | Stato | Evidenza | Azione |
|---|---|---|---|
| `Notifier`/`NotifierProvider` invece di `StateNotifier` | ✅ | `lib/providers/providers.dart` | niente |
| Stato immutabile con `copyWith` | ✅ | `BeaconSessionState`, `BeaconConfig`, `AppSettings` | niente |
| `ref.mounted` dopo un `await` | ✅ | `_probeTorch`, `_onEngineError`, `_onTimeout` | niente |
| Fire-and-forget con `unawaited` | ✅ | `_persist`, `_setWakelock`, `updateConfig` | niente |
| Provider sovrascritti nei test | ✅ | `torchControllerProvider`, `screenControllerProvider`, `sharedPreferencesProvider` | niente |
| Stato senza riferimenti mutabili condivisi | ⚠️ | `BeaconSessionNotifier.engine` è un `late final` esposto: `BeaconPage` legge `engine.startedAt` e `engine.cycle` | **D5**: valutare se portare `startedAt`/`cycle` dentro `BeaconSessionState` |
| Codegen (`riverpod_generator`) | ⚠️ | provider scritti a mano | scelta consapevole: meno dipendenze, meno magia. Si rivaluta se i provider superano la decina |

---

## Localizzazione (flutter_localizations + ARB)

| Pratica | Stato | Evidenza | Azione |
|---|---|---|---|
| Italiano come template | ✅ | `l10n.yaml` → `template-arb-file: app_it.arb` | niente |
| Parità delle chiavi | ✅ | 136 chiavi per `app_it.arb` e 136 per `app_en.arb`, nessuna differenza | niente |
| Nessuna stringa hardcoded nella UI | ✅ | grep di `Text('…')` in `lib/`: nessun risultato | niente |
| File generati aggiornati | ✅ | committati in `lib/l10n/`, CI esegue `git diff --exit-code lib/l10n/` | niente |
| Descrizioni `@chiave` per i traduttori | ⚠️ | presenti solo per 6 chiavi su 136 (`controlFrequencyValue`, `controlDutyValue`, `controlBrightnessValue`, `savePresetDefaultName`, `timeoutMinutes`, `settingsVersion`) | **D2**: obbligatorie per le chiavi nuove con placeholder, niente retrofit massivo |
| Locale di sistema + override | ✅ | `AppSettings.localeCode`, `LightBeaconApp.locale` | niente |

---

## Persistenza (shared_preferences 2.5)

| Pratica | Stato | Evidenza | Azione |
|---|---|---|---|
| Dati versionati | ✅ | `schemaVersion` in ogni `toJson`, chiavi `app_settings_v1` / `last_config_v1` / `custom_presets_v1` | niente |
| Degradazione su dati corrotti | ✅ | `SettingsRepository` fa `try/catch` e torna ai default invece di crashare | niente |
| Clamp in lettura | ✅ | `BeaconConfig.fromJson`, `AppSettings.fromJson` | niente |
| API raccomandata dal pacchetto | ⚠️ | usa l'API legacy `SharedPreferences.getInstance()`; il pacchetto 2.5 raccomanda `SharedPreferencesAsync`/`SharedPreferencesWithCache` | **D1**: migrare quando si tocca la persistenza |
| Nessun dato sensibile | ✅ | solo preferenze e configurazioni | niente |

---

## Plugin di piattaforma (torch_light, wakelock_plus, screen_brightness)

| Pratica | Stato | Evidenza | Azione |
|---|---|---|---|
| Versioni pinnate con motivazione | ✅ | `torch_light: 1.1.0`, `wakelock_plus: 1.7.0` + commento nel `pubspec.yaml` (le release nuove richiedono Flutter ≥ 3.44) | niente |
| Permessi minimi | ✅ | nessun `CAMERA` (`setTorchMode` non lo richiede); `WAKE_LOCK` arriva dal manifest di `wakelock_plus`; luminosità solo applicativa | niente |
| Accesso mediato da un seam | ✅ | `TorchController`, `ScreenController` + varianti `Noop*` | niente |
| Errori di canale non bloccanti | ✅ | `_setWakelock` fire-and-forget, `ScreenController` in `try/catch`, `BeaconEngine.onError` | niente |
| Funzionamento a schermo spento | ❌ | nessun foreground service: a schermo spento il beacon si ferma | fase 4 di `docs/PLAN.md` |

---

## Testing (flutter_test)

| Pratica | Stato | Evidenza | Azione |
|---|---|---|---|
| Test unitari sul dominio | ✅ | `test/engine/` (pattern, fase, anti-drift, jitter), `test/domain/` (serializzazione, preset) | niente |
| Test widget senza plugin reali | ✅ | `NoopTorchController`, `NoopScreenController`, `SharedPreferences.setMockInitialValues` | niente |
| Tempo controllabile | ✅ | `FakeClock` + `TimerFactory` in `lib/core/clock/clock.dart` | niente |
| Niente `pumpAndSettle` con `Ticker` attivo | ✅ | solo `tester.pump()` con durate esplicite | niente |
| Test di regressione per ogni bug | ✅ | i bug in `docs/PLAN.md` §13-bis hanno test dedicati | niente |
| Golden test del rendering | ⚠️ | `docs/PLAN.md` §14 li prevede; oggi il painter è verificato campionando il pixel in alto a sinistra | **D3**: golden su fasi note, se il rendering diventa più complesso |
| Copertura misurata | ⚠️ | `flutter test --coverage` non è in CI | **D6**: valutare `--coverage` + soglia, senza bloccare la build |

---

## CI/CD (GitHub Actions)

| Pratica | Stato | Evidenza | Azione |
|---|---|---|---|
| Versioni fissate | ✅ | `actions/checkout@v4`, `subosito/flutter-action@v2` con `flutter-version: 3.41.2`, `actions/setup-java@v4` (17) | niente |
| Cache delle dipendenze | ✅ | `cache: true` in `flutter-action` | niente |
| Artefatti generati verificati | ✅ | `flutter gen-l10n` + `git diff --exit-code lib/l10n/` | niente |
| Smoke build | ✅ | `flutter build apk --debug` + upload artefatto | niente |
| Gate di formato | ✅ | step "Verify formatting": `dart format --output=none --set-exit-if-changed lib test` | niente |
| Info dell'analyzer bloccanti | ✅ | `flutter analyze --fatal-infos` in CI (verificato in locale: zero issue) | niente |
| Permessi minimi del workflow | ✅ | `permissions: contents: read` | niente |
| Cancellazione dei run superati | ✅ | `concurrency` con `cancel-in-progress: true` | niente |
| Trigger sui branch di lavoro | ✅ | `main` e `release/**` per push e pull request | niente |
| Aggiornamento di dipendenze e action | ✅ | `.github/dependabot.yml`: weekly su `pub` e `github-actions`, con `ignore` su `torch_light`/`wakelock_plus` | niente |

---

## Packaging Android

| Pratica | Stato | Evidenza | Azione |
|---|---|---|---|
| SDK coerenti con il target | ✅ | `minSdk` 24 / `targetSdk` 36 dai default Flutter, JDK 17 | niente |
| Orientamento bloccato | ✅ | `android:screenOrientation="portrait"` nel manifest | niente |
| Icona adattiva + splash | ✅ | `mipmap-anydpi-v26/`, `values-v31/`, layer monocromatico per Android 13+ | niente |
| Firma di release | ❌ | `build.gradle.kts` firma la release con le chiavi di debug | fase 6 di `docs/PLAN.md` |
| `applicationId` definitivo | ⚠️ | `com.lightbeacon.light_beacon`, con TODO nel gradle | decidere prima della pubblicazione |

---

## Strumenti Python (tools/)

| Pratica | Stato | Evidenza | Azione |
|---|---|---|---|
| Script eseguibile e documentato | ✅ | docstring con comandi e output, `main()` + `if __name__ == "__main__"` | niente |
| `pathlib` invece di `os.path` | ⚠️ | `tools/generate_icons.py` usa `os.path.join` | **D7**: convertire quando lo si tocca |
| Ignore degli artefatti Python | ⚠️ | `.gitignore` copre `*.pyc` ma non `__pycache__/` | **D7**: aggiungere la voce |
| Dipendenze dichiarate | ⚠️ | Pillow è citato nel README, ma nessun `requirements.txt` | **D7**: `tools/requirements.txt` |

---

## Debiti aperti

| # | Debito | Azione | Dove |
|---|---|---|---|
| D1 | `shared_preferences` su API legacy | migrare a `SharedPreferencesAsync`/`WithCache` | §Persistenza |
| D2 | Descrizioni `@chiave` ARB quasi assenti | obbligatorie per le chiavi nuove | §Localizzazione |
| D3 | Nessun golden test sul painter | golden su fasi note | §Testing |
| D4 | Accessibilità non verificata con TalkBack | prova su device e annotazione | §Flutter |
| D5 | `engine` esposto dal notifier | valutare `startedAt`/`cycle` nello stato | §Riverpod |
| D6 | Copertura non misurata | `flutter test --coverage` in CI | §Testing |
| D7 | `tools/generate_icons.py` fuori standard (`os.path`, Pillow non dichiarato, `__pycache__/`) | conversione a `pathlib` + requirements + ignore | §Strumenti Python |

