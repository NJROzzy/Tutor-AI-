// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutor AI Home')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Choose a mode:', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: () => context.go('/child'),
                  child: const Text('Child Page')),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: () => context.push('/parent'),
                  child: const Text('Parent Page')),
            ],
          ),
        ),
      ),
    );
  }
}
