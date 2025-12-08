import 'package:shared_preferences/shared_preferences.dart';

Future<Duration> loadBlankTimeDuration() async {
  final prefs = await SharedPreferences.getInstance();
  final str = prefs.getString("blank_time_minutes");

  final minutes = int.tryParse(str ?? "") ?? 2; // default: 2 minutes
  return Duration(minutes: minutes);
}
