import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import '../../main.dart';
import 'lesson_editor.screen.dart';
import '../exercises/exercises_list.screen.dart';

/// Lists all lessons for a given unit
class LessonsListScreen extends StatefulWidget {
  final Unit unit;

  const LessonsListScreen({super.key, required this.unit});

  @override
  State<LessonsListScreen> createState() => _LessonsListScreenState();
}

class _LessonsListScreenState extends State<LessonsListScreen> {
  List<Lesson> _lessons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('lessons')
          .select()
          .eq('unit_id', widget.unit.id)
          .order('display_order');

      setState(() {
        _lessons = (response as List).map((l) => Lesson.fromJson(l)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading lessons: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteLesson(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson?'),
        content: const Text('This will permanently delete the lesson, its exercise, and all sections.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase.from('lessons').delete().eq('id', id);
        _loadLessons();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _openEditor([Lesson? lesson]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonEditorScreen(
          unit: widget.unit,
          lesson: lesson,
        ),
      ),
    ).then((_) => _loadLessons());
  }

  void _openExercises(Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExercisesListScreen(lesson: lesson),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Lessons: ${widget.unit.title}'),
        actions: [
          FilledButton.icon(
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add),
            label: const Text('New Lesson'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unit info header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: widget.unit.isPremium
                            ? Colors.amber.withOpacity(0.2)
                            : colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.unit.isPremium ? Icons.star : Icons.folder,
                        color: widget.unit.isPremium
                            ? Colors.amber.shade700
                            : colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unit ${widget.unit.displayOrder}: ${widget.unit.title}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.unit.description != null)
                            Text(
                              widget.unit.description!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.unit.isPremium)
                      Chip(
                        label: Text('${widget.unit.unlockCost} XP'),
                        avatar: const Icon(Icons.lock, size: 16),
                        backgroundColor: Colors.amber.withOpacity(0.1),
                      ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('${_lessons.length} lessons'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _lessons.isEmpty
                      ? _buildEmptyState(theme)
                      : _buildLessonsList(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 80,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No lessons yet',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first lesson for this unit',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add),
            label: const Text('Create Lesson'),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsList(ThemeData theme) {
    return ListView.builder(
      itemCount: _lessons.length,
      itemBuilder: (context, index) {
        final lesson = _lessons[index];
        final hasVideo = lesson.youtubeVideoUrl != null &&
            lesson.youtubeVideoUrl!.isNotEmpty;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.book,
                color: theme.colorScheme.tertiary,
              ),
            ),
            title: Row(
              children: [
                Text(
                  'Lesson ${lesson.displayOrder}: ',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    lesson.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              lesson.explanationText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasVideo)
                  Tooltip(
                    message: 'Has video',
                    child: Icon(
                      Icons.play_circle_outline,
                      color: Colors.red.shade400,
                      size: 20,
                    ),
                  ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(lesson.isActive ? 'Active' : 'Draft'),
                  backgroundColor: lesson.isActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.assignment_outlined),
                  onPressed: () => _openExercises(lesson),
                  tooltip: 'Manage Exercises',
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _openEditor(lesson),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteLesson(lesson.id),
                  tooltip: 'Delete',
                ),
              ],
            ),
            onTap: () => _openExercises(lesson),
          ),
        );
      },
    );
  }
}
