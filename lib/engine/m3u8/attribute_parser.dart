/// Parses HLS attribute lists of the form
/// `KEY=VALUE,KEY="quoted value",...` used by tags such as
/// `#EXT-X-STREAM-INF` and `#EXT-X-KEY`.
library;

/// Parses an attribute list string into an ordered map.
///
/// Handles quoted values (which may contain commas) and unquoted tokens.
/// Returns an empty map for null/blank input.
Map<String, String> parseAttributeList(String? input) {
  final result = <String, String>{};
  if (input == null) return result;
  final text = input.trim();
  if (text.isEmpty) return result;

  var i = 0;
  final n = text.length;
  while (i < n) {
    // Skip leading separators/whitespace.
    while (i < n && (text[i] == ',' || text[i] == ' ')) {
      i++;
    }
    if (i >= n) break;

    // Read key up to '='.
    final eq = text.indexOf('=', i);
    if (eq == -1) break;
    final key = text.substring(i, eq).trim();
    i = eq + 1;
    if (key.isEmpty) {
      // Malformed; advance to avoid infinite loop.
      final nextComma = text.indexOf(',', i);
      i = nextComma == -1 ? n : nextComma + 1;
      continue;
    }

    String value;
    if (i < n && text[i] == '"') {
      // Quoted value: find the closing quote.
      final close = text.indexOf('"', i + 1);
      if (close == -1) {
        value = text.substring(i + 1);
        i = n;
      } else {
        value = text.substring(i + 1, close);
        i = close + 1;
      }
    } else {
      // Unquoted value: read until comma.
      final comma = text.indexOf(',', i);
      if (comma == -1) {
        value = text.substring(i).trim();
        i = n;
      } else {
        value = text.substring(i, comma).trim();
        i = comma + 1;
      }
    }
    result[key] = value;
  }
  return result;
}
