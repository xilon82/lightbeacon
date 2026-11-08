# AGENTS.md

Mappa tecnica del repository, per agenti AI e per chi contribuisce.

**I vincoli operativi non sono qui: stanno in [`.clinerules`](.clinerules).**
Lo stato delle best practice e i debiti aperti sono in
[docs/BEST_PRACTICES.md](docs/BEST_PRACTICES.md); il perché delle scelte
tecniche, la roadmap e i bug già incontrati in [docs/PLAN.md](docs/PLAN.md).

---

## Cosa fa il progetto

LightBeacon trasforma un telefono Android in un segnale di visibilità: flash
lampeggiante, schermo colorato con effetti, torcia fissa. Un solo motore di
lampeggio, due uscite fisiche (LED e display) pilotate da clock separati.

---

## Architettura

| Layer | Contenuto | Può dipendere da |
|---|---|---|
| `core/` | `Clock` monotono, tema | — |
| `domain/` | engine (edge clock, pattern, fase, jitter), modelli, repository | `core` |
| `platform/` | seam `TorchController`, `ScreenController` | plugin di piattaforma |
| `providers/` | stato Riverpod, sessione beacon | `core`, `domain`, `platform` |
| `features/` | UI: home, beacon, presets, settings, onboarding | `core`, `domain`, `l10n`, `providers` |
| `l10n/` | ARB it/en + file generati | — |

Vincoli di dipendenza verificati nel codice:

- `domain/` non importa `platform/`, `providers/` né `features/`. Unica
  eccezione consapevole: `beacon_config.dart` importa `dart:ui` per serializzare
  i `Color`.
- `features/` non importa mai `platform/`: parla solo con i provider.
- `providers/providers.dart` è l'unico punto che costruisce i controller di
  piattaforma (`PluginTorchController`, `PluginScreenController`).

### Due clock separati

- **Edge clock** (`BeaconEngine`): pianifica i fronti della torcia su
  un'origine assoluta, `startedAt + n * cycle + offset`. Il jitter non si somma.
- **Render clock** (`Ticker` in `BeaconPage`): ricalcola la fase da
  `engine.startedAt` e disegna. Non comanda mai la torcia.

I pattern sono frazioni di ciclo (`PatternSegment.fraction`), non millisecondi:
cambiare la frequenza riscala tutto coerentemente. Il perché in `docs/PLAN.md`
§4.

---

## Invarianti di dominio

| Invariante | Dove è imposto | Test che lo difende |
|---|---|---|
| Nessun colore blu | `BeaconPalette` non lo espone | `test/domain/built_in_presets_test.dart` |
| Frequenza 0.5–10 Hz | `BeaconConfig.cycleDuration`, `fromJson` | `built_in_presets_test`, `pattern_test` |
| Duty cycle 5–95% | `PatternBuilder.segments`, `fromJson` | `pattern_test`, `config_serialization_test` |
| SOS a ciclo fisso di 7 s | `BeaconConfig.cycleDuration` | `pattern_test` |
| Pattern in frazioni di ciclo | `PatternBuilder` | `pattern_test` (i segmenti coprono esattamente un ciclo) |
| Effetti pattern-driven degradano con `steady` | `BeaconConfig.normalized`, `effectSupported` | `config_serialization_test`, `effect_painter_test` |
| Torcia mai accesa se `torchEnabled` è falso | `BeaconEngine.start` | `beacon_engine_test` |
| Stop non bloccante | `BeaconSessionNotifier._setWakelock`, `ScreenController` | non coperto da test: verificato sul device |

---

## Come estendere

### Nuova modalità (card in home)

1. Voce in `BeaconMode` (`lib/domain/models/beacon_config.dart`).
2. Ramo nello `switch` di `BeaconConfig.forMode`: è esaustivo, il compilatore
   ti avvisa se lo dimentichi.
3. Card in `lib/features/home/home_page.dart`, etichette `mode<X>Title` /
   `mode<X>Subtitle`.
4. Chiavi in `app_it.arb` **e** `app_en.arb`, poi `flutter gen-l10n`.
5. Test: default sicuri in `test/domain/config_serialization_test.dart`.

### Nuovo pattern di flash

1. Voce in `FlashPattern`.
2. `PatternBuilder.segments` (frazioni di ciclo, duty rispettato) e
   `PatternBuilder.transitions` (solo i cambi di stato).
