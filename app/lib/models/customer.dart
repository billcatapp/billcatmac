class Customer {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final double creditBalance;
  final DateTime createdAt;
  final bool synced;

  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.creditBalance = 0,
    required this.createdAt,
    this.synced = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone ?? '',
    'address': address ?? '',
    'credit_balance': creditBalance,
    'created_at': createdAt.toIso8601String(),
    'synced': synced ? 1 : 0,
  };

  static Customer fromMap(Map<String, dynamic> m) => Customer(
    id: m['id'] as String,
    name: m['name'] as String,
    phone: (m['phone'] as String?)?.isEmpty == true ? null : m['phone'] as String?,
    address: (m['address'] as String?)?.isEmpty == true ? null : m['address'] as String?,
    creditBalance: (m['credit_balance'] as num?)?.toDouble() ?? 0,
    createdAt: DateTime.parse(m['created_at'] as String),
    synced: (m['synced'] as int) == 1,
  );
}
