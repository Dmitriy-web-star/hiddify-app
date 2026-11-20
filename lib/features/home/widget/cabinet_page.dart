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
      ..setBackgroundColor(const Color(0xFF121318))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;

            // Перехватываем deep-link ссылки автоимпорта из кабинета Bedolaga
            if (url.startsWith('hiddify://') ||
                url.startsWith('happ://') ||
                url.startsWith('v2rayng://') ||
                url.startsWith('v2raytun://')) {
              _handleDeepLinkImport(url);
              return NavigationDecision.prevent;
            }

            // Внешние ссылки (Telegram-бот, оплата и т.д.) открываем в системе
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
      // Достаем ?url=... если ссылка вида hiddify://import/https://... или ?url=https://...
      if (uri.queryParameters.containsKey('url')) {
        subUrl = uri.queryParameters['url'];
      } else {
        final idx = rawUrl.indexOf('https://');
        if (idx != -1) {
          subUrl = Uri.decodeFull(rawUrl.substring(idx));
        }
      }
    }

    if (subUrl != null && subUrl.startsWith('http')) {
      await ref.read(addProfileProvider.notifier).add(subUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Подписка успешно добавлена! Нажмите кнопку подключения.')),
        );
        widget.onSubscriptionImported();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Личный кабинет'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
