import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:economicskills/app/pages/exercises/elasticity.dart';
import '../login_screen.dart';
import '../signup_screen.dart';
import '../home_screen.dart';

class AppRouterDelegate extends RouterDelegate<Uri>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Uri> {
  @override
  final GlobalKey<NavigatorState> navigatorKey;

  Uri _path = Uri.parse('/');
  bool _isAuthenticated = false;
  StreamSubscription<AuthState>? _authSubscription;

  AppRouterDelegate() : navigatorKey = GlobalKey<NavigatorState>() {
    _checkAuthState();
    _setupAuthListener();
  }

  bool get isAuthenticated => _isAuthenticated;

  @override
  Uri get currentConfiguration => _path;

  void _checkAuthState() {
    final user = Supabase.instance.client.auth.currentUser;
    _isAuthenticated = user != null;
  }

  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.signedOut) {
        _checkAuthState();
        if (_isAuthenticated) {
          // Redirect to home after successful authentication
          _path = Uri.parse('/');
        }
        _safeNotifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _checkAuthState(); // Check auth state on every build
    final pages = _getRoutes(_path);

    return Navigator(
      key: navigatorKey,
      pages: pages,
      onDidRemovePage: (Page page) {
        if (pages.isNotEmpty && pages.last.name == page.name) {
          if (!_isAuthenticated) {
            // Handle auth screen navigation
            if (_path.path == '/signup') {
              _path = Uri.parse('/login');
            }
          } else {
            // Handle authenticated screen navigation
            if (pages.length > 1) {
              _path = _path.replace(
                pathSegments: _path.pathSegments.isNotEmpty
                    ? _path.pathSegments.sublist(0, _path.pathSegments.length - 1)
                    : [],
              );
              if (_path.pathSegments.isEmpty) {
                _path = Uri.parse('/');
              }
            } else {
              _path = Uri.parse('/');
            }
          }
          _safeNotifyListeners();
        }
      },
    );
  }

  @override
  Future<void> setNewRoutePath(Uri configuration) async {
    _path = configuration;
    _safeNotifyListeners();
  }

  void go(String path) {
    if (_path.toString() == path && path != '/') return;
    _path = Uri.parse(path);
    _safeNotifyListeners();
  }

  void goToLogin() {
    _path = Uri.parse('/login');
    _safeNotifyListeners();
  }

  void goToSignup() {
    _path = Uri.parse('/signup');
    _safeNotifyListeners();
  }

  void goToHome() {
    _path = Uri.parse('/');
    _safeNotifyListeners();
  }

  List<Page> _getRoutes(Uri path) {
    final pages = <Page>[];

    if (!_isAuthenticated) {
      // Show authentication screens
      if (path.path == '/signup') {
        pages.add(MaterialPage(
          child: SignupScreen(routerDelegate: this),
          key: const ValueKey('signup'),
          name: '/signup',
        ));
      } else {
        // Default to login for unauthenticated users
        pages.add(MaterialPage(
          child: LoginScreen(routerDelegate: this),
          key: const ValueKey('login'),
          name: '/login',
        ));
      }
    } else {
      // Show authenticated screens
      // Always add HomeScreen as the base for authenticated users
      pages.add(MaterialPage(
        child: const HomeScreen(),
        key: const ValueKey('home'),
        name: '/',
      ));

      // Add additional pages based on path
      if (path.pathSegments.isNotEmpty) {
        if (path.pathSegments.length == 2 &&
            path.pathSegments[0] == 'exercises' &&
            path.pathSegments[1] == 'elasticity') {
          pages.add(MaterialPage(
            key: const ValueKey('ElasticityPage'),
            name: '/exercises/elasticity',
            child: const ElasticityPage(),
          ));
        } else if (path.pathSegments.length == 1 && path.pathSegments[0] == 'content') {
          // Example for a hypothetical /content page
          print("Navigating to content page (placeholder) - you might want to add a real page here.");
        }
      }
    }

    return pages;
  }

  void _safeNotifyListeners() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }
}