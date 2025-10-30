import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/tutor_scaffold.dart';

class ParentHomePage extends StatelessWidget {
  const ParentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return TutorScaffold(
      title: 'Parent Dashboard',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Today'),
              subtitle: const Text('Minutes: 10  •  Last score: 4/5'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/parent/progress'),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              title: Text('Plan (stub)'),
              subtitle: Text('Set goals and downtime'),
            ),
          ),
        ],
      ),
    );
  }
}
