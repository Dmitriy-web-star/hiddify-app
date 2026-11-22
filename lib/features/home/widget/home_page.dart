import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
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

    useEffect(() {
      final timer = Timer.periodic(const Duration(hours: 1), (_) {
        final profile = ref.read(activeProfileProvider).valueOrNull;
        if (profile is RemoteProfileEntity) {
          ref.read(updateProfileNotifierProvider(profile.id).notifier).updateProfile(profile);
        }
      });
      return timer.cancel;
    }, const []);

    final status = connectionState.valueOrNull ?? const Disconnected();
    final isConnected = status is Connected;
    final isBusy = pendingTap.value || status is Connecting || status is Disconnecting || status is Waiting;

    useEffect(() {
      if (status is Connected || status is Disconnected) {
        pendingTap.value = false;
      }
      return null;
    }, [status]);

    final statusText = isConnected ? 'Подключено' : (isBusy ? 'Подключение...' : 'Нажмите для подключения');

    return Scaffold(
      backgroundColor: const Color(0xFF0E0D15),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0D15),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Image.asset(
                'assets/images/tray_icon.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.shield_rounded, color: Color(0xFF7B61FF), size: 20),
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
                      child: SizedBox(
                        width: 220,
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: isConnected ? 186 : 170,
                              height: isConnected ? 186 : 170,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: isConnected
                                      ? [
                                          const Color(0xFFFFF8E7),
                                          const Color(0xFFFFD580).withValues(alpha: 0.75),
                                          const Color(0xFF00E676).withValues(alpha: 0.25),
                                          Colors.transparent,
                                        ]
                                      : [
                                          const Color(0xFFE6ECFF).withValues(alpha: 0.85),
                                          const Color(0xFFB8C7E8).withValues(alpha: 0.35),
                                          const Color(0xFF7B8BB2).withValues(alpha: 0.08),
                                          Colors.transparent,
                                        ],
                                  stops: const [0.78, 0.86, 0.94, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isConnected ? const Color(0xFFFFE0A3) : const Color(0xFFD6E2FF))
                                        .withValues(alpha: isConnected ? 0.42 : 0.18),
                                    blurRadius: isConnected ? 45 : 30,
                                    spreadRadius: isConnected ? 6 : 2,
                                  ),
                                  BoxShadow(
                                    color: (isConnected ? const Color(0xFFFFF6D6) : const Color(0xFFFFFFFF))
                                        .withValues(alpha: isConnected ? 0.55 : 0.28),
                                    blurRadius: 18,
                                    offset: const Offset(5, -5),
                                  ),
                                ],
                              ),
                            ),
                            if (isBusy && !isConnected)
                              const SizedBox(
                                width: 174,
                                height: 174,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFE0A3)),
                                ),
                              ),
                            Container(
                              width: 156,
                              height: 156,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [Color(0xFF0A0A0F), Color(0xFF050508)],
                                  stops: [0.7, 1.0],
                                ),
                                border: Border.all(
                                  color: (isConnected ? const Color(0xFFFFF3D1) : const Color(0xFFE2E8F0))
                                      .withValues(alpha: isConnected ? 0.85 : 0.45),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.power_settings_new_rounded,
                                  size: 62,
                                  color: isConnected
                                      ? const Color(0xFF00E676)
                                      : (isBusy ? const Color(0xFFFFE0A3) : Colors.white.withValues(alpha: 0.9)),
                                ),
                              ),
                            ),
                          ],
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
