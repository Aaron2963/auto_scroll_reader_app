class Bookmark {
  final String title;
  final String url;

  Bookmark(this.title, this.url);

  factory Bookmark.fromString(String content) {
    List<String> cts = content.split('\n');
    return Bookmark(cts[0], cts.sublist(1).join('\n'));
  }

  toString() {
    return '$title\n$url';
  }
}
