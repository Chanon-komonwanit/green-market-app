import 'package:string_similarity/string_similarity.dart';

/// Returns true if [query] and [text] are similar enough (fuzzy match).
/// This is case-insensitive and works for Thai and English.
bool isFuzzyMatch(String query, String text, {double threshold = 0.5}) {
  if (query.trim().isEmpty || text.trim().isEmpty) return false;
  final score = StringSimilarity.compareTwoStrings(
      query.trim().toLowerCase(), text.trim().toLowerCase());
  return score >= threshold;
}

/// Returns the similarity score between [query] and [text] (0.0 - 1.0).
double fuzzyScore(String query, String text) {
  return StringSimilarity.compareTwoStrings(
      query.trim().toLowerCase(), text.trim().toLowerCase());
}
