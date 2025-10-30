import 'package:flutter/material.dart';
import '../../widgets/tutor_scaffold.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TutorScaffold(
      title: 'Progress (wireframe)',
      body: const Center(
        child: Text('Math: ⭐⭐⭐⭐☆   •   English: ⭐⭐⭐☆☆'),
      ),
    );
  }
}
