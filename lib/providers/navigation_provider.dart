import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationState {
  final int currentIndex;

  const NavigationState({required this.currentIndex});

  NavigationState copyWith({int? currentIndex}) {
    return NavigationState(currentIndex: currentIndex ?? this.currentIndex);
  }
}

class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(const NavigationState(currentIndex: 0));

  void setCurrentIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }
}

final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>(
      (ref) => NavigationNotifier(),
    );
