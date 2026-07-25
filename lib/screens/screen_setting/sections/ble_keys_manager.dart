// Author: Ujwal N K /w Claude
// Created: 2026.07.24
// Registration & management UI for a proprietary BLE remote, shown inside "Rider Gestures" when
// "Bluetooth LE Device" is enabled. Two stages: pair a device (scan -> connect -> auto-subscribe),
// then register buttons on it (learn mode: wait for the next notification payload).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/controllers/ble_hid_intent_detector/ble_hid_bridge.dart';
import 'package:moto_dash/controllers/ble_hid_intent_detector/ble_registered_key.dart';
import 'package:moto_dash/controllers/navigation_intent_handler.dart' show NavigationIntent;
import 'package:moto_dash/screens/screen_setting/setting_card.dart';

class BleKeysManager extends StatefulWidget {
  const BleKeysManager({super.key});

  @override
  State<BleKeysManager> createState() => _BleKeysManagerState();
}

class _BleKeysManagerState extends State<BleKeysManager> {
  List<BleRegisteredKey> _keys = ConfigProvider.riderGesturesBleKeys;
  bool _scanning = false;
  bool _learning = false;

  String? get _deviceId => ConfigProvider.riderGesturesBleDeviceId;

  String? get _deviceName => ConfigProvider.riderGesturesBleDeviceName;

  Future<void> _persistKeys() => ConfigProvider.setRiderGesturesBleKeys(_keys);

  BleRegisteredKey? _findByCode(String code) {
    for (final key in _keys) {
      if (key.code == code) return key;
    }
    return null;
  }

  void _updateKey(BleRegisteredKey updated) {
    setState(() {
      _keys = _keys.map((k) => k.id == updated.id ? updated : k).toList();
    });
    _persistKeys();
  }

  void _deleteKey(BleRegisteredKey key) {
    setState(() {
      _keys = _keys.where((k) => k.id != key.id).toList();
    });
    _persistKeys();
  }

  // -------------------------
  // DEVICE PAIRING
  // -------------------------

