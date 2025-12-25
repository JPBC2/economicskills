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
    return Unit(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isPremium: json['is_premium'] as bool? ?? false,
      unlockCost: json['unlock_cost'] as int? ?? 150,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lessons: json['lessons'] != null
          ? (json['lessons'] as List).map((l) => Lesson.fromJson(l)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'course_id': courseId,
        'title': title,
        'description': description,
        'display_order': displayOrder,
        'is_premium': isPremium,
        'unlock_cost': unlockCost,
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
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Exercise? exercise;

  Lesson({
    required this.id,
    required this.unitId,
    required this.title,
    required this.explanationText,
    this.sourceReferences,
    this.youtubeVideoUrl,
    required this.displayOrder,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.exercise,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      unitId: json['unit_id'] as String,
      title: json['title'] as String,
      explanationText: json['explanation_text'] as String,
      sourceReferences: json['source_references'] as String?,
      youtubeVideoUrl: json['youtube_video_url'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      exercise: json['exercises'] != null && (json['exercises'] as List).isNotEmpty
          ? Exercise.fromJson((json['exercises'] as List).first)
          : null,
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
    return Exercise(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String,
      title: json['title'] as String,
      instructions: json['instructions'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      sections: json['sections'] != null
          ? (json['sections'] as List).map((s) => Section.fromJson(s)).toList()
          : null,
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
  final int displayOrder;
  final String templateSpreadsheetId;
  final int xpReward;
  final DateTime createdAt;
  final DateTime updatedAt;

  Section({
    required this.id,
    required this.exerciseId,
    required this.title,
    required this.displayOrder,
    required this.templateSpreadsheetId,
    this.xpReward = 10,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['id'] as String,
      exerciseId: json['exercise_id'] as String,
      title: json['title'] as String,
      displayOrder: json['display_order'] as int? ?? 0,
      templateSpreadsheetId: json['template_spreadsheet_id'] as String,
      xpReward: json['xp_reward'] as int? ?? 10,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'exercise_id': exerciseId,
        'title': title,
        'display_order': displayOrder,
        'template_spreadsheet_id': templateSpreadsheetId,
        'xp_reward': xpReward,
      };
}
