// Author: Ujwal N K /w Claude
// Created: 2026.08.08
// Per-feature onboarding step bodies. Each of these only returns the scrollable *content* for its step — the
// surrounding OnboardingScaffold (title, progress bar, Continue button) is supplied by screen_onboarding.dart so
// every step shares identical chrome.
//
// Steps that require a runtime permission (Phone, Voice Notes, Dynamic Volume) request it as soon as they're
// mounted and report back to the parent via [onDisableFeature] if it's denied — onboarding itself never blocks or
// re-prompts.

import 'package:flutter/material.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/settings_tiles.dart';
import 'package:moto_dash/screens/onboarding/onboarding_widgets.dart';
import 'package:moto_dash/screens/screen_permissions.dart' show NativePermissions;
import 'package:moto_dash/screens/screen_setting/sections/contacts_setting.dart';
import 'package:moto_dash/screens/screen_setting/sections/navigation_settings.dart';
import 'package:permission_handler/permission_handler.dart';

// ============================================================================
// PHONE
// ============================================================================
class OnboardingPhoneStep extends StatefulWidget {
  const OnboardingPhoneStep({super.key, required this.onDisableFeature});

  final VoidCallback onDisableFeature;

  @override
  State<OnboardingPhoneStep> createState() => _OnboardingPhoneStepState();
}

class _OnboardingPhoneStepState extends State<OnboardingPhoneStep> {
  bool? _granted; // null while the request is in flight

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _request());
  }

  Future<void> _request() async {
    final phone = await Permission.phone.request();
    final contacts = await Permission.contacts.request();
    final callLog = await NativePermissions.requestCallLog();

    final granted = phone.isGranted && contacts.isGranted && callLog;
    if (!granted) widget.onDisableFeature();
    if (mounted) setState(() => _granted = granted);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OnboardingInfoCard(
          text:
              "MotoDash can place, answer, reject, and end calls, and show your recent calls and favourite "
              "contacts — all with large, glove-friendly buttons.",
        ),
        if (_granted == false) const OnboardingPermissionDeniedCard(featureName: "Phone"),
        const OnboardingSectionLabel("Recent calls"),
        const PrefTextFieldTile(
          label: "Maximum recent calls displayed",
          prefKey: PrefKeys.miscMaxCallLogsListed,
          defaultValue: "5",
          inputType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        const OnboardingSectionLabel("Favourite contacts"),
        const ContactsSettingsSection(),
      ],
    );
  }
}

// ============================================================================
// MUSIC
// ============================================================================
class OnboardingMusicStep extends StatefulWidget {
  const OnboardingMusicStep({super.key});

  @override
  State<OnboardingMusicStep> createState() => _OnboardingMusicStepState();
}

class _OnboardingMusicStepState extends State<OnboardingMusicStep> {
  late bool _swapped = ConfigProvider.miscSwapMusicButtonPositions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OnboardingInfoCard(text: "Control media playback — play, pause, and skip — while you ride."),
        _MusicButtonPreview(swapped: _swapped),
        const SizedBox(height: 8),
        PrefSwitchTile(
          title: "Swap Previous & Play/Pause position",
          prefKey: PrefKeys.miscSwapMusicButtonPositions,
          defaultValue: ConfigProvider.miscSwapMusicButtonPositions,
          onChanged: (v) => setState(() => _swapped = v),
        ),
      ],
    );
  }
}

class _MusicButtonPreview extends StatelessWidget {
  const _MusicButtonPreview({required this.swapped});

  final bool swapped;

  @override
  Widget build(BuildContext context) {
    final chips = [
      _MusicChip(icon: Icons.skip_previous_rounded, label: "Previous"),
      _MusicChip(icon: Icons.play_arrow_rounded, label: "Play / Pause", highlighted: true),
    ];
    final ordered = swapped ? chips.reversed.toList() : chips;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: kOnboardingCard, borderRadius: BorderRadius.circular(18)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ordered),
    );
  }
}

class _MusicChip extends StatelessWidget {
  const _MusicChip({required this.icon, required this.label, this.highlighted = false});

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlighted ? kOnboardingAccent : Colors.white.withAlpha(20),
          ),
          child: Icon(icon, color: highlighted ? Colors.black : Colors.white70, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 12)),
      ],
    );
  }
}

// ============================================================================
// ASSISTANT
// ============================================================================
class OnboardingAssistantStep extends StatelessWidget {
  const OnboardingAssistantStep({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnboardingInfoCard(
          text:
              "MotoDash launches your phone's configured default voice assistant with a single tap. "
              "No extra permissions are required for this.",
          icon: Icons.mic_none_rounded,
        ),
      ],
    );
  }
}

// ============================================================================
// VOICE NOTES
// ============================================================================
class OnboardingVoiceNotesStep extends StatefulWidget {
  const OnboardingVoiceNotesStep({super.key, required this.onDisableFeature});

  final VoidCallback onDisableFeature;

