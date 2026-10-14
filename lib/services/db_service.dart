import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/app_user.dart';
import '../models/category.dart';
import '../models/equipment.dart';
import '../models/rental.dart';
import 'cart.dart';

/// All Firestore reads and writes for categories, equipment and rentals.
class DbService {
  static final _db = FirebaseFirestore.instance;
  static final _categories = _db.collection('categories');
  static final _equipment = _db.collection('equipment');
  static final _rentals = _db.collection('rentals');

  /// Date as 'yyyy-MM-dd' text, used by the transaction report.
  static String dayKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  // ---------------- Categories ----------------

  static Stream<List<EquipmentCategory>> categoriesStream() {
    return _categories.snapshots().map((snap) {
      final list = snap.docs.map(EquipmentCategory.fromDoc).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  static Future<void> addCategory(String name) {
    return _categories.add({'name': name});
  }

  static Future<void> deleteCategory(String id) {
    return _categories.doc(id).delete();
  }

  // ---------------- Equipment ----------------

  /// All equipment, or only one category if categoryId is given.
  static Stream<List<Equipment>> equipmentStream({String? categoryId}) {
    Query<Map<String, dynamic>> query = _equipment;
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    return query.snapshots().map((snap) {
      final list = snap.docs.map(Equipment.fromDoc).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  static Future<void> addEquipment(Equipment e) => _equipment.add(e.toMap());

  static Future<void> updateEquipment(Equipment e) =>
      _equipment.doc(e.id).update(e.toMap());

  static Future<void> deleteEquipment(String id) => _equipment.doc(id).delete();

  static Future<Equipment?> findByBarcode(String code) async {
    final snap =
        await _equipment.where('barcode', isEqualTo: code).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return Equipment.fromDoc(snap.docs.first);
  }

  static Future<int> countEquipmentInCategory(String categoryId) async {
    final snap =
        await _equipment.where('categoryId', isEqualTo: categoryId).get();
    return snap.docs.length;
  }

  // ---------------- Rentals ----------------

  /// Saves the cart as a rental and lowers the available quantity.
  /// A Firestore transaction is used so two players can't rent
  /// the last piece of equipment at the same time.
  static Future<void> submitRental(AppUser user, Cart cart) async {
    await _db.runTransaction((tx) async {
      // 1) Read all equipment first and check there is enough
      final docs = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final item in cart.items) {
        final doc = await tx.get(_equipment.doc(item.equipment.id));
        if (!doc.exists) {
          throw Exception('${item.equipment.name} was removed by the owner.');
        }
        final available = (doc.data()!['quantity'] ?? 0).toInt();
        if (available < item.quantity) {
          throw Exception(
              'Only $available of ${item.equipment.name} available now.');
        }
        docs[item.equipment.id] = doc;
      }

      // 2) Then write: lower the quantities and save the rental
      for (final item in cart.items) {
        final available = (docs[item.equipment.id]!.data()!['quantity']).toInt();
        tx.update(_equipment.doc(item.equipment.id),
            {'quantity': available - item.quantity});
      }
      final now = DateTime.now();
      tx.set(_rentals.doc(), {
        'userId': user.uid,
        'userName': user.name,
        'items': cart.items
            .map((i) => RentalItem(
                  equipmentId: i.equipment.id,
                  name: i.equipment.name,
                  price: i.equipment.price,
                  quantity: i.quantity,
                ).toMap())
            .toList(),
        'days': cart.days,
        'total': cart.total,
        'status': 'rented',
        'rentDate': Timestamp.fromDate(now),
        'rentDay': dayKey(now),
        'returnDate': null,
        'returnDay': null,
      });
    });
  }

  /// Owner marks a rental as returned: quantities go back up.
  static Future<void> markReturned(Rental rental) async {
    await _db.runTransaction((tx) async {
      final refs = rental.items.map((i) => _equipment.doc(i.equipmentId));
      final docs = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final ref in refs) {
        docs.add(await tx.get(ref));
      }
      for (var i = 0; i < docs.length; i++) {
        // Skip equipment that the owner deleted meanwhile
        if (!docs[i].exists) continue;
        final current = (docs[i].data()!['quantity'] ?? 0).toInt();
        tx.update(docs[i].reference,
            {'quantity': current + rental.items[i].quantity});
      }
      final now = DateTime.now();
      tx.update(_rentals.doc(rental.id), {
        'status': 'returned',
        'returnDate': Timestamp.fromDate(now),
        'returnDay': dayKey(now),
      });
    });
  }

  static List<Rental> _sortedNewestFirst(QuerySnapshot<Map<String, dynamic>> s) {
    final list = s.docs.map(Rental.fromDoc).toList();
    list.sort((a, b) => (b.rentDate ?? DateTime(0)).compareTo(a.rentDate ?? DateTime(0)));
    return list;
  }

  static Stream<List<Rental>> myRentalsStream(String uid) {
    return _rentals
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map(_sortedNewestFirst);
  }

  static Stream<List<Rental>> activeRentalsStream() {
    return _rentals
        .where('status', isEqualTo: 'rented')
        .snapshots()
        .map(_sortedNewestFirst);
  }

  /// For the report: rentals made on [day] and rentals returned on [day].
  static Future<(List<Rental>, List<Rental>)> report(DateTime day) async {
    final key = dayKey(day);
    final rented = await _rentals.where('rentDay', isEqualTo: key).get();
    final returned = await _rentals.where('returnDay', isEqualTo: key).get();
    return (_sortedNewestFirst(rented), _sortedNewestFirst(returned));
  }
}
