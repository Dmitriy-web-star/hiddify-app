import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/features/proxy/active/active_proxy_card.dart';
import 'package:hiddify/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeProfileProvider);
    final connectionState = ref.watch(connectionNotifierProvider);
    final activeCard = ref.watch(activeProxyCardProvider);
    final pendingTap = useState(false);

    final status = connectionState.valueOrNull ?? const Disconnected();
    final isConnected = status is Connected;
    final isBusy = pendingTap.value || status is Connecting || status is Disconnecting || status is Waiting;

    useEffect(() {
      if (status is Connected || status is Disconnected) {
        pendingTap.value = false;
      }
      return null;
    }, [status]);

    final ringColor = isConnected
        ? const Color(0xFF00E676)
        : isBusy
            ? const Color(0xFF7B61FF)
            : const Color(0xFF3A3556);

    final statusText = isConnected
        ? 'Подключено'
        : isBusy
            ? 'Подключение...'
            : 'Нажмите для подключения';

    return Scaffold(
      backgroundColor: const Color(0xFF0E0D15),
            appBar: AppBar(
        backgroundColor: const Color(0xFF0E0D15),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/source/ic_launcher_foreground.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const Gap(10),
            const Text('X-Platform VPN', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4)),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Раздача прокси / VPN',
            icon: const Icon(Icons.wifi_tethering_rounded, color: Colors.white70),
            onPressed: () => ref.read(dialogNotifierProvider.notifier).showLocalProxy(),
          ),
          IconButton(
            tooltip: 'Подключить Android TV (QR)',
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF7B61FF)),
            onPressed: () => ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile(),
          ),
          const Gap(6),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              switch (activeProfile) {
                AsyncData(value: final profile?) => ProfileTile(
                    profile: profile,
                    isMain: true,
                    margin: const EdgeInsets.only(top: 8),
                  ),
                _ => Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181624),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2A263D)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Color(0xFF7B61FF)),
                        Gap(12),
                        Expanded(
                          child: Text(
                            'Нет активной подписки. Откройте вкладку «Кабинет» внизу экрана.',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
              },
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        pendingTap.value = true;
                        ref.read(connectionNotifierProvider.notifier).toggleConnection();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 164,
                        height: 164,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF181624),
                          border: Border.all(color: ringColor, width: 3.5),
                          boxShadow: [
                            BoxShadow(
                              color: ringColor.withValues(alpha: isConnected || isBusy ? 0.38 : 0.12),
                              blurRadius: 32,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: isBusy && !isConnected
                              ? const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(color: Color(0xFF7B61FF), strokeWidth: 3.5),
                                )
                              : Icon(
                                  Icons.power_settings_new_rounded,
                                  size: 68,
                                  color: isConnected ? const Color(0xFF00E676) : Colors.white,
                                ),
                        ),
                      ),
                    ),
                    const Gap(20),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isConnected ? const Color(0xFF00E676) : Colors.white,
                      ),
                    ),
                    const Gap(6),
                    if (isConnected) const ActiveProxyDelayIndicator(),
                  ],
                ),
              ),
              if (isConnected) const ActiveProxyFooter(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: const Color(0xFF0E0D15),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (_) => const SizedBox(height: 620, child: ProxiesOverviewPage()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181624),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2B2740)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B61FF).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.public_rounded, color: Color(0xFF7B61FF), size: 22),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Выбор локации / серверов',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              Text(
                                activeCard != null ? 'Нажмите, чтобы сменить сервер' : 'Все серверы подписки и пинг',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
