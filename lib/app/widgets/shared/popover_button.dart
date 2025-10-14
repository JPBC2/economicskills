import 'package:flutter/material.dart';
import 'package:popover/popover.dart';
import 'popover_content_items.dart'; // Import the content widget

class ReusablePopoverButton extends StatelessWidget {
  final String label;
  final List<String> popoverItemsPlaceholders;
  final Color? textColor; // Optional: for theming in TopNav vs Drawer
  final Color? backgroundColor;
  final bool isForDrawer; // To adjust styling if needed

  const ReusablePopoverButton({
    super.key,
    required this.label,
    required this.popoverItemsPlaceholders,
    this.textColor,
    this.backgroundColor,
    this.isForDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    // The Builder is crucial for providing the correct context to showPopover
    return Builder(
      builder: (BuildContext builderContext) {
        if (isForDrawer) {
          // For Drawer, we'll wrap with ListTile for consistent styling
          return ListTile(
            title: Text(label, style: TextStyle(color: textColor)),
            trailing: const Icon(Icons.arrow_drop_down, size: 24), // Indicate popover
            onTap: () {
              _showPopover(builderContext);
            },
          );
        } else {
          // For TopNav (AppBar actions)
          return TextButton(
            style: TextButton.styleFrom(foregroundColor: textColor),
            onPressed: () {
              _showPopover(builderContext);
            },
            child: Row( // Add dropdown icon for visual cue
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 18, color: textColor),
              ],
            ),
          );
        }
      },
    );
  }

  void _showPopover(BuildContext context) {
    showPopover(
      context: context,
      bodyBuilder: (BuildContext popoverContext) => Container(
        color: backgroundColor ?? Colors.white,
        child: PopoverContentItems(
          baseLabel: label,
          itemPlaceholders: popoverItemsPlaceholders,
          textColor: textColor ?? Colors.black,
        ),
      ),
      direction: PopoverDirection.bottom,
      width: 220, // Adjust as needed
      arrowHeight: 9,
      arrowWidth: 18,
      backgroundColor: backgroundColor ?? Colors.white,
      // You can add more popover configurations here if needed
      // e.g., backgroundColor, barrierColor etc.
    );
  }
}
