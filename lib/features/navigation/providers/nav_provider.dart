import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavState {
  final int selectedIndex;
  final bool isExpanded;

  NavState({
    this.selectedIndex = 0,
    this.isExpanded = true, // Starts expanded so the user knows it's there
  });

  NavState copyWith({int? selectedIndex, bool? isExpanded}) {
    return NavState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

class NavNotifier extends Notifier<NavState> {
  @override
  NavState build() {
    return NavState();
  }

  void setIndex(int index) {
    // When a user selects a page, change the index AND minimize the bar
    state = state.copyWith(selectedIndex: index, isExpanded: false);
  }

  void toggleExpanded() {
    // Open or close the nav bar
    state = state.copyWith(isExpanded: !state.isExpanded);
  }
}

final navProvider = NotifierProvider<NavNotifier, NavState>(NavNotifier.new);