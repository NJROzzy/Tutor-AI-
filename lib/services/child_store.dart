import 'package:flutter/foundation.dart';

class ChildProfile {
  final String name;
  final int age;
  final String gender; // "Male" | "Female" | "Other"
  final String grade; // e.g., "K", "1", "2", ...

  const ChildProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.grade,
  });
}

class ChildStore extends ChangeNotifier {
  final List<ChildProfile> _children = [];
  ChildProfile? _selected;

  List<ChildProfile> get children => List.unmodifiable(_children);
  ChildProfile? get selected => _selected;

  void addChild(ChildProfile c) {
    _children.add(c);
    notifyListeners();
  }

  void select(ChildProfile c) {
    _selected = c;
    notifyListeners();
  }

  void clear() {
    _children.clear();
    _selected = null;
    notifyListeners();
  }
}

// Simple global for now (you can swap to Provider later)
final childStore = ChildStore();
