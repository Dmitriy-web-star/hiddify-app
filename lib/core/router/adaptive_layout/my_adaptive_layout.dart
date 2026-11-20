import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/adaptive_layout/shell_route_action.dart';
import 'package:hiddify/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:hiddify/core/router/go_router/routing_config_notifier.dart';
import 'package:hiddify/features/home/widget/cabinet_page.dart';
import 'package:hiddify/features/stats/widget/side_bar_stats_overview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MyAdaptiveLayout extends HookConsumerWidget {
  const MyAdaptiveLayout({
    super.key,
    required this.navigationShell,
    required this.isMobileBreakpoint,
    required this.showProfilesAction,
  });

  final StatefulNavigationShell navigationShell;
  final bool isMobileBreakpoint;
  final bool showProfilesAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final showCabinet = useState(false);

    final primaryFocusHash = useState<int?>(null);
    final navScopeNode = useFocusScopeNode();
    useEffect(() {
      bool handler(KeyEvent event) {
        final arrows = isMobileBreakpoint ? KeyboardConst.verticalArrows : KeyboardConst.horizontalArrows;
        if (!arrows.contains(event.logicalKey)) return false;
        if (event is KeyDownEvent) {
          primaryFocusHash.value = FocusManager.instance.primaryFocus.hashCode;
        } else {
          if (primaryFocusHash.value == FocusManager.instance.primaryFocus.hashCode) {
            if (branchesScope.values.any((node) => node.hasFocus)) {
              navScopeNode.requestFocus();
            } else if (navScopeNode.hasFocus) {
              branchesScope[getNameOfBranch(isMobileBreakpoint, showProfilesAction, navigationShell.currentIndex)]
                  ?.requestFocus();
            }
          }
        }
        return true;
      }

      HardwareKeyboard.instance.addHandler(handler);
      return () {
        HardwareKeyboard.instance.removeHandler(handler);
      };
    }, [isMobileBreakpoint, showProfilesAction, navigationShell.currentIndex]);

    final mobileSelectedIndex = showCabinet.value
        ? 1
        : (navigationShell.currentIndex == 0 ? 0 : 2);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (showCabinet.value) {
          showCabinet.value = false;
          return;
        }
        final homeIndex = getIndexOfBranch(isMobileBreakpoint, showProfilesAction, 'home');
        if (navigationShell.currentIndex != homeIndex) {
          navigationShell.goBranch(homeIndex);
        } else {
          SystemNavigator.pop();
        }
      },
      child: NotificationListener<NavigationNotification>(
        onNotification: (notification) {
          if (notification.canHandlePop) return false;
          const NavigationNotification(canHandlePop: true).dispatch(context);
          return true;
        },
        child: Material(
          child: Scaffold(
            body: isMobileBreakpoint
                ? IndexedStack(
                    index: showCabinet.value ? 1 : 0,
                    children: [
                      navigationShell,
                      CabinetPage(
                        onSubscriptionImported: () {
                          showCabinet.value = false;
                          navigationShell.goBranch(0);
                        },
                      ),
                    ],
                  )
                : Row(
                    children: [
                      FocusScope(
                        node: navScopeNode,
                        child: NavigationRail(
                          extended: Breakpoint(context).isDesktop(),
                          destinations: _navRailDests(_actions(t, showProfilesAction, isMobileBreakpoint)),
                          selectedIndex: navigationShell.currentIndex,
                          onDestinationSelected: (index) => _onTap(context, index, showCabinet),
                          trailing: Breakpoint(context).isDesktop()
                              ? const Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: SizedBox(width: 220, child: SideBarStatsOverview()),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Expanded(child: Semantics(container: true, child: navigationShell)),
                    ],
                  ),
            bottomNavigationBar: isMobileBreakpoint
                ? FocusScope(
                    node: navScopeNode,
                    child: NavigationBar(
                      selectedIndex: mobileSelectedIndex,
                      destinations: _navDests(_actions(t, showProfilesAction, isMobileBreakpoint)),
                      onDestinationSelected: (index) => _onTap(context, index, showCabinet),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index, ValueNotifier<bool> showCabinet) {
    if (isMobileBreakpoint) {
      if (index == 1) {
        showCabinet.value = true;
        return;
      }
      showCabinet.value = false;
      final branchIndex = index == 0 ? 0 : 1;
      navigationShell.goBranch(branchIndex, initialLocation: branchIndex == navigationShell.currentIndex);
      return;
    }
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  List<ShellRouteAction> _actions(Translations t, bool showProfilesAction, bool isMobileBreakpoint) => [
    ShellRouteAction(Icons.power_settings_new_rounded, 'VPN'),
    if (isMobileBreakpoint) const ShellRouteAction(Icons.account_circle_rounded, 'Кабинет'),
    if (showProfilesAction && !isMobileBreakpoint) ShellRouteAction(Icons.view_list_rounded, t.pages.profiles.title),
    ShellRouteAction(Icons.settings_rounded, t.pages.settings.title),
    if (!isMobileBreakpoint) ShellRouteAction(Icons.description_rounded, t.pages.logs.title),
    if (!isMobileBreakpoint) ShellRouteAction(Icons.info_rounded, t.pages.about.title),
  ];

  List<NavigationDestination> _navDests(List<ShellRouteAction> actions) =>
      actions.map((e) => NavigationDestination(icon: Icon(e.icon), label: e.title)).toList();
  List<NavigationRailDestination> _navRailDests(List<ShellRouteAction> actions) =>
      actions.map((e) => NavigationRailDestination(icon: Icon(e.icon), label: Text(e.title))).toList();
}
