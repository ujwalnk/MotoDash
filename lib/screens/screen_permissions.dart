// Author: Ujwal N K /w Claude
// Created: 2026.06.25
// Setup screen to help user configure the application & give the required permission.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../commons/constants.dart';

/// Native bridge for the two permissions `permission_handler` doesn't cover:
/// Call Log and Notification Listener access. Wire these methods up on the
/// Android side the same way you did for the `in.madilu.motodash/telephony` channel.
///
///   isCallLogGranted               -> bool, checks READ_CALL_LOG
///   requestCallLogPermission       -> triggers the native runtime request
///   isNotificationListenerEnabled  -> bool, checks the listener is in Settings.Secure ENABLED_NOTIFICATION_LISTENERS
///   openNotificationListenerSettings -> launches ACTION_NOTIFICATION_LISTENER_SETTINGS
class _NativePermissions {
  static const _channel = MethodChannel('in.madilu.motodash/permissions');

  static Future<bool> isCallLogGranted() async {
    try {
      return await _channel.invokeMethod<bool>('isCallLogGranted') ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> requestCallLog() async {
    try {
      await _channel.invokeMethod('requestCallLogPermission');
    } on PlatformException {
      // Surfaced via the next status refresh.
    }
  }

  static Future<bool> isNotificationListenerEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('isNotificationListenerEnabled') ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> openNotificationListenerSettings() async {
    try {
      await _channel.invokeMethod('openNotificationListenerSettings');
    } on PlatformException {
      // Surfaced via the next status refresh.
    }
  }
}

enum _PermKind { runtime, callLog, notificationListener }

class _PermItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final _PermKind kind;
  final List<Permission?>? permission; // set when kind == runtime
  bool granted;

  _PermItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.kind,
    this.permission,
    this.granted = false, // ignore: unused_element_parameter
  });
}

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> with WidgetsBindingObserver {
  late final List<_PermItem> _items = [
    _PermItem(
      title: 'Phone',
      subtitle: 'Detect call state, make / answer / end calls',
      icon: Icons.phone_rounded,
      kind: _PermKind.runtime,
      permission: [Permission.phone],
    ),
    _PermItem(title: 'Call Log', subtitle: 'Show recent calls', icon: Icons.history_rounded, kind: _PermKind.callLog),
    _PermItem(
      title: 'Contacts',
      subtitle: 'Show contact names and favourites',
      icon: Icons.contacts_rounded,
      kind: _PermKind.runtime,
      permission: [Permission.contacts],
    ),
    _PermItem(
      title: 'Display over other apps',
      subtitle: 'Show the incoming call UI above other apps',
      icon: Icons.layers_rounded,
      kind: _PermKind.runtime,
      permission: [Permission.systemAlertWindow],
    ),
    _PermItem(
      title: 'Notifications',
      subtitle: 'Show the persistent MotoDash notification',
      icon: Icons.notifications_none_rounded,
      kind: _PermKind.runtime,
      permission: [Permission.notification],
    ),
    _PermItem(
      title: 'Battery optimization',
      subtitle: 'Keep MotoDash running reliably in the background',
      icon: Icons.battery_full_rounded,
      kind: _PermKind.runtime,
      permission: [Permission.ignoreBatteryOptimizations],
    ),
    _PermItem(
      title: 'Location',
      subtitle: 'Determine your vehicle speed for Speed Adaptive Volume',
      icon: Icons.location_on_rounded,
      kind: _PermKind.runtime,
      permission: [Permission.location, Permission.locationAlways],
    ),
  ];

  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Overlay, battery, and notification-listener permissions are granted via
  // a Settings screen, so re-check whenever the user comes back to the app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAll();
    }
  }

  Future<void> _refreshAll() async {
    for (final item in _items) {
      item.granted = await _checkOne(item);
    }
    if (mounted) setState(() => _checking = false);
  }

  Future<bool> _checkOne(_PermItem item) async {
    switch (item.kind) {
      case _PermKind.callLog:
        return _NativePermissions.isCallLogGranted();
      case _PermKind.notificationListener:
        return _NativePermissions.isNotificationListenerEnabled();
      case _PermKind.runtime:
        for (final permission in item.permission!) {
          if (!await permission!.isGranted) {
            return false;
          }
        }
        return true;
    }
  }

  Future<void> _request(_PermItem item) async {
    switch (item.kind) {
      case _PermKind.callLog:
        await _NativePermissions.requestCallLog();
        break;

      case _PermKind.notificationListener:
        await _NativePermissions.openNotificationListenerSettings();
        break;

      case _PermKind.runtime:
        for (final permission in item.permission!) {
          if (!await permission!.isGranted) {
            await permission.request();
          }
        }
        break;
    }

    final granted = await _checkOne(item);
    if (mounted) {
      setState(() => item.granted = granted);
    }
  }

  bool get _allGranted => _items.every((e) => e.granted);

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B0D10);
    const card = Color(0xFF15181C);
    const Color accent = Colors.redAccent;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _checking
            ? const Center(child: CircularProgressIndicator(color: accent))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set up MotoDash',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Grant these permissions so MotoDash can run reliably in the background.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return _PermissionTile(
                          item: item,
                          cardColor: card,
                          accent: accent,
                          onTap: () => _request(item),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _allGranted
                            ? () async {
                                await showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Restart Required'),
                                    content: const Text(
                                      'MotoDash must be restarted for all permissions and settings to take effect.\n\n'
                                      'After leaving this screen, a persistent notification will appear. Use the notification to exit the app, or swipe the app away from the Recent Apps screen.\n\n'
                                      'Important: Do not swipe the app away from Recent Apps and then tap "Exit" from the notification. Choose only one of these methods.',
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                                    ],
                                  ),
                                );

                                if (!context.mounted) return;
                                Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          disabledBackgroundColor: Colors.black,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _allGranted ? 'Continue' : 'Grant all permissions to continue',
                          style: TextStyle(color: _allGranted ? Colors.black : accent),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final _PermItem item;
  final Color cardColor;
  final Color accent;
  final VoidCallback onTap;

  const _PermissionTile({required this.item, required this.cardColor, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(6)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Colors.white.withAlpha(5), borderRadius: BorderRadius.circular(10)),
            child: Icon(item.icon, color: item.granted ? accent : Colors.white70, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(item.subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          item.granted
              ? Icon(Icons.check_circle, color: accent, size: 22)
              : OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    side: BorderSide(color: accent.withAlpha(50)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Grant'),
                ),
        ],
      ),
    );
  }
}
