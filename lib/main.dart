import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reader_app/model/bookmark.dart';
import 'package:reader_app/model/scroll.dart';
import 'package:reader_app/user_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  return runApp(
    MaterialApp(
      home: const WebViewExample(),
      theme: ThemeData(
        useMaterial3: true,
      ),
    ),
  );
}

class WebViewExample extends StatefulWidget {
  const WebViewExample({super.key});

  @override
  State<WebViewExample> createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  late final WebViewController controller;
  SharedPreferences? prefs;
  Scroll? scroll;
  bool playing = false;

  void loadRequest(String uri) {
    controller.loadRequest(Uri.parse(uri));
  }

  void scrolling() {
    if (!playing || scroll == null) return;
    controller.runJavaScript('''
      window.scrollBy({
        top: ${scroll!.span},
        left: 0,
        behavior: 'smooth'
      });
    ''');
    Future.delayed(Duration(milliseconds: scroll!.interval), scrolling);
  }

  @override
  void initState() {
    super.initState();

    // #docregion webview_controller
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://flutter.dev'));

    if (scroll == null) {
      SharedPreferences.getInstance().then((prefs) {
        setState(() {
          this.prefs = prefs;
          scroll = Scroll(prefs);
        });
      });
    }
  }

  // #docregion webview_widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(controller: controller),
      appBar: AppBar(
        title: const Text('Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              controller.loadRequest(Uri.parse('https://www.google.com/'));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller.reload();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: const Text('Open Bookmark'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (dialogContext) {
                    final List<String> data =
                        prefs?.getStringList('bookmarks') ?? <String>[];
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
                                loadRequest(bookmark.url);
                                Navigator.pop(dialogContext);
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            ListTile(
              title: const Text('Add Bookmark'),
              onTap: () async {
                Navigator.pop(context);
                if (prefs == null) return;
                final List<String> data =
                    prefs?.getStringList('bookmarks') ?? <String>[];
                final String title = await controller.getTitle() ?? 'Untitled';
                final String url = await controller.currentUrl() ?? '';
                final bookmark = Bookmark(title, url);
                if (data.contains(bookmark.toString())) return;
                data.add(bookmark.toString());
                prefs?.setStringList('bookmarks', data);
              },
            ),
            ListTile(
              title: const Text('Remove Bookmark'),
              onTap: () async {
                Navigator.pop(context);
                if (prefs == null) return;
                final List<String> data =
                    prefs?.getStringList('bookmarks') ?? <String>[];
                final String title = await controller.getTitle() ?? 'Untitled';
                final String url = await controller.currentUrl() ?? '';
                final bookmark = Bookmark(title, url);
                if (!data.contains(bookmark.toString())) return;
                data.remove(bookmark.toString());
                prefs?.setStringList('bookmarks', data);
              },
            ),
            ListTile(
              title: const Text('Go To Top'),
              onTap: () {
                Navigator.pop(context);
                controller.runJavaScript('''
                  window.scrollTo({
                    top: 0,
                    left: 0,
                    behavior: 'instant'
                  });
                ''');
              },
            ),
            ListTile(
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserSettings(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(playing ? Icons.pause : Icons.play_arrow),
        onPressed: () => setState(() {
          playing = !playing;
          if (playing) {
            scrolling();
          }
        }),
      ),
    );
  }
  // #enddocregion webview_widget
}
