import 'package:flutter/material.dart';

import '../../models/equipment.dart';
import '../../services/db_service.dart';
import '../../widgets/equipment_qr.dart';

/// All equipment QR codes on one page, so the owner can show or print
/// them. Tap one to see it bigger.
class QrCodesScreen extends StatelessWidget {
  const QrCodesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR codes')),
      body: StreamBuilder<List<Equipment>>(
        stream: DbService.equipmentStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!.where((e) => e.barcode.isNotEmpty).toList();
          if (items.isEmpty) {
            return const Center(child: Text('No equipment with a code yet'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 0.75),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final e = items[index];
              return Card(
                child: InkWell(
                  onTap: () => showQrDialog(context, e),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Expanded(
                          child: FittedBox(child: EquipmentQr(equipment: e)),
                        ),
                        const SizedBox(height: 4),
                        Text(e.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
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
