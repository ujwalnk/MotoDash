// Author: Ujwal N K
// Created: 2026.07.24
// Owns the BLE connection to a single proprietary "HID-like" peripheral: scanning, connecting,
// service/characteristic discovery, and turning notification/indication payloads into a stream
// of {'code': String, 'bytes': List<int>} events that BleIntentDetector consumes.
//
// Nothing about the remote's service/characteristic UUIDs is known at compile time - they're
// discovered live on first connect (skipping standard Bluetooth SIG services like Generic
// Access/Attribute, Device Information, and Battery Service, which almost every peripheral
// exposes and which aren't the button data we want), then persisted via ConfigProvider so
// reconnectSaved() can go straight back to the right characteristic without re-discovering.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:moto_dash/commons/config_provider.dart';

/// A notify/indicate-capable characteristic found on a peripheral, paired with its parent
/// service - returned by [BleHidBridge.discoverCandidates] when the user needs to disambiguate
/// between more than one plausible characteristic.
class BleCandidateCharacteristic {
  const BleCandidateCharacteristic({required this.service, required this.characteristic});

  final BluetoothService service;
  final BluetoothCharacteristic characteristic;

  String get serviceUuid => service.uuid.toString();
  String get characteristicUuid => characteristic.uuid.toString();
}

class BleHidBridge {
  BleHidBridge._();
  static final BleHidBridge instance = BleHidBridge._();

  /// Well-known Bluetooth SIG services present on almost every peripheral (Generic Access,
  /// Generic Attribute, Device Information, Battery Service). None of these carry button data,
  /// so they're excluded when hunting for the remote's own characteristic - this is what was
  /// silently swallowing your ESP32's characteristic behind "Service Changed" earlier.
  static const Set<String> _standardServiceUuids = {
    '00001800-0000-1000-8000-00805f9b34fb', // Generic Access
    '00001801-0000-1000-8000-00805f9b34fb', // Generic Attribute
    '0000180a-0000-1000-8000-00805f9b34fb', // Device Information
    '0000180f-0000-1000-8000-00805f9b34fb', // Battery Service
  };

  final StreamController<Map<String, dynamic>> _events = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _events.stream;

  final StreamController<BluetoothConnectionState> _connectionState =
      StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionState => _connectionState.stream;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  StreamSubscription<List<int>>? _valueSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

  bool get isConnected => _device != null && _characteristic != null;

  // -------------------------
  // SCANNING
  // -------------------------

  /// Starts a scan and returns the live results stream. Call [stopScan] when done with it.
  /// No service filter here - the remote's service UUID isn't known until after we connect and
  /// discover it, so any nearby device is a candidate at this stage.
  Stream<List<ScanResult>> startScan({Duration timeout = const Duration(seconds: 10)}) {
    FlutterBluePlus.startScan(timeout: timeout);
    return FlutterBluePlus.onScanResults;
  }

  Future<void> stopScan() => FlutterBluePlus.stopScan();

  // -------------------------
  // DISCOVERY
  // -------------------------

  /// Connects to [device] (without subscribing to anything yet) and returns every notify- or
  /// indicate-capable characteristic found, minus standard Bluetooth SIG services. If discovery
  /// yields zero candidates or the caller decides not to proceed, call [abortDiscovery] to
  /// disconnect; otherwise call [subscribeTo] with the chosen candidate.
  Future<List<BleCandidateCharacteristic>> discoverCandidates(BluetoothDevice device) async {
    await device.connect(timeout: const Duration(seconds: 10), license: License.free);

    final services = await device.discoverServices();
    final candidates = <BleCandidateCharacteristic>[];

    for (final service in services) {
      if (_standardServiceUuids.contains(service.uuid.toString().toLowerCase())) continue;

      for (final char in service.characteristics) {
        if (char.properties.notify || char.properties.indicate) {
          candidates.add(BleCandidateCharacteristic(service: service, characteristic: char));
        }
      }
    }

    return candidates;
  }

  /// Disconnects a device that was connected via [discoverCandidates] but never subscribed to
  /// (e.g. the user cancelled the picker, or nothing suitable was found).
  Future<void> abortDiscovery(BluetoothDevice device) async {
    try {
      await device.disconnect();
    } catch (_) {}
  }

  // -------------------------
  // CONNECT / DISCONNECT
  // -------------------------

  /// Subscribes to [candidate] on [device] and persists its (dynamically-discovered) service
  /// and characteristic UUIDs via ConfigProvider, so [reconnectSaved] can find it again later
  /// without re-running discovery.
  Future<void> subscribeTo(BluetoothDevice device, BleCandidateCharacteristic candidate) async {
    await _subscribe(device, candidate.characteristic);

    await ConfigProvider.setRiderGesturesBleDevice(
      deviceId: device.remoteId.toString(),
      deviceName: device.advName.isNotEmpty ? device.advName : device.remoteId.toString(),
      serviceUuid: candidate.serviceUuid,
      characteristicUuid: candidate.characteristicUuid,
    );
  }

  /// Re-establishes a connection to the previously configured device, matching the exact
  /// service/characteristic UUIDs discovered and saved at pairing time. No-op if nothing has
  /// been registered yet.
  Future<void> reconnectSaved() async {
    final deviceId = ConfigProvider.riderGesturesBleDeviceId;
    final serviceUuid = ConfigProvider.riderGesturesBleServiceUuid;
    final characteristicUuid = ConfigProvider.riderGesturesBleCharacteristicUuid;
    if (deviceId == null || serviceUuid == null || characteristicUuid == null) return;

    await _teardown();

    try {
      final device = BluetoothDevice.fromId(deviceId);
      await device.connect(timeout: const Duration(seconds: 10), license: License.free);

      final services = await device.discoverServices();
      final service = services.firstWhere((s) => s.uuid.toString().toLowerCase() == serviceUuid.toLowerCase());
      final char = service.characteristics.firstWhere(
        (c) => c.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase(),
      );

      await _subscribe(device, char);
    } catch (e) {
      debugPrint("BleHidBridge: reconnect failed: $e");
    }
  }

  Future<void> _subscribe(BluetoothDevice device, BluetoothCharacteristic char) async {
    await _teardown();

    _device = device;
    _characteristic = char;

    _connSub = device.connectionState.listen((state) {
      _connectionState.add(state);
      if (state == BluetoothConnectionState.disconnected) {
        // Best-effort auto-reconnect; the peripheral may simply be out of range.
        Future.delayed(const Duration(seconds: 3), reconnectSaved);
      }
    });

    // Handles notify AND indicate transparently - flutter_blue_plus checks the characteristic's
    // properties and writes the matching CCCD value (0x01 vs 0x02) itself.
    await char.setNotifyValue(true);
    _valueSub = char.lastValueStream.listen(_handlePayload);
  }

  void _handlePayload(List<int> bytes) {
    if (bytes.isEmpty) return;
    _events.add({'code': payloadToCode(bytes), 'bytes': bytes});
  }

  /// Deterministic string key for a raw notification/indication payload: [0x01] -> "01",
  /// [0x0a, 0xff] -> "0aff".
  static String payloadToCode(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> forgetDevice() async {
    await _teardown();
    await ConfigProvider.clearRiderGesturesBleDevice();
  }

  Future<void> _teardown() async {
    await _valueSub?.cancel();
    await _connSub?.cancel();
    if (_device != null) {
      try {
        await _device!.disconnect();
      } catch (_) {}
    }
    _device = null;
    _characteristic = null;
  }

  Future<void> dispose() async {
    await _teardown();
  }
}
