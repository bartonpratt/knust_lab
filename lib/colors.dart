import 'package:flutter/material.dart';

// Define your custom primary color
const Color customPrimaryColor = Color.fromARGB(255, 28, 80, 193);
// Create a MaterialColor swatch based on the custom primary color
MaterialColor createCustomPrimarySwatch(Color color) {
  List<int> strengths = <int>[50, 100, 200, 300, 400, 500, 600, 700, 800, 900];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int strength in strengths) {
    final double opacity = strength / 1000;
    swatch[strength] = Color.fromRGBO(r, g, b, opacity);
  }

  return MaterialColor(color.value, swatch);
}

// Create the custom primary swatch using the custom color
final MaterialColor customPrimarySwatch =
    createCustomPrimarySwatch(customPrimaryColor);

// You can define more colors here if needed
const Color customBackgroundColor = Colors.white; // Example
const Color customTextColor = Colors.black; // Example
