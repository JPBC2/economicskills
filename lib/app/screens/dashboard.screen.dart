import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:economicskills/app/services/dashboard.service.dart';
import 'package:economicskills/app/widgets/top_nav.widget.dart';
import 'package:economicskills/app/widgets/drawer_nav.widget.dart';
import 'package:economicskills/main.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService(supabase);
  
  UserProfile? _profile;
  DashboardStats _stats = DashboardStats.empty();
  List<CourseProgress> _coursesInProgress = [];
  bool _isLoading = true;
  String? _error;
  
  // Track expanded courses and units
  final Set<String> _expandedCourses = {};
  final Set<String> _expandedUnits = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _dashboardService.getProfile();
      final stats = await _dashboardService.getDashboardStats();
      final courses = await _dashboardService.getCoursesInProgress();

      if (mounted) {
        setState(() {
          _profile = profile;
          _stats = stats;
          _coursesInProgress = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load dashboard: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 600;

    return Scaffold(
      appBar: const TopNav(),
      drawer: isNarrow ? const DrawerNav() : null,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState(theme, colorScheme)
                : _buildDashboardContent(theme, colorScheme, isNarrow),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(_error!, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(ThemeData theme, ColorScheme colorScheme, bool isNarrow) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(isNarrow ? 16 : 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting section
              _buildGreeting(theme, colorScheme),
              const SizedBox(height: 24),
              
              // Stats cards
              _buildStatsCards(theme, colorScheme, isNarrow),
              const SizedBox(height: 32),
              
              // Divider
              Divider(color: colorScheme.outlineVariant),
              const SizedBox(height: 24),
              
              // My Courses section
              _buildMyCoursesSection(theme, colorScheme),
              const SizedBox(height: 32),
              
              // Divider
              Divider(color: colorScheme.outlineVariant),
              const SizedBox(height: 24),
              
              // Explore button
              _buildExploreButton(theme, colorScheme),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(ThemeData theme, ColorScheme colorScheme) {
    final userName = _profile?.fullName ?? 'User';
    final firstName = userName.split(' ').first;
    
    return Row(
      children: [
        // Profile photo
        CircleAvatar(
          radius: 28,
          backgroundColor: colorScheme.primaryContainer,
          backgroundImage: _profile?.profilePhotoUrl != null
              ? NetworkImage(_profile!.profilePhotoUrl!)
              : null,
          child: _profile?.profilePhotoUrl == null
              ? Icon(Icons.person, color: colorScheme.onPrimaryContainer, size: 28)
              : null,
        ),
        const SizedBox(width: 16),
        // Greeting text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hey, $firstName!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'Welcome back to Economic skills',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards(ThemeData theme, ColorScheme colorScheme, bool isNarrow) {
    final cards = [
      _StatCard(
        icon: Icons.stars,
        value: '${_stats.availableXp}',
        label: 'Available XP',
        color: Colors.amber,
      ),
      _StatCard(
        icon: Icons.school,
        value: '${_stats.coursesCompleted}',
        label: 'Courses',
        color: Colors.blue,
      ),
      _StatCard(
        icon: Icons.folder,
        value: '${_stats.unitsCompleted}',
        label: 'Units',
        color: Colors.green,
      ),
      _StatCard(
        icon: Icons.library_books,
        value: '${_stats.lessonsCompleted}',
        label: 'Lessons',
        color: Colors.purple,
      ),
    ];

    if (isNarrow) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: cards.map((card) => SizedBox(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          child: _buildStatCard(theme, colorScheme, card),
        )).toList(),
      );
    }

    return Row(
      children: cards.map((card) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _buildStatCard(theme, colorScheme, card),
        ),
      )).toList(),
    );
  }

  Widget _buildStatCard(ThemeData theme, ColorScheme colorScheme, _StatCard card) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(card.icon, size: 28, color: card.color),
            const SizedBox(height: 8),
            Text(
              card.value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              card.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyCoursesSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Courses',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        if (_coursesInProgress.isEmpty)
          _buildEmptyCoursesState(theme, colorScheme)
        else
          ..._coursesInProgress.map((course) => _buildCourseProgress(theme, colorScheme, course)),
      ],
    );
  }

  Widget _buildEmptyCoursesState(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.school_outlined, size: 48, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No courses started yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore the course catalog to begin your learning journey!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseProgress(ThemeData theme, ColorScheme colorScheme, CourseProgress course) {
    final isExpanded = _expandedCourses.contains(course.courseId);
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Course header
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCourses.remove(course.courseId);
                } else {
                  _expandedCourses.add(course.courseId);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.courseTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${course.completedLessons}/${course.totalLessons} lessons',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress indicator
                  SizedBox(
                    width: 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${course.progressPercentage.toInt()}%',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: course.progressPercentage / 100,
                          backgroundColor: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expanded units
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 16, bottom: 16),
              child: Column(
                children: course.units.map((unit) => _buildUnitProgress(theme, colorScheme, unit)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnitProgress(ThemeData theme, ColorScheme colorScheme, UnitProgress unit) {
    final isExpanded = _expandedUnits.contains(unit.unitId);
    final isLocked = unit.isLocked;
    
    return Column(
      children: [
        // Unit header
        InkWell(
          onTap: isLocked ? null : () {
            setState(() {
              if (isExpanded) {
                _expandedUnits.remove(unit.unitId);
              } else {
                _expandedUnits.add(unit.unitId);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                if (isLocked)
                  Icon(Icons.lock, size: 20, color: colorScheme.outline)
                else
                  Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    unit.unitTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isLocked ? colorScheme.outline : colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isLocked)
                  Chip(
                    label: Text('${unit.unlockCost} XP'),
                    avatar: const Icon(Icons.lock_open, size: 16),
                    visualDensity: VisualDensity.compact,
                    labelStyle: theme.textTheme.labelSmall,
                  )
                else
                  Text(
                    '${unit.progressPercentage.toInt()}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Expanded lessons
        if (isExpanded && !isLocked)
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Column(
              children: unit.lessons.map((lesson) => _buildLessonProgress(theme, colorScheme, lesson)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildLessonProgress(ThemeData theme, ColorScheme colorScheme, LessonProgress lesson) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            lesson.isCompleted ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: lesson.isCompleted ? Colors.green : colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              lesson.lessonTitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          if (lesson.isCompleted)
            Text(
              '+${lesson.xpEarned} XP',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExploreButton(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: FilledButton.icon(
        onPressed: () => context.go('/courses'),
        icon: const Icon(Icons.explore),
        label: const Text('Explore Course Catalog'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      ),
    );
  }
}

class _StatCard {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
}
