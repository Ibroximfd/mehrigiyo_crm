/// Money / number formatting helpers shared across the app.
///
/// All amounts are shown in full — never rounded to "ming"/"mln" — with the
/// integer part grouped by thousands using a thin space, e.g. 16900 → "16 900".
library;

/// Full amount in so'm: `16900` → `"16 900 so'm"`.
String formatSom(num amount) => '${groupThousands(amount)} so\'m';

/// Groups the integer part by thousands without rounding.
/// `16900` → `"16 900"`, `1234.5` → `"1 234.5"`, `-500` → `"-500"`.
String groupThousands(num value) {
  final isWhole = value == value.roundToDouble();
  final raw = isWhole ? value.toInt().toString() : trimZero(value);
  final negative = raw.startsWith('-');
  final body = negative ? raw.substring(1) : raw;
  final dot = body.indexOf('.');
  final intPart = dot == -1 ? body : body.substring(0, dot);
  final fracPart = dot == -1 ? '' : body.substring(dot);
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(' ');
    buf.write(intPart[i]);
  }
  return '${negative ? '-' : ''}$buf$fracPart';
}

/// Drops a trailing ".0" so whole values read "12" not "12.0".
String trimZero(num value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toString();
}
