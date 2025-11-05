import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/tutor_scaffold.dart';

class RewardPage extends StatelessWidget {
  final int score;
  final int total;
  const RewardPage({super.key, required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    return TutorScaffold(
      title: 'Rewards',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉 Great job!',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('You scored $score / $total',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: () => context.push('/child'),
                  child: const Text('Back to Kid Home')),
            ],
          ),
        ),
      ),
    );
  }
}
