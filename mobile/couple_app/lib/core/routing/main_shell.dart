import 'package:couple_app/features/calendar/presentation/calendar_screen.dart';
import 'package:couple_app/features/auth/data/auth_api.dart';
import 'package:couple_app/features/home/presentation/home_screen.dart';
import 'package:couple_app/features/location/presentation/location_screen.dart';
import 'package:couple_app/features/more/presentation/more_screen.dart';
import 'package:couple_app/features/tasks/presentation/tasks_screen.dart';
import 'package:couple_app/features/workspace/application/workspace_controller.dart';
import 'package:flutter/material.dart';

class MainShell extends StatefulWidget {
  const MainShell({required this.session, super.key});

  final SessionController session;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late final WorkspaceController _workspace;
  bool _refreshingProfile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _workspace = WorkspaceController(session: widget.session)..refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _workspace.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshWorkspace();
  }

  Future<void> _refreshWorkspace() async {
    if (_refreshingProfile) return;
    _refreshingProfile = true;
    try {
      await widget.session.refreshProfile();
    } catch (_) {
      // The workspace request below displays network/session errors with retry.
    } finally {
      _refreshingProfile = false;
      if (mounted) await _workspace.refresh();
    }
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
    if (index < 3) _refreshWorkspace();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            HomeScreen(controller: _workspace, onSelectTab: _selectTab),
            CalendarScreen(controller: _workspace),
            TasksScreen(controller: _workspace),
            const LocationScreen(),
            MoreScreen(session: widget.session),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Lịch',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Việc cần làm',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Vị trí',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Thêm',
          ),
        ],
      ),
    );
  }
}
