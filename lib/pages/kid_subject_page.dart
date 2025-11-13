import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class KidSubjectPage extends StatelessWidget {
  const KidSubjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final child = authService.selectedChild;

    if (child == null) {
      // Safety fallback
      return Scaffold(
        appBar: AppBar(title: const Text('Choose subject')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No child selected.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go('/parent/profiles'),
                child: const Text('Back to child profiles'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Hi, ${child.name} 👋"),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "What do you want to learn today?",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  _SubjectCard(
                    title: 'Math',
                    description: 'Practice numbers, shapes and sums.',
                    emoji: '➕',
                    onTap: () => context.go('/kid/chat/math'),
                  ),
                  const SizedBox(height: 16),
                  _SubjectCard(
                    title: 'English',
                    description: 'Practice reading, words and stories.',
                    emoji: '📚',
                    onTap: () => context.go('/kid/chat/english'),
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

class _SubjectCard extends StatelessWidget {
  final String title;
  final String description;
  final String emoji;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.title,
    required this.description,
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
