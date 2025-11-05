import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/tutor_scaffold.dart';

class MathModulesPage extends StatelessWidget {
  const MathModulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = const ['counting', 'addition'];
    return TutorScaffold(
      title: 'Math Modules',
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, i) => ListTile(
          title: Text(modules[i].toUpperCase()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () =>
              context.push('/child/lesson?subject=math&module=${modules[i]}'),
        ),
        separatorBuilder: (_, __) => const Divider(),
        itemCount: modules.length,
      ),
    );
  }
}
