import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/stitch_tab.dart';
import 'pages/about_page.dart';
import 'pages/ai_fitting_room_page.dart';
import 'pages/community_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/profile_page.dart';
import 'pages/register_page.dart';
import 'pages/reset_password_page.dart';
import 'pages/saved_looks_page.dart';
import 'pages/selfie_management_page.dart';
import 'pages/settings_page.dart';
import 'pages/wardrobe_page.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StitchApp());
}

class StitchApp extends StatelessWidget {
  const StitchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Fashion App',
      debugShowCheckedModeBanner: false,
      theme: StitchTheme.light(),
      builder: (context, child) {
        return DefaultTextStyle.merge(
          style: GoogleFonts.plusJakartaSans(),
          child: child ?? const SizedBox.shrink(),
        );
      },
      initialRoute: '/login',
      routes: {
        '/': (_) => const StitchShell(),
        LoginPage.routeName: (_) => const LoginPage(),
        RegisterPage.routeName: (_) => const RegisterPage(),
        ResetPasswordPage.routeName: (_) => const ResetPasswordPage(),
        SelfieManagementPage.routeName: (_) => const SelfieManagementPage(),
        SavedLooksPage.routeName: (_) => const SavedLooksPage(),
        SettingsPage.routeName: (_) => const SettingsPage(),
        AboutPage.routeName: (_) => const AboutPage(),
      },
    );
  }
}

class StitchShell extends StatefulWidget {
  const StitchShell({super.key});

  @override
  State<StitchShell> createState() => _StitchShellState();
}

class _StitchShellState extends State<StitchShell> {
  StitchTab _currentTab = StitchTab.home;

  @override
  void initState() {
    super.initState();
    StitchShellCoordinator.register(_setTab);
  }

  @override
  void dispose() {
    StitchShellCoordinator.unregister(_setTab);
    super.dispose();
  }

  void _setTab(StitchTab tab) {
    if (_currentTab == tab) return;
    setState(() => _currentTab = tab);
  }

  void _handleTabSelected(StitchTab tab) {
    _setTab(tab);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(currentTab: _currentTab, onTabSelected: _handleTabSelected),
      WardrobePage(currentTab: _currentTab, onTabSelected: _handleTabSelected),
      CommunityPage(currentTab: _currentTab, onTabSelected: _handleTabSelected),
      AiFittingRoomPage(
        currentTab: _currentTab,
        onTabSelected: _handleTabSelected,
      ),
      ProfilePage(currentTab: _currentTab, onTabSelected: _handleTabSelected),
    ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: IndexedStack(
        key: ValueKey(_currentTab),
        index: _currentTab.index,
        children: pages,
      ),
    );
  }
}

class StitchShellCoordinator {
  const StitchShellCoordinator._();

  static void Function(StitchTab)? _tabSetter;

  static void register(void Function(StitchTab) setter) {
    _tabSetter = setter;
  }

  static void unregister(void Function(StitchTab) setter) {
    if (_tabSetter == setter) {
      _tabSetter = null;
    }
  }

  static void selectTab(StitchTab tab) {
    _tabSetter?.call(tab);
  }
}
