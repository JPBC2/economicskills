import 'package:flutter/material.dart';
import 'package:economicskills/main.dart'; // Assuming routerDelegate is here

class PopoverContentItems extends StatelessWidget {
  final String baseLabel; // e.g., "Introducción", "Vocales"
  final List<String> itemPlaceholders;
  final Color? textColor;

  const PopoverContentItems({
    super.key,
    required this.baseLabel,
    required this.itemPlaceholders,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Important for Column in Popover
        crossAxisAlignment: CrossAxisAlignment.start,
        children: itemPlaceholders.map((placeholderText) {
          // You'll want to generate unique paths for each item
          // For now, using a generic path based on placeholderText
          final path = '/${baseLabel.toLowerCase().replaceAll(' ', '-')}/${placeholderText.toLowerCase().replaceAll(' ', '-')}';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: SizedBox( // Ensures TextButtons take appropriate width
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft, // Align text to the left
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close the popover
                  routerDelegate.go(path); // Navigate to the generated path
                  // You'll need to define these routes in your router
                },
                child: Text(
                    placeholderText,
                    style: TextStyle(color: textColor ?? Colors.black),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
