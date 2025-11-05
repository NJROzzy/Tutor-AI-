import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ParentOnboardingPage extends StatelessWidget {
  const ParentOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Welcome, Parent 👋',
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  const Text(
                      'Add your child’s profile to get personalized lessons.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: () => context.go('/parent/add-child'),
                    child: const Text('Add Child Profile'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
