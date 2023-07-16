import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reader_app/bookmark_helper.dart';
import 'package:reader_app/model/scroll.dart';
import 'package:reader_app/user_settings.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  return runApp(
    MaterialApp(
      home: const AppMain(),
      theme: ThemeData(
        useMaterial3: true,
      ),
    ),
  );
}

class AppMain extends StatefulWidget {
  const AppMain({super.key});

  @override
  State<AppMain> createState() => _AppMainState();
}

class _AppMainState extends State<AppMain> {
  StreamSubscription? _intentDataStreamSubscription;
  late final WebViewController controller;
  late final SharedPreferences prefs;
  late final BookmarkHelper bookmarkHelper;
  Scroll? scroll;
  bool playing = false;
  bool showAppBar = true;
  bool activeScrollListener = true;
  String? title;

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

  void reload() {
    controller.reload();
  }

  void setTitle() {
    controller.getTitle().then((title) {
      setState(() {
        this.title = title;
      });
    });
  }

  void showUriInput(BuildContext context, String oriUri) async {
    final String? url = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        final TextEditingController inputCtrl = TextEditingController();
        inputCtrl.text = oriUri;
        return AlertDialog(
          title: const Text('輸入 URL'),
          content: TextField(
            controller: inputCtrl,
            decoration: const InputDecoration(
              labelText: 'URL',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, inputCtrl.text);
              },
              child: const Text('前往'),
            ),
          ],
        );
      },
    );
    if (url != null) {
      controller.loadRequest(Uri.parse(url));
    }
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
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
            prefs.setString('lastUri', url);
          },
          onPageFinished: (String url) {
            setTitle();
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    // subscribe to share intent
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
      controller.loadRequest(Uri.parse(value));
    });

    // handle shared text on app start on Android
    ReceiveSharingIntent.getInitialText().then((String? value) {
      if (value != null) {
        controller.loadRequest(Uri.parse(value));
      }
    });

    if (scroll == null) {
      SharedPreferences.getInstance().then((prefs) {
        setState(() {
          this.prefs = prefs;
          bookmarkHelper = BookmarkHelper(controller, prefs);
          scroll = Scroll(prefs);
          controller.loadRequest(Uri.parse(
              prefs.getString('lastUri') ?? 'https://www.google.com/'));
        });
      });
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
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
                elevation: 10,
                backgroundColor: Colors.white70,
                title: Text(
                  title ?? '',
                  style: const TextStyle(fontSize: 12.0),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      controller.currentUrl().then((uri) {
                        if (uri == null) return;
                        showUriInput(context, uri);
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark),
                    onPressed: () => bookmarkHelper.openBookmark(context),
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
              title: const Text('重新整理'),
              leading: const Icon(Icons.refresh),
              onTap: reload,
            ),
            ListTile(
              title: const Text('回到頁面頂端'),
              leading: const Icon(Icons.arrow_upward),
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
              title: const Text('上一頁'),
              leading: const Icon(Icons.arrow_back),
              onTap: () {
                Navigator.pop(context);
                controller.canGoBack().then((canGoBack) {
                  if (canGoBack) {
                    controller.goBack();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No more pages.'),
                      ),
                    );
                  }
                });
              },
            ),
            ListTile(
              title: const Text('下一頁'),
              leading: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.pop(context);
                controller.canGoForward().then((canGoForward) {
                  if (canGoForward) {
                    controller.goForward();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No more pages.'),
                      ),
                    );
                  }
                });
              },
            ),
            ListTile(
              title: const Text('以其他應用程式開啟'),
              leading: const Icon(Icons.open_in_new),
              onTap: () {
                Navigator.pop(context);
                controller.currentUrl().then((uri) {
                  if (uri == null) return;
                  try {
                    launchUrl(Uri.parse(uri),
                        mode: LaunchMode.externalApplication);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('無法開啟連結'),
                      ),
                    );
                  }
                });
              },
            ),
            ListTile(
              title: const Text('設定'),
              leading: const Icon(Icons.settings),
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
        tooltip: playing ? '暫停' : '播放',
        onPressed: () => setState(() {
          playing = !playing;
          showAppBar = !playing;
          if (playing) {
            scrolling();
          }
        }),
        child: Icon(playing ? Icons.pause : Icons.play_arrow),
      ),
    );
  }
}
