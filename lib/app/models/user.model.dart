/// User progress and XP data models

class UserProfile {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String? profilePhotoUrl;
  final bool publicProfileVisible;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.profilePhotoUrl,
    this.publicProfileVisible = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      publicProfileVisible: json['public_profile_visible'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class UserXP {
  final String id;
  final String userId;
  final int totalXpEarned;
  final int totalXpSpent;
  final int availableXp;
  final DateTime lastUpdated;

  UserXP({
    required this.id,
    required this.userId,
    required this.totalXpEarned,
    required this.totalXpSpent,
    required this.availableXp,
    required this.lastUpdated,
  });

  factory UserXP.fromJson(Map<String, dynamic> json) {
    return UserXP(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      totalXpEarned: json['total_xp_earned'] as int? ?? 0,
      totalXpSpent: json['total_xp_spent'] as int? ?? 0,
      availableXp: json['available_xp'] as int? ?? 0,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }
}

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
