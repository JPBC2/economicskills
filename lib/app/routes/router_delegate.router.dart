import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // Import for Scheduler Phase
import 'package:economicskills/app/pages/home.page.dart';
// Ensure this import path is correct and the file defines ElasticityPage
import 'package:economicskills/app/pages/exercises/elasticity.dart';
// If you have an Error404Page, ensure it's imported too, e.g.:
// import 'package:economicskills/app/pages/error404_page.dart';

class AppRouterDelegate extends RouterDelegate<Uri>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Uri> {
  @override
  final GlobalKey<NavigatorState> navigatorKey;

  Uri _path = Uri.parse('/');

  AppRouterDelegate() : navigatorKey = GlobalKey<NavigatorState>();

  @override
  Uri get currentConfiguration => _path;

  @override
  Widget build(BuildContext context) {
    final pages = _getRoutes(_path);
    return Navigator(
      key: navigatorKey,
      pages: pages,
      onDidRemovePage: (Page<dynamic> page) {
        // This callback is invoked after a page has been successfully removed by the Navigator.
        // The 'pages' variable here is from the build method's scope,
        // representing the list of pages based on _path before this pop is reflected in _path.
        if (pages.isNotEmpty && pages.last.name == page.name) {
          // The page removed by the Navigator was the one we considered to be at the top.
          // Now, update _path to reflect this change.
          if (pages.length > 1) { // If there was more than one page in the list
            _path = _path.replace(
              pathSegments: _path.pathSegments.isNotEmpty
                  ? _path.pathSegments.sublist(0, _path.pathSegments.length - 1)
                  : [], // Avoid error if pathSegments is already empty
            );
            // If pathSegments became empty, it implies we are back at the root path.
            if (_path.pathSegments.isEmpty) {
              _path = Uri.parse('/');
            }
          } else {
            // The only page in the list was popped (e.g., HomePage).
            // _path should be Uri.parse('/')
            _path = Uri.parse('/');
          }
          _safeNotifyListeners();
        }
        // If pages.last.name != page.name, it implies a pop occurred that wasn't
        // perfectly aligned with our _path logic. For robust handling,
        // one might need to re-evaluate _path based on the remaining navigator stack,
        // but the current translated logic mirrors the original's conditional update.
      },
    );
  }

  @override
  Future<void> setNewRoutePath(Uri configuration) async {
    _path = configuration;
    _safeNotifyListeners(); 
  }

  go(String path) {
    if (_path.toString() == path && path != '/') return; 
    _path = Uri.parse(path);
    _safeNotifyListeners();
  }

  List<Page> _getRoutes(Uri path) {
    final pages = <Page>[];
    // Always add HomePage as the base and set its name for onPopPage comparison
    pages.add(MaterialPage(child: HomePage(), key: ValueKey('home'), name: '/'));

    if (path.pathSegments.isNotEmpty) {
      if (path.pathSegments.length == 2 &&
          path.pathSegments[0] == 'exercises' &&
          path.pathSegments[1] == 'elasticity') {
        pages.add(MaterialPage(
          key: ValueKey('ElasticityPage'),
          name: '/exercises/elasticity', // Set name for onPopPage comparison
          child: ElasticityPage(), // Corrected class name
        ));
      } else if (path.pathSegments.length == 1 && path.pathSegments[0] == 'content') {
        // Example for a hypothetical /content page
        // pages.add(MaterialPage(key: ValueKey('ContentPage'), name: '/content', child: ContentPage()));
        print("Navigating to content page (placeholder) - you might want to add a real page here."); 
      }
      // else {
      //   // Fallback for unrecognized non-empty paths (after HomePage)
      //   if (path.path != '/') {
      //      // pages.add(MaterialPage(child: Error404Page(), key: ValueKey('error'), name: '/error'));
      //   }
      // }
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
