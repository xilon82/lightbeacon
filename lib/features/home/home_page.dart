import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/beacon_config.dart';
import '../../l10n/l10n.dart';
import '../../providers/providers.dart';
import '../beacon/beacon_page.dart';
import '../presets/presets_page.dart';
import '../settings/settings_page.dart';
import 'mode_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _start(BuildContext context, WidgetRef ref, BeaconMode mode) async {
    final configNotifier = ref.read(beaconConfigProvider.notifier);
    configNotifier.loadMode(mode);
    final config = ref.read(beaconConfigProvider);
    await ref.read(beaconSessionProvider.notifier).start(config);
    if (!context.mounted) return;
    await Navigator.of(context).push(BeaconPage.route());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(PresetsPage.route()),
            icon: const Icon(Icons.bookmarks_outlined),
            tooltip: l10n.navPresets,
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(SettingsPage.route()),
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.navSettings,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              l10n.appTagline,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.homeSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _ModeGrid(
              onStart: (mode) => _start(context, ref, mode),
            ),
            const SizedBox(height: 20),
            _TipCard(text: l10n.homeTip),
          ],
        ),
      ),
    );
  }
}

class _ModeGrid extends StatelessWidget {
  const _ModeGrid({required this.onStart});

  final ValueChanged<BeaconMode> onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cards = <Widget>[
      ModeCard(
        title: l10n.modeStrobeTitle,
        subtitle: l10n.modeStrobeSubtitle,
        icon: Icons.flash_on,
        accent: AppTheme.accent,
        onTap: () => onStart(BeaconMode.strobe),
      ),
      ModeCard(
        title: l10n.modeTorchTitle,
        subtitle: l10n.modeTorchSubtitle,
        icon: Icons.highlight,
        accent: BeaconPalette.white,
        onTap: () => onStart(BeaconMode.torch),
      ),
      ModeCard(
        title: l10n.modeScreenTitle,
        subtitle: l10n.modeScreenSubtitle,
        icon: Icons.palette_outlined,
        accent: BeaconPalette.cyan,
        onTap: () => onStart(BeaconMode.screen),
      ),
      ModeCard(
        title: l10n.modeComboTitle,
        subtitle: l10n.modeComboSubtitle,
        icon: Icons.wb_twilight,
        accent: BeaconPalette.amber,
        onTap: () => onStart(BeaconMode.combo),
      ),
      ModeCard(
        title: l10n.modeSosTitle,
        subtitle: l10n.modeSosSubtitle,
        icon: Icons.sos,
        accent: AppTheme.danger,
        onTap: () => onStart(BeaconMode.sos),
      ),
    ];

    return Column(
      children: [
        for (final card in cards) ...[
          card,
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: AppTheme.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