  Future<void> _scanAndConnect() async {
    setState(() => _scanning = true);

    final device = await _pickDevice();
    if (device == null) {
      if (mounted) setState(() => _scanning = false);
      return;
    }

    List<BleCandidateCharacteristic> candidates;
    try {
      candidates = await BleHidBridge.instance.discoverCandidates(device);
    } catch (e) {
      candidates = [];
    }

    if (candidates.isEmpty) {
      await BleHidBridge.instance.abortDiscovery(device);
      if (mounted) {
        setState(() => _scanning = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No notify/indicate characteristic found on that device.")));
      }
      return;
    }

    BleCandidateCharacteristic chosen;
    if (candidates.length == 1) {
      chosen = candidates.first;
    } else {
      final picked = await _pickCandidate(candidates);
      if (picked == null) {
        await BleHidBridge.instance.abortDiscovery(device);
        if (mounted) setState(() => _scanning = false);
        return;
      }
      chosen = picked;
    }

    await BleHidBridge.instance.subscribeTo(device, chosen);

    if (mounted) setState(() => _scanning = false);
  }

  Future<BluetoothDevice?> _pickDevice() {
    final completer = Completer<BluetoothDevice?>();
    final sub = BleHidBridge.instance.startScan().listen((_) {});

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: SettingsCard.cardBg,
          title: const Text("Nearby BLE devices", style: TextStyle(color: SettingsCard.textColor)),
          content: SizedBox(
            width: double.maxFinite,
            height: 320,
            child: StreamBuilder<List<ScanResult>>(
              stream: FlutterBluePlus.onScanResults,
              initialData: const [],
              builder: (context, snapshot) {
                final results = snapshot.data ?? [];

                if (results.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text("Scanning...", style: TextStyle(color: Colors.white70)),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final r = results[index];
                    final name = r.device.advName.isNotEmpty ? r.device.advName : r.device.remoteId.toString();
                    return ListTile(
                      title: Text(name, style: const TextStyle(color: SettingsCard.textColor)),
                      subtitle: Text(r.device.remoteId.toString(), style: TextStyle(color: Colors.white.withAlpha(90))),
                      trailing: Text("${r.rssi} dBm", style: TextStyle(color: Colors.white.withAlpha(90))),
                      onTap: () {
                        sub.cancel();
                        BleHidBridge.instance.stopScan();
                        Navigator.pop(ctx);
                        if (!completer.isCompleted) completer.complete(r.device);
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                sub.cancel();
                BleHidBridge.instance.stopScan();
                Navigator.pop(ctx);
                if (!completer.isCompleted) completer.complete(null);
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );

    return completer.future;
  }

  Future<BleCandidateCharacteristic?> _pickCandidate(List<BleCandidateCharacteristic> candidates) {
    return showDialog<BleCandidateCharacteristic>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SettingsCard.cardBg,
        title: const Text("Multiple candidates found", style: TextStyle(color: SettingsCard.textColor)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: candidates.length,
            itemBuilder: (context, index) {
              final c = candidates[index];
              return ListTile(
                title: Text(
                  "Service ${c.serviceUuid}",
                  style: const TextStyle(color: SettingsCard.textColor, fontSize: 12),
                ),
                subtitle: Text(
                  "Characteristic ${c.characteristicUuid}",
                  style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 12),
                ),
                onTap: () => Navigator.pop(ctx, c),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel"))],
      ),
    );
  }

  Future<void> _forgetDevice() async {
    await BleHidBridge.instance.forgetDevice();
    setState(() => _keys = []);
    await _persistKeys();
  }

  // -------------------------
  // ADD KEY FLOW
  // -------------------------

  Future<void> _addKey() async {
    final name = await _promptForName();
    if (name == null || name.trim().isEmpty) return;
    if (!mounted) return;

    final code = await _learnCode();
    if (code == null) return;
    if (!mounted) return;

    final duplicate = _findByCode(code);
    if (duplicate != null) {
      final replace = await _confirmReplace(duplicate);
      if (replace != true) return;
      if (!mounted) return;

      setState(() {
        _keys = _keys.where((k) => k.id != duplicate.id).toList();
      });
    }

    final newKey = BleRegisteredKey(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      code: code,
    );

    setState(() => _keys = [..._keys, newKey]);
    await _persistKeys();
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
            hintText: "e.g. Shutter",
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

  /// Enters learning mode and waits for the next notification payload. Returns null on cancel.
  Future<String?> _learnCode() async {
    setState(() => _learning = true);

    final completer = Completer<String?>();
    late final StreamSubscription<Map<String, dynamic>> sub;
    BuildContext? dialogContext;

    sub = BleHidBridge.instance.events.listen((event) {
      final String? code = event['code'] as String?;
      if (code == null) return;

      sub.cancel();
      if (completer.isCompleted) return;
      completer.complete(code);

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
          content: Text(
            "Press the button on your BLE remote now...",
            style: TextStyle(color: Colors.white.withAlpha(90)),
          ),
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

    sub.cancel();
    if (mounted) setState(() => _learning = false);
    return completer.future;
  }

  Future<bool?> _confirmReplace(BleRegisteredKey existing) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SettingsCard.cardBg,
        title: const Text("Button already registered", style: TextStyle(color: SettingsCard.textColor)),
        content: Text(
          'This payload is already registered as "${existing.name}". Replace it?',
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
    final deviceId = _deviceId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (deviceId == null) ...[
          Text("No BLE remote paired yet.", style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _scanning ? null : _scanAndConnect,
            icon: const Icon(Icons.bluetooth_searching, color: SettingsCard.textColor),
            label: Text(
              _scanning ? "Scanning..." : "Scan for BLE Remote",
              style: const TextStyle(color: SettingsCard.textColor),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withAlpha(90)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.bluetooth_connected, color: SettingsCard.textColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _deviceName ?? deviceId,
                    style: const TextStyle(color: SettingsCard.textColor, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(onPressed: _forgetDevice, child: const Text("Forget")),
              ],
            ),
          ),
          for (final key in _keys)
            Padding(
              key: ValueKey(key.id),
              padding: const EdgeInsets.only(bottom: 12),
              child: _BleKeyCard(bleKey: key, onChanged: _updateKey, onDelete: () => _deleteKey(key)),
            ),
          OutlinedButton.icon(
            onPressed: _learning ? null : _addKey,
            icon: const Icon(Icons.add, color: SettingsCard.textColor),
            label: Text(
              _learning ? "Listening for button..." : "Add Button",
              style: const TextStyle(color: SettingsCard.textColor),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withAlpha(90)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ],
    );
  }
}

class _BleKeyCard extends StatefulWidget {
  const _BleKeyCard({required this.bleKey, required this.onChanged, required this.onDelete});

  final BleRegisteredKey bleKey;
  final ValueChanged<BleRegisteredKey> onChanged;
  final VoidCallback onDelete;

  @override
  State<_BleKeyCard> createState() => _BleKeyCardState();
}

class _BleKeyCardState extends State<_BleKeyCard> {
  late final TextEditingController _nameController = TextEditingController(text: widget.bleKey.name);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submitName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == widget.bleKey.name) return;
    widget.onChanged(widget.bleKey.copyWith(name: trimmed));
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
              "Payload: 0x${widget.bleKey.code}",
              style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 13),
            ),
          ),
          _GestureDropdownRow(
            label: "Single Tap",
            value: widget.bleKey.singleTap,
            onChanged: (value) => widget.onChanged(widget.bleKey.copyWith(singleTap: value)),
          ),
          _GestureDropdownRow(
            label: "Double Tap",
            value: widget.bleKey.doubleTap,
            onChanged: (value) => widget.onChanged(widget.bleKey.copyWith(doubleTap: value)),
          ),
          _GestureDropdownRow(
            label: "Triple Tap",
            value: widget.bleKey.tripleTap,
            onChanged: (value) => widget.onChanged(widget.bleKey.copyWith(tripleTap: value)),
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