3. Etichetta in `BeaconLabels.pattern` + chiavi ARB.
4. Test in `test/engine/pattern_test.dart`: copertura esatta del ciclo, duty,
   transizioni. Poi verifica dei tempi on/off sul device.

### Nuovo effetto schermo

1. Voce in `ScreenEffect`.
2. `EffectPainter.paint` in `lib/features/beacon/effect_painter.dart`.
3. Se l'effetto legge lo stato dal pattern, aggiungilo a
   `BeaconConfig.patternDrivenEffects`: con `steady` verrà degradato a `solid`.
4. Etichetta in `BeaconLabels.effect` + chiavi ARB.
5. Test in `test/features/effect_painter_test.dart` (colore dipinto a fase nota).

### Nuovo preset predefinito

1. Costante in `lib/domain/repositories/built_in_presets.dart` e voce in `all`.
2. `nameKey` + chiavi `preset<X>` e `preset<X>Desc` nei due ARB.
3. Rami in `BeaconLabels.presetName` e `BeaconLabels.presetDescription`.
4. `flutter test test/domain/built_in_presets_test.dart`: id unici, niente blu,
   frequenza nel range.

### Nuova chiave di localizzazione

1. `lib/l10n/app_it.arb` (è il template) e `lib/l10n/app_en.arb`, sempre
   entrambi; per le chiavi con placeholder aggiungi il blocco `@chiave`.
2. `flutter gen-l10n`.
3. Committa i file generati: la CI verifica con `git diff --exit-code lib/l10n/`
   che siano aggiornati.
4. Nella UI usa `context.l10n.<chiave>`, mai stringhe letterali.

### Nuovo campo di `BeaconConfig`

1. Campo `final` + parametro `required` nel costruttore `const`.
2. `copyWith`.
3. `toJson` / `fromJson` con clamp e fallback: i dati su disco possono essere
   vecchi o corrotti. Se cambia il formato, valuta il bump di `schemaVersion`.
4. `operator ==` e `hashCode` (lo stato Riverpod li usa).
5. Eventuale aggiornamento in `normalized`.
6. Test in `test/domain/config_serialization_test.dart`: round-trip, fallback,
   clamp.

### Nuova dipendenza

1. Verifica `environment.sdk` su pub.dev contro Dart 3.11 / Flutter 3.41.
2. Se richiede Flutter > 3.41, pinna la versione esatta e motiva nel commento
   accanto (vedi `torch_light` e `wakelock_plus` in `pubspec.yaml`).
3. Se è una capacità di piattaforma, esponila dietro un seam in `lib/platform/`
   con la variante `Noop*` per i test, e registrala in `providers.dart`.

### Sostituzione del plugin torcia (fase 4)

1. Nuova classe che implementa `TorchController` in
   `lib/platform/torch/torch_controller.dart`.
2. Cambio del solo costruttore in `torchControllerProvider`.
3. Nessuna modifica a `BeaconEngine`, `BeaconPage` o ai test: parlano
   dell'interfaccia, non del plugin.

---

## Test e verifica

Comandi e gate stanno in [`.clinerules`](.clinerules). Qui cosa c'è a
disposizione.

| Helper | Dove | A cosa serve |
|---|---|---|
| `FakeClock` | `lib/core/clock/clock.dart` | tempo controllabile con `advance()` |
| `TimerFactory` | `lib/core/clock/clock.dart` | sostituisce `Timer` per far scattare gli edge a mano |
| `NoopTorchController.calls` | `lib/platform/torch/torch_controller.dart` | sequenza degli stati torcia applicati |
| `NoopScreenController.applied` / `restoreCount` | `lib/platform/screen/screen_controller.dart` | luminosità applicata e ripristini |
| `_paintTopLeft` | `test/features/effect_painter_test.dart` | colore realmente dipinto a una fase data |

Regole per i test:

- Nei widget test che montano `BeaconPage` usa `tester.pump()` con durate
  esplicite: il `Ticker` è sempre attivo e `pumpAndSettle()` non termina mai.
- Sovrascrivi `sharedPreferencesProvider` (con
  `SharedPreferences.setMockInitialValues`), `torchControllerProvider` e
  `screenControllerProvider`.
- Il pannello controlli richiede un viewport alto (`tester.view.physicalSize`),
  altrimenti i controlli finiscono fuori schermo.
- Non toccare hardware, filesystem utente o rete: i plugin sono sempre
  sostituiti dalle varianti `Noop*`.

