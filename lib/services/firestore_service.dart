import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventory_app/models/item.dart';

class FirestoreService {
  final firestore = FirebaseFirestore.instance;
  final String collection = 'items';

  Future<void> addItem(Item item) async {
    try {
      await firestore.collection(collection).add(item.toMap());
    } catch (e) {
      print("Failed to add item: $e");
    }
  }

  Stream<List<Item>> getItems() {
    return firestore.collection(collection).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Item.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> updateItem(String itemId, Item item) async {
    try {
      await firestore.collection(collection).doc(itemId).update(item.toMap());
    } catch (e) {
      print("Failed to update item: $e");
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await firestore.collection(collection).doc(itemId).delete();
    } catch (e) {
      print("Failed to delete item: $e");
    }
  }
}