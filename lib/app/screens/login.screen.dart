import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_html/html.dart' as html;
import 'package:economicskills/app/res/responsive.res.dart';
import 'package:economicskills/app/widgets/guest_drawer_nav.widget.dart';
import 'package:economicskills/app/widgets/guest_top_nav.widget.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? returnTo;
  
  const LoginScreen({super.key, this.returnTo});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Store returnTo in localStorage for post-OAuth redirect
    if (kIsWeb && widget.returnTo != null && widget.returnTo!.isNotEmpty) {
      html.window.localStorage['returnTo'] = widget.returnTo!;
    }
  }

  // Get the current origin URL (works for both localhost and production)
  String _getRedirectUrl() {
    if (kIsWeb) {
      final host = html.window.location.host;
      
      // For localhost development, use simple localhost URL
      if (host.contains('localhost') || host.contains('127.0.0.1')) {
        // Extract the port
        final port = host.split(':').length > 1 ? host.split(':')[1] : '3000';
        return 'http://localhost:$port';
      }
      
      // For production (GitHub Pages, etc.)
      final protocol = html.window.location.protocol;
      final pathname = html.window.location.pathname;

      String baseUrl = '$protocol//$host';

      // Add pathname for subpath deployments (e.g., github pages /economicskills)
      if (pathname != null && pathname != '/' && pathname.isNotEmpty) {
        String cleanPath = pathname.trim().replaceAll(RegExp(r'/+$'), '');
        if (cleanPath.isNotEmpty) {
          baseUrl = '$baseUrl$cleanPath';
        }
      }

      print('OAuth redirect URL: $baseUrl');
      return baseUrl.trim();
    }
    // Fallback for non-web platforms
    return 'http://localhost:3000';
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final redirectUrl = _getRedirectUrl();
      print('=== OAUTH DEBUG ===');
      print('Host: ${html.window.location.host}');
      print('Redirect URL being used: $redirectUrl');
      print('===================');

      // For Flutter web, use environment-aware redirect URL
      // Request Drive scope for spreadsheet copy functionality
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.platformDefault,
        scopes: 'https://www.googleapis.com/auth/drive',
      );
    } on AuthException catch (error) {
      if (mounted) {
        context.showSnackBar('Google sign-in failed: ${error.message}', isError: true);
      }
    } catch (error) {
      if (mounted) {
        context.showSnackBar('Google sign-in failed: $error', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: const GuestTopNav(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: 450,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        AppBar().preferredSize.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google Sheets icon representation
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.table_chart_rounded,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: () => context.go('/'),
                          child: const Text(
                            'Welcome to Economic Skills',
                            style: TextStyle(
                              fontSize: 24,
                              fontFamily: 'ContrailOne',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Learn applied economic theory with interactive Google Sheets',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16, 
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 48),
                        
                        // Google Sign-In Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.lock_outline_rounded,
                                size: 32,
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Sign in with your Google account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'A Google account is required to access your personalized spreadsheet exercises and use Google Sheets add-ons.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _signInWithGoogle,
                                  icon: _isLoading 
                                    ? const SizedBox.shrink()
                                    : Container(
                                        width: 24,
                                        height: 24,
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Image.network(
                                          'https://www.google.com/favicon.ico',
                                          errorBuilder: (context, error, stackTrace) => const Text(
                                            'G',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                  label: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Continue with Google',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Info note
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'New users will be automatically registered',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      drawer: MediaQuery.of(context).size.width > ScreenSizes.md
          ? null
          : const GuestDrawerNav(),
    );
  }
}