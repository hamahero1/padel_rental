import 'package:flutter/material.dart';

import '../../models/equipment.dart';
import '../../services/db_service.dart';
import '../../utils.dart';
import 'equipment_form_screen.dart';

/// Owner's list of all equipment with add / edit / delete.
class EquipmentListScreen extends StatelessWidget {
  const EquipmentListScreen({super.key});

  void _openForm(BuildContext context, [Equipment? e]) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => EquipmentFormScreen(equipment: e)));
  }

  Future<void> _confirmDelete(BuildContext context, Equipment e) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete equipment?'),
        content: Text('"${e.name}" will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true) {
      await DbService.deleteEquipment(e.id);
      showMsg('${e.name} deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equipment')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        onPressed: () => _openForm(context),
      ),
      body: StreamBuilder<List<Equipment>>(
        stream: DbService.equipmentStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(
                child: Text('No equipment yet. Tap "Add" to create one.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final e = items[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading:
                      CircleAvatar(child: Icon(categoryIcon(e.categoryName))),
                  title: Text(e.name),
                  subtitle: Text(
                      '${e.categoryName}\n${money(e.price)} / day  •  Qty: ${e.quantity}'),
                  isThreeLine: true,
                  onTap: () => _openForm(context, e),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context, e),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
