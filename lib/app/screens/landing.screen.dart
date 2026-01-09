import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/shared.dart';
import 'package:economicskills/app/widgets/top_nav.widget.dart';
import 'package:economicskills/app/widgets/hiding_scaffold.widget.dart';
import 'package:economicskills/app/widgets/drawer_nav.widget.dart';
import 'package:economicskills/app/res/responsive.res.dart';
import 'package:economicskills/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Landing Page - PUBLIC (no auth required)
/// This is the main entry point of the application
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAuthenticated = Supabase.instance.client.auth.currentUser != null;

    return HidingScaffold(
      appBar: const TopNav(),
      drawer: MediaQuery.of(context).size.width > ScreenSizes.md
          ? null
          : const DrawerNav(),
      body: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.3),
                  colorScheme.surface,
                ],
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  children: [
                    Text(
                      'Master Economics with',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Interactive Data',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Bridge the gap between theory and practice. Solve real-world economic problems using interactive Google Sheets and Python exercises with instant feedback.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.go('/courses'),
                          icon: const Icon(Icons.school),
                          label: const Text('Explore Courses'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                            textStyle: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (!isAuthenticated)
                          OutlinedButton.icon(
                            onPressed: () => context.go('/login'),
                            icon: const Icon(Icons.login),
                            label: const Text('Sign In'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                              textStyle: theme.textTheme.titleMedium,
                            ),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () => context.go('/dashboard'),
                            icon: const Icon(Icons.dashboard),
                            label: const Text('My Dashboard'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                              textStyle: theme.textTheme.titleMedium,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Features Section
          Padding(
            padding: const EdgeInsets.all(48),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1140),
                child: Column(
                  children: [
                    Text(
                      'Why Economic Skills?',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildFeatureCard(
                          theme,
                          Icons.play_circle_outline,
                          'Interactive Learning',
                          "Don't just read about economics. Do it. Manipulate data in real-time and see how economic models respond.",
                        ),
                        _buildFeatureCard(
                          theme,
                          Icons.table_chart,
                          'Google Sheets Integration',
                          'Work in the environment you know. Our seamless integration brings the power of spreadsheets to your learning.',
                        ),
                        _buildFeatureCard(
                          theme,
                          Icons.code,
                          'Python Exercises',
                          'Write Python code to analyze economic data. Build real-world skills with hands-on coding challenges.',
                        ),
                        _buildFeatureCard(
                          theme,
                          Icons.check_circle_outline,
                          'Instant Verification',
                          'Get immediate feedback on your exercises. Understand your mistakes and learn faster.',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // CTA Section
          Container(
            padding: const EdgeInsets.all(48),
            color: colorScheme.primaryContainer.withOpacity(0.2),
            child: Center(
              child: Column(
                children: [
                  Text(
                    'Ready to start learning?',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.go('/courses'),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Browse Courses'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer
          // Container(
          //   padding: const EdgeInsets.all(24),
          //   color: colorScheme.surfaceContainerHighest,
          //   child: Center(
          //     child: Text(
          //       '© 2025 Economic Skills. All rights reserved.',
          //       style: theme.textTheme.bodySmall?.copyWith(
          //         color: colorScheme.onSurfaceVariant,
          //       ),
          //     ),
          //   ),
          // ),
      ],
    );
  }

  Widget _buildFeatureCard(ThemeData theme, IconData icon, String title, String description) {
    return SizedBox(
      width: 320,
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
