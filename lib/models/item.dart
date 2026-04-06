class Item {
  final String? id;
  final String name;
  final int quantity;
  final double price;
  final String? description;

  Item({
    this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'description': description,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map, String docId) {
    return Item(
      id: docId,
      name: map['name'],
      quantity: map['quantity'],
      price: (map['price'] as num).toDouble(),
      description: map['description']
    );
  }
}