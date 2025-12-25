/// Supabase configuration for EconomicSkills
/// 
/// The anon key is safe to expose publicly when RLS is enabled.
/// The service role key should NEVER be in client code.

class SupabaseConfig {
  /// Supabase project URL
  static const String url = 'https://pwailhwgnxgfwpgrysao.supabase.co';
  
  /// Supabase anonymous key (safe for client-side)
  static const String anonKey = 'sb_publishable_irGCGTJdFV9D8iUknklA2g_ZpaevBHG';
  
  /// OAuth redirect URL for Google Sign-In
  static String get redirectUrl {
    // For web, use the current origin
    return Uri.base.origin;
  }
}
