import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import '../screens/units/unit_editor.screen.dart';
import '../screens/lessons/lesson_editor.screen.dart';
import '../screens/exercises/exercise_editor.screen.dart';
import '../screens/sections/section_editor.screen.dart';

/// Hierarchical tree view for course content navigation
/// Shows Units > Lessons > Exercises > Sections with quick actions
class CourseHierarchyTree extends StatefulWidget {
  final Course course;
  final VoidCallback onRefresh;
  final CourseService courseService;

  const CourseHierarchyTree({
    super.key,
    required this.course,
    required this.onRefresh,
    required this.courseService,
  });

  @override
  State<CourseHierarchyTree> createState() => _CourseHierarchyTreeState();
}

class _CourseHierarchyTreeState extends State<CourseHierarchyTree> {
  Course? _hierarchy;
  bool _isLoading = true;
  
  // Track expanded states
  final Set<String> _expandedUnits = {};
  final Set<String> _expandedLessons = {};
  final Set<String> _expandedExercises = {};
  int _rebuildKey = 0; // Increment to force ExpansionTile rebuild

  @override
  void initState() {
    super.initState();
    _loadHierarchy();
  }

  Future<void> _loadHierarchy() async {
    setState(() => _isLoading = true);
    try {
      final hierarchy = await widget.courseService.getFullCourseHierarchy(widget.course.id);
      setState(() {
        _hierarchy = hierarchy;
        _isLoading = false;
        // Expand all by default on load
        _expandAll();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading hierarchy: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _expandAll() {
    if (_hierarchy == null) return;
    setState(() {
      _expandedUnits.clear();
      _expandedLessons.clear();
      _expandedExercises.clear();
      for (final unit in (_hierarchy!.units ?? [])) {
        _expandedUnits.add(unit.id);
        for (final lesson in (unit.lessons ?? [])) {
          _expandedLessons.add(lesson.id);
          for (final exercise in (lesson.exercises ?? [])) {
            _expandedExercises.add(exercise.id);
          }
        }
      }
      _rebuildKey++; // Force ExpansionTiles to rebuild with expanded state
    });
  }

  void _collapseAll() {
    setState(() {
      _expandedUnits.clear();
      _expandedLessons.clear();
      _expandedExercises.clear();
      _rebuildKey++; // Force ExpansionTiles to rebuild with new collapsed state
    });
  }

  bool get _allExpanded {
    if (_hierarchy == null) return false;
    final units = _hierarchy!.units ?? [];
    if (units.isEmpty) return false;
    return units.every((u) => _expandedUnits.contains(u.id));
  }

  Future<void> _deleteItem(String table, String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "$name"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      await widget.courseService.client.from(table).delete().eq('id', id);
      _loadHierarchy();
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateOrder(String table, String id, int newOrder) async {
    try {
      await widget.courseService.client.from(table).update({'display_order': newOrder}).eq('id', id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reordering: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _navigateToEditor(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _loadHierarchy();
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_hierarchy == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                const Text('Failed to load hierarchy'),
                const SizedBox(height: 16),
                OutlinedButton(onPressed: _loadHierarchy, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_tree, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Course Hierarchy',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // Expand/Collapse All toggle
                IconButton(
                  icon: Icon(_allExpanded ? Icons.unfold_less : Icons.unfold_more),
                  onPressed: () {
                    if (_allExpanded) {
                      _collapseAll();
                    } else {
                      _expandAll();
                    }
                  },
                  tooltip: _allExpanded ? 'Collapse All' : 'Expand All',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadHierarchy,
                  tooltip: 'Refresh',
                ),
                FilledButton.icon(
                  onPressed: () => _navigateToEditor(UnitEditorScreen(course: widget.course)),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Unit'),
                ),
              ],
            ),
            const Divider(),
            if ((_hierarchy!.units ?? []).isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No units yet. Click "Add Unit" to create one.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              _buildUnitsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitsList() {
    final units = (_hierarchy!.units ?? []).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: units.length,
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > oldIndex) newIndex--;
        final unit = units[oldIndex];
        setState(() {
          units.removeAt(oldIndex);
          units.insert(newIndex, unit);
        });
        // Update display orders
        for (var i = 0; i < units.length; i++) {
          await _updateOrder('units', units[i].id, i);
        }
        _loadHierarchy();
      },
      itemBuilder: (context, index) {
        final unit = units[index];
        return _buildUnitTile(unit, Key(unit.id));
      },
    );
  }

  Widget _buildUnitTile(Unit unit, Key key) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isExpanded = _expandedUnits.contains(unit.id);
    
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        key: ValueKey('unit_${unit.id}_$_rebuildKey'),
        leading: ReorderableDragStartListener(
          index: (_hierarchy!.units ?? []).toList().indexOf(unit),
          child: const Icon(Icons.drag_handle),
        ),
        title: InkWell(
          onTap: () => _navigateToEditor(UnitEditorScreen(course: widget.course, unit: unit)),
          child: Row(
            children: [
              Icon(Icons.folder, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(unit.title, style: const TextStyle(fontWeight: FontWeight.w500))),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _deleteItem('units', unit.id, unit.title),
              tooltip: 'Delete Unit',
              color: Colors.red,
            ),
            Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
          ],
        ),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _expandedUnits.add(unit.id);
            } else {
              _expandedUnits.remove(unit.id);
            }
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 16, bottom: 8),
            child: Column(
              children: [
                ...(unit.lessons ?? []).map((lesson) => _buildLessonTile(lesson, unit)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _navigateToEditor(LessonEditorScreen(unit: unit)),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add Lesson'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonTile(Lesson lesson, Unit unit) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isExpanded = _expandedLessons.contains(lesson.id);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: colorScheme.surfaceContainerHighest,
      child: ExpansionTile(
        key: ValueKey('lesson_${lesson.id}_$_rebuildKey'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        title: InkWell(
          onTap: () => _navigateToEditor(LessonEditorScreen(unit: unit, lesson: lesson)),
          child: Row(
            children: [
              Icon(Icons.menu_book, color: colorScheme.secondary, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w500))),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => _deleteItem('lessons', lesson.id, lesson.title),
              tooltip: 'Delete Lesson',
              color: Colors.red,
              iconSize: 18,
            ),
            Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 20),
          ],
        ),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _expandedLessons.add(lesson.id);
            } else {
              _expandedLessons.remove(lesson.id);
            }
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
            child: Column(
              children: [
                ...(lesson.exercises ?? []).map((exercise) => _buildExerciseTile(exercise, lesson)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _navigateToEditor(ExerciseEditorScreen(lesson: lesson)),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add Exercise'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseTile(Exercise exercise, Lesson lesson) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isExpanded = _expandedExercises.contains(exercise.id);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: colorScheme.surfaceContainerHigh,
      child: ExpansionTile(
        key: ValueKey('exercise_${exercise.id}_$_rebuildKey'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        title: InkWell(
          onTap: () => _navigateToEditor(ExerciseEditorScreen(lesson: lesson, exercise: exercise)),
          child: Row(
            children: [
              Icon(Icons.assignment, color: colorScheme.tertiary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exercise.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16),
              onPressed: () => _deleteItem('exercises', exercise.id, exercise.title ?? 'Exercise'),
              tooltip: 'Delete Exercise',
              color: Colors.red,
              iconSize: 16,
            ),
            Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 18),
          ],
        ),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _expandedExercises.add(exercise.id);
            } else {
              _expandedExercises.remove(exercise.id);
            }
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
            child: Column(
              children: [
                ...(exercise.sections ?? []).map((section) => _buildSectionTile(section, exercise)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _navigateToEditor(SectionEditorScreen(exercise: exercise)),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add Section'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTile(Section section, Exercise exercise) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(Icons.article, size: 20, color: colorScheme.outline),
      title: Text(
        section.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 20),
        onPressed: () => _deleteItem('sections', section.id, section.title),
        tooltip: 'Delete Section',
        color: Colors.red,
        iconSize: 20,
      ),
      onTap: () => _navigateToEditor(SectionEditorScreen(exercise: exercise, section: section)),
    );
  }
}
