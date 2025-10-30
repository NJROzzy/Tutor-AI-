import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/tutor_scaffold.dart';

class EnglishModulesPage extends StatelessWidget {
  const EnglishModulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = const ['letters', 'sight_words'];
    return TutorScaffold(
      title: 'English Modules',
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, i) => ListTile(
          title: Text(modules[i].toUpperCase().replaceAll('_', ' ')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context
              .push('/child/lesson?subject=english&module=${modules[i]}'),
        ),
        separatorBuilder: (_, __) => const Divider(),
        itemCount: modules.length,
      ),
    );
  }
}
