import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../main.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGitHubLoading = false;
  String? _error;
  HttpServer? _localServer;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _localServer?.close();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGitHub() async {
    setState(() {
      _isGitHubLoading = true;
      _error = null;
    });

    try {
      // Start local server to capture OAuth callback
      await _startLocalServer();

      // Use signInWithOAuth - it opens browser automatically
      await supabase.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: 'http://localhost:54321/auth/callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      // Show waiting message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complete login in browser. Waiting for authentication...'),
            duration: Duration(seconds: 30),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'GitHub login error: $e';
        _isGitHubLoading = false;
      });
      _localServer?.close();
    }
  }

  Future<void> _startLocalServer() async {
    try {
      _localServer?.close();
      _localServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 54321);
      
      _localServer!.listen((request) async {
        if (request.uri.path == '/auth/callback') {
          final queryParams = request.uri.queryParameters;
          final code = queryParams['code'];
          
          // Send success response to browser
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.html
            ..write('''
              <html>
                <head>
                  <title>Login Successful</title>
                  <style>
                    body { font-family: system-ui; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: #1a1a2e; color: white; }
                    .container { text-align: center; }
                    h1 { color: #4ade80; }
                  </style>
                </head>
                <body>
                  <div class="container">
                    <h1>✓ Login Successful!</h1>
                    <p>You can close this window and return to the app.</p>
                  </div>
                </body>
              </html>
            ''');
          await request.response.close();

          // Exchange code for session
          if (code != null) {
            try {
              await supabase.auth.exchangeCodeForSession(code);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Login successful!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                setState(() {
                  _error = 'Failed to complete login: $e';
                });
              }
            }
          }

          // Close server
          await _localServer?.close();
          _localServer = null;
          
          if (mounted) {
            setState(() {
              _isGitHubLoading = false;
            });
          }
        }
      });

      // Timeout after 2 minutes
      Future.delayed(const Duration(minutes: 2), () {
        if (_localServer != null) {
          _localServer?.close();
          _localServer = null;
          if (mounted) {
            setState(() {
              _isGitHubLoading = false;
              _error = 'Login timed out. Please try again.';
            });
          }
        }
      });
    } catch (e) {
      throw Exception('Failed to start local server: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 64,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'EconomicSkills Admin',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Content Management System',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // GitHub Sign In Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isGitHubLoading ? null : _signInWithGitHub,
                      icon: _isGitHubLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.code),
                      label: Text(_isGitHubLoading ? 'Waiting for browser...' : 'Sign in with GitHub'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Divider(color: colorScheme.outline)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: colorScheme.outline)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Email/Password fields
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outlined),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    onSubmitted: (_) => _signInWithEmail(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(color: colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _signInWithEmail,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign In with Email'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
