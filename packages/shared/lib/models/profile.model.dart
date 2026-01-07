// User profile and XP data models for EconomicSkills

/// Represents a user profile with personal information and settings
class UserProfile {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String? profilePhotoUrl;
  final String? programDegree;
  final String? universityInstitution;
  final String? professionalBio;
  final String? linkedinUrl;
  final String? githubUrl;
  final String? xUrl;
  final String? websiteUrl;
  final bool publicProfileVisible;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.profilePhotoUrl,
    this.programDegree,
    this.universityInstitution,
    this.professionalBio,
    this.linkedinUrl,
    this.githubUrl,
    this.xUrl,
    this.websiteUrl,
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
      programDegree: json['program_degree'] as String?,
      universityInstitution: json['university_institution'] as String?,
      professionalBio: json['professional_bio'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      githubUrl: json['github_url'] as String?,
      xUrl: json['x_url'] as String?,
      websiteUrl: json['website_url'] as String?,
      publicProfileVisible: json['public_profile_visible'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'full_name': fullName,
        'email': email,
        'profile_photo_url': profilePhotoUrl,
        'program_degree': programDegree,
        'university_institution': universityInstitution,
        'professional_bio': professionalBio,
        'linkedin_url': linkedinUrl,
        'github_url': githubUrl,
        'x_url': xUrl,
        'website_url': websiteUrl,
        'public_profile_visible': publicProfileVisible,
      };

  UserProfile copyWith({
    String? fullName,
    String? profilePhotoUrl,
    String? programDegree,
    String? universityInstitution,
    String? professionalBio,
    String? linkedinUrl,
    String? githubUrl,
    String? xUrl,
    String? websiteUrl,
    bool? publicProfileVisible,
  }) {
    return UserProfile(
      id: id,
      userId: userId,
      fullName: fullName ?? this.fullName,
      email: email,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      programDegree: programDegree ?? this.programDegree,
      universityInstitution: universityInstitution ?? this.universityInstitution,
      professionalBio: professionalBio ?? this.professionalBio,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      xUrl: xUrl ?? this.xUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      publicProfileVisible: publicProfileVisible ?? this.publicProfileVisible,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Represents a user's XP balance
class UserXP {
  final String id;
  final String userId;
  final int totalXpEarned;
  final int totalXpSpent;
  final DateTime lastUpdated;

  UserXP({
    required this.id,
    required this.userId,
    required this.totalXpEarned,
    required this.totalXpSpent,
    required this.lastUpdated,
  });

  /// Available XP (what the user can spend)
  int get availableXp => totalXpEarned - totalXpSpent;

  factory UserXP.fromJson(Map<String, dynamic> json) {
    return UserXP(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      totalXpEarned: json['total_xp_earned'] as int? ?? 0,
      totalXpSpent: json['total_xp_spent'] as int? ?? 0,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'total_xp_earned': totalXpEarned,
        'total_xp_spent': totalXpSpent,
      };
}

/// Represents an XP transaction (earning or spending)
class XPTransaction {
  final String id;
  final String userId;
  final String transactionType; // 'earned', 'spent'
  final int amount;
  final String sourceType; // 'section_completion', 'unit_unlock'
  final String? sourceId;
  final String? description;
  final DateTime createdAt;

  XPTransaction({
    required this.id,
    required this.userId,
    required this.transactionType,
    required this.amount,
    required this.sourceType,
    this.sourceId,
    this.description,
    required this.createdAt,
  });

  factory XPTransaction.fromJson(Map<String, dynamic> json) {
    return XPTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      transactionType: json['transaction_type'] as String,
      amount: json['amount'] as int,
      sourceType: json['source_type'] as String,
      sourceId: json['source_id'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'transaction_type': transactionType,
        'amount': amount,
        'source_type': sourceType,
        'source_id': sourceId,
        'description': description,
      };
}

/// Dashboard statistics model
class DashboardStats {
  final int totalXpEarned;
  final int totalXpSpent;
  final int availableXp;
  final int coursesCompleted;
  final int unitsCompleted;
  final int lessonsCompleted;

  DashboardStats({
    required this.totalXpEarned,
    required this.totalXpSpent,
    required this.availableXp,
    required this.coursesCompleted,
    required this.unitsCompleted,
    required this.lessonsCompleted,
  });

  factory DashboardStats.empty() => DashboardStats(
        totalXpEarned: 0,
        totalXpSpent: 0,
        availableXp: 0,
        coursesCompleted: 0,
        unitsCompleted: 0,
        lessonsCompleted: 0,
      );
}

/// Course progress model for dashboard
class CourseProgress {
  final String courseId;
  final String courseTitle;
  final int completedLessons;
  final int totalLessons;
  final List<UnitProgress> units;

  CourseProgress({
    required this.courseId,
    required this.courseTitle,
    required this.completedLessons,
    required this.totalLessons,
    required this.units,
  });

  double get progressPercentage =>
      totalLessons > 0 ? (completedLessons / totalLessons) * 100 : 0;

  bool get isCompleted => completedLessons == totalLessons && totalLessons > 0;
}

/// Unit progress model for dashboard
class UnitProgress {
  final String unitId;
  final String unitTitle;
  final bool isPremium;
  final bool isUnlocked;
  final int unlockCost;
  final int completedLessons;
  final int totalLessons;
  final List<LessonProgress> lessons;

  UnitProgress({
    required this.unitId,
    required this.unitTitle,
    required this.isPremium,
    required this.isUnlocked,
    required this.unlockCost,
    required this.completedLessons,
    required this.totalLessons,
    required this.lessons,
  });

  double get progressPercentage =>
      totalLessons > 0 ? (completedLessons / totalLessons) * 100 : 0;

  bool get isCompleted => completedLessons == totalLessons && totalLessons > 0;

  bool get isLocked => isPremium && !isUnlocked;
}

/// Lesson progress model for dashboard
class LessonProgress {
  final String lessonId;
  final String lessonTitle;
  final bool isCompleted;
  final int xpEarned;

  LessonProgress({
    required this.lessonId,
    required this.lessonTitle,
    required this.isCompleted,
    required this.xpEarned,
  });
}
