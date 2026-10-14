import 'package:cloud_firestore/cloud_firestore.dart';

/// One item inside a rental, e.g. 2 x "Bullpadel Vertex" at 50 per day.
class RentalItem {
  final String equipmentId;
  final String name;
  final double price;
  final int quantity;

  RentalItem({
    required this.equipmentId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory RentalItem.fromMap(Map<String, dynamic> map) => RentalItem(
        equipmentId: map['equipmentId'] ?? '',
        name: map['name'] ?? '',
        price: (map['price'] ?? 0).toDouble(),
        quantity: (map['quantity'] ?? 0).toInt(),
      );

  Map<String, dynamic> toMap() => {
        'equipmentId': equipmentId,
        'name': name,
        'price': price,
        'quantity': quantity,
      };
}

/// A rental transaction in the "rentals" collection.
/// status is 'rented' until the owner marks it 'returned'.
/// rentDay / returnDay are saved as 'yyyy-MM-dd' text so the
/// report can find all transactions of a specific date easily.
class Rental {
  final String id;
  final String userId;
  final String userName;
  final List<RentalItem> items;
  final int days;
  final double total;
  final String status;
  final DateTime? rentDate;
  final DateTime? returnDate;

  Rental({
    required this.id,
    required this.userId,
    required this.userName,
    required this.items,
    required this.days,
    required this.total,
    required this.status,
    this.rentDate,
    this.returnDate,
  });

  bool get isReturned => status == 'returned';

  factory Rental.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Rental(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      items: ((data['items'] ?? []) as List)
          .map((e) => RentalItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      days: (data['days'] ?? 1).toInt(),
      total: (data['total'] ?? 0).toDouble(),
      status: data['status'] ?? 'rented',
      rentDate: (data['rentDate'] as Timestamp?)?.toDate(),
      returnDate: (data['returnDate'] as Timestamp?)?.toDate(),
    );
  }
}
