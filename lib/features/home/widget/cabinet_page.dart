import 'package:flutter/material.dart';
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

  static const String _cabinetUrl = 'https://cabinet.skydpi.online';

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
            // Перехватываем клики по deep-link ссылкам, если сайт открывает их через JS
            _controller.runJavaScript('''
              document.addEventListener('click', function(e) {
                var a = e.target.closest('a');
                if (a && a.href && (
                  a.href.startsWith('xplatform://') ||
                  a.href.startsWith('hiddify://') ||
                  a.href.startsWith('happ://') ||
                  a.href.startsWith('v2raytun://') ||
                  a.href.startsWith('v2rayng://')
                )) {
                  e.preventDefault();
                  XPlatformBridge.postMessage(a.href);
                }
              }, true);
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
      await ref.read(addProfileNotifierProvider.notifier).addClipboard(subUrl);
      if (mounted) {
        widget.onSubscriptionImported();
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
