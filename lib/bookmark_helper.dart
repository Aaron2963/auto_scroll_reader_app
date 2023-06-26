import 'package:flutter/material.dart';
import 'package:reader_app/model/bookmark.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BookmarkHelper {
  final WebViewController controller;
  final SharedPreferences prefs;

  BookmarkHelper(this.controller, this.prefs);

  void openBookmark(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final List<String> data =
            prefs.getStringList('bookmarks') ?? <String>[];
        final List<Bookmark> bookmarks =
            data.map((e) => Bookmark.fromString(e)).toList();
        return AlertDialog(
          title: const Text('Bookmarks'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                final bookmark = bookmarks[index];
                return ListTile(
                  title: Text(bookmark.title),
                  subtitle: Text(bookmark.url),
                  onTap: () {
                    controller.loadRequest(Uri.parse(bookmark.url));
                    Navigator.pop(dialogContext);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void addBookmark(BuildContext context) async {
    final List<String> data = prefs.getStringList('bookmarks') ?? <String>[];
    final String title = await controller.getTitle() ?? 'Untitled';
    final String url = await controller.currentUrl() ?? '';
    final bookmark = Bookmark(title, url);
    if (data.contains(bookmark.toString())) return;
    data.add(bookmark.toString());
    prefs.setStringList('bookmarks', data);
  }

  void removeBookmark(BuildContext context) async {
    final List<String> data = prefs.getStringList('bookmarks') ?? <String>[];
    final String title = await controller.getTitle() ?? 'Untitled';
    final String url = await controller.currentUrl() ?? '';
    final bookmark = Bookmark(title, url);
    if (!data.contains(bookmark.toString())) return;
    data.remove(bookmark.toString());
    prefs.setStringList('bookmarks', data);
  }
}
