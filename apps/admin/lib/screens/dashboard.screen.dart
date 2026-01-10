import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import 'courses/courses_list.screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  final List<NavigationRailDestination> _destinations = const [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Dashboard'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.school_outlined),
      selectedIcon: Icon(Icons.school),
      label: Text('Courses'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.quiz_outlined),
      selectedIcon: Icon(Icons.quiz),
      label: Text('Quizzes'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.people_outlined),
      selectedIcon: Icon(Icons.people),
      label: Text('Users'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('Settings'),
    ),
  ];

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return const _DashboardHome();
      case 1:
        return const CoursesListScreen();
      case 2:
        return const Center(child: Text('Quizzes - Coming Soon'));
      case 3:
        return const Center(child: Text('Users - Coming Soon'));
      case 4:
        return const Center(child: Text('Settings - Coming Soon'));
      default:
        return const _DashboardHome();
    }
  }

  /// Build theme toggle button with 3 states: System, Light, Dark
  Widget _buildThemeToggle(ThemeData theme, ColorScheme colorScheme) {
    final currentMode = ref.watch(themeModeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildThemeButton(
            icon: Icons.brightness_auto,
            tooltip: 'System',
            isSelected: currentMode == ThemeMode.system,
            onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
            colorScheme: colorScheme,
          ),
          _buildThemeButton(
            icon: Icons.light_mode,
            tooltip: 'Light',
            isSelected: currentMode == ThemeMode.light,
            onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
            colorScheme: colorScheme,
          ),
          _buildThemeButton(
            icon: Icons.dark_mode,
            tooltip: 'Dark',
            isSelected: currentMode == ThemeMode.dark,
            onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeButton({
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = supabase.auth.currentUser;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            minExtendedWidth: 200,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            leading: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.auto_stories, size: 40, color: colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(
                    'Admin CMS',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Theme toggle button
                      _buildThemeToggle(theme, colorScheme),
                      const SizedBox(height: 16),
                      CircleAvatar(
                        child: Text(user?.email?.substring(0, 1).toUpperCase() ?? 'A'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user?.email ?? '',
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      TextButton.icon(
                        onPressed: () => supabase.auth.signOut(),
                        icon: const Icon(Icons.logout, size: 16),
                        label: const Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            destinations: _destinations,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _getBody()),
        ],
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome to the EconomicSkills Content Management System',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatCard(
                icon: Icons.school,
                label: 'Courses',
                value: '0',
                color: Colors.blue,
              ),
              _StatCard(
                icon: Icons.book,
                label: 'Lessons',
                value: '0',
                color: Colors.green,
              ),
              _StatCard(
                icon: Icons.quiz,
                label: 'Quizzes',
                value: '0',
                color: Colors.orange,
              ),
              _StatCard(
                icon: Icons.people,
                label: 'Users',
                value: '0',
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                        label: const Text('New Course'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                        label: const Text('New Lesson'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                        label: const Text('New Quiz'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
