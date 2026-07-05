// Author: Ujwal N K
// Created:
// Global services

import 'package:moto_dash/controllers/magnet_intent_detector.dart';
import 'package:moto_dash/services/tts_service.dart';

final MagnetIntentService magnetService = MagnetIntentService();
final TtsService ttsService = TtsService();

/// Set to true whenever a navigation was triggered via magnet.
/// Screens will read this to decide whether to auto-speak.
bool lastNavigationWasMagnet = false;
