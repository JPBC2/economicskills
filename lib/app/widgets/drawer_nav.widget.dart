import 'package:flutter/material.dart';
// for routerDelegate.go()
import 'package:economicskills/app/config/menu_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:economicskills/app/view_models/theme_mode.vm.dart';

class DrawerNav extends StatefulWidget {
  const DrawerNav({super.key});

  @override
  State<DrawerNav> createState() => _DrawerNavState();
}

class _DrawerNavState extends State<DrawerNav> {
  final int _expandedIndex = -1; // Keep for existing accordion if uncommented
  late List<ExpansibleController> _tileControllers; // Keep for existing accordion

  // Controller for the language ExpansionTile
  final ExpansibleController _languageController = ExpansibleController();
  // Controller for the new Content ExpansionTile
  final ExpansibleController _contentItemsController = ExpansibleController();

  final List<String> _languageItems = ['Español'/*, 'Français', 'Русский', '中文', 'العربية'*/];
  final List<String> _contentItems = ["Scatter plot", "Clustered column chart", "Area chart"];

  @override
  void initState() {
    super.initState();
    // Initialize a controller for each menu section to control expansion
    _tileControllers = List.generate(
        popoverConfigurations.length, (_) => ExpansibleController());
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    
    // Style for the Drawer Header
    TextStyle? baseTitleLargeStyle = textTheme.titleLarge;
    TextStyle headerTextStyle = baseTitleLargeStyle?.copyWith(
      color: Colors.white,
      fontFamily: 'ContrailOne',
    ) ??
        const TextStyle(
          color: Colors.white,
          fontFamily: 'ContrailOne',
          fontSize: 22,
        );

    // Common color and text style for drawer items
    final Color itemColor = isDarkTheme ? Colors.white : Colors.black;
    final TextStyle? baseItemTextStyle = textTheme.titleMedium;
    final TextStyle itemTextStyle = baseItemTextStyle?.copyWith(color: itemColor) ?? 
                                   TextStyle(color: itemColor, fontSize: 16, fontWeight: FontWeight.w500);
    final TextStyle subItemTextStyle = itemTextStyle.copyWith(fontWeight: FontWeight.normal);

    return Drawer(
      child: ListView(
        children: [
          // App name header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDarkTheme
                    ? [Colors.blue.shade900, Colors.blue.shade700]
                    : [Colors.lightBlue.shade900, Colors.cyanAccent.shade700],
              ),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Text("Economic skills", style: headerTextStyle),
          ),

          // Content button
          ListTile(
            leading: Icon(Icons.menu_book, color: itemColor),
            title: Text("Content", style: itemTextStyle),
            onTap: () {
              print('Content button tapped');
              Navigator.pop(context); // Close drawer
            },
          ),

          // Access button
          ListTile(
            leading: Icon(Icons.person, color: itemColor),
            title: Text("Access", style: itemTextStyle),
            onTap: () {
              print('Access button tapped');
              Navigator.pop(context); // Close drawer
            },
          ),

          // Language Popover
          ExpansionTile(
            controller: _languageController,
            leading: Icon(Icons.language_sharp, color: itemColor),
            title: Text('English', style: itemTextStyle),
            iconColor: itemColor,
            collapsedIconColor: itemColor,
            children: _languageItems.map((String item) {
              return ListTile(
                contentPadding: const EdgeInsets.only(left: 53.0),
                title: Text(item, style: subItemTextStyle),
                onTap: () {
                  print('Selected language: $item');
                  _languageController.collapse(); 
                  Navigator.pop(context); 
                },
              );
            }).toList(),
          ),

          // Theme toggle button at the very bottom
          Consumer(
            builder: (context, ref, _) {
              final themeModeVM = ref.watch(themeModeProvider);
              // itemColor is already defined above and matches the theme

              return Tooltip(
                message: 'Switch theme (dark / light)',
                child: ListTile(
                  onTap: themeModeVM.toggleThemeMode,
                  leading: Icon(
                    themeModeVM.themeMode == ThemeMode.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: itemColor,
                  ),
                  title: Text('Theme', style: itemTextStyle),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
