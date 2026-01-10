/// Assignment and Task data models for EconomicSkills
/// Represents the new hierarchy additions: Section > Assignment > Task
library;

/// Assignment: Tool-specific implementation within a Section
/// Can be 'spreadsheet', 'python', or 'r'
class Assignment {
  final String id;
  final String sectionId;
  final String toolType; // 'spreadsheet', 'python', 'r'
  final int displayOrder;
  
  // Content fields
  final String? instructions;
  final String? hint;
  final int xpReward;
  
  // Spreadsheet-specific fields
  final String? templateSpreadsheetId;
  final String? solutionSpreadsheetId;
  final String? validationRange;
  
  // Code-specific fields (Python/R)
  final String? starterCode;
  final String? solutionCode;
  final Map<String, dynamic>? validationConfig;
  
  // Language-specific content (i18n)
  final Map<String, String> instructionsI18n;
  final Map<String, String> hintI18n;
  final Map<String, String> starterCodeI18n;
  final Map<String, String?> templateSpreadsheetsI18n;
  final Map<String, String?> solutionSpreadsheetsI18n;
  
  // Nested tasks
  final List<Task>? tasks;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  Assignment({
    required this.id,
    required this.sectionId,
    required this.toolType,
    this.displayOrder = 1,
    this.instructions,
    this.hint,
    this.xpReward = 10,
    this.templateSpreadsheetId,
    this.solutionSpreadsheetId,
    this.validationRange,
    this.starterCode,
    this.solutionCode,
    this.validationConfig,
    this.instructionsI18n = const {},
    this.hintI18n = const {},
    this.starterCodeI18n = const {},
    this.templateSpreadsheetsI18n = const {},
    this.solutionSpreadsheetsI18n = const {},
    this.tasks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    // Parse i18n fields
    Map<String, String> parseStringMap(dynamic data) {
      if (data == null) return {};
      if (data is Map) {
        return Map<String, String>.from(
          data.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
        );
      }
      return {};
    }

    Map<String, String?> parseNullableStringMap(dynamic data) {
      if (data == null) return {};
      if (data is Map) {
        return Map<String, String?>.from(
          data.map((k, v) => MapEntry(k.toString(), v?.toString())),
        );
      }
      return {};
    }

    // Parse nested tasks
    List<Task>? parsedTasks;
    if (json['tasks'] != null && json['tasks'] is List) {
      parsedTasks = (json['tasks'] as List)
          .map((t) => Task.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    return Assignment(
      id: json['id'] as String,
      sectionId: json['section_id'] as String,
      toolType: json['tool_type'] as String,
      displayOrder: json['display_order'] as int? ?? 1,
      instructions: json['instructions'] as String?,
      hint: json['hint'] as String?,
      xpReward: json['xp_reward'] as int? ?? 10,
      templateSpreadsheetId: json['template_spreadsheet_id'] as String?,
      solutionSpreadsheetId: json['solution_spreadsheet_id'] as String?,
      validationRange: json['validation_range'] as String?,
      starterCode: json['starter_code'] as String?,
      solutionCode: json['solution_code'] as String?,
      validationConfig: json['validation_config'] as Map<String, dynamic>?,
      instructionsI18n: parseStringMap(json['instructions_i18n']),
      hintI18n: parseStringMap(json['hint_i18n']),
      starterCodeI18n: parseStringMap(json['starter_code_i18n']),
      templateSpreadsheetsI18n: parseNullableStringMap(json['template_spreadsheets_i18n']),
      solutionSpreadsheetsI18n: parseNullableStringMap(json['solution_spreadsheets_i18n']),
      tasks: parsedTasks,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'section_id': sectionId,
    'tool_type': toolType,
    'display_order': displayOrder,
    'instructions': instructions,
    'hint': hint,
    'xp_reward': xpReward,
    'template_spreadsheet_id': templateSpreadsheetId,
    'solution_spreadsheet_id': solutionSpreadsheetId,
    'validation_range': validationRange,
    'starter_code': starterCode,
    'solution_code': solutionCode,
    'validation_config': validationConfig,
    'instructions_i18n': instructionsI18n,
    'hint_i18n': hintI18n,
    'starter_code_i18n': starterCodeI18n,
    'template_spreadsheets_i18n': templateSpreadsheetsI18n,
    'solution_spreadsheets_i18n': solutionSpreadsheetsI18n,
  };

  /// Get instructions for a specific language, falling back to English then default
  String? getInstructionsForLanguage(String langCode) {
    return instructionsI18n[langCode] ?? instructionsI18n['en'] ?? instructions;
  }

  /// Get hint for a specific language
  String? getHintForLanguage(String langCode) {
    return hintI18n[langCode] ?? hintI18n['en'] ?? hint;
  }

  /// Get starter code for a specific language
  String? getStarterCodeForLanguage(String langCode) {
    return starterCodeI18n[langCode] ?? starterCodeI18n['en'] ?? starterCode;
  }

  /// Get template spreadsheet ID for a specific language
  String? getTemplateForLanguage(String langCode) {
    return templateSpreadsheetsI18n[langCode] ?? 
           templateSpreadsheetsI18n['en'] ?? 
           templateSpreadsheetId;
  }

  /// Get solution spreadsheet ID for a specific language
  String? getSolutionForLanguage(String langCode) {
    return solutionSpreadsheetsI18n[langCode] ?? 
           solutionSpreadsheetsI18n['en'] ?? 
           solutionSpreadsheetId;
  }
}

/// Task: Individual step within an Assignment with its own XP reward
/// Tasks are completed sequentially
class Task {
  final String id;
  final String assignmentId;
  final int displayOrder;
  final String title;
  final String instructions;
  final String? hint;
  final int xpReward;
  final Map<String, dynamic> validationConfig;
  
  // Language-specific content (i18n)
  final Map<String, String> titleI18n;
  final Map<String, String> instructionsI18n;
  final Map<String, String> hintI18n;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.assignmentId,
    required this.displayOrder,
    required this.title,
    required this.instructions,
    this.hint,
    this.xpReward = 5,
    required this.validationConfig,
    this.titleI18n = const {},
    this.instructionsI18n = const {},
    this.hintI18n = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    Map<String, String> parseStringMap(dynamic data) {
      if (data == null) return {};
      if (data is Map) {
        return Map<String, String>.from(
          data.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
        );
      }
      return {};
    }

    return Task(
      id: json['id'] as String,
      assignmentId: json['assignment_id'] as String,
      displayOrder: json['display_order'] as int? ?? 1,
      title: json['title'] as String,
      instructions: json['instructions'] as String,
      hint: json['hint'] as String?,
      xpReward: json['xp_reward'] as int? ?? 5,
      validationConfig: json['validation_config'] as Map<String, dynamic>? ?? {},
      titleI18n: parseStringMap(json['title_i18n']),
      instructionsI18n: parseStringMap(json['instructions_i18n']),
      hintI18n: parseStringMap(json['hint_i18n']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'assignment_id': assignmentId,
    'display_order': displayOrder,
    'title': title,
    'instructions': instructions,
    'hint': hint,
    'xp_reward': xpReward,
    'validation_config': validationConfig,
    'title_i18n': titleI18n,
    'instructions_i18n': instructionsI18n,
    'hint_i18n': hintI18n,
  };

  /// Get title for a specific language
  String getTitleForLanguage(String langCode) {
    return titleI18n[langCode] ?? titleI18n['en'] ?? title;
  }

  /// Get instructions for a specific language
  String getInstructionsForLanguage(String langCode) {
    return instructionsI18n[langCode] ?? instructionsI18n['en'] ?? instructions;
  }

  /// Get hint for a specific language
  String? getHintForLanguage(String langCode) {
    return hintI18n[langCode] ?? hintI18n['en'] ?? hint;
  }
}

/// UserTaskProgress: Tracks user's progress on individual tasks
class UserTaskProgress {
  final String id;
  final String userId;
  final String taskId;
  final bool isCompleted;
  final DateTime? completedAt;
  final int xpEarned;
  final int attemptCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserTaskProgress({
    required this.id,
    required this.userId,
    required this.taskId,
    this.isCompleted = false,
    this.completedAt,
    this.xpEarned = 0,
    this.attemptCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserTaskProgress.fromJson(Map<String, dynamic> json) {
    return UserTaskProgress(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      taskId: json['task_id'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      xpEarned: json['xp_earned'] as int? ?? 0,
      attemptCount: json['attempt_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'task_id': taskId,
    'is_completed': isCompleted,
    'completed_at': completedAt?.toIso8601String(),
    'xp_earned': xpEarned,
    'attempt_count': attemptCount,
  };

  UserTaskProgress copyWith({
    bool? isCompleted,
    DateTime? completedAt,
    int? xpEarned,
    int? attemptCount,
  }) {
    return UserTaskProgress(
      id: id,
      userId: userId,
      taskId: taskId,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      xpEarned: xpEarned ?? this.xpEarned,
      attemptCount: attemptCount ?? this.attemptCount,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
