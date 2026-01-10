import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    final isDark = theme.brightness == Brightness.dark;
    final isAuthenticated = Supabase.instance.client.auth.currentUser != null;
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

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
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        colorScheme.primaryContainer.withValues(alpha: 0.3),
                        colorScheme.surface,
                      ]
                    : [
                        const Color(0xFF1A237E), // Indigo (darkest)
                        const Color(0xFF303F9F), // Deep indigo
                        const Color(0xFF5C6BC0), // Medium indigo (bottom)
                      ],
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  children: [
                    Text(
                      l10n.landingHeroTitle1,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? colorScheme.onSurface : Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      l10n.landingHeroTitle2,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? colorScheme.primary : const Color(0xFF80DEEA),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.landingHeroSubtitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDark ? colorScheme.onSurfaceVariant : Colors.white.withValues(alpha: 0.9),
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
                          icon: Icon(isRtl ? Icons.school : Icons.school),
                          label: Text(l10n.landingExploreCourses),
                          style: FilledButton.styleFrom(
                            backgroundColor: isDark ? null : Colors.white,
                            foregroundColor: isDark ? null : const Color(0xFF1A237E),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                            textStyle: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (!isAuthenticated)
                          OutlinedButton.icon(
                            onPressed: () => context.go('/login'),
                            icon: const Icon(Icons.login),
                            label: Text(l10n.navSignIn),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? null : Colors.white,
                              side: isDark ? null : const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                              textStyle: theme.textTheme.titleMedium,
                            ),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () => context.go('/dashboard'),
                            icon: const Icon(Icons.dashboard),
                            label: Text(l10n.landingMyDashboard),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? null : Colors.white,
                              side: isDark ? null : const BorderSide(color: Colors.white),
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
                      l10n.landingWhyTitle,
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
                          context,
                          theme,
                          Icons.play_circle_outline,
                          l10n.landingFeature1Title,
                          l10n.landingFeature1Desc,
                          gradientColors: [Colors.red.shade400, Colors.red.shade700],
                        ),
                        _buildFeatureCard(
                          context,
                          theme,
                          Icons.table_chart,
                          l10n.landingFeature2Title,
                          l10n.landingFeature2Desc,
                          gradientColors: [Colors.green.shade400, Colors.green.shade700],
                        ),
                        _buildFeatureCard(
                          context,
                          theme,
                          Icons.code,
                          l10n.landingFeature3Title,
                          l10n.landingFeature3Desc,
                          gradientColors: [Colors.purple.shade400, Colors.purple.shade700],
                        ),
                        _buildFeatureCard(
                          context,
                          theme,
                          Icons.check_circle_outline,
                          l10n.landingFeature4Title,
                          l10n.landingFeature4Desc,
                          gradientColors: [Colors.amber.shade500, Colors.orange.shade600],
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
            color: colorScheme.primaryContainer.withValues(alpha: 0.2),
            child: Center(
              child: Column(
                children: [
                  Text(
                    l10n.landingCtaTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.go('/courses'),
                    icon: Icon(isRtl ? Icons.arrow_back : Icons.arrow_forward),
                    label: Text(l10n.landingBrowseCourses),
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

  Widget _buildFeatureCard(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String title,
    String description, {
    List<Color>? gradientColors,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // Adjust gradient colors for dark theme (slightly lighter)
    final effectiveColors = gradientColors != null
        ? (isDark
            ? gradientColors.map((c) => Color.lerp(c, Colors.white, 0.15)!).toList()
            : gradientColors)
        : null;

    return SizedBox(
      width: 320,
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            // Use directional alignment for RTL support
            crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: effectiveColors != null
                      ? effectiveColors.first.withValues(alpha: isDark ? 0.2 : 0.15)
                      : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: effectiveColors != null
                    ? ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: effectiveColors,
                        ).createShader(bounds),
                        child: Icon(icon, color: Colors.white, size: 28),
                      )
                    : Icon(icon, color: theme.colorScheme.primary, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
