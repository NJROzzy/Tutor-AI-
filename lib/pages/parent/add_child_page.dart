import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/child_store.dart';

class AddChildPage extends StatefulWidget {
  const AddChildPage({super.key});
  @override
  State<AddChildPage> createState() => _AddChildPageState();
}

class _AddChildPageState extends State<AddChildPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  String _gender = 'Male';
  String _grade = 'K';

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final ageVal = int.tryParse(_age.text.trim()) ?? 0;
    final child = ChildProfile(
      name: _name.text.trim(),
      age: ageVal,
      gender: _gender,
      grade: _grade,
    );
    childStore.addChild(child);
    context.go('/parent/select-child');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Child')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                          labelText: 'Child’s name',
                          prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _age,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Age',
                          prefixIcon: Icon(Icons.cake_outlined)),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null || n <= 0 || n > 18)
                          return 'Enter a valid age';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                            value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                      decoration: const InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(Icons.wc_outlined)),
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
                          labelText: 'Grade level',
                          prefixIcon: Icon(Icons.school_outlined)),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                        onPressed: _submit, child: const Text('Save Child')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
