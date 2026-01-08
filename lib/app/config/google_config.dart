/// Google Sheets API Configuration
/// 
/// SETUP INSTRUCTIONS:
/// 1. Create a Google Cloud Project at https://console.cloud.google.com
/// 2. Enable the Google Sheets API and Google Drive API
/// 3. Create a Service Account with Editor role
/// 4. Download the JSON key file
/// 5. Set the environment variables below OR store credentials securely
/// 
/// For Flutter Web, you'll need to expose these via a backend proxy
/// since service account credentials shouldn't be in client-side code.
library;

class GoogleConfig {
  // These should be loaded from environment variables or a secure backend
  // DO NOT commit actual values to source control
  
  /// Service account email (from JSON key)
  static const String serviceAccountEmail = String.fromEnvironment(
    'GOOGLE_SERVICE_ACCOUNT_EMAIL',
    defaultValue: '',
  );
  
  /// Private key (from JSON key) - Use a backend proxy in production
  static const String privateKey = String.fromEnvironment(
    'GOOGLE_PRIVATE_KEY',
    defaultValue: '',
  );
  
  /// Project ID
  static const String projectId = String.fromEnvironment(
    'GOOGLE_PROJECT_ID',
    defaultValue: '',
  );
  
  /// OAuth Client ID (for Google Sign-In)
  static const String webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );
  
  /// Scopes required for Google Sheets and Drive operations
  static const List<String> scopes = [
    'https://www.googleapis.com/auth/spreadsheets',
    'https://www.googleapis.com/auth/drive.file',
  ];
  
  /// Check if configuration is valid
  static bool get isConfigured =>
      serviceAccountEmail.isNotEmpty && 
      privateKey.isNotEmpty;
}
