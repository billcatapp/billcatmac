class Dealer {
  final String id;
  final String name;
  final String? phone;
  final String? company;
  final double totalPurchased;
  final double balancePayable; // amount you still owe this dealer
  final DateTime createdAt;
  final bool synced;

  const Dealer({
    required this.id,
    required this.name,
    this.phone,
    this.company,
    this.totalPurchased = 0,
    this.balancePayable = 0,
    required this.createdAt,
    this.synced = false,
  });

  Dealer copyWith({
    String? name,
    String? phone,
    String? company,
    double? totalPurchased,
    double? balancePayable,
    bool? synced,
  }) => Dealer(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    company: company ?? this.company,
    totalPurchased: totalPurchased ?? this.totalPurchased,
    balancePayable: balancePayable ?? this.balancePayable,
    createdAt: createdAt,
    synced: synced ?? this.synced,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone ?? '',
    'company': company ?? '',
    'total_purchased': totalPurchased,
    'balance_payable': balancePayable,
    'created_at': createdAt.toIso8601String(),
    'synced': synced ? 1 : 0,
  };

  static Dealer fromMap(Map<String, dynamic> m) => Dealer(
    id: m['id'] as String,
    name: m['name'] as String,
    phone: (m['phone'] as String?)?.isEmpty == true ? null : m['phone'] as String?,
    company: (m['company'] as String?)?.isEmpty == true ? null : m['company'] as String?,
    totalPurchased: (m['total_purchased'] as num?)?.toDouble() ?? 0,
    balancePayable: (m['balance_payable'] as num?)?.toDouble() ?? 0,
    createdAt: DateTime.parse(m['created_at'] as String),
    synced: (m['synced'] as int) == 1,
  );
}
