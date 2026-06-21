const kProductUnits = ['pcs', 'kg', 'g', 'L', 'mL', 'm', 'ft', 'box', 'dozen', 'pair'];

class Product {
  final String id;
  final String name;
  final double price;
  final double buyingPrice;
  final double taxPercent;
  final String category;
  final String emoji;
  final String sku;
  final int stock;
  final String description;
  final String unit;
  final String barcodeNo;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.buyingPrice = 0.0,
    this.taxPercent = 0.0,
    required this.category,
    required this.emoji,
    required this.sku,
    required this.stock,
    this.description = '',
    this.unit = 'pcs',
    this.barcodeNo = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'price': price,
    'buying_price': buyingPrice,
    'tax_percent': taxPercent,
    'category': category,
    'emoji': emoji,
    'sku': sku,
    'stock': stock,
    'description': description,
    'unit': unit,
    'barcode_no': barcodeNo,
    'synced': 0,
  };

  static Product fromMap(Map<String, dynamic> m) => Product(
    id: m['id'] as String,
    name: m['name'] as String,
    price: (m['price'] as num).toDouble(),
    buyingPrice: (m['buying_price'] as num?)?.toDouble() ?? 0.0,
    taxPercent: (m['tax_percent'] as num?)?.toDouble() ?? 0.0,
    category: m['category'] as String,
    emoji: m['emoji'] as String,
    sku: m['sku'] as String,
    stock: m['stock'] as int,
    description: (m['description'] as String?) ?? '',
    unit: (m['unit'] as String?) ?? 'pcs',
    barcodeNo: (m['barcode_no'] as String?) ?? '',
  );

  Product copyWith({int? stock, String? barcodeNo}) => Product(
    id: id, name: name, price: price, buyingPrice: buyingPrice,
    taxPercent: taxPercent, category: category,
    emoji: emoji, sku: sku, stock: stock ?? this.stock,
    description: description, unit: unit,
    barcodeNo: barcodeNo ?? this.barcodeNo,
  );
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}
