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
                        width: 224,
                        height: 224,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: 162,
                              height: 162,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isConnected
                                            ? const Color(0xFFFFE6A8)
                                            : const Color(0xFFCEDBFF))
                                        .withValues(alpha: isConnected ? 0.34 : 0.16),
                                    blurRadius: isConnected ? 56 : 38,
                                    spreadRadius: isConnected ? 10 : 3,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFFFFFFF)
                                        .withValues(alpha: isConnected ? 0.48 : 0.22),
                                    blurRadius: 20,
                                    offset: const Offset(5, -5),
                                  ),
                                ],
                              ),
                            ),
                            if (isBusy && !isConnected)
                              const SizedBox(
                                width: 170,
                                height: 170,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFE299)),
                                ),
                              ),
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  center: Alignment(-0.32, -0.32),
                                  radius: 0.95,
                                  colors: [
                                    Color(0xFF282D3B),
                                    Color(0xFF171A24),
                                    Color(0xFF0C0E14),
                                    Color(0xFF06070A),
                                  ],
                                  stops: [0.0, 0.45, 0.80, 1.0],
                                ),
                                border: Border.all(
                                  color: (isConnected
                                          ? const Color(0xFFFFF2CC)
                                          : const Color(0xFFD6E0F5))
                                      .withValues(alpha: isConnected ? 0.45 : 0.22),
                                  width: 1.0,
                                ),
                              ),
                              child: ClipOval(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CustomPaint(size: const Size(160, 160), painter: _MoonCratersPainter()),
                                    Icon(
                                      Icons.power_settings_new_rounded,
                                      size: 60,
                                      color: isConnected
                                          ? const Color(0xFF00E676)
                                          : (isBusy ? const Color(0xFFFFE299) : Colors.white.withValues(alpha: 0.92)),
                                    ),
                                  ],
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

class _MoonCratersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final marePaint = Paint()
      ..color = const Color(0xFF090B10).withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.35, h * 0.34), width: w * 0.36, height: h * 0.28), marePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.64, h * 0.38), width: w * 0.28, height: h * 0.34), marePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.46, h * 0.70), width: w * 0.38, height: h * 0.24), marePaint);
    canvas.drawCircle(Offset(w * 0.25, h * 0.56), w * 0.11, marePaint);

    void drawSoftCrater(double dx, double dy, double r) {
      final center = Offset(w * dx, h * dy);
      final body = Paint()
        ..color = const Color(0xFF08090E).withValues(alpha: 0.48)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      final highlight = Paint()
        ..color = const Color(0xFFA8B6D1).withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawCircle(center.translate(1.2, 1.2), w * r, highlight);
      canvas.drawCircle(center, w * r, body);
    }

    drawSoftCrater(0.28, 0.26, 0.055);
    drawSoftCrater(0.68, 0.24, 0.042);
    drawSoftCrater(0.22, 0.55, 0.062);
    drawSoftCrater(0.76, 0.56, 0.050);
    drawSoftCrater(0.35, 0.75, 0.046);
    drawSoftCrater(0.63, 0.73, 0.058);
    drawSoftCrater(0.50, 0.18, 0.036);
    drawSoftCrater(0.81, 0.40, 0.032);
    drawSoftCrater(0.48, 0.84, 0.040);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
