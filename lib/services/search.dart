import '../models/equipment.dart';

/// Search used by the products screen for typed and spoken text.
///
/// It is forgiving because voice recognition is not perfect:
/// - extra words are ignored ("show me the rackets" -> "rackets")
/// - singular / plural both match ("ball" finds "Balls")
/// - one wrong letter is accepted ("rocket" finds "racket")
/// - name, category and description are all searched
List<Equipment> searchEquipment(List<Equipment> all, String query) {
  final words = _words(query).where((w) => !_ignoredWords.contains(w)).toList();
  if (words.isEmpty) return all;

  // First try items that match every word, e.g. "head racket"
  final exact = all.where((e) => words.every((w) => _matches(e, w))).toList();
  if (exact.isNotEmpty) return exact;

  // Otherwise show items that match at least one word
  return all.where((e) => words.any((w) => _matches(e, w))).toList();
}

/// Words said around the real search words that should not be searched for.
const _ignoredWords = {
  'a', 'an', 'the', 'i', 'me', 'my', 'we', 'show', 'find', 'search', 'for',
  'want', 'need', 'some', 'any', 'please', 'rent', 'get', 'give', 'looking',
  'to', 'of', 'and', 'with', 'is', 'are', 'do', 'you', 'have', 'all', 'padel',
};

bool _matches(Equipment e, String word) {
  final text = _words('${e.name} ${e.categoryName} ${e.description}');
  final w = _singular(word);
  for (final t in text) {
    final s = _singular(t);
    if (s.startsWith(w) || s == w) return true;
    // Allow one wrong letter in longer words (speech mistakes)
    if (w.length >= 4 && _oneEditAway(s, w)) return true;
  }
  return false;
}

/// "Rackets, Balls!" -> ["rackets", "balls"]
List<String> _words(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
    .split(' ')
    .where((w) => w.isNotEmpty)
    .toList();

/// "rackets" -> "racket", "shoes" -> "shoe", "accessories" -> "accessory"
String _singular(String w) {
  if (w.length > 4 && w.endsWith('ies')) return '${w.substring(0, w.length - 3)}y';
  if (w.length > 3 && w.endsWith('s') && !w.endsWith('ss')) {
    return w.substring(0, w.length - 1);
  }
  return w;
}

/// True if a and b differ by one changed, added or removed letter.
bool _oneEditAway(String a, String b) {
  if ((a.length - b.length).abs() > 1) return false;
  var i = 0, j = 0, edits = 0;
  while (i < a.length && j < b.length) {
    if (a[i] == b[j]) {
      i++;
      j++;
      continue;
    }
    if (++edits > 1) return false;
    if (a.length > b.length) {
      i++;
    } else if (a.length < b.length) {
      j++;
    } else {
      i++;
      j++;
    }
  }
  return edits + (a.length - i) + (b.length - j) <= 1;
}
