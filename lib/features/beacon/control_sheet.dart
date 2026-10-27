import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/beacon_config.dart';
import '../../l10n/l10n.dart';
import '../../providers/providers.dart';
import 'beacon_labels.dart';

/// Bottom sheet with the live controls.
///
/// Every change is applied immediately: the beacon keeps running while the
/// user tunes it, which is the whole point of a visibility device.
class ControlSheet extends ConsumerStatefulWidget {
  const ControlSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Transparent so the sheet's own rounded corners are visible; the
      // surface colour is painted by the DraggableScrollableSheet below.
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => const ControlSheet(),
    );
  }

  @override
  ConsumerState<ControlSheet> createState() => _ControlSheetState();
}

class _ControlSheetState extends ConsumerState<ControlSheet> {
  bool _highFrequencyWarned = false;

  void _update(BeaconConfig Function(BeaconConfig) transform) {
    final notifier = ref.read(beaconConfigProvider.notifier);
    final next = transform(ref.read(beaconConfigProvider)).normalized;
    notifier.apply(next);
    ref.read(beaconSessionProvider.notifier).updateConfig(next);
  }

  /// Saves the current configuration as a named preset.
  ///
  /// The name is pre-filled with a timestamp so the user can save in one tap
  /// while still being able to tell presets apart later.
  Future<void> _savePreset() async {
    final l10n = context.l10n;
    final config = ref.read(beaconConfigProvider);
    final now = DateTime.now();
    final defaultName = l10n.savePresetDefaultName(
      '${now.day.toString().padLeft(2, '0')}/'
      '${now.month.toString().padLeft(2, '0')} '
      '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}',
    );

    final name = await showDialog<String>(
      context: context,
      builder: (_) => _SavePresetDialog(initialName: defaultName),
    );

    if (name == null || !mounted) return;

    await ref.read(presetsProvider.notifier).save(name, config);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.savePresetSaved),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onFrequencyChanged(double value) async {
    if (value > 3 && !_highFrequencyWarned) {
      _highFrequencyWarned = true;
      final l10n = context.l10n;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surfaceHigh,
          title: Text(l10n.warningHighFrequencyTitle),
          content: Text(l10n.warningHighFrequencyBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.warningContinue),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    _update((c) => c.copyWith(frequencyHz: value));
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(beaconConfigProvider);
    final settings = ref.watch(settingsProvider);
    final l10n = context.l10n;

    // DraggableScrollableSheet coordinates the two vertical gestures that
    // would otherwise fight each other: dragging the list scrolls it, and
    // dragging down while already at the top shrinks the sheet. Once it
    // reaches minChildSize, shouldCloseOnMinExtent pops the route.
    //
    // snap is deliberately off: with snapping enabled the sheet springs back
    // to a snap size instead of continuing down to the dismiss threshold.
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.15,
      maxChildSize: 0.95,
      expand: false,
      shouldCloseOnMinExtent: true,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            // --- Flash -------------------------------------------------
            _SectionTitle(l10n.controlSectionFlash),
            _ToggleRow(
              label: l10n.controlTorchToggle,
              description: l10n.controlTorchToggleDesc,
              value: config.torchEnabled,
              onChanged: (v) => _update((c) => c.copyWith(torchEnabled: v)),
            ),
            if (!config.torchEnabled)
              _Hint(l10n.hintTorchOff)
            else ...[
              _ChipRow<FlashPattern>(
                label: l10n.controlPattern,
                description: l10n.controlPatternDesc,
                values: FlashPattern.values,
                selected: config.pattern,
                labelOf: (p) => BeaconLabels.pattern(context, p),
                onSelected: (p) => _update((c) => c.copyWith(pattern: p)),
              ),
              const SizedBox(height: 16),
              if (config.pattern == FlashPattern.steady)
                _Hint(l10n.hintSteadyTorch)
              else ...[
                _SliderRow(
                  label: l10n.controlFrequency,
                  description: l10n.controlFrequencyDesc,
                  valueLabel: config.frequencyLocked
                      ? l10n.patternSos
                      : l10n.controlFrequencyValue(
                          config.frequencyHz.toStringAsFixed(1),
                        ),
                  value: config.frequencyHz.clamp(0.5, 10),
                  min: 0.5,
                  max: 10,
                  divisions: 19,
                  enabled: !config.frequencyLocked,
                  onChanged: _onFrequencyChanged,
                ),
                _SliderRow(
                  label: l10n.controlDuty,
                  description: l10n.controlDutyDesc,
                  valueLabel: l10n.controlDutyValue(
                    (config.dutyCycle * 100).round().toString(),
                  ),
                  value: config.dutyCycle,
                  min: 0.1,
                  max: 0.9,
                  divisions: 16,
                  onChanged: (v) => _update((c) => c.copyWith(dutyCycle: v)),
                ),
              ],
            ],

            // --- Screen ------------------------------------------------
            const SizedBox(height: 8),
            _SectionTitle(l10n.controlSectionScreen),
            _ToggleRow(
              label: l10n.controlScreenToggle,
              description: l10n.controlScreenToggleDesc,
              value: config.screenEnabled,
              onChanged: (v) => _update((c) => c.copyWith(screenEnabled: v)),
            ),
            if (!config.screenEnabled)
              _Hint(l10n.hintScreenOff)
            else ...[
              _ChipRow<ScreenEffect>(
                label: l10n.controlEffect,
                description: l10n.controlEffectDesc,
                values: config.availableEffects,
                selected: config.effect,
                labelOf: (e) => BeaconLabels.effect(context, e),
                onSelected: (e) => _update((c) => c.copyWith(effect: e)),
              ),
              if (config.pattern == FlashPattern.steady)
                _Hint(l10n.hintSteadyScreen),
              const SizedBox(height: 16),
              _ColorRow(
                label: l10n.controlPrimaryColor,
                selected: config.primaryColor,
                onSelected: (c) =>
                    _update((cfg) => cfg.copyWith(primaryColor: c)),
              ),
              if (config.effect == ScreenEffect.alternate ||
                  config.effect == ScreenEffect.sweep) ...[
                const SizedBox(height: 12),
                _ColorRow(
                  label: l10n.controlSecondaryColor,
                  selected: config.secondaryColor,
                  onSelected: (c) =>
                      _update((cfg) => cfg.copyWith(secondaryColor: c)),
                ),
              ],
              const SizedBox(height: 8),
              _SliderRow(
                label: l10n.controlBrightness,
                description: l10n.controlBrightnessDesc,
                valueLabel: l10n.controlBrightnessValue(
                  (config.brightness * 100).round().toString(),
                ),
                value: config.brightness.clamp(0.1, settings.brightnessCap),
                min: 0.1,
                max: settings.brightnessCap,
                divisions: 18,
                onChanged: (v) => _update((c) => c.copyWith(brightness: v)),
              ),
            ],

            // --- Timing ------------------------------------------------
            const SizedBox(height: 8),
            _SectionTitle(l10n.controlSectionTiming),
            if (config.syncRelevant)
              _ChipRow<SyncMode>(
                label: l10n.controlSync,
                description: l10n.controlSyncDesc,
                values: SyncMode.values,
                selected: config.sync,
                labelOf: (s) => BeaconLabels.sync(context, s),
                onSelected: (s) => _update((c) => c.copyWith(sync: s)),
              )
            else
              _Hint(l10n.hintSyncNeedsBoth),
            const SizedBox(height: 16),
            _ChipRow<int>(
              label: l10n.controlTimeout,
              description: l10n.controlTimeoutDesc,
              values: const [0, 5, 15, 30, 60],
              selected: config.timeoutMinutes,
              labelOf: (m) => BeaconLabels.timeout(context, m),
              onSelected: (m) => _update((c) => c.copyWith(timeoutMinutes: m)),
            ),

            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _savePreset,
              icon: const Icon(Icons.bookmark_add_outlined),
              label: Text(l10n.savePresetAction),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppTheme.minTouchTarget),
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Name prompt for saving the current configuration as a preset.
///
/// Owns its [TextEditingController] so the controller outlives the dialog's
/// closing animation.
class _SavePresetDialog extends StatefulWidget {
  const _SavePresetDialog({required this.initialName});

  final String initialName;

  @override
  State<_SavePresetDialog> createState() => _SavePresetDialogState();
}

class _SavePresetDialogState extends State<_SavePresetDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      setState(() => _error = context.l10n.savePresetEmptyName);
      return;
    }
    Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: AppTheme.surfaceHigh,
      title: Text(l10n.savePresetTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: l10n.savePresetNameLabel,
          hintText: l10n.savePresetNameHint,
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.savePresetSave),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
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

/// Small explanatory line shown under a control label.
class _Description extends StatelessWidget {
  const _Description(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          height: 1.3,
        ),
      ),
    );
  }
}

/// Explains why a control is hidden or has no effect.
class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                _Description(description),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.description,
    this.divisions,
    this.enabled = true,
  });

  final String label;
  final String? description;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  if (description != null) _Description(description!),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              valueLabel,
              style: TextStyle(
                color: enabled ? AppTheme.accent : AppTheme.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}

class _ChipRow<T> extends StatelessWidget {
  const _ChipRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.description,
  });

  final String label;
  final String? description;
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        if (description != null) _Description(description!),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              ChoiceChip(
                label: Text(labelOf(value)),
                selected: value == selected,
                onSelected: (_) => onSelected(value),
                showCheckmark: false,
                backgroundColor: AppTheme.surfaceHigh,
                selectedColor: AppTheme.accent,
                labelStyle: TextStyle(
                  color: value == selected ? Colors.black : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                side: const BorderSide(color: AppTheme.outline),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
          ],
        ),
      ],
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final color in BeaconPalette.all)
              Semantics(
                label: BeaconLabels.color(context, color),
                selected: color == selected,
                button: true,
                child: GestureDetector(
                  onTap: () => onSelected(color),
                  child: ColorDot(color: color, selected: color == selected),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
