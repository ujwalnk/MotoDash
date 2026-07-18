// Author: Ujwal N K
// Created: 2026.07.12
// Registration & management UI for Bluetooth HID keys, shown inside "Rider Gestures" when
// Bluetooth HID Device is enabled.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:moto_dash/bridges/input_event_bridge.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/controllers/bt_hid_intent_detector/hid_key_registry.dart';
import 'package:moto_dash/controllers/navigation_intent_handler.dart' show NavigationIntent;
import 'package:moto_dash/screens/screen_setting/setting_card.dart';

/// Android's `KeyEvent.ACTION_DOWN`. Only key-down events count as a "press"; ACTION_UP is ignored.
const int _kActionDown = 0;

class HidKeysManager extends StatefulWidget {
  const HidKeysManager({super.key});

  @override
  State<HidKeysManager> createState() => _HidKeysManagerState();
}

class _HidKeysManagerState extends State<HidKeysManager> {
  List<HidRegisteredKey> _keys = ConfigProvider.riderGesturesHidKeys;
  bool _learning = false;

  Future<void> _persist() => ConfigProvider.setRiderGesturesHidKeys(_keys);

  HidRegisteredKey? _findByKeyCode(int keyCode) {
    for (final key in _keys) {
      if (key.keyCode == keyCode) return key;
    }
    return null;
  }

  void _updateKey(HidRegisteredKey updated) {
    setState(() {
      _keys = _keys.map((k) => k.id == updated.id ? updated : k).toList();
    });
    _persist();
  }

  void _deleteKey(HidRegisteredKey key) {
    setState(() {
      _keys = _keys.where((k) => k.id != key.id).toList();
    });
    _persist();
  }

  // -------------------------
  // ADD KEY FLOW
  // -------------------------

  Future<void> _addKey() async {
    final name = await _promptForName();
    if (name == null || name.trim().isEmpty) return;
    if (!mounted) return;

    final learned = await _learnKey();
    if (learned == null) return;
    if (!mounted) return;

    final duplicate = _findByKeyCode(learned.keyCode);
    if (duplicate != null) {
      final replace = await _confirmReplace(duplicate);
      if (replace != true) return;
      if (!mounted) return;

      setState(() {
        _keys = _keys.where((k) => k.id != duplicate.id).toList();
      });
    }

    final newKey = HidRegisteredKey(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      keyCode: learned.keyCode,
      scanCode: learned.scanCode,
    );

    setState(() {
      _keys = [..._keys, newKey];
    });

    await _persist();
  }

