import 'package:flutter/material.dart';
import 'package:economicskills/app/res/responsive.res.dart';
import 'package:economicskills/app/widgets/drawer_nav.widget.dart';
import 'package:economicskills/app/widgets/hiding_scaffold.widget.dart';
import 'package:economicskills/app/widgets/top_nav.widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:economicskills/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return HidingScaffold(
      appBar: const TopNav(),
      drawer: MediaQuery.of(context).size.width > ScreenSizes.md
          ? null
          : const DrawerNav(),
      body: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1140),
              child: Padding(
                padding: const EdgeInsets.all(24.0),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 1140),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.homeWelcome,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (user != null) ...[
                              Text(
                                'Email: ${user.email}',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'User ID: ${user.id}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ] else 
                              Text(
                                'Not logged in',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.error,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      l10n.sheetsExercisesTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Text(
                        l10n.sheetsExercisesDesc,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        context.go('/exercises/elasticity');
                      },
                      child: Text(l10n.elasticityExerciseBtn),
                    ),
                    const SizedBox(height: 48),
                    Card(
                      elevation: 0,
                      color: colorScheme.secondaryContainer.withOpacity(0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.comingSoonTitle,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureItem(l10n.comingSoonSheets, theme),
                            _buildFeatureItem(l10n.comingSoonEvaluation, theme),
                            _buildFeatureItem(l10n.comingSoonProgress, theme),
                            _buildFeatureItem(l10n.comingSoonCourse, theme),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
    );
  }

  Widget _buildFeatureItem(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 20, color: theme.colorScheme.secondary),
          const SizedBox(width: 8),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

