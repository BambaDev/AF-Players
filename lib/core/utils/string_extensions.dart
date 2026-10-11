extension StringCleaning on String {
  String stripHtmlTags() {
    return replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  String normalizeWhitespace() {
    return replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String cleanSubtitle() {
    return stripHtmlTags().normalizeWhitespace();
  }
}
