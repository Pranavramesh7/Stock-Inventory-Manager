import 'package:cloud_firestore/cloud_firestore.dart';
class StockItem {
  final String id;
  final String sku;
  final String itemName;
  final String category;
  final int quantity;
  final double unitPrice;
  final int reorderLevel;

  StockItem({
    required this.id,
    required this.sku,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.unitPrice,
    required this.reorderLevel,
  });

  factory StockItem.fromMap(String id, Map<String, dynamic> data) {
    return StockItem(
      id: id,
      sku: data['sku'] as String,
      itemName: data['itemName'] as String,
      category: data['category'] as String,
      quantity: (data['quantity'] as num).toInt(),
      unitPrice: (data['unitPrice'] as num).toDouble(),
      reorderLevel: (data['reorderLevel'] as num).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sku': sku,
      'itemName': itemName.trim(),
      'category': category,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'reorderLevel': reorderLevel,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}