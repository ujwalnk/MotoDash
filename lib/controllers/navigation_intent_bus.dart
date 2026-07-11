// Author: Ujwal N K
// Created: 2026.07.09

import 'dart:async';

import 'navigation_intent_handler.dart' show NavigationIntent;

// Central event bus for application navigation intents.
//
// Navigation intent providers should emit [NavigationIntent] events through this bus instead of performing navigation
// directly. The navigation controller is responsible for consuming these events and coordinating all subsequent
// navigation behavior.
class NavigationIntentBus {
  NavigationIntentBus._(); // Prevent instantiation

  /// Broadcast [StreamController] that distributes [NavigationIntent] events to all active subscribers.
  ///
  /// Created as a broadcast controller to support multiple concurrent listeners without buffering events for future
  /// subscribers.
  static final StreamController<NavigationIntent> _controller = StreamController<NavigationIntent>.broadcast();

  /// Broadcast stream of [NavigationIntent] events emitted through [_controller].
  ///
  /// Returns the shared stream for subscribing to navigation intent notifications.
  static Stream<NavigationIntent> get stream => _controller.stream;

  /// Publishes a [NavigationIntent] to all active subscribers of [stream].
  ///
  /// Side effects:
  /// - Adds [intent] to [_controller].
  ///
  /// State mutations:
  /// - Appends [intent] to [_controller].
  ///
  /// External variables modified: None.
  ///
  /// Navigation calls: None.
  ///
  /// Async behavior: None.
  static void emit(NavigationIntent intent) => _controller.add(intent);

  /// Closes [_controller] and releases its resources.
  ///
  /// After completion, no further events can be emitted or delivered through [stream].
  ///
  /// Side effects:
  /// - Closes [_controller].
  ///
  /// State mutations:
  /// - Transitions [_controller] to the closed state.
  ///
  /// External variables modified: None.
  ///
  /// Navigation calls: None.
  ///
  /// Async behavior:
  /// - Completes after [_controller] has finished closing.
  static Future<void> dispose() async => await _controller.close();
}
