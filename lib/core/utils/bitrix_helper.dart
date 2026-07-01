import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';

/// Normalizes a phone into Bitrix24 dial format: keeps a leading `+` and the
/// digits, dropping spaces, dashes and parentheses.
String _normalizeBitrixPhone(String phone) {
  final trimmed = phone.trim();
  final hasPlus = trimmed.startsWith('+');
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  return hasPlus ? '+$digits' : digits;
}

/// Builds the Bitrix24 web click-to-call link for [phone].
///
/// Opens the Bitrix24 web messenger / telephony panel and immediately starts
/// dialing the number:
///   `https://<portal>/online/?IM_DIAL=%2B998901234567`
///
/// Built with [Uri.https] so the leading `+` is percent-encoded as `%2B` — a
/// raw `+` in a query string is decoded to a space by the server, which was the
/// reason the number never dialed correctly before.
Uri buildBitrixCallUri(String phone) {
  return Uri.https(kBitrixDomain, '/online/', {
    'IM_DIAL': _normalizeBitrixPhone(phone),
  });
}

/// Opens the Bitrix24 call screen for [phone] in a new tab (web) / external app,
/// with the number prefilled and ready to call.
///
/// The operator must be signed in to Bitrix24 in the same browser. Returns
/// false when the phone is empty or the URL can't be launched.
Future<bool> launchBitrixCall(String phone) async {
  if (phone.trim().isEmpty) return false;
  return launchUrl(
    buildBitrixCallUri(phone),
    mode: LaunchMode.externalApplication,
  );
}