Cosa i test **non** coprono: il timing reale del LED. Un errore di scala (edge
scalati su un secondo invece che sul ciclo) passa i test unitari e si vede solo
nei log del driver: vedi `docs/PLAN.md` §13-bis.

---

## Mappa dei file

| File | Responsabilità |
|---|---|
| `lib/main.dart` | bootstrap: orientamento, `SharedPreferences`, `ProviderScope` |
| `lib/app.dart` | `MaterialApp`, locale, tema, onboarding vs home |
| `lib/core/clock/clock.dart` | `Clock`, `StopwatchClock`, `FakeClock`, `TimerFactory` |
| `lib/core/theme/app_theme.dart` | tema dark, palette UI, `minTouchTarget` |
| `lib/domain/engine/beacon_engine.dart` | scheduling degli edge, anti-drift, resync, timeout |
| `lib/domain/engine/pattern.dart` | pattern → segmenti di ciclo, `isOnAt` |
| `lib/domain/engine/phase.dart` | fase del ciclo dal tempo trascorso |
| `lib/domain/engine/jitter_monitor.dart` | statistiche di jitter, soglia di instabilità |
| `lib/domain/models/beacon_config.dart` | configurazione immutabile, palette, serializzazione, `normalized` |
| `lib/domain/models/app_settings.dart` | lingua, avviso di sicurezza, cap luminosità, keep-awake |
| `lib/domain/models/preset.dart` | preset predefiniti (per chiave) e utente (per nome) |
| `lib/domain/repositories/built_in_presets.dart` | i 6 preset predefiniti |
| `lib/domain/repositories/settings_repository.dart` | persistenza JSON versionata su `SharedPreferences` |
| `lib/platform/torch/torch_controller.dart` | seam torcia + `NoopTorchController` |
| `lib/platform/screen/screen_controller.dart` | seam luminosità applicativa + `NoopScreenController` |
| `lib/providers/providers.dart` | provider, notifier, sessione beacon (engine + jitter watch) |
| `lib/features/beacon/beacon_page.dart` | schermo fullscreen, `Ticker`, HUD, stop |
| `lib/features/beacon/control_sheet.dart` | pannello controlli contestuale, avviso oltre 3 Hz, salvataggio preset |
| `lib/features/beacon/effect_painter.dart` | rendering degli effetti schermo |
| `lib/features/beacon/beacon_labels.dart` | etichette localizzate di enum e preset |
| `lib/features/home/` | scelta della modalità (`home_page.dart`, `mode_card.dart`) |
| `lib/features/presets/presets_page.dart` | preset predefiniti e personalizzati |
| `lib/features/settings/settings_page.dart` | lingua, luminosità massima, keep-awake |
| `lib/features/onboarding/safety_page.dart` | avviso di sicurezza al primo avvio |
| `lib/l10n/*.arb` | stringhe it/en (l'italiano è il template) |
| `lib/l10n/app_localizations*.dart` | generati da `flutter gen-l10n`, committati |
| `test/engine/` | pattern, fase, anti-drift, jitter |
| `test/domain/` | serializzazione, normalizzazione, preset, guardie di sicurezza |
| `test/features/` | colore dipinto dal painter |
| `test/widget/` | onboarding, home, beacon, pannello controlli, salvataggio preset |
| `tools/generate_icons.py` | rigenera icona legacy, concept e splash (Pillow) |
| `docs/PLAN.md` | architettura, vincoli, roadmap, bug incontrati |
| `docs/BEST_PRACTICES.md` | best practice per tecnologia, stato, debiti |
| `.github/workflows/ci.yml` | analyze + test + build, verifica l10n |
| `.github/pull_request_template.md` | checklist della PR |

---

## File → per chi

| File | Pubblico | Cosa ci trovi |
|---|---|---|
| `README.md` | utente e chi installa | cosa fa, requisiti, build, uso, sicurezza |
| `.clinerules` | chi scrive codice (umano o AI) | vincoli operativi, gate, policy git |
| `AGENTS.md` | agenti e contributori | architettura, invarianti, come estendere, test |
| `docs/PLAN.md` | chi progetta | il perché, la roadmap, i bug già visti |
| `docs/BEST_PRACTICES.md` | chi mantiene | scostamenti dalle best practice e debiti |
| `test/` | chi modifica il motore | il contratto verificabile |

