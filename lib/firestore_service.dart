import 'package:cloud_firestore/cloud_firestore.dart';
import 'stock_item.dart';

class FirestoreService {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('stockItems');

  Future<void> addStock(StockItem item) async {
    await _collection.add(item.toMap());
  }

  Stream<List<StockItem>> getStockItems() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return StockItem.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}