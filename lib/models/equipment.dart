import 'package:cloud_firestore/cloud_firestore.dart';

/// One piece of equipment in the "equipment" collection.
/// price is the rental price per day, quantity is how many are available now.
class Equipment {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String categoryName;
  final double price;
  final int quantity;
  final String barcode;

  Equipment({
    this.id = '',
    required this.name,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.price,
    required this.quantity,
    required this.barcode,
  });

  factory Equipment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Equipment(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: (data['quantity'] ?? 0).toInt(),
      barcode: data['barcode'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'price': price,
        'quantity': quantity,
        'barcode': barcode,
      };
}
