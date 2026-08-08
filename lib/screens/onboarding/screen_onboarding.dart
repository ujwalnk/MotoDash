// Author: Ujwal N K /w Claude
// Created: 2026.08.08
// First-run onboarding flow. Shown once, right after the app's first launch (see main.dart / ConfigProvider
// .isFirstRun), and re-visitable any time from Settings.
//
// The page list is dynamic: disabling a feature on the "Features" step removes its dedicated setup step and the
// progress bar recalculates against the new, shorter list. Every setting configured here is written straight
// through the existing ConfigProvider / PrefKeys / settings-tile widgets used by the Settings screen — onboarding
// introduces exactly one new persisted value, the feature enable/disable map.

import 'package:flutter/material.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/settings_tiles.dart';
import 'package:moto_dash/controllers/bt_hid_intent_detector/hid_keys_manager.dart';
import 'package:moto_dash/screens/onboarding/onboarding_feature_steps.dart';
import 'package:moto_dash/screens/onboarding/onboarding_widgets.dart';
import 'package:moto_dash/screens/screen_setting/sections/ble_keys_manager.dart';
import 'package:moto_dash/screens/screen_setting/sections/rider_gesture_setting.dart';

enum _Step {
  welcome,
  ridingControls,
  features,
  appearance,
  screenSaver,
  phone,
  music,
  assistant,
  voiceNotes,
  navigation,
  volumeControls,
  dynamicVolume,
  summary,
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  _Step _current = _Step.welcome;

  // Welcome
  bool _disclaimerAccepted = false;

  // Riding controls (values only drive whether the extra config widgets are shown — the switches themselves
  // auto-persist through PrefSwitchTile).
  bool _btEnabled = ConfigProvider.riderGesturesBtEnabled;
  bool _bleEnabled = ConfigProvider.riderGesturesBleEnabled;
  bool _magnetEnabled = ConfigProvider.riderGesturesMagnetEnabled;

  // Features — seeded from ConfigProvider so re-entering onboarding from Settings reflects the current state.
  late bool _phoneEnabled = ConfigProvider.phoneEnabled;
  late bool _musicEnabled = ConfigProvider.musicEnabled;
  late bool _navigationEnabled = ConfigProvider.navigationEnabled;
  late bool _assistantEnabled = ConfigProvider.assistantEnabled;
  late bool _voiceNotesEnabled = ConfigProvider.voiceNotesEnabled;
  late bool _volumeControlsEnabled = ConfigProvider.volumeControlsEnabled;

  // Screen saver
  late bool _screenSaverAnimated = ConfigProvider.screenSaverAnimation;

  // Set when a permission-gated feature gets disabled automatically, so the summary can explain why.
  final Set<String> _disabledByPermission = {};

  // A step whose feature gets disabled by a denied permission while it's the *current* step stays in the list
  // until the user moves on — otherwise the step would vanish out from under them mid-view. Every other
  // enable/disable decision happens on the Features step, before its dedicated step is ever reached.
  List<_Step> get _visibleSteps => [
    _Step.welcome,
    _Step.ridingControls,
    _Step.features,
    _Step.appearance,
    _Step.screenSaver,
    if (_phoneEnabled || _current == _Step.phone) _Step.phone,
    if (_musicEnabled) _Step.music,
    if (_assistantEnabled) _Step.assistant,
    if (_voiceNotesEnabled || _current == _Step.voiceNotes) _Step.voiceNotes,
    if (_navigationEnabled) _Step.navigation,
    if (_volumeControlsEnabled) _Step.volumeControls,
    _Step.dynamicVolume,
    _Step.summary,
  ];

  int get _index => _visibleSteps.indexOf(_current);

  Future<void> _setFeature(String key, bool value) async {
    await ConfigProvider.setFeatureEnabled(key, value);
  }

  void _goNext() {
    final steps = _visibleSteps;
    final i = steps.indexOf(_current);
    if (i == steps.length - 1) {
      _finish();
      return;
    }
    setState(() => _current = steps[i + 1]);
  }

  void _goBack() {
    final steps = _visibleSteps;
    final i = steps.indexOf(_current);
    if (i <= 0) return;
    setState(() => _current = steps[i - 1]);
  }

