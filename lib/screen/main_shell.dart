import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_models.dart';
import 'api_service.dart';
import 'dashboard_screen.dart';
import 'simulation_screen.dart';
import 'tips_screen.dart';
import 'ranking_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  AppTab _activeTab = AppTab.dashboard;
  UserStats _stats = const UserStats(xp: 0);
  List<PhishSimulation> _simulations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final statsJson = await ApiService.getStats();
      final simsJson = await ApiService.getSimulations();
      if (!mounted) return;
      setState(() {
        _stats = UserStats.fromJson(statsJson);
        _simulations = simsJson
            .map((e) => PhishSimulation.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _navigate(AppTab tab) {
    setState(() => _activeTab = tab);
    if (tab == AppTab.dashboard) {
      _loadData();
    }
  }

  Future<void> _onSimulationDone(String id) async {
    await _loadData();
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }
    switch (_activeTab) {
      case AppTab.dashboard:
        return DashboardScreen(
            stats: _stats, onNavigate: _navigate, onRefresh: _loadData);
      case AppTab.simulations:
        return SimulationsScreen(
          simulations: _simulations,
          onStart: _onSimulationDone,
        );
      case AppTab.tips:
        return const TipsScreen();
      case AppTab.ranking:
        return RankingScreen(currentUserId: UserSession.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(key: ValueKey(_activeTab), child: _buildBody()),
      ),
      bottomNavigationBar:
          _BottomNav(activeTab: _activeTab, onTabChange: _navigate),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final AppTab activeTab;
  final ValueChanged<AppTab> onTabChange;

  const _BottomNav({required this.activeTab, required this.onTabChange});

  static const _tabs = [
    (AppTab.dashboard, 'Dashboard', Icons.home_outlined),
    (AppTab.simulations, 'Simulações', Icons.grid_view_outlined),
    (AppTab.tips, 'Aprender', Icons.menu_book_outlined),
    (AppTab.ranking, 'Ranking', Icons.leaderboard_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0E14),
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _tabs
                .map((t) => _NavItem(
                      icon: t.$3,
                      label: t.$2,
                      isActive: activeTab == t.$1,
                      onTap: () => onTabChange(t.$1),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accent.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 22,
                color: isActive ? AppColors.accent : AppColors.textMuted),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.accent : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
