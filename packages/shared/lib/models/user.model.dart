/// User progress and spreadsheet data models
/// Note: UserProfile and UserXP are now in profile.model.dart
library;

class UserSpreadsheet {
  final String id;
  final String userId;
  final String sectionId;
  final String spreadsheetId;
  final String spreadsheetUrl;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime lastAccessedAt;

  UserSpreadsheet({
    required this.id,
    required this.userId,
    required this.sectionId,
    required this.spreadsheetId,
    required this.spreadsheetUrl,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    required this.lastAccessedAt,
  });

  factory UserSpreadsheet.fromJson(Map<String, dynamic> json) {
    return UserSpreadsheet(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sectionId: json['section_id'] as String,
      spreadsheetId: json['spreadsheet_id'] as String,
      spreadsheetUrl: json['spreadsheet_url'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastAccessedAt: DateTime.parse(json['last_accessed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'section_id': sectionId,
        'spreadsheet_id': spreadsheetId,
        'spreadsheet_url': spreadsheetUrl,
        'is_completed': isCompleted,
      };
}

class UserProgress {
  final String id;
  final String userId;
  final String sectionId;
  final bool isCompleted;
  final int xpEarned;
  final int attemptCount;
  final DateTime? firstAttemptAt;
  final DateTime? completedAt;
  final DateTime? lastAttemptAt;

  UserProgress({
    required this.id,
    required this.userId,
    required this.sectionId,
    this.isCompleted = false,
    this.xpEarned = 0,
    this.attemptCount = 0,
    this.firstAttemptAt,
    this.completedAt,
    this.lastAttemptAt,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sectionId: json['section_id'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
      xpEarned: json['xp_earned'] as int? ?? 0,
      attemptCount: json['attempt_count'] as int? ?? 0,
      firstAttemptAt: json['first_attempt_at'] != null
          ? DateTime.parse(json['first_attempt_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      lastAttemptAt: json['last_attempt_at'] != null
          ? DateTime.parse(json['last_attempt_at'] as String)
          : null,
    );
  }
}
