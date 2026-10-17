import 'package:flutter_test/flutter_test.dart';
import 'package:padel_rental/models/equipment.dart';
import 'package:padel_rental/services/search.dart';

Equipment item(String name, String category) => Equipment(
    name: name,
    description: '',
    categoryId: '',
    categoryName: category,
    price: 10,
    quantity: 1,
    barcode: '');

void main() {
  final all = [
    item('Head Delta Pro', 'Padel Rackets'),
    item('Bullpadel Vertex 04', 'Padel Rackets'),
    item('Wilson Padel Balls (3 pack)', 'Balls'),
    item('Asics Gel Padel Pro', 'Shoes'),
    item('Wristbands', 'Accessories'),
  ];
  List<String> names(String q) => searchEquipment(all, q).map((e) => e.name).toList();

  test('empty search shows everything', () => expect(names('').length, 5));
  test('plural and singular', () {
    expect(names('ball'), ['Wilson Padel Balls (3 pack)']);
    expect(names('racket').length, 2);
  });
  test('extra spoken words are ignored', () => expect(names('show me the rackets').length, 2));
  test('one wrong letter (speech mistake)', () => expect(names('rocket').length, 2));
  test('several words narrow the result', () => expect(names('head racket'), ['Head Delta Pro']));
  test('category accessories', () => expect(names('accessory'), ['Wristbands']));
}
