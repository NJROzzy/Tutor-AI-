import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart' show authService, ChildProfile;

class ParentProfilesPage extends StatefulWidget {
  const ParentProfilesPage({super.key});

  @override
  State<ParentProfilesPage> createState() => _ParentProfilesPageState();
}

class _ParentProfilesPageState extends State<ParentProfilesPage> {
  bool _loading = true;
  String? _error;
  List<ChildProfile> _children = [];

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await authService.fetchChildren(); // from AuthService
      setState(() => _children = items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openAddChildSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddChildSheet(),
    );

    if (result == null) return;

    try {
      // NOTE: AuthService.createChild expects `grade`, not `gradeLevel`
      final created = await authService.createChild(
        name: result['name'] as String,
        age: result['age'] as int,
        gender: result['gender'] as String,
        grade: result['grade'] as String,
      );
      setState(() => _children = [..._children, created]);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Child profile added')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add: $e')),
      );
    }
  }

  void _selectChild(ChildProfile c) {
    // remember which child is active
    authService.selectChild(c);

    // Go to subject selection (math / english)
    context.go('/kid/subject');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Who's learning?")),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadChildren,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadChildren,
                    child: _children.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              const Icon(Icons.child_care, size: 64),
                              const SizedBox(height: 16),
                              const Center(
                                child: Text(
                                  'No profiles yet',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: FilledButton.icon(
                                  onPressed: _openAddChildSheet,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Child Profile'),
                                ),
                              ),
                            ],
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: GridView.builder(
                              itemCount: _children.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.9,
                              ),
                              itemBuilder: (_, i) {
                                final c = _children[i];
                                return _ChildTile(
                                  name: c.name,
                                  // ChildProfile from auth_service has `gradeLevel`
                                  subtitle: '${c.gradeLevel} • ${c.age} yrs',
                                  onTap: () => _selectChild(c),
                                );
                              },
                            ),
                          ),
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddChildSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
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

class _AddChildSheet extends StatefulWidget {
  const _AddChildSheet();

  @override
  State<_AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends State<_AddChildSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  String _gender = 'Male';
  String _grade = 'K';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    // Return the form data to the parent page
    Navigator.of(context).pop({
      'name': _name.text.trim(),
      'age': int.tryParse(_age.text.trim()) ?? 0,
      'gender': _gender,
      'grade': _grade, // <-- key is `grade` (matches _openAddChildSheet)
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Text(
              'Add Child',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Child’s name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _age,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
                prefixIcon: Icon(Icons.cake_outlined),
              ),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n <= 0 || n > 18) return 'Enter a valid age';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _gender = v ?? 'Male'),
              decoration: const InputDecoration(
                labelText: 'Gender',
                prefixIcon: Icon(Icons.wc_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _grade,
              items: const [
                DropdownMenuItem(value: 'Pre-K', child: Text('Pre-K')),
                DropdownMenuItem(value: 'K', child: Text('K')),
                DropdownMenuItem(value: '1', child: Text('Grade 1')),
                DropdownMenuItem(value: '2', child: Text('Grade 2')),
                DropdownMenuItem(value: '3', child: Text('Grade 3')),
                DropdownMenuItem(value: '4', child: Text('Grade 4')),
                DropdownMenuItem(value: '5', child: Text('Grade 5')),
                DropdownMenuItem(value: '6', child: Text('Grade 6')),
                DropdownMenuItem(value: '7', child: Text('Grade 7')),
                DropdownMenuItem(value: '8', child: Text('Grade 8')),
              ],
              onChanged: (v) => setState(() => _grade = v ?? 'K'),
              decoration: const InputDecoration(
                labelText: 'Grade',
                prefixIcon: Icon(Icons.school_outlined),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
