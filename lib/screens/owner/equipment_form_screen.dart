import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../models/equipment.dart';
import '../../services/db_service.dart';
import '../../utils.dart';
import '../scanner_screen.dart';

/// Add new equipment (equipment == null) or edit existing equipment.
/// The owner sets the category, rental price and available quantity here.
class EquipmentFormScreen extends StatefulWidget {
  final Equipment? equipment;
  const EquipmentFormScreen({super.key, this.equipment});

  @override
  State<EquipmentFormScreen> createState() => _EquipmentFormScreenState();
}

class _EquipmentFormScreenState extends State<EquipmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.equipment?.name);
  late final _description =
      TextEditingController(text: widget.equipment?.description);
  late final _price =
      TextEditingController(text: widget.equipment?.price.toString());
  late final _quantity =
      TextEditingController(text: widget.equipment?.quantity.toString());
  late final _barcode = TextEditingController(text: widget.equipment?.barcode);
  late String? _categoryId = widget.equipment?.categoryId;
  final _categoriesStream = DbService.categoriesStream();
  bool _saving = false;

  bool get _isEdit => widget.equipment != null;

  Future<void> _scanBarcode() async {
    final code = await Navigator.push<String>(
        context, MaterialPageRoute(builder: (_) => const ScannerScreen()));
    if (code != null) setState(() => _barcode.text = code);
  }

  Future<void> _save(List<EquipmentCategory> categories) async {
    if (!_formKey.currentState!.validate()) return;
    final category = categories.firstWhere((c) => c.id == _categoryId);
    final e = Equipment(
      id: widget.equipment?.id ?? '',
      name: _name.text.trim(),
      description: _description.text.trim(),
      categoryId: category.id,
      categoryName: category.name,
      price: double.parse(_price.text.trim()),
      quantity: int.parse(_quantity.text.trim()),
      // Every equipment gets a code for its QR code. If the owner left it
      // empty, make a unique one from the current time.
      barcode: _barcode.text.trim().isEmpty
          ? 'P${DateTime.now().millisecondsSinceEpoch}'
          : _barcode.text.trim(),
    );
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await DbService.updateEquipment(e);
      } else {
        await DbService.addEquipment(e);
      }
      showMsg(_isEdit ? 'Equipment updated' : 'Equipment added');
      if (mounted) Navigator.pop(context);
    } catch (err) {
      showMsg('Error: $err');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit equipment' : 'Add equipment')),
      body: StreamBuilder<List<EquipmentCategory>>(
        stream: _categoriesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data!;
          if (categories.isEmpty) {
            return const Center(
                child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Create a category first (Owner home > Categories).',
                  textAlign: TextAlign.center),
            ));
          }
          // If the saved category was deleted, ask to choose again
          if (!categories.any((c) => c.id == _categoryId)) _categoryId = null;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final c in categories)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                  validator: (v) => v == null ? 'Choose a category' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Description (optional)'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Price per day', suffixText: 'EGP'),
                        validator: (v) {
                          final n = double.tryParse(v?.trim() ?? '');
                          return n == null || n < 0 ? 'Enter a price' : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _quantity,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Available quantity'),
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          return n == null || n < 0 ? 'Enter a number' : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _barcode,
                  decoration: InputDecoration(
                    labelText: 'QR / barcode code',
                    helperText: 'Leave empty to create one automatically',
                    suffixIcon: IconButton(
                      tooltip: 'Scan with camera',
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: _scanBarcode,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : () => _save(categories),
                  child: Text(_isEdit ? 'Save changes' : 'Add equipment'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
