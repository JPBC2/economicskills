/// Course data models for EconomicSkills
/// Represents the hierarchical structure: Course > Unit > Lesson > Exercise > Section

class Course {
  final String id;
  final String title;
  final String? description;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Unit>? units;

  Course({
    required this.id,
    required this.title,
    this.description,
    required this.displayOrder,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.units,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      units: json['units'] != null
          ? (json['units'] as List).map((u) => Unit.fromJson(u)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'display_order': displayOrder,
        'is_active': isActive,
      };
}

class Unit {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final int displayOrder;
  final bool isPremium;
  final int unlockCost;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Lesson>? lessons;

  Unit({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.displayOrder,
    this.isPremium = false,
    this.unlockCost = 150,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.lessons,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    List<Lesson>? parsedLessons;
    if (json['lessons'] != null) {
      final lessonsData = json['lessons'];
      if (lessonsData is List) {
        parsedLessons = lessonsData.map((l) => Lesson.fromJson(l as Map<String, dynamic>)).toList();
      }
    }
    
    return Unit(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isPremium: json['is_premium'] as bool? ?? false,
      unlockCost: json['unlock_cost_xp'] as int? ?? 150,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lessons: parsedLessons,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'course_id': courseId,
        'title': title,
        'description': description,
        'display_order': displayOrder,
        'is_premium': isPremium,
        'unlock_cost_xp': unlockCost,
        'is_active': isActive,
      };
}

class Lesson {
  final String id;
  final String unitId;
  final String title;
  final String explanationText;
  final String? sourceReferences;
  final String? youtubeVideoUrl;
  final String slug;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Exercise>? exercises;

  Lesson({
    required this.id,
    required this.unitId,
    required this.title,
    required this.explanationText,
    this.sourceReferences,
    this.youtubeVideoUrl,
    required this.slug,
    required this.displayOrder,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.exercises,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    List<Exercise>? parsedExercises;
    if (json['exercises'] != null) {
      final exercisesData = json['exercises'];
      if (exercisesData is List) {
        parsedExercises = exercisesData.map((e) => Exercise.fromJson(e as Map<String, dynamic>)).toList();
      } else if (exercisesData is Map<String, dynamic>) {
        // Single exercise returned as object (1:1 relationship)
        parsedExercises = [Exercise.fromJson(exercisesData)];
      }
    }
    
    return Lesson(
      id: json['id'] as String,
      unitId: json['unit_id'] as String,
      title: json['title'] as String,
      explanationText: json['explanation_text'] as String? ?? '',
      sourceReferences: json['source_references'] as String?,
      youtubeVideoUrl: json['youtube_video_url'] as String?,
      slug: json['slug'] as String? ?? '', // Fallback for old data or laggy migration
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      exercises: parsedExercises,
    );
  }

  /// Extract YouTube video ID from URL
  String? get youtubeVideoId {
    if (youtubeVideoUrl == null) return null;
    final uri = Uri.tryParse(youtubeVideoUrl!);
    if (uri == null) return null;
    
    // Handle youtu.be format
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    
    // Handle youtube.com/watch?v= format
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    }
    
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'unit_id': unitId,
        'title': title,
        'explanation_text': explanationText,
        'source_references': sourceReferences,
        'youtube_video_url': youtubeVideoUrl,
        'display_order': displayOrder,
        'is_active': isActive,
      };
}

class Exercise {
  final String id;
  final String lessonId;
  final String title;
  final String instructions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Section>? sections;

  Exercise({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.instructions,
    required this.createdAt,
    required this.updatedAt,
    this.sections,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    List<Section>? parsedSections;
    if (json['sections'] != null) {
      final sectionsData = json['sections'];
      if (sectionsData is List) {
        parsedSections = sectionsData.map((s) => Section.fromJson(s as Map<String, dynamic>)).toList();
      }
    }
    
    return Exercise(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String,
      title: json['title'] as String,
      instructions: json['instructions'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      sections: parsedSections,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'lesson_id': lessonId,
        'title': title,
        'instructions': instructions,
      };
}

class Section {
  final String id;
  final String exerciseId;
  final String title;
  final String? explanation;
  final String? instructions; // Legacy/shared instructions
  final String? hint; // Legacy/shared hint
  final int displayOrder;
  final String? templateSpreadsheetId;
  final int xpReward; // Legacy/shared XP reward
  final DateTime createdAt;
  final DateTime updatedAt;

  // Exercise type support flags
  final bool supportsSpreadsheet;
  final bool supportsPython;
  final bool supportsR;
  final String sectionType; // 'python', 'spreadsheet', 'r', 'both', or 'all'

  // Tool-specific instructions, hints, and XP rewards
  final String? instructionsSpreadsheet;
  final String? instructionsPython;
  final String? instructionsR;
  final String? hintSpreadsheet;
  final String? hintPython;
  final String? hintR;
  final int xpRewardSpreadsheet;
  final int xpRewardPython;
  final int xpRewardR;

  // Language-specific template and solution spreadsheet IDs
  final Map<String, String?> templateSpreadsheets;
  final Map<String, String?> solutionSpreadsheets;

  // Python exercise fields
  final Map<String, String?> pythonStarterCode;
  final String? pythonSolutionCode;
  final Map<String, dynamic>? pythonValidationConfig;

  // R exercise fields
  final Map<String, String?> rStarterCode;
  final String? rSolutionCode;
  final Map<String, dynamic>? rValidationConfig;

  Section({
    required this.id,
    required this.exerciseId,
    required this.title,
    this.explanation,
    this.instructions,
    this.hint,
    required this.displayOrder,
    this.templateSpreadsheetId,
    this.xpReward = 10,
    required this.createdAt,
    required this.updatedAt,
    this.supportsSpreadsheet = true,
    this.supportsPython = false,
    this.supportsR = false,
    this.sectionType = 'spreadsheet',
    this.instructionsSpreadsheet,
    this.instructionsPython,
    this.instructionsR,
    this.hintSpreadsheet,
    this.hintPython,
    this.hintR,
    this.xpRewardSpreadsheet = 10,
    this.xpRewardPython = 10,
    this.xpRewardR = 10,
    this.templateSpreadsheets = const {},
    this.solutionSpreadsheets = const {},
    this.pythonStarterCode = const {},
    this.pythonSolutionCode,
    this.pythonValidationConfig,
    this.rStarterCode = const {},
    this.rSolutionCode,
    this.rValidationConfig,
  });

  /// Get instructions for a specific tool, falling back to shared instructions
  String? getInstructionsForTool(String tool) {
    switch (tool) {
      case 'python':
        return instructionsPython ?? instructions;
      case 'r':
        return instructionsR ?? instructions;
      default:
        return instructionsSpreadsheet ?? instructions;
    }
  }

  /// Get hint for a specific tool, falling back to shared hint
  String? getHintForTool(String tool) {
    switch (tool) {
      case 'python':
        return hintPython ?? hint;
      case 'r':
        return hintR ?? hint;
      default:
        return hintSpreadsheet ?? hint;
    }
  }

  /// Get XP reward for a specific tool, falling back to shared XP reward
  int getXpRewardForTool(String tool) {
    switch (tool) {
      case 'python':
        return xpRewardPython > 0 ? xpRewardPython : xpReward;
      case 'r':
        return xpRewardR > 0 ? xpRewardR : xpReward;
      default:
        return xpRewardSpreadsheet > 0 ? xpRewardSpreadsheet : xpReward;
    }
  }

  /// Get template spreadsheet ID for a specific language, falling back to English then default
  String? getTemplateForLanguage(String langCode) {
    return templateSpreadsheets[langCode]
        ?? templateSpreadsheets['en']
        ?? templateSpreadsheetId;
  }

  /// Get solution spreadsheet ID for a specific language, falling back to English
  String? getSolutionForLanguage(String langCode) {
    return solutionSpreadsheets[langCode] ?? solutionSpreadsheets['en'];
  }

  /// Get Python starter code for a specific language, falling back to English
  String? getPythonStarterCodeForLanguage(String langCode) {
    return pythonStarterCode[langCode] ?? pythonStarterCode['en'];
  }

  /// Get R starter code for a specific language, falling back to English
  String? getRStarterCodeForLanguage(String langCode) {
    return rStarterCode[langCode] ?? rStarterCode['en'];
  }

  factory Section.fromJson(Map<String, dynamic> json) {
    // Parse language-specific templates and solutions
    final templates = <String, String?>{};
    final solutions = <String, String?>{};
    final pythonStarter = <String, String?>{};
    final rStarter = <String, String?>{};

    for (final lang in ['en', 'es', 'zh', 'ru', 'fr', 'pt', 'it', 'ca', 'ro', 'de', 'nl']) {
      templates[lang] = json['template_spreadsheet_$lang'] as String?;
      solutions[lang] = json['solution_spreadsheet_$lang'] as String?;
      pythonStarter[lang] = json['python_starter_code_$lang'] as String?;
      rStarter[lang] = json['r_starter_code_$lang'] as String?;
    }

    return Section(
      id: json['id'] as String,
      exerciseId: json['exercise_id'] as String,
      title: json['title'] as String,
      explanation: json['explanation'] as String?,
      instructions: json['instructions'] as String?,
      hint: json['hint'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      templateSpreadsheetId: json['template_spreadsheet_id'] as String?,
      xpReward: json['xp_reward'] as int? ?? 10,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      supportsSpreadsheet: json['supports_spreadsheet'] as bool? ?? true,
      supportsPython: json['supports_python'] as bool? ?? false,
      supportsR: json['supports_r'] as bool? ?? false,
      sectionType: json['section_type'] as String? ?? 'spreadsheet',
      // Tool-specific fields
      instructionsSpreadsheet: json['instructions_spreadsheet'] as String?,
      instructionsPython: json['instructions_python'] as String?,
      instructionsR: json['instructions_r'] as String?,
      hintSpreadsheet: json['hint_spreadsheet'] as String?,
      hintPython: json['hint_python'] as String?,
      hintR: json['hint_r'] as String?,
      xpRewardSpreadsheet: json['xp_reward_spreadsheet'] as int? ?? 10,
      xpRewardPython: json['xp_reward_python'] as int? ?? 10,
      xpRewardR: json['xp_reward_r'] as int? ?? 10,
      templateSpreadsheets: templates,
      solutionSpreadsheets: solutions,
      pythonStarterCode: pythonStarter,
      pythonSolutionCode: json['python_solution_code'] as String?,
      pythonValidationConfig: json['python_validation_config'] as Map<String, dynamic>?,
      rStarterCode: rStarter,
      rSolutionCode: json['r_solution_code'] as String?,
      rValidationConfig: json['r_validation_config'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'exercise_id': exerciseId,
      'title': title,
      'explanation': explanation,
      'instructions': instructions,
      'hint': hint,
      'display_order': displayOrder,
      'template_spreadsheet_id': templateSpreadsheetId,
      'xp_reward': xpReward,
      'supports_spreadsheet': supportsSpreadsheet,
      'supports_python': supportsPython,
      'section_type': sectionType,
      // Tool-specific fields
      'instructions_spreadsheet': instructionsSpreadsheet,
      'instructions_python': instructionsPython,
      'hint_spreadsheet': hintSpreadsheet,
      'hint_python': hintPython,
      'xp_reward_spreadsheet': xpRewardSpreadsheet,
      'xp_reward_python': xpRewardPython,
      'python_solution_code': pythonSolutionCode,
      'python_validation_config': pythonValidationConfig,
    };

    // Add language-specific templates and solutions
    for (final entry in templateSpreadsheets.entries) {
      if (entry.value != null) {
        json['template_spreadsheet_${entry.key}'] = entry.value;
      }
    }
    for (final entry in solutionSpreadsheets.entries) {
      if (entry.value != null) {
        json['solution_spreadsheet_${entry.key}'] = entry.value;
      }
    }
    for (final entry in pythonStarterCode.entries) {
      if (entry.value != null) {
        json['python_starter_code_${entry.key}'] = entry.value;
      }
    }

    return json;
  }
}