  void _finish() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final steps = _visibleSteps;
    final stepNumber = _index + 1;
    final totalSteps = steps.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index > 0) _goBack();
      },
      child: Scaffold(
        backgroundColor: kOnboardingBg,
        body: OnboardingStepTransition(
          stepKey: _current,
          child: _buildStep(context, stepNumber: stepNumber, totalSteps: totalSteps),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, {required int stepNumber, required int totalSteps}) {
    switch (_current) {
      case _Step.welcome:
        return _welcomeStep(stepNumber, totalSteps);
      case _Step.ridingControls:
        return _ridingControlsStep(stepNumber, totalSteps);
      case _Step.features:
        return _featuresStep(stepNumber, totalSteps);
      case _Step.appearance:
        return _appearanceStep(stepNumber, totalSteps);
      case _Step.screenSaver:
        return _screenSaverStep(stepNumber, totalSteps);
      case _Step.phone:
        return OnboardingScaffold(
          title: "Phone",
          icon: Icons.phone_rounded,
          stepNumber: stepNumber,
          totalSteps: totalSteps,
          onBack: _goBack,
          onContinue: _goNext,
          children: [
            OnboardingPhoneStep(
              onDisableFeature: () {
                _disabledByPermission.add("Phone");
                setState(() => _phoneEnabled = false);
                _setFeature(FeatureKeys.phone, false);
              },
            ),
          ],
        );
      case _Step.music:
        return OnboardingScaffold(
          title: "Music",
          icon: Icons.music_note_rounded,
          stepNumber: stepNumber,
          totalSteps: totalSteps,
          onBack: _goBack,
          onContinue: _goNext,
          children: const [OnboardingMusicStep()],
        );
      case _Step.assistant:
        return OnboardingScaffold(
          title: "Assistant",
          icon: Icons.assistant_rounded,
          stepNumber: stepNumber,
          totalSteps: totalSteps,
          onBack: _goBack,
          onContinue: _goNext,
          children: const [OnboardingAssistantStep()],
        );
      case _Step.voiceNotes:
        return OnboardingScaffold(
          title: "Voice Notes",
          icon: Icons.mic_rounded,
          stepNumber: stepNumber,
          totalSteps: totalSteps,
          onBack: _goBack,
          onContinue: _goNext,
          children: [
            OnboardingVoiceNotesStep(
              onDisableFeature: () {
                _disabledByPermission.add("Voice Notes");
                setState(() => _voiceNotesEnabled = false);
                _setFeature(FeatureKeys.voiceNotes, false);
              },
            ),
          ],
        );
      case _Step.navigation:
        return OnboardingScaffold(
          title: "Navigation",
          icon: Icons.navigation_rounded,
          stepNumber: stepNumber,
          totalSteps: totalSteps,
          onBack: _goBack,
          onContinue: _goNext,
          children: const [OnboardingNavigationStep()],
        );
      case _Step.volumeControls:
        return OnboardingScaffold(
          title: "Volume Controls",
          icon: Icons.volume_up_rounded,
          stepNumber: stepNumber,
          totalSteps: totalSteps,
          onBack: _goBack,
          onContinue: _goNext,
          children: const [OnboardingVolumeControlsStep()],
        );
      case _Step.dynamicVolume:
        return OnboardingScaffold(
          title: "Dynamic Volume",
          icon: Icons.speed_rounded,
          stepNumber: stepNumber,
          totalSteps: totalSteps,
          onBack: _goBack,
          onContinue: _goNext,
          children: [
            OnboardingDynamicVolumeStep(
              onDisable: () => setState(() => _disabledByPermission.add("Dynamic Volume")),
            ),
          ],
        );
      case _Step.summary:
        return _summaryStep(stepNumber, totalSteps);
    }
  }

  // --------------------------------------------------------------------------------------------------------------
  // WELCOME
  // --------------------------------------------------------------------------------------------------------------
  Widget _welcomeStep(int stepNumber, int totalSteps) {
    const disclaimer =
        "Ride safely. Your attention should always remain on the road. By continuing, you acknowledge that you "
        "are solely responsible for how you use MotoDash while operating a vehicle. The developer and "
        "contributors are not liable for any loss, damage, injury, or legal consequences resulting from the use "
        "or misuse of this application. Continue only if you understand and accept this responsibility.";

    return OnboardingScaffold(
      title: "Welcome to MotoDash",
      subtitle:
          "MotoDash helps you safely access your phone's important features while keeping your attention on "
          "the road. The next few screens will set it up.",
      icon: Icons.two_wheeler_rounded,
      stepNumber: stepNumber,
      totalSteps: totalSteps,
      continueLabel: "Get started",
      onContinue: _disclaimerAccepted ? _goNext : null,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kOnboardingAccent.withAlpha(16),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kOnboardingAccent.withAlpha(60)),
          ),
          child: const Text(disclaimer, style: TextStyle(color: Colors.white, fontSize: 13.5, height: 1.5)),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _disclaimerAccepted = !_disclaimerAccepted),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _disclaimerAccepted,
                  onChanged: (v) => setState(() => _disclaimerAccepted = v ?? false),
                  activeColor: kOnboardingAccent,
                  checkColor: Colors.black,
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      "I understand that I am solely responsible for using MotoDash safely while operating "
                      "a vehicle and accept the above disclaimer.",
                      style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------------------------------------------
  // RIDING CONTROLS
  // --------------------------------------------------------------------------------------------------------------
  Widget _ridingControlsStep(int stepNumber, int totalSteps) {
    return OnboardingScaffold(
      title: "Riding Controls",
      subtitle: "MotoDash can also be controlled without touching the screen.",
      icon: Icons.gamepad_rounded,
      stepNumber: stepNumber,
      totalSteps: totalSteps,
      onBack: _goBack,
      onContinue: _goNext,
      children: [
        const OnboardingInfoCard(text: "Display Mode is always enabled.", icon: Icons.smartphone_rounded),
        PrefSwitchTile(
          title: "Bluetooth Controller",
          prefKey: PrefKeys.riderGesturesBtEnable,
          defaultValue: ConfigProvider.riderGesturesBtEnabled,
          onChanged: (v) => setState(() => _btEnabled = v),
        ),
        if (_btEnabled) const Padding(padding: EdgeInsets.only(bottom: 8), child: HidKeysManager()),
        PrefSwitchTile(
          title: "BLE Button",
          prefKey: PrefKeys.riderGesturesBleEnable,
          defaultValue: ConfigProvider.riderGesturesBleEnabled,
          onChanged: (v) => setState(() => _bleEnabled = v),
        ),
        if (_bleEnabled) const Padding(padding: EdgeInsets.only(bottom: 8), child: BleKeysManager()),
        PrefSwitchTile(
          title: "Magnet Controls",
          prefKey: PrefKeys.riderGesturesMagnetEnable,
          defaultValue: ConfigProvider.riderGesturesMagnetEnabled,
          onChanged: (v) => setState(() => _magnetEnabled = v),
        ),
        if (_magnetEnabled) const MagnetGestureConfig(),
      ],
    );
  }

  // --------------------------------------------------------------------------------------------------------------
  // FEATURES
  // --------------------------------------------------------------------------------------------------------------
  Widget _featuresStep(int stepNumber, int totalSteps) {
    return OnboardingScaffold(
      title: "Features",
      subtitle: "Choose what MotoDash shows on your dashboard. You can change this anytime in Settings.",
      icon: Icons.tune_rounded,
      stepNumber: stepNumber,
      totalSteps: totalSteps,
      onBack: _goBack,
      onContinue: _goNext,
      children: [
        OnboardingFeatureTile(
          icon: Icons.phone_rounded,
          title: "Phone",
          description: "Make and answer calls, recent calls, favourite contacts.",
          value: _phoneEnabled,
          onChanged: (v) {
            setState(() => _phoneEnabled = v);
            _setFeature(FeatureKeys.phone, v);
          },
        ),
        OnboardingFeatureTile(
          icon: Icons.music_note_rounded,
          title: "Music",
          description: "Control media playback while riding.",
          value: _musicEnabled,
          onChanged: (v) {
            setState(() => _musicEnabled = v);
            _setFeature(FeatureKeys.music, v);
          },
        ),
        OnboardingFeatureTile(
          icon: Icons.navigation_rounded,
          title: "Navigation",
          description: "Launch saved destinations and replay directions.",
          value: _navigationEnabled,
          onChanged: (v) {
            setState(() => _navigationEnabled = v);
            _setFeature(FeatureKeys.navigation, v);
          },
        ),
        OnboardingFeatureTile(
          icon: Icons.assistant_rounded,
          title: "Assistant",
          description: "Launch your phone's default voice assistant.",
          value: _assistantEnabled,
          onChanged: (v) {
            setState(() => _assistantEnabled = v);
            _setFeature(FeatureKeys.assistant, v);
          },
        ),
        OnboardingFeatureTile(
          icon: Icons.mic_rounded,
          title: "Voice Notes",
          description: "Quickly record voice memos while riding.",
          value: _voiceNotesEnabled,
          onChanged: (v) {
            setState(() => _voiceNotesEnabled = v);
            _setFeature(FeatureKeys.voiceNotes, v);
          },
        ),
        OnboardingFeatureTile(
          icon: Icons.volume_up_rounded,
          title: "Volume Controls",
          description: "Adjust media volume directly from MotoDash.",
          value: _volumeControlsEnabled,
          onChanged: (v) {
            setState(() => _volumeControlsEnabled = v);
            _setFeature(FeatureKeys.volumeControls, v);
          },
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------------------------------------------
  // APPEARANCE
  // --------------------------------------------------------------------------------------------------------------
  Widget _appearanceStep(int stepNumber, int totalSteps) {
    return OnboardingScaffold(
      title: "Appearance",
      icon: Icons.palette_rounded,
      stepNumber: stepNumber,
      totalSteps: totalSteps,
      onBack: _goBack,
      onContinue: _goNext,
      children: [
        const OnboardingInfoCard(
          text:
              "MotoDash defaults to deep red on black because AMOLED displays use the least power showing red "
              "on a black background.",
          icon: Icons.bolt_rounded,
        ),
        PrefColorTile(label: "Accent Colour", prefKey: PrefKeys.dashboardFontColor, defaultValue: Colors.red),
        const SizedBox(height: 12),
        PrefColorTile(
          label: "Border Colour & Opacity",
          prefKey: PrefKeys.dashboardBorderColor,
          defaultValue: Colors.red.withAlpha(60),
        ),
        const SizedBox(height: 12),
        PrefColorTile(
          label: "Background Colour",
          prefKey: PrefKeys.dashboardBackgroundColor,
          defaultValue: Colors.black,
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------------------------------------------
  // SCREEN SAVER
  // --------------------------------------------------------------------------------------------------------------
  Widget _screenSaverStep(int stepNumber, int totalSteps) {
    return OnboardingScaffold(
      title: "Screen Saver",
      subtitle: "Both options help prevent OLED burn-in.",
      icon: Icons.brightness_low_rounded,
      stepNumber: stepNumber,
      totalSteps: totalSteps,
      onBack: _goBack,
      onContinue: _goNext,
      children: [
        Row(
          children: [
            Expanded(
              child: _ScreenSaverOption(
                title: "Animated",
                icon: Icons.blur_circular_rounded,
                selected: _screenSaverAnimated,
                onTap: () => _setScreenSaverAnimated(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ScreenSaverOption(
                title: "Blank",
                icon: Icons.brightness_1_rounded,
                selected: !_screenSaverAnimated,
                onTap: () => _setScreenSaverAnimated(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const OnboardingWarningCard(
          text:
              "If you choose to turn the screen completely off, make sure you can distinguish between the "
              "display entering screen saver mode and the phone becoming locked.",
        ),
        const SizedBox(height: 8),
        const OnboardingSectionLabel("Brightness"),
        const PrefSliderTile(title: "Brightness", prefKey: PrefKeys.displayBrightness, defaultValue: 0, max: 100),
        Text(
          "0 = Automatic brightness.",
          style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 12.5),
        ),
      ],
    );
  }

  Future<void> _setScreenSaverAnimated(bool animated) async {
    await ConfigProvider.prefs.setBool(PrefKeys.displayScreenSaverAnimation, animated);
    setState(() => _screenSaverAnimated = animated);
  }

  // --------------------------------------------------------------------------------------------------------------
  // SUMMARY
  // --------------------------------------------------------------------------------------------------------------
  Widget _summaryStep(int stepNumber, int totalSteps) {
    final features = <String, bool>{
      "Phone": _phoneEnabled,
      "Music": _musicEnabled,
      "Navigation": _navigationEnabled,
      "Assistant": _assistantEnabled,
      "Voice Notes": _voiceNotesEnabled,
      "Volume Controls": _volumeControlsEnabled,
    };
    final enabled = features.entries.where((e) => e.value).map((e) => e.key).toList();
    final disabled = features.entries.where((e) => !e.value).map((e) => e.key).toList();

    return OnboardingScaffold(
      title: "You're all set",
      subtitle: "Every option here can be changed later from Settings.",
      icon: Icons.check_circle_rounded,
      stepNumber: stepNumber,
      totalSteps: totalSteps,
      onBack: _goBack,
      onContinue: _finish,
      continueLabel: "Start MotoDash",
      children: [
        if (enabled.isNotEmpty) ...[
          const OnboardingSectionLabel("Enabled features"),
          _SummaryChipRow(labels: enabled, color: kOnboardingAccent, icon: Icons.check_rounded),
          const SizedBox(height: 20),
        ],
        if (disabled.isNotEmpty) ...[
          const OnboardingSectionLabel("Disabled features"),
          _SummaryChipRow(labels: disabled, color: Colors.white38, icon: Icons.close_rounded),
          const SizedBox(height: 20),
        ],
        if (_disabledByPermission.isNotEmpty) ...[
          const OnboardingSectionLabel("Disabled due to missing permissions"),
          OnboardingInfoCard(
            text: "${_disabledByPermission.join(", ")} — re-grant permissions in Settings to turn these back on.",
            icon: Icons.privacy_tip_outlined,
          ),
        ],
      ],
    );
  }
}

class _ScreenSaverOption extends StatelessWidget {
  const _ScreenSaverOption({required this.title, required this.icon, required this.selected, required this.onTap});

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kOnboardingCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? kOnboardingAccent : Colors.white.withAlpha(14)),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? kOnboardingAccent : Colors.white54, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white60,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryChipRow extends StatelessWidget {
  const _SummaryChipRow({required this.labels, required this.color, required this.icon});

  final List<String> labels;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels
          .map(
            (label) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withAlpha(24),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withAlpha(90)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 14),
                  const SizedBox(width: 6),
                  Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
