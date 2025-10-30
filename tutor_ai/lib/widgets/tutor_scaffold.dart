import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TutorScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const TutorScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    // Let AppBar decide when to show the back arrow.
    // It uses Navigator.canPop(context) under the hood.
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true, // default, but explicit for clarity
        title: Text(title),
        actions: actions,
      ),
      body: body,
    );
  }
}
