// Author: Ujwal N K /w Claude
// Created: 2026.08.08
// Shared visual building blocks for the first-run onboarding flow. Kept separate from the step content itself so
// every step looks and animates identically without repeating layout code.

import 'package:flutter/material.dart';

/// MotoDash's onboarding accent — matches the red used throughout the rest of the app (dashboard defaults, sliders,
/// permission screen).
const Color kOnboardingAccent = Colors.redAccent;
const Color kOnboardingBg = Colors.black;
const Color kOnboardingCard = Color(0xFF121212);

/// Common page chrome for every onboarding step: a top progress bar, scrollable body, and a bottom action bar with
/// an optional Back button and a primary Continue button.
///
/// [stepNumber] / [totalSteps] are 1-based and drive the progress bar. Passing a fresh [totalSteps] on every build
/// is what lets the indicator recalculate itself as feature pages are skipped.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    required this.stepNumber,
    required this.totalSteps,
    this.onContinue,
    this.onBack,
    this.continueLabel = "Continue",
    this.icon,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final int stepNumber;
  final int totalSteps;
  final VoidCallback? onContinue;
  final VoidCallback? onBack;
  final String continueLabel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      color: kOnboardingBg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _OnboardingProgressBar(stepNumber: stepNumber, totalSteps: totalSteps, onBack: onBack),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (icon != null) ...[
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: kOnboardingAccent.withAlpha(28),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: kOnboardingAccent, size: 28),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        subtitle!,
                        style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 15.5, height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 28),
                    ...children,
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 16 + bottomInset),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOnboardingAccent,
                    disabledBackgroundColor: Colors.white.withAlpha(20),
                    foregroundColor: Colors.black,
                    disabledForegroundColor: Colors.white38,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(continueLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingProgressBar extends StatelessWidget {
  const _OnboardingProgressBar({required this.stepNumber, required this.totalSteps, this.onBack});

  final int stepNumber;
  final int totalSteps;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final double progress = totalSteps <= 0 ? 0 : (stepNumber / totalSteps).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 24, 4),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: onBack == null
                ? null
                : IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18),
                  ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: Colors.white.withAlpha(20),
                  valueColor: const AlwaysStoppedAnimation(kOnboardingAccent),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text(
              "$stepNumber/$totalSteps",
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps step transitions in a subtle fade + slide, keyed by the caller so `AnimatedSwitcher` knows when to
/// transition versus rebuild in place.
class OnboardingStepTransition extends StatelessWidget {
  const OnboardingStepTransition({super.key, required this.child, required this.stepKey});

  final Widget child;
  final Object stepKey;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(key: ValueKey(stepKey), child: child),
    );
  }
}

/// A large, tappable feature-enable row used on the "Features" step. Deliberately larger than a settings list tile
/// to keep touch targets generous while riding gear is on.
class OnboardingFeatureTile extends StatelessWidget {
  const OnboardingFeatureTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: kOnboardingCard,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onChanged(!value),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: value ? kOnboardingAccent.withAlpha(90) : Colors.white.withAlpha(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (value ? kOnboardingAccent : Colors.white).withAlpha(22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: value ? kOnboardingAccent : Colors.white54, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(description, style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 13)),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  thumbColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) => states.contains(WidgetState.selected) ? kOnboardingAccent : null,
                  ),
                  trackColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) => states.contains(WidgetState.selected) ? kOnboardingAccent.withAlpha(100) : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Muted informational note card — used for explanatory or "how this works" copy inside a step.
class OnboardingInfoCard extends StatelessWidget {
  const OnboardingInfoCard({super.key, required this.text, this.icon = Icons.info_outline_rounded});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kOnboardingCard, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13.5, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

/// Amber warning/notice card — used for the safety and hardware-limitation callouts the spec calls out explicitly
/// (screen saver vs. lock screen, phone-must-be-unlocked for navigation, etc.).
class OnboardingWarningCard extends StatelessWidget {
  const OnboardingWarningCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    const Color amber = Color(0xFFFFB74D);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: amber.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: amber.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: amber, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: amber, fontSize: 13.5, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

/// Shown after a permission request is denied — explains the feature was disabled and that it can be re-enabled
/// later. Never blocks progress; onboarding always continues.
class OnboardingPermissionDeniedCard extends StatelessWidget {
  const OnboardingPermissionDeniedCard({super.key, required this.featureName});

  final String featureName;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kOnboardingAccent.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kOnboardingAccent.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.block_rounded, color: kOnboardingAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$featureName has been disabled because the required permission wasn't granted. "
              "You can enable it later from Settings.",
              style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section label used to break up a step's body (e.g. "Favourite Contacts" within the Phone step).
class OnboardingSectionLabel extends StatelessWidget {
  const OnboardingSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withAlpha(120),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