  Future<String?> _promptForName() {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SettingsCard.cardBg,
        title: const Text("Name this button", style: TextStyle(color: SettingsCard.textColor)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: SettingsCard.textColor),
          decoration: InputDecoration(
            hintText: "e.g. Volume Up",
            hintStyle: TextStyle(color: Colors.white.withAlpha(90)),
          ),
          onSubmitted: (value) => Navigator.pop(ctx, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text("Next")),
        ],
      ),
    );
  }

  /// Enters learning mode and waits for the next `ACTION_DOWN` key event from
  /// [InputEventBridge.events]. Returns `null` if the user cancels.
  Future<({int keyCode, int? scanCode})?> _learnKey() async {
    setState(() => _learning = true);

    final completer = Completer<({int keyCode, int? scanCode})?>();
    late final StreamSubscription<Map<dynamic, dynamic>> sub;
    BuildContext? dialogContext;

    sub = InputEventBridge.events.listen((event) {
      final int? action = event['action'] as int?;
      if (action != _kActionDown) return; // Ignore ACTION_UP and anything else

      sub.cancel();
      if (completer.isCompleted) return;

      completer.complete((keyCode: event['keyCode'] as int, scanCode: event['scanCode'] as int?));

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return AlertDialog(
          backgroundColor: SettingsCard.cardBg,
          title: const Text("Learning", style: TextStyle(color: SettingsCard.textColor)),
          content: Text("Press the button on your remote now...", style: TextStyle(color: Colors.white.withAlpha(90))),
          actions: [
            TextButton(
              onPressed: () {
                sub.cancel();
                if (!completer.isCompleted) completer.complete(null);
                Navigator.pop(ctx);
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );

    sub.cancel(); // Safety net in case the dialog was dismissed some other way

    if (mounted) setState(() => _learning = false);

    return completer.future;
  }

  Future<bool?> _confirmReplace(HidRegisteredKey existing) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SettingsCard.cardBg,
        title: const Text("Key already registered", style: TextStyle(color: SettingsCard.textColor)),
        content: Text(
          'This button is already registered as "${existing.name}". Replace it with the new registration?',
          style: TextStyle(color: Colors.white.withAlpha(90)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Replace")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final key in _keys)
          Padding(
            key: ValueKey(key.id),
            padding: const EdgeInsets.only(bottom: 12),
            child: _HidKeyCard(hidKey: key, onChanged: _updateKey, onDelete: () => _deleteKey(key)),
          ),
        OutlinedButton.icon(
          onPressed: _learning ? null : _addKey,
          icon: const Icon(Icons.add, color: SettingsCard.textColor),
          label: Text(
            _learning ? "Listening for key..." : "Add Key",
            style: const TextStyle(color: SettingsCard.textColor),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white.withAlpha(90)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _HidKeyCard extends StatefulWidget {
  const _HidKeyCard({required this.hidKey, required this.onChanged, required this.onDelete});

  final HidRegisteredKey hidKey;
  final ValueChanged<HidRegisteredKey> onChanged;
  final VoidCallback onDelete;

  @override
  State<_HidKeyCard> createState() => _HidKeyCardState();
}

class _HidKeyCardState extends State<_HidKeyCard> {
  late final TextEditingController _nameController = TextEditingController(text: widget.hidKey.name);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submitName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == widget.hidKey.name) return;
    widget.onChanged(widget.hidKey.copyWith(name: trimmed));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: SettingsCard.textColor, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                  onSubmitted: _submitName,
                  onEditingComplete: () => _submitName(_nameController.text),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: widget.onDelete,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              "Key code: ${widget.hidKey.keyCode}",
              style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13),
            ),
          ),
          _GestureDropdownRow(
            label: "Single Tap",
            value: widget.hidKey.singleTap,
            onChanged: (value) => widget.onChanged(widget.hidKey.copyWith(singleTap: value)),
          ),
          _GestureDropdownRow(
            label: "Double Tap",
            value: widget.hidKey.doubleTap,
            onChanged: (value) => widget.onChanged(widget.hidKey.copyWith(doubleTap: value)),
          ),
          _GestureDropdownRow(
            label: "Triple Tap",
            value: widget.hidKey.tripleTap,
            onChanged: (value) => widget.onChanged(widget.hidKey.copyWith(tripleTap: value)),
          ),
        ],
      ),
    );
  }
}

class _GestureDropdownRow extends StatelessWidget {
  const _GestureDropdownRow({required this.label, required this.value, required this.onChanged});

  final String label;
  final NavigationIntent? value;
  final ValueChanged<NavigationIntent?> onChanged;

  static String _labelFor(NavigationIntent intent) {
    switch (intent) {
      case NavigationIntent.next:
        return "Next";
      case NavigationIntent.previous:
        return "Previous";
      case NavigationIntent.select:
        return "Select";
      case NavigationIntent.back:
        return "Back";
      case NavigationIntent.emergency:
        return "Emergency";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13)),
          ),
          DropdownButton<NavigationIntent?>(
            value: value,
            dropdownColor: SettingsCard.cardBg,
            style: const TextStyle(color: SettingsCard.textColor, fontSize: 13),
            underline: const SizedBox.shrink(),
            items: [
              const DropdownMenuItem(value: null, child: Text("None")),
              ...NavigationIntent.values.map(
                (intent) => DropdownMenuItem(value: intent, child: Text(_labelFor(intent))),
              ),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
