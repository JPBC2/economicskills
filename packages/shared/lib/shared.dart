/// Shared library for EconomicSkills apps
/// Contains models and services used by both web and admin apps

library shared;

// Models
export 'models/course.model.dart';
export 'models/user.model.dart';
export 'models/translation.model.dart';
export 'models/profile.model.dart';

// Services
export 'services/course.service.dart';
export 'services/user.service.dart';
export 'services/google_sheets.service.dart';
export 'services/translation.service.dart';

// Config
export 'config/supabase_config.dart';
export 'config/theme.dart';
export 'config/text_styles.dart';
export 'config/gradients.dart';