  @override
  State<OnboardingVoiceNotesStep> createState() => _OnboardingVoiceNotesStepState();
}

class _OnboardingVoiceNotesStepState extends State<OnboardingVoiceNotesStep> {
  bool? _granted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _request());
  }

  Future<void> _request() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) widget.onDisableFeature();
    if (mounted) setState(() => _granted = mic.isGranted);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OnboardingInfoCard(
          text: "Voice notes are recorded with a single tap and saved automatically to your Downloads folder.",
          icon: Icons.mic_rounded,
        ),
        const OnboardingInfoCard(
          text:
              "A Bluetooth microphone generally produces much better recordings while riding — the phone's "
              "built-in microphone may pick up wind and road noise depending on your device.",
          icon: Icons.bluetooth_audio_rounded,
        ),
        if (_granted == false) const OnboardingPermissionDeniedCard(featureName: "Voice Notes"),
      ],
    );
  }
}

// ============================================================================
// NAVIGATION
// ============================================================================
class OnboardingNavigationStep extends StatelessWidget {
  const OnboardingNavigationStep({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnboardingInfoCard(
          text: "Save your favourite destinations here for one-tap access while riding.",
          icon: Icons.navigation_rounded,
        ),
        OnboardingWarningCard(
          text: "Your phone must be unlocked before starting navigation.",
        ),
        OnboardingInfoCard(
          text:
              "Navigation is started from the MotoDash Navigation page. Once directions are underway, the "
              "Re-read button repeats the next spoken instruction whenever you need it.",
          icon: Icons.replay_rounded,
        ),
        SizedBox(height: 8),
        OnboardingSectionLabel("Saved destinations"),
        NavigationSettings(),
      ],
    );
  }
}

// ============================================================================
// VOLUME CONTROLS
// ============================================================================
class OnboardingVolumeControlsStep extends StatelessWidget {
  const OnboardingVolumeControlsStep({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnboardingInfoCard(
          text: "Adjust media volume directly from MotoDash without reaching for your phone.",
          icon: Icons.volume_up_rounded,
        ),
      ],
    );
  }
}

// ============================================================================
// DYNAMIC VOLUME
// ============================================================================
class OnboardingDynamicVolumeStep extends StatefulWidget {
  const OnboardingDynamicVolumeStep({super.key, required this.onDisable});

  final VoidCallback onDisable;

  @override
  State<OnboardingDynamicVolumeStep> createState() => _OnboardingDynamicVolumeStepState();
}

class _OnboardingDynamicVolumeStepState extends State<OnboardingDynamicVolumeStep> {
  bool? _granted;
  late bool _enabled = ConfigProvider.adaptiveVolumeEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _request());
  }

  Future<void> _request() async {
    final location = await Permission.location.request();
    final always = location.isGranted ? await Permission.locationAlways.request() : location;
    final granted = location.isGranted && always.isGranted;

    if (!granted) {
      await ConfigProvider.prefs.setBool(PrefKeys.adaptiveVolumeEnable, false);
      widget.onDisable();
    }
    if (mounted) {
      setState(() {
        _granted = granted;
        if (!granted) _enabled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OnboardingInfoCard(
          text: "MotoDash can automatically raise or lower media volume based on how fast you're riding.",
          icon: Icons.speed_rounded,
        ),
        if (_granted == false) const OnboardingPermissionDeniedCard(featureName: "Dynamic Volume"),
        PrefSwitchTile(
          // Re-keyed once the permission result is in so the switch reloads from prefs and reflects a denial
          // that was just forced through directly, even if it had been mounted showing "on" beforehand.
          key: ValueKey('dynamic-volume-switch-$_granted'),
          title: "Speed Adaptive Volume",
          prefKey: PrefKeys.adaptiveVolumeEnable,
          defaultValue: ConfigProvider.adaptiveVolumeEnabled,
          onChanged: (v) => setState(() => _enabled = v),
        ),
        if (_enabled && _granted != false) ...[
          const SizedBox(height: 8),
          const PrefTextFieldTile(
            label: "Activation speed (km/h)",
            prefKey: PrefKeys.adaptiveVolumeActivateMinSpeed,
            defaultValue: "50",
            inputType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          const PrefTextFieldTile(
            label: "Volume increase interval (km/h)",
            prefKey: PrefKeys.adaptiveVolumeSpeedInterval,
            defaultValue: "10",
            inputType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          const PrefTextFieldTile(
            label: "Maximum volume steps",
            prefKey: PrefKeys.adaptiveVolumeMaxSteps,
            defaultValue: "3",
            inputType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          const OnboardingSectionLabel("Sensitivity"),
          const PrefSliderTile(
            title: "Sensitivity",
            prefKey: PrefKeys.adaptiveVolumeSamplingInterval,
            defaultValue: 3.0,
            min: 1,
            max: 10,
          ),
          Text(
            "How frequently MotoDash samples speed to adjust the media volume. Default: 3 seconds.",
            style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 12.5),
          ),
        ],
      ],
    );
  }
}
