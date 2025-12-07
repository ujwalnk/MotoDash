import 'package:url_launcher/url_launcher.dart';

Future<void> callNumber(String number) async {
  final Uri uri = Uri(scheme: 'tel', path: number);

  if (!await launchUrl(uri)) {
    throw 'Could not open dialer';
  }
}
