import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import '../../main.dart';
import 'unit_editor.screen.dart';
import '../lessons/lessons_list.screen.dart';

/// Lists all units for a given course
class UnitsListScreen extends StatefulWidget {
  final Course course;

  const UnitsListScreen({super.key, required this.course});

  @override
  State<UnitsListScreen> createState() => _UnitsListScreenState();
}

class _UnitsListScreenState extends State<UnitsListScreen> {
  List<Unit> _units = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('units')
          .select()
          .eq('course_id', widget.course.id)
          .order('display_order');

      setState(() {
        _units = (response as List).map((u) => Unit.fromJson(u)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading units: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteUnit(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Unit?'),
        content: const Text('This will permanently delete the unit and all its lessons, exercises, and sections.'),
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
        await supabase.from('units').delete().eq('id', id);
        _loadUnits();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _openEditor([Unit? unit]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnitEditorScreen(
          course: widget.course,
          unit: unit,
        ),
      ),
    ).then((_) => _loadUnits());
  }

  void _openLessons(Unit unit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonsListScreen(unit: unit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Units: ${widget.course.title}'),
        actions: [
          FilledButton.icon(
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add),
            label: const Text('New Unit'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course info header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.school, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.course.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.course.description != null)
                            Text(
                              widget.course.description!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text('${_units.length} units'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _units.isEmpty
                      ? _buildEmptyState(theme)
                      : _buildUnitsList(theme),
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
            Icons.folder_open_outlined,
            size: 80,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No units yet',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first unit for this course',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add),
            label: const Text('Create Unit'),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsList(ThemeData theme) {
    return ListView.builder(
      itemCount: _units.length,
      itemBuilder: (context, index) {
        final unit = _units[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: unit.isPremium
                    ? Colors.amber.withOpacity(0.2)
                    : theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                unit.isPremium ? Icons.star : Icons.folder,
                color: unit.isPremium
                    ? Colors.amber.shade700
                    : theme.colorScheme.secondary,
              ),
            ),
            title: Row(
              children: [
                Text(
                  'Unit ${unit.displayOrder}: ',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    unit.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              unit.description ?? 'No description',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (unit.isPremium)
                  Chip(
                    label: Text('${unit.unlockCost} XP'),
                    avatar: const Icon(Icons.lock, size: 16),
                    backgroundColor: Colors.amber.withOpacity(0.1),
                  ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(unit.isActive ? 'Active' : 'Draft'),
                  backgroundColor: unit.isActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.list_alt_outlined),
                  onPressed: () => _openLessons(unit),
                  tooltip: 'View Lessons',
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _openEditor(unit),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteUnit(unit.id),
                  tooltip: 'Delete',
                ),
              ],
            ),
            onTap: () => _openLessons(unit),
          ),
        );
      },
    );
  }
}
