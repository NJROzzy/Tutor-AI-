import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart' show authService, ChildProfile;
import '../../services/child_store.dart' show childStore;

class SelectChildPage extends StatefulWidget {
  const SelectChildPage({super.key});

  @override
  State<SelectChildPage> createState() => _SelectChildPageState();
}

class _SelectChildPageState extends State<SelectChildPage> {
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChildren(); // pull from backend once when page opens
  }

  Future<void> _loadChildren() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1) get children from backend
      final apiKids = await authService.fetchChildren();

      // 2) store them in our global childStore
      childStore.setChildren(apiKids);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectChild(ChildProfile c) {
    childStore.select(c); // remember which kid is active
    context.go('/kid/subject'); // go to main app
  }

  @override
  Widget build(BuildContext context) {
    final kids = childStore.children;

    return Scaffold(
      appBar: AppBar(title: const Text('Who’s learning?')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadChildren,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : kids.isEmpty
                    ? Center(
                        child: Column(
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
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: GridView.builder(
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
                              // NOTE: uses gradeLevel from auth_service.ChildProfile
                              subtitle: '${c.gradeLevel} • ${c.age} yrs',
                              onTap: () => _selectChild(c),
                            );
                          },
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
  const _ChildTile({
    required this.name,
    required this.subtitle,
    required this.onTap,
  });

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
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 28),
              ),
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
