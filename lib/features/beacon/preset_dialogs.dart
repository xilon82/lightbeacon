import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';

/// Name prompt shared by "save as new preset" and "rename preset".
///
/// Owns its [TextEditingController] so the controller outlives the dialog's
/// closing animation.
class PresetNameDialog extends StatefulWidget {
  const PresetNameDialog({
    super.key,
    required this.title,
    required this.initialName,
  });

  final String title;
  final String initialName;

  @override
  State<PresetNameDialog> createState() => _PresetNameDialogState();
}

class _PresetNameDialogState extends State<PresetNameDialog> {
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
      title: Text(widget.title),
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
        FilledButton(onPressed: _submit, child: Text(l10n.savePresetSave)),
      ],
    );
  }
}

/// Asks for a preset name. Returns `null` when the user cancels.
Future<String?> showPresetNameDialog(
  BuildContext context, {
  required String title,
  required String initialName,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => PresetNameDialog(title: title, initialName: initialName),
  );
}

/// Pre-filled name for a new preset: "Configurazione 08/11 22:41".
///
/// A timestamp lets the user save in one tap while still telling presets apart
/// later.
String defaultPresetName(BuildContext context) {
  final now = DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  return context.l10n.savePresetDefaultName(
    '${two(now.day)}/${two(now.month)} ${two(now.hour)}:${two(now.minute)}',
  );
}
