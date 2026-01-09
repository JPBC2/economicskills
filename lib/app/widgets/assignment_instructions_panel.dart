import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

/// Progress state for an assignment (loaded from/saved to database)
class AssignmentProgress {
  final bool isCompleted;
  final bool hintUsed;
  final bool answerUsed;
  final int xpEarned;

  const AssignmentProgress({
    this.isCompleted = false,
    this.hintUsed = false,
    this.answerUsed = false,
    this.xpEarned = 0,
  });

  AssignmentProgress copyWith({
    bool? isCompleted,
    bool? hintUsed,
    bool? answerUsed,
    int? xpEarned,
  }) {
    return AssignmentProgress(
      isCompleted: isCompleted ?? this.isCompleted,
      hintUsed: hintUsed ?? this.hintUsed,
      answerUsed: answerUsed ?? this.answerUsed,
      xpEarned: xpEarned ?? this.xpEarned,
    );
  }
}

/// Shared instructions panel for all assignment types (Spreadsheet, Python, R)
/// Contains: Section title, explanation, instructions, hint button, answer button, XP display
class AssignmentInstructionsPanel extends StatefulWidget {
  final Section section;
  final String tool; // 'spreadsheet', 'python', or 'r'
  final AssignmentProgress progress;
  final VoidCallback? onBackPressed;
  final Function(AssignmentProgress) onProgressChanged;
  final VoidCallback? onShowAnswer;
  final String? courseSlug; // For back navigation

  const AssignmentInstructionsPanel({
    super.key,
    required this.section,
    required this.tool,
    required this.progress,
    required this.onProgressChanged,
    this.onBackPressed,
    this.onShowAnswer,
    this.courseSlug,
  });

  @override
  State<AssignmentInstructionsPanel> createState() => _AssignmentInstructionsPanelState();
}

class _AssignmentInstructionsPanelState extends State<AssignmentInstructionsPanel> {
  bool _showHint = false;
  bool _instructionsExpanded = true;

  /// Get instructions for this tool
  String? get _instructions => widget.section.getInstructionsForTool(widget.tool);

  /// Get hint for this tool
  String? get _hint => widget.section.getHintForTool(widget.tool);

  /// Get XP reward for this tool
  int get _xpReward => widget.section.getXpRewardForTool(widget.tool);

  /// Calculate display XP (with penalties)
  int get _displayXp {
    if (widget.progress.answerUsed) {
      return (_xpReward * 0.5).floor();
    } else if (widget.progress.hintUsed) {
      return (_xpReward * 0.7).floor();
    }
    return _xpReward;
  }

  /// Handle hint button press
  void _onHintPressed() {
    setState(() => _showHint = !_showHint);

    // Mark hint as used (only on first reveal)
    if (!widget.progress.hintUsed && _showHint) {
      widget.onProgressChanged(widget.progress.copyWith(hintUsed: true));
    }
  }

