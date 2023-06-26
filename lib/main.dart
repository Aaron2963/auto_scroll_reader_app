import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reader_app/bookmark_helper.dart';
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
  late final SharedPreferences prefs;
  late final BookmarkHelper bookmarkHelper;
  Scroll? scroll;
  bool playing = false;
  bool showAppBar = true;
  bool activeScrollListener = true;

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
          bookmarkHelper = BookmarkHelper(controller, prefs);
          scroll = Scroll(prefs);
        });
      });
    }
  }

  void reload() {
    controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: showAppBar ? 56 : 0,
              child: AppBar(
                title: const Text('Reader'),
                elevation: 10,
                backgroundColor: Colors.white70,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      controller
                          .loadRequest(Uri.parse('https://www.google.com/'));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: reload,
                  ),
                ],
              ),
            ),
            Expanded(child: WebViewWidget(controller: controller)),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: const Text('Open Bookmark'),
              onTap: () {
                Navigator.pop(context);
                bookmarkHelper.openBookmark(context);
              },
            ),
            ListTile(
              title: const Text('Add Bookmark'),
              onTap: () {
                Navigator.pop(context);
                bookmarkHelper.addBookmark(context);
              },
            ),
            ListTile(
              title: const Text('Remove Bookmark'),
              onTap: () {
                Navigator.pop(context);
                bookmarkHelper.removeBookmark(context);
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
          showAppBar = !playing;
          if (playing) {
            scrolling();
          }
        }),
      ),
    );
  }
}
