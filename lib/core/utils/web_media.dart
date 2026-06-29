import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS('fetch')
external JSPromise<web.Response> _fetch(JSString url);

/// Downloads [url] fully and wraps it in an in-memory `blob:` URL.
///
/// Playing audio from a blob avoids the HTTP range-request streaming that the
/// HTML `<audio>` element normally uses. On deployed Flutter web builds that
/// streaming is intercepted by the service worker (absent under `flutter run`),
/// which stalls the element in a permanent "loading" state. Loading the whole
/// (small) clip first sidesteps the service worker, range requests and preload
/// quirks entirely.
///
/// Returns null if the fetch fails (caller should fall back to the direct URL).
/// The caller owns the returned URL and must [revokeBlobUrl] it when done.
Future<String?> fetchAsBlobUrl(String url) async {
  try {
    final resp = await _fetch(url.toJS).toDart;
    if (!resp.ok) return null;
    final blob = await resp.blob().toDart;
    return web.URL.createObjectURL(blob);
  } catch (_) {
    return null;
  }
}

/// Releases a `blob:` URL created by [fetchAsBlobUrl].
void revokeBlobUrl(String blobUrl) {
  try {
    web.URL.revokeObjectURL(blobUrl);
  } catch (_) {}
}
