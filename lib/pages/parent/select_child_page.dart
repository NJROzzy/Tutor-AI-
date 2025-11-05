import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/child_store.dart';

class SelectChildPage extends StatelessWidget {
  const SelectChildPage({super.key});

  @override
  Widget build(BuildContext context) {
    final kids = childStore.children;

    return Scaffold(
      appBar: AppBar(title: const Text('Who’s learning?')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: kids.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No profiles yet',
                            style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => context.go('/parent/add-child'),
                          child: const Text('Add Child Profile'),
                        ),
                      ],
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: kids.length,
                      itemBuilder: (_, i) {
                        final c = kids[i];
                        return _ChildTile(
                          name: c.name,
                          subtitle: '${c.grade} • ${c.age} yrs',
                          onTap: () {
                            childStore.select(c);
                            context.go('/home'); // go to app home
                          },
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/parent/add-child'),
        label: const Text('Add'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _ChildTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback onTap;
  const _ChildTile(
      {required this.name, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 38,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
