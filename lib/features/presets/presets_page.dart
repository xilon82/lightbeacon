import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/preset.dart';
import '../../l10n/l10n.dart';
import '../../providers/providers.dart';
import '../beacon/beacon_labels.dart';
import '../beacon/beacon_page.dart';

class PresetsPage extends ConsumerWidget {
  const PresetsPage({super.key});

  static Route<void> route() => MaterialPageRoute<void>(
    builder: (_) => const PresetsPage(),
  );

  Future<void> _apply(
    BuildContext context,
    WidgetRef ref,
    Preset preset,
  ) async {
    ref.read(beaconConfigProvider.notifier).loadPreset(preset);
    final config = ref.read(beaconConfigProvider);
    await ref.read(beaconSessionProvider.notifier).start(config);
    if (!context.mounted) return;
    await Navigator.of(context).push(BeaconPage.route());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final builtIn = ref.watch(builtInPresetsProvider);
    final custom = ref.watch(presetsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.presetsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _SectionHeader(l10n.presetsBuiltIn),
          for (final preset in builtIn)
            _PresetTile(
              preset: preset,
              onTap: () => _apply(context, ref, preset),
            ),
          if (custom.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader(l10n.presetsCustom),
            for (final preset in custom)
              _PresetTile(
                preset: preset,
                onTap: () => _apply(context, ref, preset),
                onDelete: () =>
                    ref.read(presetsProvider.notifier).remove(preset.id),
              ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.preset,
    required this.onTap,
    this.onDelete,
  });

  final Preset preset;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final name = BeaconLabels.presetName(
      context,
      preset.nameKey,
      preset.customName,
    );
    final description = BeaconLabels.presetDescription(context, preset.nameKey);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Row(
              children: [
                ColorDot(color: preset.config.primaryColor, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    color: AppTheme.textSecondary,
                  )
                else
                  const Icon(Icons.play_arrow_rounded, color: AppTheme.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
