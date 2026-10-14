import 'package:flutter_test/flutter_test.dart';
import 'package:padel_rental/models/equipment.dart';
import 'package:padel_rental/services/cart.dart';

Equipment item(String id, double price, int quantity) => Equipment(
      id: id,
      name: 'Item $id',
      description: '',
      categoryId: 'c',
      categoryName: 'Rackets',
      price: price,
      quantity: quantity,
      barcode: '',
    );

void main() {
  test('total = sum of (price x quantity) x days', () {
    final cart = Cart();
    cart.add(item('a', 50, 5), 2); // 100 per day
    cart.add(item('b', 10, 5), 3); // 30 per day
    cart.setDays(3);
    expect(cart.perDay, 130);
    expect(cart.total, 390);
    expect(cart.count, 5);
  });

  test('quantity cannot go above available stock', () {
    final cart = Cart();
    final racket = item('a', 50, 2);
    cart.add(racket, 1);
    cart.add(racket, 5); // same item again -> merged and capped at 2
    expect(cart.items.length, 1);
    expect(cart.items.first.quantity, 2);
  });

  test('setting quantity to 0 removes the item', () {
    final cart = Cart();
    cart.add(item('a', 50, 2), 1);
    cart.setQuantity(cart.items.first, 0);
    expect(cart.items, isEmpty);
  });
}
