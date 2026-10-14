import 'package:flutter/foundation.dart';

import '../models/equipment.dart';

class CartItem {
  final Equipment equipment;
  int quantity;

  CartItem(this.equipment, this.quantity);

  double get subtotal => equipment.price * quantity;
}

/// The rental cart. It is a ChangeNotifier, so any screen wrapped in
/// ListenableBuilder(listenable: cart, ...) rebuilds when the cart changes.
class Cart extends ChangeNotifier {
  final List<CartItem> items = [];

  /// How many days the player wants to rent for.
  int days = 1;

  int get count => items.fold(0, (sum, i) => sum + i.quantity);

  /// Total = (price per day x quantity for every item) x number of days
  double get perDay => items.fold(0, (sum, i) => sum + i.subtotal);
  double get total => perDay * days;

  /// Adds equipment. If it's already in the cart, increases its quantity
  /// (but never more than what is available).
  void add(Equipment e, int quantity) {
    final index = items.indexWhere((i) => i.equipment.id == e.id);
    if (index == -1) {
      items.add(CartItem(e, quantity.clamp(1, e.quantity)));
    } else {
      final item = items[index];
      item.quantity = (item.quantity + quantity).clamp(1, e.quantity);
    }
    notifyListeners();
  }

  void setQuantity(CartItem item, int quantity) {
    if (quantity <= 0) {
      items.remove(item);
    } else {
      item.quantity = quantity.clamp(1, item.equipment.quantity);
    }
    notifyListeners();
  }

  void remove(CartItem item) {
    items.remove(item);
    notifyListeners();
  }

  void setDays(int value) {
    days = value.clamp(1, 30);
    notifyListeners();
  }

  void clear() {
    items.clear();
    days = 1;
    notifyListeners();
  }
}

/// One cart for the whole app.
final cart = Cart();
