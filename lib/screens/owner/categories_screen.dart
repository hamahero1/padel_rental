import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../services/db_service.dart';
import '../../utils.dart';

/// Owner creates (and deletes empty) categories.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _nameController = TextEditingController();
  final _stream = DbService.categoriesStream();

  Future<void> _add(List<EquipmentCategory> existing) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showMsg('Enter a category name');
      return;
    }
    if (existing.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
      showMsg('This category already exists');
      return;
    }
    await DbService.addCategory(name);
    _nameController.clear();
    showMsg('Category "$name" added');
  }

  Future<void> _delete(EquipmentCategory c) async {
    // Don't leave equipment without a category
    final count = await DbService.countEquipmentInCategory(c.id);
    if (count > 0) {
      showMsg('Delete or move the $count item(s) in "${c.name}" first');
      return;
    }
    await DbService.deleteCategory(c.id);
    showMsg('Category deleted');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: StreamBuilder<List<EquipmentCategory>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data!;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                            labelText: 'New category (e.g. Padel Rackets)',
                            isDense: true),
                        onSubmitted: (_) => _add(categories),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => _add(categories),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: categories.isEmpty
                    ? const Center(child: Text('No categories yet'))
                    : ListView(
                        children: [
                          for (final c in categories)
                            ListTile(
                              leading: Icon(categoryIcon(c.name)),
                              title: Text(c.name),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _delete(c),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
