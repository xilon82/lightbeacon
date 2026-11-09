import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../providers/providers.dart';
import 'preset_dialogs.dart';

/// Save affordances at the bottom of the control sheet.
///
/// What can be saved depends on where the configuration came from: a mode can
/// be overwritten or reset to its factory values, a preset can be overwritten,
/// and anything can always be saved as a new preset.
class ConfigActions extends ConsumerWidget {
  const ConfigActions({super.key});

  static ButtonStyle _primaryStyle() => FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(AppTheme.minTouchTarget),
  );

  static ButtonStyle _outlinedStyle() => OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(AppTheme.minTouchTarget),
    foregroundColor: AppTheme.accent,
    side: const BorderSide(color: AppTheme.accent),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveAsNew(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final name = await showPresetNameDialog(
      context,
      title: l10n.savePresetTitle,
      initialName: defaultPresetName(context),
    );
    if (name == null || !context.mounted) return;

    await ref.read(beaconConfigProvider.notifier).saveAsNewPreset(name);
    if (!context.mounted) return;
    _snack(context, l10n.savePresetSaved);
  }

  Future<void> _saveOverPreset(BuildContext context, WidgetRef ref) async {
    await ref.read(beaconConfigProvider.notifier).saveOverPreset();
    if (!context.mounted) return;
    _snack(context, context.l10n.presetUpdated);
  }

  void _saveOverMode(BuildContext context, WidgetRef ref) {
    ref.read(beaconConfigProvider.notifier).saveOverMode();
    _snack(context, context.l10n.saveModeSaved);
  }

  Future<void> _resetMode(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceHigh,
        title: Text(l10n.resetModeTitle),
        content: Text(l10n.resetModeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonReset),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    ref.read(beaconConfigProvider.notifier).resetMode();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final source = ref.watch(activeSourceProvider);
    final dirty = ref.watch(beaconConfigDirtyProvider);
    final overrides = ref.watch(modeOverridesProvider);

    final mode = source?.mode;
    final buttons = <Widget>[];

    if (mode != null) {
      if (dirty) {
        buttons.add(
          FilledButton.icon(
            onPressed: () => _saveOverMode(context, ref),
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n.saveModeAction),
            style: _primaryStyle(),
          ),
        );
      }
      if (overrides.containsKey(mode)) {
        buttons.add(
          TextButton.icon(
            onPressed: () => _resetMode(context, ref),
            icon: const Icon(Icons.restart_alt),
            label: Text(l10n.resetModeAction),
          ),
        );
      }
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _saveAsNew(context, ref),
          icon: const Icon(Icons.bookmark_add_outlined),
          label: Text(l10n.savePresetAction),
          style: _outlinedStyle(),
        ),
      );
    } else if (source?.isPreset ?? false) {
      if (dirty) {
        buttons.add(
          FilledButton.icon(
            onPressed: () => _saveOverPreset(context, ref),
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n.savePresetSave),
            style: _primaryStyle(),
          ),
        );
      }
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _saveAsNew(context, ref),
          icon: const Icon(Icons.bookmark_add_outlined),
          label: Text(l10n.saveAsNewPresetAction),
          style: _outlinedStyle(),
        ),
      );
    } else {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _saveAsNew(context, ref),
          icon: const Icon(Icons.bookmark_add_outlined),
          label: Text(l10n.savePresetAction),
          style: _outlinedStyle(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dirty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: _ModifiedHint(),
          ),
        for (final button in buttons)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: button),
      ],
    );
  }
}

class _ModifiedHint extends StatelessWidget {
  const _ModifiedHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.edit_outlined, size: 14, color: AppTheme.accent),
        const SizedBox(width: 6),
        Text(
          context.l10n.configModifiedHint,
          style: const TextStyle(color: AppTheme.accent, fontSize: 12),
        ),
      ],
    );
  }
}
