import 'package:flutter/foundation.dart';
import 'auth_service.dart' show ChildProfile;

/// Store for child profiles that the UI can read from.
class ChildStore extends ChangeNotifier {
  final List<ChildProfile> _children = [];
  ChildProfile? _selected;

  List<ChildProfile> get children => List.unmodifiable(_children);
  ChildProfile? get selected => _selected;

  /// Replace all children with a fresh list from the backend.
  void setChildren(List<ChildProfile> newChildren) {
    _children
      ..clear()
      ..addAll(newChildren);

    // Optional: auto-select the first child if any
    _selected = _children.isNotEmpty ? _children.first : null;

    notifyListeners();
  }

  /// Add a single child (e.g. after creating one).
  void addChild(ChildProfile c) {
    _children.add(c);
    notifyListeners();
  }

  /// Let the UI mark which child is active.
  void select(ChildProfile c) {
    _selected = c;
    notifyListeners();
  }

  /// Clear everything (e.g. on logout).
  void clear() {
    _children.clear();
    _selected = null;
    notifyListeners();
  }
}

/// Simple global instance for now.
final childStore = ChildStore();
