import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/preset.dart';
import '../../l10n/l10n.dart';
import '../../providers/providers.dart';
import '../beacon/beacon_labels.dart';
import '../beacon/beacon_page.dart';
import '../beacon/preset_dialogs.dart';

class PresetsPage extends ConsumerWidget {
  const PresetsPage({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const PresetsPage());

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

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

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    Preset preset,
  ) async {
    final name = await showPresetNameDialog(
      context,
      title: context.l10n.presetRenameTitle,
      initialName: BeaconLabels.presetName(
        context,
        preset.nameKey,
        preset.customName,
      ),
    );
    if (name == null) return;

    await ref.read(presetsProvider.notifier).rename(preset.id, name);
    if (!context.mounted) return;
    _snack(context, context.l10n.presetUpdated);
  }

  Future<void> _overwrite(
    BuildContext context,
    WidgetRef ref,
    Preset preset,
  ) async {
    await ref
        .read(presetsProvider.notifier)
        .overwrite(preset.id, ref.read(beaconConfigProvider));
    if (!context.mounted) return;
    _snack(context, context.l10n.presetUpdated);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Preset preset,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceHigh,
        title: Text(l10n.presetDeleteTitle),
        content: Text(
          preset.isBuiltIn
              ? l10n.presetDeleteBuiltInBody
              : l10n.presetDeleteBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(presetsProvider.notifier).remove(preset.id);
    if (!context.mounted) return;
    _snack(context, l10n.presetDeleted);
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    Preset preset,
  ) async {
    await ref.read(presetsProvider.notifier).restoreBuiltIn(preset.id);
    if (!context.mounted) return;
    _snack(context, context.l10n.presetRestored);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final library = ref.watch(presetsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.presetsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _SectionHeader(l10n.presetsBuiltIn),
          for (final preset in library.builtIn)
            _PresetTile(
              preset: preset,
              modified: library.isOverridden(preset.id),
              onTap: () => _apply(context, ref, preset),
              onRename: () => _rename(context, ref, preset),
              onOverwrite: () => _overwrite(context, ref, preset),
              onDelete: () => _delete(context, ref, preset),
              onRestore: library.isOverridden(preset.id)
                  ? () => _restore(context, ref, preset)
                  : null,
            ),
          if (library.custom.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader(l10n.presetsCustom),
            for (final preset in library.custom)
              _PresetTile(
                preset: preset,
                modified: false,
                onTap: () => _apply(context, ref, preset),
                onRename: () => _rename(context, ref, preset),
                onOverwrite: () => _overwrite(context, ref, preset),
                onDelete: () => _delete(context, ref, preset),
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
    required this.modified,
    required this.onTap,
    required this.onRename,
    required this.onOverwrite,
    required this.onDelete,
    this.onRestore,
  });

  final Preset preset;
  final bool modified;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onOverwrite;
  final VoidCallback onDelete;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (modified) ...[
                            const SizedBox(width: 8),
                            const _ModifiedBadge(),
                          ],
                        ],
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
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppTheme.textSecondary,
                  ),
                  color: AppTheme.surfaceHigh,
                  onSelected: (value) {
                    switch (value) {
                      case 'rename':
                        onRename();
                      case 'overwrite':
                        onOverwrite();
                      case 'restore':
                        onRestore?.call();
                      case 'delete':
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: Text(l10n.presetActionRename),
                    ),
                    PopupMenuItem(
                      value: 'overwrite',
                      child: Text(l10n.presetActionOverwrite),
                    ),
                    if (onRestore != null)
                      PopupMenuItem(
                        value: 'restore',
                        child: Text(l10n.presetActionRestore),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(l10n.commonDelete),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModifiedBadge extends StatelessWidget {
  const _ModifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.6)),
      ),
      child: Text(
        context.l10n.presetModifiedBadge,
        style: const TextStyle(
          color: AppTheme.accent,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
