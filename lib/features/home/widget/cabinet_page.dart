import 'package:flutter/material.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CabinetPage extends ConsumerStatefulWidget {
  const CabinetPage({super.key, required this.onSubscriptionImported});

  final VoidCallback onSubscriptionImported;

  @override
  ConsumerState<CabinetPage> createState() => _CabinetPageState();
}

class _CabinetPageState extends ConsumerState<CabinetPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isImporting = false;

  static const String _cabinetUrl = 'https://skydpi.online';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0E0D15))
      ..addJavaScriptChannel(
        'XPlatformBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _handleDeepLinkImport(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
            _controller.runJavaScript('''
              (function() {
                if (window._xpHooked) return;
                window._xpHooked = true;

                function checkAndSend(url) {
                  if (!url || typeof url !== 'string') return false;
                  if (
                    url.startsWith('xplatform://') ||
                    url.startsWith('hiddify://') ||
                    url.startsWith('happ://') ||
                    url.startsWith('v2raytun://') ||
                    url.startsWith('v2rayng://')
                  ) {
                    XPlatformBridge.postMessage(url);
                    return true;
                  }
                  return false;
                }

                const origOpen = window.open;
                window.open = function(url) {
                  if (checkAndSend(url)) return null;
                  return origOpen.apply(this, arguments);
                };

                document.addEventListener('click', function(e) {
                  var a = e.target.closest('a');
                  if (a && checkAndSend(a.href)) {
                    e.preventDefault();
                    e.stopPropagation();
                    return;
                  }
                }, true);

                const origAppend = Element.prototype.appendChild;
                Element.prototype.appendChild = function(el) {
                  if (el && el.tagName === 'IFRAME' && checkAndSend(el.src)) {
                    return el;
                  }
                  return origAppend.apply(this, arguments);
                };
              })();
            ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;

            if (url.startsWith('xplatform://') ||
                url.startsWith('hiddify://') ||
                url.startsWith('happ://') ||
                url.startsWith('v2rayng://') ||
                url.startsWith('v2raytun://')) {
              _handleDeepLinkImport(url);
              return NavigationDecision.prevent;
            }

            if (!url.startsWith(_cabinetUrl) &&
                !url.startsWith('https://telegram.org')) {
              final uri = Uri.tryParse(url);
              if (uri != null) {
                launchUrl(uri, mode: LaunchMode.externalApplication);
                return NavigationDecision.prevent;
              }
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_cabinetUrl));
  }

  Future<void> _handleDeepLinkImport(String rawUrl) async {
    if (_isImporting) return;
    String? subUrl;
    final uri = Uri.tryParse(rawUrl);

    if (uri != null) {
      if (uri.queryParameters.containsKey('url')) {
        subUrl = uri.queryParameters['url'];
      } else {
        final idx = rawUrl.indexOf('https://');
        if (idx != -1) {
          subUrl = Uri.decodeFull(rawUrl.substring(idx));
        } else {
          final httpIdx = rawUrl.indexOf('http://');
          if (httpIdx != -1) {
            subUrl = Uri.decodeFull(rawUrl.substring(httpIdx));
          }
        }
      }
    }

    if (subUrl != null && subUrl.startsWith('http')) {
      setState(() => _isImporting = true);
      try {
        await ref.read(addProfileNotifierProvider.notifier).addClipboard(subUrl);
        // Ждем, пока база данных обновит активный профиль
        await Future.delayed(const Duration(milliseconds: 600));
        await ref.read(activeProfileProvider.future);
      } finally {
        if (mounted) {
          setState(() => _isImporting = false);
          widget.onSubscriptionImported();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0D15),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
              ),
            if (_isImporting)
              Container(
                color: const Color(0xE60E0D15),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF7B61FF)),
                      SizedBox(height: 16),
                      Text(
                        'Загрузка подписки и серверов...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              right: 12,
              bottom: 12,
              child: FloatingActionButton.small(
                heroTag: 'reload_cabinet',
                backgroundColor: const Color(0xFF1A1829),
                foregroundColor: const Color(0xFF7B61FF),
                onPressed: () => _controller.reload(),
                child: const Icon(Icons.refresh_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
