import 'package:flutter_riverpod/flutter_riverpod.dart';

// In Riverpod 3.0, NotifierProvider is the stable replacement for StateProvider
final navigationIndexProvider = NotifierProvider<NavigationNotifier, int>(
  NavigationNotifier.new,
);

class NavigationNotifier extends Notifier<int> {
  @override
  int build() {
    return 0; // Initial page index (Storage)
  }

  void setIndex(int index) {
    state = index;
  }
}
