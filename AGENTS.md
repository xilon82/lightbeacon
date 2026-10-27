# AGENTS.md

Guida per agenti AI (e per chiunque contribuisca) che lavorano su questo
repository. Le regole qui sotto sono vincolanti: descrivono convenzioni già in
uso nel codice, non aspirazioni.

---

## Contesto del progetto

LightBeacon è un'app Android in Flutter che trasforma il telefono in un segnale
di visibilità: lampeggio del flash, schermo colorato con effetti, torcia fissa.

Il documento di riferimento è [docs/PLAN.md](docs/PLAN.md): architettura,
vincoli tecnici, roadmap e bug già incontrati. **Leggilo prima di modificare il
motore di lampeggio.**

---

## Comandi

```bash
flutter pub get            # dipendenze
flutter gen-l10n           # rigenera le traduzioni (obbligatorio dopo aver toccato lib/l10n/*.arb)
flutter analyze            # deve essere pulito, zero warning
flutter test               # 88 test, devono essere tutti verdi
flutter build apk --debug  # verifica che compili
```

Dopo ogni modifica a stringhe, modelli o motore: `flutter gen-l10n`,
`flutter analyze`, `flutter test`.

---

## Regole non negoziabili

### Sicurezza

1. **Nessun colore blu.** Il lampeggio blu è riservato ai veicoli di emergenza
   (art. 151/153 CdS). `BeaconPalette` non lo espone e un test lo verifica.
2. **Frequenza massima 10 Hz**, default 2 Hz. Avviso modale oltre 3 Hz.
3. **Duty cycle massimo 95%**, minimo 5%.
4. Ogni nuova modalità o preset deve passare i test di sicurezza in
   `test/domain/built_in_presets_test.dart`.

### Timing

5. **Mai `Timer.periodic` o `sleep(period)` cumulativo** per la torcia. Gli edge
   si pianificano sempre su un'origine assoluta:
   `start + n * cycle + offset`. Il jitter non deve sommarsi.
6. **Il render clock non comanda la torcia.** Lo schermo calcola la fase dal
   `Ticker`; la torcia ha il suo edge clock. Non accoppiarli.
7. I pattern si esprimono in **frazioni di ciclo**, mai in millisecondi assoluti.
8. Ogni modifica al motore va verificata **sul device**, non solo nei test:

   ```bash
   adb logcat -c && sleep 10
   adb logcat -d | grep setTorchModeStrength
   ```

   Controlla che i tempi on/off corrispondano alla configurazione. I test
   unitari non catturano errori di scala (è già successo: vedi
   [docs/PLAN.md](docs/PLAN.md), sezione 13-bis).

### Architettura

9. **`TorchController` e `ScreenController` sono seam.** Non chiamare
   `torch_light` o `screen_brightness` direttamente dalla UI o dal motore: passa
   sempre dal controller, così il plugin Kotlin potrà sostituirli senza toccare
   il resto.
10. **La UI non contiene logica di timing.** Se ti serve un calcolo temporale,
    va nel motore.
11. **Nessuna chiamata di piattaforma bloccante nel percorso di stop.** Wakelock
    e luminosità sono best-effort: un canale che non risponde non deve impedire
    lo spegnimento del beacon.

### Dipendenze

12. **`torch_light` e `wakelock_plus` sono pinnati** a versioni precedenti
    l'ultima: le release più recenti richiedono Flutter ≥ 3.44, il progetto usa
    3.41. Non aggiornarli senza aver verificato il vincolo SDK.
13. Prima di aggiungere un pacchetto, verifica il vincolo `environment.sdk` su
    pub.dev contro Dart 3.11.

### Internazionalizzazione

14. **Nessuna stringa hardcoded nella UI.** Tutto passa da
    `context.l10n.<chiave>`.
15. Ogni nuova chiave va aggiunta **sia** a `lib/l10n/app_it.arb` **sia** a
    `lib/l10n/app_en.arb`. L'italiano è il template.
16. Dopo aver toccato gli ARB: `flutter gen-l10n`.

### Test

17. Ogni bug corretto richiede un test di regressione che fallirebbe senza la
    correzione.
18. I test widget che montano `BeaconPage` devono usare `tester.pump()` con
    durate esplicite, **mai `pumpAndSettle()`**: il `Ticker` è sempre attivo e
    `pumpAndSettle` non termina mai.
19. Nei test, sovrascrivi sempre `torchControllerProvider` e
    `screenControllerProvider` con le implementazioni `Noop*`.

---

## Convenzioni di codice

- **Lingua del codice**: inglese (nomi, commenti, messaggi di commit).
  **Lingua della documentazione utente**: italiano.
- Commenti solo dove serve spiegare il *perché*, non il *cosa*.
- Preferisci `const` e classi immutabili; `BeaconConfig` è immutabile con
  `copyWith`.
- Stato applicativo via Riverpod (`Notifier`/`NotifierProvider`), non
  `setState` per stato condiviso.
- Errori di piattaforma: cattura e degrada, non propagare alla UI se non è
  azionabile dall'utente.

---

## Mappa dei file

| File | Responsabilità |
|---|---|
| `lib/domain/engine/beacon_engine.dart` | Scheduling degli edge della torcia, anti-drift, timeout |
| `lib/domain/engine/pattern.dart` | Conversione pattern → segmenti di ciclo |
| `lib/domain/engine/phase.dart` | Fase del ciclo dal tempo trascorso |
| `lib/domain/engine/jitter_monitor.dart` | Statistiche di jitter, soglia di instabilità |
| `lib/domain/models/beacon_config.dart` | Configurazione immutabile + serializzazione |
| `lib/platform/torch/torch_controller.dart` | Seam torcia (plugin attuale + Noop per test) |
| `lib/platform/screen/screen_controller.dart` | Seam luminosità |
| `lib/providers/providers.dart` | Stato Riverpod, sessione beacon |
| `lib/features/beacon/control_sheet.dart` | Pannello controlli contestuale |
| `lib/features/beacon/effect_painter.dart` | Rendering degli effetti schermo |

---

## Cosa NON fare

- Non aggiungere il blu alla palette.
- Non usare `pumpAndSettle()` nei test della schermata beacon.
- Non aggiornare `torch_light`/`wakelock_plus` senza verificare Flutter 3.44.
- Non mettere logica di timing nella UI.
- Non chiamare i plugin di piattaforma fuori dai controller.
- Non introdurre stringhe non tradotte.
- Non dichiarare "funziona" senza averlo verificato sul device fisico.
