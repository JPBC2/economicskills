import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:economicskills/app/screens/landing.screen.dart';
import 'package:economicskills/app/screens/login.screen.dart';
import 'package:economicskills/app/screens/home.screen.dart';
import 'package:economicskills/app/screens/error_404.screen.dart';
import 'package:economicskills/app/screens/content/course_catalog.screen.dart';
import 'package:economicskills/app/screens/content/course_detail.screen.dart';
import 'package:economicskills/app/screens/content/section.screen.dart';
import 'package:economicskills/app/screens/content/lesson.screen.dart';
import 'package:economicskills/app/screens/dashboard.screen.dart';
import 'package:economicskills/app/screens/exercises/elasticity.dart';

/// Global router configuration using go_router
final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  
  // Redirect logic for authentication
  redirect: (BuildContext context, GoRouterState state) {
    final user = Supabase.instance.client.auth.currentUser;
    final isAuthenticated = user != null;
    final isGoingToLogin = state.matchedLocation == '/login';
    final isGoingToSignup = state.matchedLocation == '/signup';
    final isPublicRoute = isPublicRoutePath(state.matchedLocation);

    // If user is authenticated and on landing page, redirect to dashboard
    if (isAuthenticated && state.matchedLocation == '/') {
      return '/dashboard';
    }

    // If user is authenticated and trying to access login/signup, redirect to dashboard
    if (isAuthenticated && (isGoingToLogin || isGoingToSignup)) {
      return '/dashboard';
    }

    // If user is not authenticated and trying to access protected route, redirect to login
    if (!isAuthenticated && !isPublicRoute) {
      return '/login';
    }

    // No redirect needed
    return null;
  },

  // Error page builder for 404s
  errorBuilder: (context, state) => const Error404Screen(),

  // Route definitions
  routes: [
    // PUBLIC ROUTES
    
    // Landing page
    GoRoute(
      path: '/',
      name: 'landing',
      builder: (context, state) => const LandingScreen(),
    ),

    // Login
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) {
        final returnTo = state.uri.queryParameters['returnTo'];
        return LoginScreen(returnTo: returnTo);
      },
    ),

    // Signup redirect (Google-only auth)
    GoRoute(
      path: '/signup',
      name: 'signup',
      redirect: (context, state) => '/login',
    ),

    // Dashboard (authenticated users home)
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),

    // Course catalog
    GoRoute(
      path: '/courses',
      name: 'courses',
      builder: (context, state) => const CourseCatalogScreen(),
      routes: [
        // Course detail (nested route) - accepts slug or ID
        GoRoute(
          path: ':courseSlug',
          name: 'course-detail',
          builder: (context, state) {
            final courseSlug = state.pathParameters['courseSlug'] ?? '';
            return CourseDetailScreen(courseSlug: courseSlug);
          },
        ),
      ],
    ),

    // Sections (exercise screens) - accepts slug or ID
    GoRoute(
      path: '/sections/:sectionSlug',
      name: 'section',
      builder: (context, state) {
        final sectionSlug = state.pathParameters['sectionSlug'] ?? '';
        return SectionScreen(sectionSlug: sectionSlug);
      },
    ),

    // Lessons
    GoRoute(
      path: '/lessons/:lessonSlug',
      name: 'lesson',
      builder: (context, state) {
        final lessonSlug = state.pathParameters['lessonSlug'] ?? '';
        return LessonScreen(lessonId: lessonSlug); // Service now handles slug or ID
      },
    ),

    // Content redirect to courses
    GoRoute(
      path: '/content',
      name: 'content',
      redirect: (context, state) => '/courses',
    ),

    // PROTECTED ROUTES
    
    // Exercises
    GoRoute(
      path: '/exercises/elasticity',
      name: 'elasticity',
      builder: (context, state) => const ElasticityPage(),
    ),
  ],
);

/// Helper function to determine if a route is public
/// Exported for use in sign-out logic
bool isPublicRoutePath(String path) {
  const publicRoutes = [
    '/',
    '/login',
    '/courses',
    '/lessons',
    '/sections',
    '/content',
  ];

  // Exact match
  if (publicRoutes.contains(path)) return true;

  // Prefix match for dynamic routes
  if (path.startsWith('/courses/')) return true;
  if (path.startsWith('/lessons/')) return true;
  if (path.startsWith('/sections/')) return true;

  return false;
}
