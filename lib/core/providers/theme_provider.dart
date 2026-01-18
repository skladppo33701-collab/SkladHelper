import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

// Ensure 'S' and 'P' are capitalized.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
