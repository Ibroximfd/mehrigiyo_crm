import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';

/// Builds the Bitrix24 click-to-call deep link for [phone].
///
/// Strips spaces, dashes and parentheses but keeps the leading `+` and digits:
///   `https://<portal>/telephony/call/?PHONE_NUMBER=+998901234567`
String buildBitrixCallUrl(String phone) {
  final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  return 'https://$kBitrixDomain/telephony/call/?PHONE_NUMBER=$cleaned';
}

/// Opens the Bitrix24 call screen for [phone] in a new tab (web) / external app.
/// Returns false when the phone is empty or the URL can't be launched.
Future<bool> launchBitrixCall(String phone) async {
  if (phone.trim().isEmpty) return false;
  final uri = Uri.parse(buildBitrixCallUrl(phone));
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
