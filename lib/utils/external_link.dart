import 'package:url_launcher/url_launcher.dart';

/// Opens [uri] in an external browser. Returns false when no handler exists.
Future<bool> openExternalUrl(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
