import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/dish.dart';
import '../../models/restaurant.dart';

class DishService {
  final _db = FirebaseFirestore.instance;

  // Catálogo en tiempo real
  Stream<List<Dish>> streamDishes() {
    return _db.collection('foods')
      .orderBy('nombre') // opcional
      .snapshots()
      .map((qs) => qs.docs.map(Dish.fromFirestore).toList());
  }

  // Restaurantes por plato (si usas subcolección platos/{id}/restaurantes)
  Future<List<Restaurant>> fetchRestaurantsForDish(String dishId) async {
    final snap = await _db
      .collection('foods')
      .doc(dishId)
      .collection('restaurantes')
      .get();

    return snap.docs.map(Restaurant.fromFirestore).toList();
  }
}
