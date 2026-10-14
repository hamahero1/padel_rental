import 'package:cloud_firestore/cloud_firestore.dart';

/// A product category, e.g. "Padel Rackets" or "Balls".
/// (Named EquipmentCategory because Flutter already has a class called Category.)
class EquipmentCategory {
  final String id;
  final String name;

  EquipmentCategory({required this.id, required this.name});

  factory EquipmentCategory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return EquipmentCategory(id: doc.id, name: doc.data()?['name'] ?? '');
  }
}