  /// Handle answer button press
  void _onAnswerPressed() {
    // Mark answer as used (only on first reveal)
    if (!widget.progress.answerUsed) {
      widget.onProgressChanged(widget.progress.copyWith(answerUsed: true));
    }
    widget.onShowAnswer?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAuthenticated = true; // TODO: Get from auth state

    return Container(
      color: colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            if (widget.onBackPressed != null || widget.courseSlug != null)
              _buildBackButton(theme, colorScheme),

            const SizedBox(height: 16),

            // Section title with tool badge
            _buildHeader(theme, colorScheme),

            const SizedBox(height: 16),

            // Explanation (if available)
            if (widget.section.explanation != null && widget.section.explanation!.isNotEmpty) ...[
              Text(
                widget.section.explanation!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Instructions section (collapsible)
            if (_instructions != null && _instructions!.isNotEmpty)
              _buildInstructionsSection(theme, colorScheme),

            // Hint button and content
            if (_hint != null && _hint!.isNotEmpty && isAuthenticated) ...[
              const SizedBox(height: 24),
              _buildHintSection(theme, colorScheme),
            ],

            // Answer button
            if (isAuthenticated) ...[
              const SizedBox(height: 12),
              _buildAnswerButton(theme, colorScheme),
            ],

            const SizedBox(height: 24),

            // Links to other tools
            _buildToolLinks(theme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(ThemeData theme, ColorScheme colorScheme) {
    return TextButton.icon(
      onPressed: widget.onBackPressed,
      icon: Icon(Icons.arrow_back, size: 18, color: colorScheme.primary),
      label: Text('Back to course', style: TextStyle(color: colorScheme.primary)),
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    // Tool badge color
    final toolColor = switch (widget.tool) {
      'spreadsheet' => Colors.green,
      'python' => Colors.deepPurple,
      'r' => Colors.blue,
      _ => colorScheme.primary,
    };

    final toolLabel = switch (widget.tool) {
      'spreadsheet' => 'Google Sheets',
      'python' => 'Python',
      'r' => 'R',
      _ => widget.tool,
    };

    final toolIcon = switch (widget.tool) {
      'spreadsheet' => Icons.table_chart,
      'python' => Icons.code,
      'r' => Icons.analytics,
      _ => Icons.assignment,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tool badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: toolColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: toolColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(toolIcon, size: 16, color: toolColor),
              const SizedBox(width: 6),
              Text(
                toolLabel,
                style: TextStyle(
                  color: toolColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Section title
        Text(
          widget.section.title,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInstructionsSection(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _instructionsExpanded = !_instructionsExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'Instructions',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  // XP chip
                  _buildXpChip(colorScheme),
                  const SizedBox(width: 8),
                  Icon(
                    _instructionsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          // Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                _instructions!,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6, color: colorScheme.onSurface),
              ),
            ),
            crossFadeState: _instructionsExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildXpChip(ColorScheme colorScheme) {
    final isCompleted = widget.progress.isCompleted;
    final xpEarned = widget.progress.xpEarned;

    Color chipColor;
    Color textColor;
    String xpText;

    if (isCompleted) {
      chipColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
      xpText = '$xpEarned XP earned';
    } else {
      chipColor = colorScheme.surfaceContainerHighest;
      textColor = colorScheme.onSurface;
      xpText = '$_displayXp XP';
    }

    return Chip(
      avatar: Icon(Icons.star, size: 14, color: Colors.amber.shade600),
      label: Text(xpText, style: TextStyle(fontSize: 12, color: textColor)),
      backgroundColor: chipColor,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildHintSection(ThemeData theme, ColorScheme colorScheme) {
    final hintUsed = widget.progress.hintUsed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _onHintPressed,
          icon: Icon(
            _showHint ? Icons.lightbulb : Icons.lightbulb_outline,
            color: Colors.amber.shade700,
          ),
          label: Text(
            hintUsed
                ? (_showHint ? 'Hide hint' : 'Show hint')
                : 'Take a hint (-30% XP)',
            style: TextStyle(color: colorScheme.onSurface),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colorScheme.outline),
          ),
        ),
        // Hint content
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Text(
              _hint!,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: Colors.amber.shade900,
              ),
            ),
          ),
          crossFadeState: _showHint ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildAnswerButton(ThemeData theme, ColorScheme colorScheme) {
    final answerUsed = widget.progress.answerUsed;

    // Check if this tool has a solution
    final hasSolution = switch (widget.tool) {
      'spreadsheet' => widget.section.getSolutionForLanguage('en') != null,
      'python' => widget.section.pythonSolutionCode != null && widget.section.pythonSolutionCode!.isNotEmpty,
      'r' => false, // TODO: Add R solution support
      _ => false,
    };

    if (!hasSolution) return const SizedBox.shrink();

    return OutlinedButton.icon(
      onPressed: _onAnswerPressed,
      icon: Icon(
        answerUsed ? Icons.refresh : Icons.visibility_outlined,
        color: Colors.deepPurple.shade600,
      ),
      label: Text(
        answerUsed ? 'Reload solution' : 'Show answer (-50% XP)',
        style: TextStyle(color: colorScheme.onSurface),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: colorScheme.outline),
      ),
    );
  }

  Widget _buildToolLinks(ThemeData theme, ColorScheme colorScheme) {
    final supportsSpreadsheet = widget.section.supportsSpreadsheet;
    final supportsPython = widget.section.supportsPython;
    // TODO: Add supportsR when implemented

    // Don't show if only one tool is supported
    if (!supportsSpreadsheet || !supportsPython) return const SizedBox.shrink();

    // Build slug for navigation
    var slug = widget.section.title.toLowerCase()
        .replaceAll(' ', '-')
        .replaceAll(RegExp(r'[^a-z0-9-]'), '');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Also available:',
            style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (widget.tool != 'spreadsheet' && supportsSpreadsheet)
                _buildToolLinkChip('spreadsheet', slug, Icons.table_chart, Colors.green),
              if (widget.tool != 'python' && supportsPython)
                _buildToolLinkChip('python', slug, Icons.code, Colors.deepPurple),
              // TODO: Add R link when implemented
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolLinkChip(String tool, String slug, IconData icon, Color color) {
    final label = switch (tool) {
      'spreadsheet' => 'Google Sheets',
      'python' => 'Python',
      'r' => 'R',
      _ => tool,
    };

    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      onPressed: () {
        // Navigate to other tool
        context.go('/sections/$slug-$tool');
      },
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }
}
