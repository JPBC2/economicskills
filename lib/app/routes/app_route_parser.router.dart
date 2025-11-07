import 'package:flutter/material.dart';

class AppRouteInformationParser extends RouteInformationParser<Uri> {
  @override
  Future<Uri> parseRouteInformation(RouteInformation routeInformation) async {
    final uri = routeInformation.uri;
    
    // Debug log to see what URLs are being parsed
    print('RouteInformationParser: Parsing URI: $uri');
    print('RouteInformationParser: Query parameters: ${uri.queryParameters}');
    
    // Return the complete URI with all query parameters and fragments
    return uri;
  }

  @override
  RouteInformation restoreRouteInformation(Uri configuration) {
    final routeInformation = RouteInformation(uri: configuration);
    
    // Debug log to see what's being restored
    print('RouteInformationParser: Restoring URI: $configuration');
    
    return routeInformation;
  }
}