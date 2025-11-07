import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:economicskills/app/screens/exercises/elasticity.dart';
import '../screens/login.screen.dart';
import '../screens/signup.screen.dart';
import '../screens/home.screen.dart';
import '../screens/error_404.screen.dart';

class AppRouterDelegate extends RouterDelegate<Uri>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Uri> {
  @override
  final GlobalKey<NavigatorState> navigatorKey;

  Uri _path = Uri.parse('/');
  bool _isAuthenticated = false;
  StreamSubscription<AuthState>? _authSubscription;

  AppRouterDelegate() : navigatorKey = GlobalKey<NavigatorState>() {
    print('AppRouterDelegate: Constructor called');
    _checkAuthState();
    _setupAuthListener();
    _handleInitialAuth();
  }

  bool get isAuthenticated => _isAuthenticated;

  @override
  Uri get currentConfiguration {
    print('AppRouterDelegate: getCurrentConfiguration returning: $_path');
    return _path;
  }

  void _checkAuthState() {
    final user = Supabase.instance.client.auth.currentUser;
    final wasAuthenticated = _isAuthenticated;
    _isAuthenticated = user != null;
    
    print('AppRouterDelegate: Auth state check - User: ${user?.email ?? 'null'}, Authenticated: $_isAuthenticated');
    
    if (wasAuthenticated != _isAuthenticated) {
      print('AppRouterDelegate: Auth state changed from $wasAuthenticated to $_isAuthenticated');
    }
  }

  Future<void> _handleInitialAuth() async {
    try {
      print('AppRouterDelegate: Handling initial auth...');
      
      // Check current browser URL for OAuth parameters
      final currentUrl = Uri.base;
      print('AppRouterDelegate: Current browser URL: $currentUrl');
      
      if (_isOAuthCallback(currentUrl)) {
        print('AppRouterDelegate: Initial URL is OAuth callback, processing...');
        await _handleOAuthCallback(currentUrl);
      }
      
      _checkAuthState();
      if (_isAuthenticated) {
        _path = Uri.parse('/');
        print('AppRouterDelegate: User authenticated in initial auth, setting path to /');
        _safeNotifyListeners();
      }
    } catch (e) {
      print('AppRouterDelegate: Initial auth error: $e');
    }
  }

