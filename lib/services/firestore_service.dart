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

  Future<void> restoreItem(Item item) async {
    try {
      // Re-adds the item with its original ID if undo is clicked
      if (item.id != null) {
        await firestore.collection(collection).doc(item.id).set(item.toMap());
      }
    } catch (e) {
      print("Failed to restore item: $e");
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