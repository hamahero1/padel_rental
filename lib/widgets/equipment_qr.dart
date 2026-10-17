import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/equipment.dart';

/// QR code of one piece of equipment. It holds the equipment's code,
/// so scanning it with "Search by barcode" opens this equipment.
class EquipmentQr extends StatelessWidget {
  final Equipment equipment;
  final double size;
  const EquipmentQr({super.key, required this.equipment, this.size = 180});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // White background so the camera can read it in dark mode too
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(8),
          child: QrImageView(data: equipment.barcode, size: size),
        ),
        const SizedBox(height: 4),
        Text(equipment.barcode, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

/// Big QR code in a dialog, easy to show to a camera.
void showQrDialog(BuildContext context, Equipment equipment) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(equipment.name, textAlign: TextAlign.center),
      content: EquipmentQr(equipment: equipment, size: 240),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    ),
  );
}