  void _setupAuthListener() {
    print('AppRouterDelegate: Setting up auth listener...');
    
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      print('AppRouterDelegate: Auth state changed: $event');
      
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.signedOut) {
        _checkAuthState();
        if (_isAuthenticated) {
          _path = Uri.parse('/');
          print('AppRouterDelegate: User authenticated, redirecting to home');
        } else {
          _path = Uri.parse('/login');
          print('AppRouterDelegate: User signed out, redirecting to login');
        }
        _safeNotifyListeners();
      }
    });
  }

  @override
  void dispose() {
    print('AppRouterDelegate: Disposing...');
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('AppRouterDelegate: Building with path: $_path, authenticated: $_isAuthenticated');
    _checkAuthState(); // Check auth state on every build
    final pages = _getRoutes(_path);
    print('AppRouterDelegate: Generated ${pages.length} pages');

    return Navigator(
      key: navigatorKey,
      pages: pages,
      onDidRemovePage: (Page page) {
        print('AppRouterDelegate: onDidRemovePage called for: ${page.name}');
        if (pages.isNotEmpty && pages.last.name == page.name) {
          if (!_isAuthenticated) {
            if (_path.path == '/signup') {
              _path = Uri.parse('/login');
            }
          } else {
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
    print('AppRouterDelegate: setNewRoutePath called with: $configuration');
    print('AppRouterDelegate: Query parameters: ${configuration.queryParameters}');
    print('AppRouterDelegate: Fragment: ${configuration.fragment}');
    
    // Handle OAuth callback URLs with query parameters
    if (_isOAuthCallback(configuration)) {
      print('AppRouterDelegate: Detected OAuth callback URL');
      await _handleOAuthCallback(configuration);
      return;
    }
    
    _path = configuration;
    print('AppRouterDelegate: Set path to: $_path');
    _safeNotifyListeners();
  }

  bool _isOAuthCallback(Uri uri) {
    final hasOAuthParams = uri.queryParameters.containsKey('code') ||
           uri.queryParameters.containsKey('access_token') ||
           uri.queryParameters.containsKey('error') ||
           uri.queryParameters.containsKey('error_code') ||
           uri.fragment.contains('access_token') ||
           uri.fragment.contains('error');
           
    print('AppRouterDelegate: _isOAuthCallback check for $uri: $hasOAuthParams');
    return hasOAuthParams;
  }

  Future<void> _handleOAuthCallback(Uri uri) async {
    try {
      print('AppRouterDelegate: Processing OAuth callback with URI: $uri');
      
      // Check for error in callback
      if (uri.queryParameters.containsKey('error') || 
          uri.queryParameters.containsKey('error_code')) {
        final error = uri.queryParameters['error'] ?? 'Unknown error';
        final errorDescription = uri.queryParameters['error_description'] ?? '';
        print('AppRouterDelegate: OAuth error: $error - $errorDescription');
        
        _path = Uri.parse('/login');
        _safeNotifyListeners();
        return;
      }

      // Handle successful OAuth callback
      if (uri.queryParameters.containsKey('code') || 
          uri.queryParameters.containsKey('access_token') ||
          uri.fragment.contains('access_token')) {
        
        print('AppRouterDelegate: Processing OAuth code/token exchange...');
        
        // Let Supabase handle the OAuth token exchange
        final response = await Supabase.instance.client.auth.getSessionFromUrl(uri);
        
        // The session is guaranteed to be non-null on success, so no need to check for null.
        print('AppRouterDelegate: OAuth success - session created: ${response.session.user.email}');
        _checkAuthState();
        _path = Uri.parse('/');
        
        _safeNotifyListeners();
      }
    } catch (e) {
      print('AppRouterDelegate: OAuth callback error: $e');
      _path = Uri.parse('/login');
      _safeNotifyListeners();
    }
  }

  void go(String path) {
    print('AppRouterDelegate: go() called with path: $path');
    if (_path.toString() == path && path != '/') return;
    _path = Uri.parse(path);
    _safeNotifyListeners();
  }

  void goToLogin() {
    print('AppRouterDelegate: goToLogin() called');
    _path = Uri.parse('/login');
    _safeNotifyListeners();
  }

  void goToSignup() {
    print('AppRouterDelegate: goToSignup() called');
    _path = Uri.parse('/signup');
    _safeNotifyListeners();
  }

  void goToHome() {
    print('AppRouterDelegate: goToHome() called');
    _path = Uri.parse('/');
    _safeNotifyListeners();
  }

  List<Page> _getRoutes(Uri path) {
    print('AppRouterDelegate: _getRoutes called with path: $path, authenticated: $_isAuthenticated');
    final pages = <Page>[];
    final pathSegments = path.pathSegments;

    if (!_isAuthenticated) {
      if (path.path == '/signup') {
        print('AppRouterDelegate: Adding SignupScreen page');
        pages.add(MaterialPage(
          child: SignupScreen(routerDelegate: this),
          key: const ValueKey('signup'),
          name: '/signup',
        ));
      } else {
        print('AppRouterDelegate: Adding LoginScreen page');
        pages.add(MaterialPage(
          child: LoginScreen(routerDelegate: this),
          key: const ValueKey('login'),
          name: '/login',
        ));
      }
    } else {
      if (pathSegments.isEmpty || path.path == '/') {
        print('AppRouterDelegate: Adding HomeScreen page');
        pages.add(MaterialPage(
          child: const HomeScreen(),
          key: const ValueKey('home'),
          name: '/',
        ));
      } else if (pathSegments.length == 2 &&
                 pathSegments[0] == 'exercises' &&
                 pathSegments[1] == 'elasticity') {
        print('AppRouterDelegate: Adding ElasticityPage page');
        pages.add(MaterialPage(
          key: const ValueKey('ElasticityPage'),
          name: '/exercises/elasticity',
          child: const ElasticityPage(),
        ));
      } else {
        print('AppRouterDelegate: Route not found, adding Error404Screen page');
        pages.add(MaterialPage(
          child: Error404Screen(routerDelegate: this),
          key: const ValueKey('error404'),
          name: '/404',
        ));
      }
    }

    print('AppRouterDelegate: Generated ${pages.length} pages: ${pages.map((p) => p.name).join(', ')}');
    return pages;
  }

  void _safeNotifyListeners() {
    print('AppRouterDelegate: _safeNotifyListeners called');
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        print('AppRouterDelegate: Notifying listeners (post-frame)');
        notifyListeners();
      });
    } else {
      print('AppRouterDelegate: Notifying listeners (immediate)');
      notifyListeners();
    }
  }
}
