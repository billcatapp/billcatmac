import 'dart:io';
import 'dart:math' show max;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/transaction_record.dart';
import '../../providers/cart_provider.dart';
import '../../services/connectivity_service.dart';
import '../../services/local_db_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../services/update_service.dart';
import 'package:printing/printing.dart' show Printer, Printing, PdfPreview;
import '../../services/receipt_printer.dart';
import '../../widgets/whatsapp_panel.dart';
import '../auth/login_screen.dart';

const _defaultProducts = <Product>[];


// ── Currency data ────────────────────────────────────────────────────────────

typedef _Currency = ({String flag, String code, String name, String symbol});

const List<_Currency> _currencies = [
  (flag: '🇮🇳', code: 'INR', name: 'Indian Rupee',           symbol: '₹'),
  (flag: '🇺🇸', code: 'USD', name: 'US Dollar',               symbol: '\$'),
  (flag: '🇪🇺', code: 'EUR', name: 'Euro',                    symbol: '€'),
  (flag: '🇬🇧', code: 'GBP', name: 'British Pound',           symbol: '£'),
  (flag: '🇯🇵', code: 'JPY', name: 'Japanese Yen',            symbol: '¥'),
  (flag: '🇨🇳', code: 'CNY', name: 'Chinese Yuan',            symbol: '¥'),
  (flag: '🇦🇺', code: 'AUD', name: 'Australian Dollar',       symbol: 'A\$'),
  (flag: '🇨🇦', code: 'CAD', name: 'Canadian Dollar',         symbol: 'C\$'),
  (flag: '🇨🇭', code: 'CHF', name: 'Swiss Franc',             symbol: 'Fr'),
  (flag: '🇸🇬', code: 'SGD', name: 'Singapore Dollar',        symbol: 'S\$'),
  (flag: '🇭🇰', code: 'HKD', name: 'Hong Kong Dollar',        symbol: 'HK\$'),
  (flag: '🇳🇿', code: 'NZD', name: 'New Zealand Dollar',      symbol: 'NZ\$'),
  (flag: '🇰🇷', code: 'KRW', name: 'South Korean Won',        symbol: '₩'),
  (flag: '🇳🇴', code: 'NOK', name: 'Norwegian Krone',         symbol: 'kr'),
  (flag: '🇸🇪', code: 'SEK', name: 'Swedish Krona',           symbol: 'kr'),
  (flag: '🇩🇰', code: 'DKK', name: 'Danish Krone',            symbol: 'kr'),
  (flag: '🇲🇽', code: 'MXN', name: 'Mexican Peso',            symbol: 'MX\$'),
  (flag: '🇿🇦', code: 'ZAR', name: 'South African Rand',      symbol: 'R'),
  (flag: '🇧🇷', code: 'BRL', name: 'Brazilian Real',          symbol: 'R\$'),
  (flag: '🇦🇪', code: 'AED', name: 'UAE Dirham',              symbol: 'د.إ'),
  (flag: '🇸🇦', code: 'SAR', name: 'Saudi Riyal',             symbol: '﷼'),
  (flag: '🇹🇭', code: 'THB', name: 'Thai Baht',               symbol: '฿'),
  (flag: '🇮🇩', code: 'IDR', name: 'Indonesian Rupiah',       symbol: 'Rp'),
  (flag: '🇲🇾', code: 'MYR', name: 'Malaysian Ringgit',       symbol: 'RM'),
  (flag: '🇵🇭', code: 'PHP', name: 'Philippine Peso',         symbol: '₱'),
  (flag: '🇵🇰', code: 'PKR', name: 'Pakistani Rupee',         symbol: '₨'),
  (flag: '🇧🇩', code: 'BDT', name: 'Bangladeshi Taka',        symbol: '৳'),
  (flag: '🇱🇰', code: 'LKR', name: 'Sri Lankan Rupee',        symbol: '₨'),
  (flag: '🇳🇵', code: 'NPR', name: 'Nepalese Rupee',          symbol: '₨'),
  (flag: '🇹🇷', code: 'TRY', name: 'Turkish Lira',            symbol: '₺'),
  (flag: '🇷🇺', code: 'RUB', name: 'Russian Ruble',           symbol: '₽'),
  (flag: '🇵🇱', code: 'PLN', name: 'Polish Zloty',            symbol: 'zł'),
  (flag: '🇨🇿', code: 'CZK', name: 'Czech Koruna',            symbol: 'Kč'),
  (flag: '🇭🇺', code: 'HUF', name: 'Hungarian Forint',        symbol: 'Ft'),
  (flag: '🇷🇴', code: 'RON', name: 'Romanian Leu',            symbol: 'lei'),
  (flag: '🇺🇦', code: 'UAH', name: 'Ukrainian Hryvnia',       symbol: '₴'),
  (flag: '🇮🇱', code: 'ILS', name: 'Israeli New Shekel',      symbol: '₪'),
  (flag: '🇰🇼', code: 'KWD', name: 'Kuwaiti Dinar',           symbol: 'KD'),
  (flag: '🇧🇭', code: 'BHD', name: 'Bahraini Dinar',          symbol: 'BD'),
  (flag: '🇶🇦', code: 'QAR', name: 'Qatari Riyal',            symbol: 'QR'),
  (flag: '🇴🇲', code: 'OMR', name: 'Omani Rial',              symbol: 'OMR'),
  (flag: '🇯🇴', code: 'JOD', name: 'Jordanian Dinar',         symbol: 'JD'),
  (flag: '🇪🇬', code: 'EGP', name: 'Egyptian Pound',          symbol: 'E£'),
  (flag: '🇳🇬', code: 'NGN', name: 'Nigerian Naira',          symbol: '₦'),
  (flag: '🇰🇪', code: 'KES', name: 'Kenyan Shilling',         symbol: 'KSh'),
  (flag: '🇬🇭', code: 'GHS', name: 'Ghanaian Cedi',           symbol: '₵'),
  (flag: '🇹🇿', code: 'TZS', name: 'Tanzanian Shilling',      symbol: 'TSh'),
  (flag: '🇺🇬', code: 'UGX', name: 'Ugandan Shilling',        symbol: 'USh'),
  (flag: '🇪🇹', code: 'ETB', name: 'Ethiopian Birr',          symbol: 'Br'),
  (flag: '🇦🇷', code: 'ARS', name: 'Argentine Peso',          symbol: 'AR\$'),
  (flag: '🇨🇱', code: 'CLP', name: 'Chilean Peso',            symbol: 'CL\$'),
  (flag: '🇨🇴', code: 'COP', name: 'Colombian Peso',          symbol: 'CO\$'),
  (flag: '🇵🇪', code: 'PEN', name: 'Peruvian Sol',            symbol: 'S/'),
  (flag: '🇻🇳', code: 'VND', name: 'Vietnamese Dong',         symbol: '₫'),
  (flag: '🇹🇼', code: 'TWD', name: 'Taiwan Dollar',           symbol: 'NT\$'),
  (flag: '🇮🇷', code: 'IRR', name: 'Iranian Rial',            symbol: '﷼'),
  (flag: '🇲🇦', code: 'MAD', name: 'Moroccan Dirham',         symbol: 'MAD'),
  (flag: '🇩🇿', code: 'DZD', name: 'Algerian Dinar',          symbol: 'دج'),
  (flag: '🇹🇳', code: 'TND', name: 'Tunisian Dinar',          symbol: 'DT'),
  (flag: '🇮🇸', code: 'ISK', name: 'Icelandic Króna',         symbol: 'kr'),
  (flag: '🇭🇷', code: 'HRK', name: 'Croatian Kuna',           symbol: 'kn'),
  (flag: '🇷🇸', code: 'RSD', name: 'Serbian Dinar',           symbol: 'din'),
  (flag: '🇧🇬', code: 'BGN', name: 'Bulgarian Lev',           symbol: 'лв'),
  (flag: '🇲🇲', code: 'MMK', name: 'Myanmar Kyat',            symbol: 'K'),
  (flag: '🇰🇭', code: 'KHR', name: 'Cambodian Riel',          symbol: '៛'),
  (flag: '🇱🇦', code: 'LAK', name: 'Lao Kip',                 symbol: '₭'),
  (flag: '🇲🇳', code: 'MNT', name: 'Mongolian Tugrik',        symbol: '₮'),
  (flag: '🇦🇲', code: 'AMD', name: 'Armenian Dram',           symbol: '֏'),
  (flag: '🇬🇪', code: 'GEL', name: 'Georgian Lari',           symbol: '₾'),
  (flag: '🇦🇿', code: 'AZN', name: 'Azerbaijani Manat',       symbol: '₼'),
  (flag: '🇰🇿', code: 'KZT', name: 'Kazakhstani Tenge',       symbol: '₸'),
  (flag: '🇺🇿', code: 'UZS', name: 'Uzbekistani Sum',         symbol: 'лв'),
  (flag: '🇹🇲', code: 'TMT', name: 'Turkmenistani Manat',     symbol: 'T'),
  (flag: '🇧🇾', code: 'BYN', name: 'Belarusian Ruble',        symbol: 'Br'),
  (flag: '🇲🇩', code: 'MDL', name: 'Moldovan Leu',            symbol: 'L'),
  (flag: '🇦🇱', code: 'ALL', name: 'Albanian Lek',            symbol: 'L'),
  (flag: '🇲🇰', code: 'MKD', name: 'Macedonian Denar',        symbol: 'ден'),
  (flag: '🇧🇦', code: 'BAM', name: 'Bosnia Mark',             symbol: 'KM'),
  (flag: '🇲🇹', code: 'MTL', name: 'Maltese Lira',            symbol: 'Lm'),
  (flag: '🇵🇦', code: 'PAB', name: 'Panamanian Balboa',       symbol: 'B/.'),
  (flag: '🇨🇷', code: 'CRC', name: 'Costa Rican Colón',       symbol: '₡'),
  (flag: '🇬🇹', code: 'GTQ', name: 'Guatemalan Quetzal',      symbol: 'Q'),
  (flag: '🇧🇴', code: 'BOB', name: 'Bolivian Boliviano',      symbol: 'Bs.'),
  (flag: '🇵🇾', code: 'PYG', name: 'Paraguayan Guaraní',      symbol: '₲'),
  (flag: '🇺🇾', code: 'UYU', name: 'Uruguayan Peso',          symbol: 'UY\$'),
  (flag: '🇪🇨', code: 'USD', name: 'Ecuadorian (USD)',         symbol: '\$'),
  (flag: '🇨🇺', code: 'CUP', name: 'Cuban Peso',              symbol: '₱'),
  (flag: '🇩🇴', code: 'DOP', name: 'Dominican Peso',          symbol: 'RD\$'),
  (flag: '🇯🇲', code: 'JMD', name: 'Jamaican Dollar',         symbol: 'J\$'),
  (flag: '🇹🇹', code: 'TTD', name: 'Trinidad Dollar',         symbol: 'TT\$'),
  (flag: '🇧🇧', code: 'BBD', name: 'Barbadian Dollar',        symbol: 'Bds\$'),
  (flag: '🇫🇯', code: 'FJD', name: 'Fijian Dollar',           symbol: 'FJ\$'),
  (flag: '🇵🇬', code: 'PGK', name: 'Papua New Guinea Kina',   symbol: 'K'),
];

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});
  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  List<Product> _products = List.from(_defaultProducts);
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  int _selectedTab = 1;
  String _inventorySearchQuery = '';
  String _inventoryCategoryFilter = 'All';
  double _rightPanelWidth = 400;

  // Reports state
  String _reportView = 'Sales';
  String _salesSearchQuery = '';
  String _customerSearchQuery = '';
  List<Customer> _reportCustomers = [];
  List<Customer> _savedCustomers = [];
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _customerNameFocus = FocusNode();
  final _customerPhoneFocus = FocusNode();

  // Dynamic categories (user can add more)
  List<String> _userCategories = [];

  // Dashboard state (real data)
  double _dashSales = 0;
  int    _dashTxCount = 0;
  int    _dashItemsSold = 0;
  double _dashAvgOrder = 0;
  double _dashYestSales = 0;
  int    _dashYestTxCount = 0;
  int    _dashYestItems = 0;
  double _dashYestAvg = 0;
  double _dashWeekSales = 0;
  double _dashMonthSales = 0;
  double _dashYearSales = 0;

  // Per-period additional metrics
  int    _dashWeekTxCount = 0;  int _dashWeekItems = 0;  double _dashWeekAvg = 0;
  int    _dashMonthTxCount = 0; int _dashMonthItems = 0; double _dashMonthAvg = 0;
  int    _dashYearTxCount = 0;  int _dashYearItems = 0;  double _dashYearAvg = 0;

  // Profit per period
  double _dashProfitToday = 0;
  double _dashProfitWeek  = 0;
  double _dashProfitMonth = 0;

  // Period selector
  String _dashPeriod = 'Today';

  // Chart bars per period
  List<(String, double)> _chartBarsToday = [];
  List<(String, double)> _chartBarsWeek  = [];
  List<(String, double)> _chartBarsMonth = [];
  List<(String, double)> _chartBarsYear  = [];

  // Same-day last week (for "No data yesterday" comparison)
  double _dashLastWeekSameDaySales = 0;

  // Top sold products per period: (name, qty, revenue)
  List<(String, int, double)> _topProductsToday = [];
  List<(String, int, double)> _topProductsWeek  = [];
  List<(String, int, double)> _topProductsMonth = [];
  List<(String, int, double)> _topProductsYear  = [];
  List<(String, double, Color)> _dashCategories = [];
  List<TransactionRecord> _dashRecentTx = [];

  // Sales report period
  String _reportSalesPeriod = 'This Week';
  List<TransactionRecord> _txListToday = [];
  List<TransactionRecord> _txListWeek  = [];
  List<TransactionRecord> _txListMonth = [];

  // Settings state
  String _storeName = 'BillCat Store';
  String _storeAddress = '';
  String _storePhone = '';
  String _storeEmail = '';
  String _storeGstin = '';
  String _logoPath = '';
  String _receiptFooter = 'Thank you for your purchase!';
  String _taxLabel = 'GST';
  String _taxRateDisplay = '0';
  String _currencySymbol = '₹';
  String _currencyCode = 'INR';
  String _invoiceLayout = 'Classic';
  String _printOrientation = 'Portrait';
  String _storeTerms = 'Payment due within 30 days. Goods once sold will not be taken back.';

  // Printer state
  String _selectedPrinter = 'System Default';
  Printer? _activePrinter;
  String _paperSize = 'A4';
  bool _autoPrint = false;


  // Top toast
  String _toastMessage = '';
  bool _toastVisible = false;
  bool _toastIsError = false;

  // Update banner
  UpdateInfo? _updateInfo;
  bool _updateDismissed = false;
  bool _isCheckingUpdate = false;
  String _currentVersion = '';
  double? _downloadProgress; // null=idle, 0–1=downloading, 1.0=done
  String _downloadedPath = '';

  // Owner / Staff access
  bool   _ownerLockEnabled = false;
  bool   _isOwnerMode      = false;
  String _ownerPasscode    = '';

  // Settings panel
  bool _showSettings = false;
  bool _isPrinting = false;
  bool _addingCustomProduct = false;
  final _customNameCtrl = TextEditingController();
  final _customPriceCtrl = TextEditingController();
  String _settingsPage = 'General';
  String _editStoreName = 'BillCat Store';
  String _editStoreAddress = '';
  String _editLogoPath = '';
  String _editReceiptFooter = 'Thank you for your purchase!';
  String _editTaxLabel = 'VAT';
  String _editTaxRate = '0';
  String _editCurrencyCode = 'INR';
  String _editCurrencySymbol = '₹';
  String _editPaperSize = 'A4';
  bool _editAutoPrint = false;
  String _editStorePhone = '';
  String _editStoreEmail = '';
  String _editStoreGstin = '';
  String _editInvoiceLayout = 'Classic';
  String _editPrintOrientation = 'Portrait';
  String _editPrinterTab = 'Regular';
  int _previewRevision = 0;
  String _editStoreTerms = 'Payment due within 30 days. Goods once sold will not be taken back.';

  List<Product> get _filteredProducts {
    return _products.where((p) {
      final matchCat = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.sku.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadSettingsFromStorage();
    _loadProducts();
    _loadDashboardData();
    _loadSavedCustomers();
    ConnectivityService.instance.addListener(_onSyncComplete);
    _checkForUpdate();
    _loadCurrentVersion();
    ReceiptPrinter.preWarm();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncTaxRate());
  }

  Future<void> _loadSettingsFromStorage() async {
    final s = await LocalDbService.getSettings();
    if (s.isEmpty || !mounted) return;
    setState(() {
      _storeName = s['store_name'] ?? _storeName;
      _storeAddress = s['store_address'] ?? _storeAddress;
      _storePhone = s['store_phone'] ?? _storePhone;
      _storeEmail = s['store_email'] ?? _storeEmail;
      _storeGstin = s['store_gstin'] ?? _storeGstin;
      _receiptFooter = s['receipt_footer'] ?? _receiptFooter;
      _taxLabel = s['tax_label'] ?? _taxLabel;
      _taxRateDisplay = s['tax_rate'] ?? _taxRateDisplay;
      _currencyCode = s['currency_code'] ?? _currencyCode;
      _currencySymbol = s['currency_symbol'] ?? _currencySymbol;
      _paperSize = s['paper_size'] ?? _paperSize;
      _selectedPrinter = s['selected_printer'] ?? _selectedPrinter;
      _printOrientation = s['print_orientation'] ?? _printOrientation;
      final savedLayout = s['invoice_layout'] ?? _invoiceLayout;
      const _validLayouts = ['Classic','Simple','Modern','GST','Landscape','Theme 1','Theme 2','Theme 3','Theme 4','Theme 5'];
      _invoiceLayout = _validLayouts.contains(savedLayout) ? savedLayout : 'Classic';
      _storeTerms = s['store_terms'] ?? _storeTerms;
      _logoPath = s['logo_path'] ?? _logoPath;
      _autoPrint = (s['auto_print'] ?? '0') == '1';
      _ownerPasscode    = s['owner_passcode'] ?? '';
      _ownerLockEnabled = (s['owner_lock_enabled'] ?? '0') == '1';
    });
    _syncTaxRate();
    _restoreActivePrinter();
  }

  Future<void> _restoreActivePrinter() async {
    if (_selectedPrinter == 'PDF Export' || _selectedPrinter == 'System Default') return;
    try {
      final printers = await Printing.listPrinters();
      final match = printers.where((p) => p.name == _selectedPrinter).toList();
      if (match.isNotEmpty && mounted) setState(() => _activePrinter = match.first);
    } catch (_) {}
  }

  void _syncTaxRate() {
    final cart = context.read<CartProvider>();
    cart.setTaxRate(double.tryParse(_taxRateDisplay) ?? 0.0);
  }

  Future<void> _loadSavedCustomers() async {
    final customers = await LocalDbService.getCustomers();
    if (mounted) setState(() => _savedCustomers = customers);
  }

  Future<void> _loadCurrentVersion() async {
    final v = await UpdateService.currentVersion();
    if (mounted) setState(() => _currentVersion = v);
  }

  Future<void> _checkForUpdate() async {
    try {
      final info = await UpdateService.checkForUpdate();
      if (mounted && info != null) setState(() => _updateInfo = info);
    } catch (_) {}
  }

  Future<void> _manualCheckForUpdate() async {
    if (_isCheckingUpdate) return;
    setState(() { _isCheckingUpdate = true; _updateDismissed = false; });
    try {
      final info = await UpdateService.checkForUpdate();
      if (!mounted) return;
      if (info != null) {
        setState(() { _updateInfo = info; _isCheckingUpdate = false; });
      } else {
        setState(() { _updateInfo = null; _isCheckingUpdate = false; });
        if (mounted) {
          _showToast('BillCat is up to date (v${_currentVersion.isNotEmpty ? _currentVersion : '1.0.0'})');
        }
      }
    } on UpdateCheckError catch (e) {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
        _showToast(e.message, isError: true);
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingUpdate = false);
    }
  }

  Future<void> _installUpdate() async {
    final info = _updateInfo;
    if (info == null || _downloadProgress != null) return;
    setState(() { _downloadProgress = 0.0; _downloadedPath = ''; });
    try {
      await UpdateService.installUpdate(
        info.downloadUrl,
        (p) { if (mounted) setState(() => _downloadProgress = p); },
      );
    } on UpdateCheckError catch (e) {
      if (mounted) {
        setState(() => _downloadProgress = null);
        _showToast(e.message, isError: true);
      }
    } catch (_) {
      if (mounted) setState(() => _downloadProgress = null);
    }
  }

  Future<void> _loadProducts() async {
    final local = await LocalDbService.getProducts();
    final savedCats = await LocalDbService.getCategories();
    if (mounted) setState(() {
      _products = local;
      final seen = <String>{};
      // Merge: categories from DB table + categories from products
      final fromProducts = local
          .map((p) => p.category)
          .where((c) => c.isNotEmpty)
          .toSet();
      _userCategories = [
        ...savedCats,
        ...fromProducts.where((c) => !savedCats.contains(c)),
      ].where((c) => seen.add(c)).toList();
    });
  }

  Future<void> _loadDashboardData() async {
    final today     = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    // Week: Mon–today
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    // Month: 1st of current month
    final monthStart = DateTime(today.year, today.month, 1);
    // Year: Jan 1
    final yearStart  = DateTime(today.year, 1, 1);

    final lastWeekSameDay = today.subtract(const Duration(days: 7));

    final results = await Future.wait([
      LocalDbService.getTransactionsForDate(today),
      LocalDbService.getTransactionsForDate(yesterday),
      LocalDbService.getTransactionsForRange(weekStart, today),
      LocalDbService.getTransactionsForRange(monthStart, today),
      LocalDbService.getTransactionsForRange(yearStart, today),
      LocalDbService.getTransactionsForDate(lastWeekSameDay),
    ]);

    final todayTx          = results[0];
    final yesterdayTx      = results[1];
    final weekTx           = results[2];
    final monthTx          = results[3];
    final yearTx           = results[4];
    final lastWeekSameDayTx = results[5];

    final products = await LocalDbService.getProducts();
    final catMap          = {for (final p in products) p.id: p.category};
    final buyingPriceMap  = {for (final p in products) p.id: p.buyingPrice};

    double sales = 0, ySales = 0;
    int txCount = todayTx.length, yTxCount = yesterdayTx.length;
    int items = 0, yItems = 0;
    final catRevenue = <String, double>{};

    for (final t in todayTx) {
      sales += t.total;
      for (final i in t.items) {
        items += i.quantity;
        final cat = catMap[i.productId] ?? 'Other';
        catRevenue[cat] = (catRevenue[cat] ?? 0) + i.total;
      }
    }
    for (final t in yesterdayTx) {
      ySales += t.total;
      for (final i in t.items) yItems += i.quantity;
    }

    double weekSales           = weekTx.fold(0.0,           (s, t) => s + t.total);
    double monthSales          = monthTx.fold(0.0,          (s, t) => s + t.total);
    double yearSales           = yearTx.fold(0.0,           (s, t) => s + t.total);
    double lastWeekSameDaySales = lastWeekSameDayTx.fold(0.0, (s, t) => s + t.total);

    int weekItems = 0, monthItems = 0, yearItems = 0;
    for (final t in weekTx)  { for (final i in t.items) weekItems  += i.quantity; }
    for (final t in monthTx) { for (final i in t.items) monthItems += i.quantity; }
    for (final t in yearTx)  { for (final i in t.items) yearItems  += i.quantity; }

    // ── Profit per period ─────────────────────────────────────────────────────
    double calcProfit(List<TransactionRecord> txs) {
      double profit = 0;
      for (final t in txs) {
        double cogs = 0;
        for (final i in t.items) {
          cogs += (buyingPriceMap[i.productId] ?? 0.0) * i.quantity;
        }
        profit += t.total - cogs;
      }
      return profit;
    }
    final profitToday = calcProfit(todayTx);
    final profitWeek  = calcProfit(weekTx);
    final profitMonth = calcProfit(monthTx);

    // ── Chart bars ────────────────────────────────────────────────────────────
    // Today: 8 three-hour slots
    final tSlotLabels = ['12a','3a','6a','9a','12p','3p','6p','9p'];
    final tSlotMap = {for (final l in tSlotLabels) l: 0.0};
    for (final t in todayTx) { final l = tSlotLabels[t.createdAt.hour ~/ 3]; tSlotMap[l] = tSlotMap[l]! + t.total; }
    final chartToday = tSlotLabels.map((l) => (l, tSlotMap[l]!)).toList();

    // Week: Mon–Sun
    const wLabels = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final wMap = {for (final l in wLabels) l: 0.0};
    for (final t in weekTx) { final l = wLabels[t.createdAt.weekday - 1]; wMap[l] = wMap[l]! + t.total; }
    final chartWeek = wLabels.map((l) => (l, wMap[l]!)).toList();

    // Month: weeks W1–W5
    const mLabels = ['W1','W2','W3','W4','W5'];
    final mMap = {for (final l in mLabels) l: 0.0};
    for (final t in monthTx) { final l = 'W${((t.createdAt.day - 1) ~/ 7) + 1}'; mMap[l] = (mMap[l] ?? 0) + t.total; }
    final chartMonth = mLabels.map((l) => (l, mMap[l]!)).toList();

    // Year: Jan–Dec
    final yMap = {for (int i = 1; i <= 12; i++) _monthName(i): 0.0};
    for (final t in yearTx) { final l = _monthName(t.createdAt.month); yMap[l] = yMap[l]! + t.total; }
    final chartYear = List.generate(12, (i) => (_monthName(i + 1), yMap[_monthName(i + 1)]!));

    // ── Top sold products ─────────────────────────────────────────────────────
    List<(String, int, double)> _topOf(List<TransactionRecord> txs) {
      final map = <String, (int, double)>{};
      for (final t in txs) {
        for (final item in t.items) {
          final e = map[item.productName] ?? (0, 0.0);
          map[item.productName] = (e.$1 + item.quantity, e.$2 + item.total);
        }
      }
      final sorted = map.entries.toList()..sort((a, b) => b.value.$1.compareTo(a.value.$1));
      return sorted.take(5).map((e) => (e.key, e.value.$1, e.value.$2)).toList();
    }
    final topToday = _topOf(todayTx);
    final topWeek  = _topOf(weekTx);
    final topMonth = _topOf(monthTx);
    final topYear  = _topOf(yearTx);

    const catColors = [
      Color(0xFF1B2B4B), Color(0xFF3B82F6), Color(0xFF10B981),
      Color(0xFFF59E0B), Color(0xFF8B5CF6), Color(0xFFEF4444),
    ];
    final sortedCats = catRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final dashCats = sortedCats.take(5).toList().asMap().entries.map((e) =>
      (e.value.key, e.value.value, catColors[e.key % catColors.length])).toList();

    // ── Payment breakdown ─────────────────────────────────────────────────────
    const payColors = {
      'cash':   Color(0xFF10B981),
      'card':   Color(0xFF3B82F6),
      'upi':    Color(0xFF8B5CF6),
      'hybrid': Color(0xFFF59E0B),
    };
    if (!mounted) return;
    setState(() {
      _dashSales      = sales;
      _dashTxCount    = txCount;
      _dashItemsSold  = items;
      _dashAvgOrder   = txCount > 0 ? sales / txCount : 0;
      _dashYestSales  = ySales;
      _dashYestTxCount = yTxCount;
      _dashYestItems  = yItems;
      _dashYestAvg    = yTxCount > 0 ? ySales / yTxCount : 0;
      _dashWeekSales  = weekSales;
      _dashMonthSales = monthSales;
      _dashYearSales  = yearSales;
      _dashWeekTxCount  = weekTx.length;  _dashWeekItems  = weekItems;  _dashWeekAvg  = weekTx.isNotEmpty  ? weekSales  / weekTx.length  : 0;
      _dashMonthTxCount = monthTx.length; _dashMonthItems = monthItems; _dashMonthAvg = monthTx.isNotEmpty ? monthSales / monthTx.length : 0;
      _dashYearTxCount  = yearTx.length;  _dashYearItems  = yearItems;  _dashYearAvg  = yearTx.isNotEmpty  ? yearSales  / yearTx.length  : 0;
      _chartBarsToday = chartToday;
      _chartBarsWeek  = chartWeek;
      _chartBarsMonth = chartMonth;
      _chartBarsYear  = chartYear;
      _dashLastWeekSameDaySales = lastWeekSameDaySales;
      _topProductsToday = topToday;
      _topProductsWeek  = topWeek;
      _topProductsMonth = topMonth;
      _topProductsYear  = topYear;
      _dashCategories = dashCats;
      _dashRecentTx   = todayTx.take(5).toList();
      _txListToday = todayTx;
      _txListWeek  = weekTx;
      _txListMonth = monthTx;
      _dashProfitToday = profitToday;
      _dashProfitWeek  = profitWeek;
      _dashProfitMonth = profitMonth;
    });
  }

  void _onSyncComplete() {
    _loadProducts();
    _loadDashboardData();
  }

  @override
  void dispose() {
    ConnectivityService.instance.removeListener(_onSyncComplete);
    _searchController.dispose();
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _customerNameFocus.dispose();
    _customerPhoneFocus.dispose();
    _customNameCtrl.dispose();
    _customPriceCtrl.dispose();
    super.dispose();
  }

  void _showToast(String message, {bool isError = false}) {
    setState(() {
      _toastMessage = message;
      _toastIsError = isError;
      _toastVisible = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toastVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _showSettings
              ? _buildSettingsPanel()
              : Column(
                  key: const ValueKey('main'),
                  children: [
                    _buildTopBar(),
                    _buildUpdateBanner(),
                    Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _buildDashboardView(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildLeftPanel(),
                      _buildResizeDivider(),
                      _buildRightPanel(),
                    ],
                  ),
                  _buildInventoryView(),
                  _buildReportsView(),
                ],
              ),
            ),
                    _buildBottomBar(),
                  ],
                ),
        ),
            // ── Top toast ──
            _buildToast(),
            // ── Print loading overlay ──
            if (_isPrinting)
              _buildPrintingOverlay(),
          ],
        ),
    );
  }

  Widget _buildPrintingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.35),
      child: Center(
        child: Container(
          width: 200,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Preparing\nReceipt...',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D1D1F),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Toast ────────────────────────────────────────────────────────────────

  Widget _buildToast() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 380),
      curve: _toastVisible ? Curves.easeOutBack : Curves.easeIn,
      top: _toastVisible ? 24 : -80,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 280),
          opacity: _toastVisible ? 1.0 : 0.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _toastIsError
                  ? const Color(0xFFB71C1C)
                  : const Color(0xFF1D1D1F),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _toastIsError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                  color: _toastIsError ? Colors.red[200] : const Color(0xFF4CAF50),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _toastMessage,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Update Banner ────────────────────────────────────────────────────────────

  Widget _buildUpdateBanner() {
    if (_updateInfo == null || _updateDismissed) return const SizedBox.shrink();
    final info = _updateInfo!;
    final isDownloading = _downloadProgress != null && _downloadProgress! < 1.0;
    final isDone = _downloadProgress != null && _downloadProgress! >= 1.0;
    final bannerColor = info.mandatory ? AppColors.error : const Color(0xFF1565C0);

    return Material(
      color: bannerColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.system_update_alt_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isDownloading
                        ? 'Installing BillCat ${info.version}...'
                        : 'BillCat ${info.version} is available'
                            '${info.releaseNotes.isNotEmpty ? ' — ${info.releaseNotes}' : ''}',
                    style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                if (!isDownloading && !isDone)
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: _installUpdate,
                    child: const Text('Install Update',
                        style: TextStyle(fontSize: 12)),
                  ),
                if (!info.mandatory && !isDownloading) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                    onPressed: () => setState(() {
                      _updateDismissed = true;
                      _downloadProgress = null;
                    }),
                    tooltip: 'Dismiss',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ],
            ),
            if (isDownloading) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _downloadProgress,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${((_downloadProgress ?? 0) * 100).toInt()}%',
                    style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Top Bar ─────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.point_of_sale_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Text('BillCat',
              style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: -0.5)),
          const SizedBox(width: 32),
          // Nav tabs
          if (!_ownerLockEnabled || _isOwnerMode) ...[
            _navTab('Dashboard', 0),
            const SizedBox(width: 4),
          ],
          _navTab('Billing', 1),
          const SizedBox(width: 4),
          _navTab('Inventory', 2),
          if (!_ownerLockEnabled || _isOwnerMode) ...[
            const SizedBox(width: 4),
            _reportsDropdownTab(),
          ],
          const Spacer(),
          // Lock icon only shown when staff access control is enabled
          if (_ownerLockEnabled) ...[
            _topBarIconBtn(
              _isOwnerMode ? Icons.lock_open_outlined : Icons.lock_outline_rounded,
              _isOwnerMode ? 'Lock (Staff Mode)' : 'Owner Access',
              _isOwnerMode ? _lockOwnerMode : _showOwnerPasscodeDialog,
            ),
            const SizedBox(width: 8),
          ],
          // Printer + Settings
          _topBarIconBtn(Icons.print_outlined, 'Printer', _showPrinterDialog),
          const SizedBox(width: 8),
          _topBarIconBtn(Icons.settings_outlined, 'Settings', _openSettings),
          const SizedBox(width: 16),
          // Profile avatar
          _buildProfileMenu(),
        ],
      ),
    );
  }

  Widget _navTab(String label, int index) {
    final selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? AppColors.accentBlue
                  : AppColors.textMuted.withValues(alpha: 0.7),
            )),
      ),
    );
  }

  Widget _reportsDropdownTab() {
    final selected = _selectedTab == 3;
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.white,
      elevation: 4,
      onSelected: (value) {
        setState(() {
          _selectedTab = 3;
          _reportView = value;
        });
        if (value == 'Customers') _loadReportCustomers();
      },
      itemBuilder: (_) => [
        'Sales', 'Customers', 'Inventory',
      ].map((v) => PopupMenuItem<String>(
        value: v,
        height: 40,
        child: Row(
          children: [
            Icon(
              switch (v) {
                'Sales'     => Icons.bar_chart_rounded,
                'Customers' => Icons.people_alt_outlined,
                _           => Icons.inventory_2_outlined,
              },
              size: 16,
              color: (selected && _reportView == v) ? AppColors.accentBlue : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Text(v, style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: (selected && _reportView == v) ? FontWeight.w700 : FontWeight.w500,
              color: (selected && _reportView == v) ? AppColors.accentBlue : AppColors.textDark,
            )),
          ],
        ),
      )).toList(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentBlue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected ? _reportView : 'Reports',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.accentBlue : AppColors.textMuted.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: selected ? AppColors.accentBlue : AppColors.textMuted.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  // ── Left Panel ───────────────────────────────────────────────────────────────

  Widget _buildLeftPanel() {
    return Expanded(
      flex: 62,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(color: AppColors.cardShadow, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'Scan or type item name...',
                        hintStyle: GoogleFonts.inter(color: AppColors.textMuted.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.w400),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () => setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(11)),
                        child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textMuted),
                      ),
                    ),
                  ] else
                    const SizedBox(width: 16),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Category chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', ..._userCategories.where((c) => _products.any((p) => p.category == c))].map((cat) {
                  final selected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 9),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2))
                                ]
                              : null,
                        ),
                        child: Text(cat.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              letterSpacing: 0.8,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textMuted,
                            )),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            // Product grid
            Expanded(
              child: Consumer<CartProvider>(
                builder: (context, cart, _) => GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (_, i) => _ProductCard(
                    product: _filteredProducts[i],
                    onTap: () => cart.addProduct(_filteredProducts[i]),
                    currencySymbol: _currencySymbol,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Right Panel ──────────────────────────────────────────────────────────────

  Widget _buildResizeDivider() {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _rightPanelWidth =
              (_rightPanelWidth - details.delta.dx).clamp(280.0, 680.0);
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: Container(
          width: 6,
          color: Colors.transparent,
          child: Center(
            child: Container(width: 1, color: AppColors.border),
          ),
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      width: _rightPanelWidth,
      color: Colors.white,
      child: Consumer<CartProvider>(
        builder: (context, cart, _) => Column(
          children: [
            _buildCustomerBar(cart),
            _buildCartTable(cart),
            _buildSummary(cart),
            _buildPaymentMethods(cart),
            _buildActionButtons(context, cart),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerBar(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Customer Name with autocomplete
          Expanded(
            child: _customerAutocomplete(
              controller: _customerNameCtrl,
              focusNode: _customerNameFocus,
              icon: Icons.person_outline_rounded,
              hint: 'Customer Name',
              filterFn: (c, q) => c.name.toLowerCase().contains(q.toLowerCase()),
              displayFn: (c) => c.name,
              onChanged: (v) => cart.customerName = v,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: () => _customerPhoneFocus.requestFocus(),
              onSelected: (c) {
                _customerNameCtrl.text = c.name;
                _customerPhoneCtrl.text = c.phone ?? '';
                cart.customerName = c.name;
                cart.customerPhone = c.phone ?? '';
                setState(() {});
                _customerPhoneFocus.requestFocus();
              },
            ),
          ),
          const SizedBox(width: 10),
          // Phone with autocomplete
          SizedBox(
            width: 140,
            child: _customerAutocomplete(
              controller: _customerPhoneCtrl,
              focusNode: _customerPhoneFocus,
              icon: Icons.phone_outlined,
              hint: 'Phone Number',
              filterFn: (c, q) => (c.phone ?? '').contains(q),
              displayFn: (c) => c.phone ?? '',
              onChanged: (v) => cart.customerPhone = v,
              onSelected: (c) {
                _customerNameCtrl.text = c.name;
                _customerPhoneCtrl.text = c.phone ?? '';
                cart.customerName = c.name;
                cart.customerPhone = c.phone ?? '';
                setState(() {});
              },
              keyboardType: TextInputType.phone,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _customerAutocomplete({
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required String hint,
    required bool Function(Customer, String) filterFn,
    required String Function(Customer) displayFn,
    required ValueChanged<String> onChanged,
    required ValueChanged<Customer> onSelected,
    TextInputType? keyboardType,
    VoidCallback? onFieldSubmitted,
    TextInputAction? textInputAction,
  }) {
    return RawAutocomplete<Customer>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (v) {
        if (v.text.trim().isEmpty) return const [];
        return _savedCustomers.where((c) => filterFn(c, v.text)).take(6);
      },
      displayStringForOption: displayFn,
      onSelected: onSelected,
      fieldViewBuilder: (context, textCtrl, fn, onSubmit) {
        return Container(
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.5),
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 10),
              Icon(icon, size: 15, color: AppColors.textMuted),
              const SizedBox(width: 7),
              Expanded(
                child: TextField(
                  controller: textCtrl,
                  focusNode: fn,
                  onChanged: onChanged,
                  textInputAction: textInputAction ?? TextInputAction.done,
                  onSubmitted: (_) {
                    onSubmit();
                    onFieldSubmitted?.call();
                  },
                  keyboardType: keyboardType,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
                      color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
      optionsViewBuilder: (context, onSel, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 280),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (_, i) {
                final c = options.elementAt(i);
                return InkWell(
                  onTap: () => onSel(c),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(children: [
                      const Icon(Icons.person_outline_rounded, size: 14,
                          color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.name, style: GoogleFonts.inter(fontSize: 12,
                            fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        if (c.phone != null && c.phone!.isNotEmpty)
                          Text(c.phone!, style: GoogleFonts.inter(fontSize: 11,
                              color: AppColors.textMuted)),
                      ])),
                    ]),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _customerField({
    required IconData icon,
    required String hint,
    required Function(String) onChanged,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
              color: AppColors.textMuted.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w300),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCartTable(CartProvider cart) {
    return Expanded(
      child: ClipRect(child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 12),
            color: AppColors.surfaceVariant,
            child: Row(
              children: [
                Expanded(
                    child: Text('DESCRIPTION',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 1.5))),
                SizedBox(
                    width: 90,
                    child: Text('QTY',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 1.5))),
                SizedBox(
                    width: 90,
                    child: Text('AMOUNT',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 1.5))),
                const SizedBox(width: 28),
              ],
            ),
          ),
          // Cart items
          Expanded(
            child: (cart.items.isEmpty && !_addingCustomProduct)
                ? Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.border),
                          const SizedBox(height: 8),
                          Text('No items added', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: () => setState(() { _addingCustomProduct = true; _customNameCtrl.clear(); _customPriceCtrl.clear(); }),
                            icon: const Icon(Icons.add_rounded, size: 15),
                            label: Text('Custom Product', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              side: const BorderSide(color: AppColors.border),
                              foregroundColor: AppColors.textDark,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: cart.items.length + 1,
                    itemBuilder: (_, i) {
                      if (i == cart.items.length) {
                        return _addingCustomProduct
                            ? _buildInlineCustomRow(cart)
                            : _addCustomProductBtn(cart);
                      }
                      return _CartRow(
                          item: cart.items[i], cart: cart, currencySymbol: _currencySymbol);
                    },
                  ),
          ),
        ],
      )),
    );
  }

  Widget _addCustomProductBtn(CartProvider cart) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      child: OutlinedButton.icon(
        onPressed: () => setState(() { _addingCustomProduct = true; _customNameCtrl.clear(); _customPriceCtrl.clear(); }),
        icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
        label: Text('CUSTOM PRODUCT',
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.8)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 46),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildInlineCustomRow(CartProvider cart) {
    void confirm() {
      final name = _customNameCtrl.text.trim();
      final price = double.tryParse(_customPriceCtrl.text) ?? 0;
      if (name.isNotEmpty && price > 0) {
        cart.addProduct(Product(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name, price: price,
          category: 'Custom', emoji: '📦', sku: 'CUSTOM', stock: 99,
        ));
        setState(() => _addingCustomProduct = false);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FF),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        const Text('📦', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          flex: 5,
          child: TextField(
            controller: _customNameCtrl,
            autofocus: true,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            decoration: InputDecoration.collapsed(hintText: 'Item name', hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
            onSubmitted: (_) => confirm(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: TextField(
            controller: _customPriceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration.collapsed(hintText: 'Price', hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
            textAlign: TextAlign.right,
            onSubmitted: (_) => confirm(),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: confirm,
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => setState(() => _addingCustomProduct = false),
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
          ),
        ),
      ]),
    );
  }

  Widget _buildSummary(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
              color: Color(0x08000000),
              blurRadius: 20,
              offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        children: [
          _summaryRow('SUBTOTAL', cart.subtotal),
          const SizedBox(height: 10),
          // Discount row
          Row(
            children: [
              Text('DISCOUNT',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                      letterSpacing: 1.5)),
              const SizedBox(width: 10),
              _DiscountToggle(cart: cart, currencySymbol: _currencySymbol),
              const Spacer(),
              Text(
                  '-$_currencySymbol${cart.discountAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.success,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          _summaryRow('TAX ($_taxLabel $_taxRateDisplay%)', cart.taxAmount),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOTAL PAYABLE',
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textMuted,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 2),
                  Text(
                      '$_currencySymbol${cart.total.toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: -1)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text('${cart.itemCount} ITEMS',
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                        letterSpacing: 1.0)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount) {
    return Row(
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
                letterSpacing: 1.5)),
        const Spacer(),
        Text('$_currencySymbol${amount.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
      ],
    );
  }

  Widget _buildPaymentMethods(CartProvider cart) {
    const methods = [
      (PaymentMethod.cash, 'Cash'),
      (PaymentMethod.card, 'Card'),
      (PaymentMethod.upi, 'UPI/QR'),
      (PaymentMethod.hybrid, 'Hybrid'),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PAYMENT METHOD',
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                  letterSpacing: 1.5)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: methods.map((m) {
              final selected = cart.paymentMethod == m.$1;
              return GestureDetector(
                onTap: () => cart.setPaymentMethod(m.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accentBlue.withValues(alpha: 0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                        color: selected
                            ? AppColors.accentBlue
                            : AppColors.border,
                        width: selected ? 2 : 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.accentBlue
                              : Colors.transparent,
                          border: Border.all(
                              color: selected
                                  ? AppColors.accentBlue
                                  : AppColors.border,
                              width: 1.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(m.$2.toUpperCase(),
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              letterSpacing: 0.8,
                              color: selected
                                  ? AppColors.accentBlue
                                  : AppColors.textMuted)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, CartProvider cart) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: cart.items.isEmpty
                      ? null
                      : () => _confirmClear(context, cart),
                  icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                  label: Text('CLEAR BILL',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: AppColors.border),
                    foregroundColor: AppColors.textDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (cart.items.isEmpty || _isPrinting) ? null : () => _showPrintBillDialog(cart),
                  icon: const Icon(Icons.print_outlined, size: 16),
                  label: Text('PRINT BILL',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 13),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    disabledBackgroundColor: AppColors.border,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: cart.items.isEmpty
                  ? null
                  : () => _closeBill(context, cart),
              icon: const Icon(Icons.check_circle_outline_rounded,
                  size: 22),
              label: Text('Paid - Close Bill',
                  style: GoogleFonts.manrope(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                disabledBackgroundColor: AppColors.border,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ───────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _bottomBarBtn(Icons.keyboard_outlined, 'SHORTCUTS'),
          const SizedBox(width: 4),
          _bottomBarBtn(Icons.inventory_2_outlined, 'INVENTORY',
              onPressed: () =>
                  setState(() => _selectedTab = 2)),
          const SizedBox(width: 4),
          _bottomBarBtn(Icons.receipt_outlined, 'LAST RECEIPT'),
          const Spacer(),
          Text(
              'POS T-01  •  SESSION: ${TimeOfDay.now().format(context)}  •  ${_sessionUserLabel()}',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textMuted.withValues(alpha: 0.7),
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _bottomBarBtn(IconData icon, String label,
      {VoidCallback? onPressed}) {
    return TextButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 14, color: AppColors.textMuted),
      label: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
              letterSpacing: 0.8)),
      style: TextButton.styleFrom(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
      ),
    );
  }

  String _sessionUserLabel() {
    final email = SupabaseService.currentUser?.email ?? '';
    final local = email.split('@').first;
    final parts = local.split(RegExp(r'[._\-]'));
    if (parts.length >= 2) {
      return '${parts[0].toUpperCase()} ${parts[1][0].toUpperCase()}.';
    }
    return local.toUpperCase();
  }

  // ── Top bar helper ───────────────────────────────────────────────────────────

  Widget _topBarIconBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.textMuted),
        ),
      ),
    );
  }

  // ── Profile menu ─────────────────────────────────────────────────────────────

  Widget _buildProfileMenu() {
    final user = SupabaseService.currentUser;
    final email = user?.email ?? 'user@example.com';
    final initials = email.isNotEmpty ? email[0].toUpperCase() : 'U';

    return PopupMenuButton<String>(
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: Colors.white,
      onSelected: (value) {
        if (value == 'logout') _confirmLogout(context);
        if (value == 'profile') _showProfileDialog(email);
      },
      itemBuilder: (_) => [
        // Header — non-interactive user info
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(initials,
                        style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Account',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark)),
                      Text(email,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w300,
                              color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'profile',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: 10),
              Text('Profile',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'logout',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.logout_rounded,
                  size: 16, color: AppColors.error),
              const SizedBox(width: 10),
              Text('Logout',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.error)),
            ],
          ),
        ),
      ],
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(initials,
              style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ),
      ),
    );
  }

  void _showProfileDialog(String email) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(email[0].toUpperCase(),
                      style: GoogleFonts.manrope(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              Text('My Account',
                  style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              const SizedBox(height: 4),
              Text(email,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textMuted)),
              const SizedBox(height: 24),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 20),
              // Info rows
              _profileInfoRow(Icons.store_outlined, 'General', _storeName),
              const SizedBox(height: 12),
              _profileInfoRow(Icons.email_outlined, 'Email', email),
              const SizedBox(height: 12),
              _profileInfoRow(Icons.print_outlined, 'Printer', _selectedPrinter),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmLogout(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.error),
                        foregroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Logout',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Close',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Text('$label:',
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(value,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
        ),
      ],
    );
  }

  // ── Settings panel (Apple-style) ─────────────────────────────────────────────

  void _openSettings() {
    setState(() {
      _editStoreName = _storeName;
      _editStoreAddress = _storeAddress;
      _editStorePhone = _storePhone;
      _editStoreEmail = _storeEmail;
      _editStoreGstin = _storeGstin;
      _editReceiptFooter = _receiptFooter;
      _editTaxLabel = _taxLabel;
      _editTaxRate = _taxRateDisplay;
      _editCurrencyCode = _currencyCode;
      _editCurrencySymbol = _currencySymbol;
      _editPaperSize = _paperSize;
      _editAutoPrint = _autoPrint;
      _editInvoiceLayout = _invoiceLayout;
      _editPrintOrientation = _printOrientation;
      _editPrinterTab = 'Regular';
      _editStoreTerms = _storeTerms;
      _editLogoPath = _logoPath;
      _settingsPage = 'General';
      _showSettings = true;
    });
  }

  void _saveSettings() {
    setState(() {
      _storeName = _editStoreName.trim().isEmpty ? 'BillCat Store' : _editStoreName.trim();
      _storeAddress = _editStoreAddress.trim();
      _storePhone = _editStorePhone.trim();
      _storeEmail = _editStoreEmail.trim();
      _storeGstin = _editStoreGstin.trim();
      _receiptFooter = _editReceiptFooter.trim();
      _taxLabel = _editTaxLabel.trim().isEmpty ? 'GST' : _editTaxLabel.trim();
      _taxRateDisplay = _editTaxRate.trim().isEmpty ? '0' : _editTaxRate.trim();
      _syncTaxRate();
      _currencyCode = _editCurrencyCode;
      _currencySymbol = _editCurrencySymbol;
      _paperSize = _editPaperSize;
      _autoPrint = _editAutoPrint;
      _invoiceLayout = _editInvoiceLayout;
      _printOrientation = _editPrintOrientation;
      _storeTerms = _editStoreTerms;
      _logoPath = _editLogoPath;
      _showSettings = false;
    });
    _persistSettings();
  }

  Future<void> _persistSettings() async {
    await LocalDbService.saveSettings({
      'store_name': _storeName,
      'store_address': _storeAddress,
      'store_phone': _storePhone,
      'store_email': _storeEmail,
      'store_gstin': _storeGstin,
      'receipt_footer': _receiptFooter,
      'tax_label': _taxLabel,
      'tax_rate': _taxRateDisplay,
      'currency_code': _currencyCode,
      'currency_symbol': _currencySymbol,
      'paper_size': _paperSize,
      'selected_printer': _selectedPrinter,
      'print_orientation': _printOrientation,
      'invoice_layout': _invoiceLayout,
      'store_terms': _storeTerms,
      'logo_path': _logoPath,
      'auto_print': _autoPrint ? '1' : '0',
    });
    ConnectivityService.instance.syncNow();
  }

  static const _settingsNavItems = [
    (icon: Icons.storefront_outlined,       label: 'General'),
    (icon: Icons.percent_rounded,           label: 'Tax'),
    (icon: Icons.print_outlined,            label: 'Printer'),
    (icon: Icons.person_outline_rounded,    label: 'Account'),
    (icon: Icons.shield_outlined,           label: 'Security'),
  ];

  Widget _buildSettingsPanel() {
    return Container(
      key: const ValueKey('settings'),
      color: const Color(0xFFF2F2F7),
      child: Column(
        children: [
          // ── header bar ──
          Container(
            height: 64,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _showSettings = false),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                  label: Text('Back',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const Spacer(),
                Text('Settings',
                    style: GoogleFonts.manrope(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D1D1F))),
                const Spacer(),
                FilledButton(
                  onPressed: _saveSettings,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text('Done',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          // ── body: sidebar + content ──
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSettingsSidebar(),
                Container(width: 1, color: const Color(0xFFD8D8DC)),
                Expanded(child: _buildSettingsContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSidebar() {
    return Container(
      width: 200,
      color: const Color(0xFFF5F5F7),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _settingsNavItems.map((item) {
          final selected = _settingsPage == item.label;
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _settingsPage = item.label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(item.icon,
                          size: 16,
                          color: selected ? AppColors.primary : const Color(0xFF8E8E93)),
                      const SizedBox(width: 10),
                      Text(item.label,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              color: selected
                                  ? AppColors.primary
                                  : const Color(0xFF3C3C43))),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsContent() {
    if (_settingsPage == 'Printer') return _buildSettingsPrinter();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: switch (_settingsPage) {
            'General' => _buildSettingsStore(),
            'Tax'     => _buildSettingsTax(),
            'Account' => _buildSettingsAccount(),
            'Security'=> _buildSettingsSecurity(),
            _         => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }

  // ── Store ──
  Widget _buildSettingsStore() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _settingsPageTitle('General', Icons.storefront_outlined),
        const SizedBox(height: 24),
        _settingsCard([
          _settingsTextField('Store Name', _editStoreName,
              (v) => setState(() => _editStoreName = v)),
          _settingsDivider(),
          _settingsTextField('Store Address', _editStoreAddress,
              (v) => setState(() => _editStoreAddress = v)),
        ]),
        const SizedBox(height: 24),
        _settingsSectionHeader('CURRENCY'),
        const SizedBox(height: 8),
        _settingsCard([
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () async {
                final result = await _showCurrencyPicker(context, _editCurrencyCode);
                if (result != null) {
                  setState(() {
                    _editCurrencyCode = result.code;
                    _editCurrencySymbol = result.symbol;
                  });
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Text(
                      _currencies.firstWhere((c) => c.code == _editCurrencyCode,
                          orElse: () => _currencies.first).flag,
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$_editCurrencyCode  $_editCurrencySymbol',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1D1D1F))),
                          Text(
                            _currencies.firstWhere(
                                (c) => c.code == _editCurrencyCode,
                                orElse: () => _currencies.first).name,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: const Color(0xFF6E6E73)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFFC7C7CC), size: 20),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ],
    );
  }

  // ── Tax ──
  Widget _buildSettingsTax() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _settingsPageTitle('Tax', Icons.percent_rounded),
        const SizedBox(height: 24),
        _settingsCard([
          _settingsTextField('Tax Label', _editTaxLabel,
              (v) => setState(() => _editTaxLabel = v)),
          _settingsDivider(),
          _settingsTextField('Tax Rate (%)', _editTaxRate,
              (v) => setState(() => _editTaxRate = v),
              keyboardType: TextInputType.number),
        ]),
      ],
    );
  }

  // ── Receipt ──
  Widget _buildSettingsReceipt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _settingsPageTitle('Receipt', Icons.receipt_long_outlined),
        const SizedBox(height: 24),
        _settingsCard([
          _settingsTextField('Receipt Footer', _editReceiptFooter,
              (v) => setState(() => _editReceiptFooter = v), maxLines: 3),
        ]),
      ],
    );
  }

  // ── Printer ──
  Widget _buildSettingsPrinter() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Left: settings column ──────────────────────────────────────
        SizedBox(
          width: 420,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _settingsPageTitle('Print Settings', Icons.print_outlined),
                const SizedBox(height: 20),

                // Printer type tabs (Regular / Thermal)
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEF0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(children: [
                    for (final t in ['Regular', 'Thermal'])
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _editPrinterTab = t;
                            const reg = ['Classic','Simple','Modern','GST','Landscape'];
                            const thm = ['Theme 1','Theme 2','Theme 3','Theme 4','Theme 5'];
                            final valid = t == 'Regular' ? reg : thm;
                            if (!valid.contains(_editInvoiceLayout)) {
                              _editInvoiceLayout = t == 'Regular' ? 'Classic' : 'Theme 1';
                            }
                            _editPaperSize = t == 'Regular' ? 'A4' : '3 inch';
                            _previewRevision++;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: _editPrinterTab == t ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _editPrinterTab == t
                                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))]
                                  : [],
                            ),
                            child: Center(
                              child: Text('$t Printer',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: _editPrinterTab == t ? FontWeight.w600 : FontWeight.w400,
                                      color: _editPrinterTab == t ? const Color(0xFF1D1D1F) : const Color(0xFF6E6E73))),
                            ),
                          ),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 24),

                // Invoice layout themes
                _settingsSectionHeader('INVOICE LAYOUT'),
                const SizedBox(height: 12),
                Builder(builder: (context) {
                  const reg = ['Classic','Simple','Modern','GST','Landscape'];
                  const thm = ['Theme 1','Theme 2','Theme 3','Theme 4','Theme 5'];
                  final layouts = _editPrinterTab == 'Regular' ? reg : thm;
                  return SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      itemCount: layouts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final layout = layouts[i];
                        final selected = _editInvoiceLayout == layout;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _editInvoiceLayout = layout;
                              _invoiceLayout = layout;
                              _previewRevision++;
                            });
                            LocalDbService.saveSettings({'invoice_layout': layout});
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            width: 88,
                            height: 100,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withValues(alpha: 0.06)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected ? AppColors.primary : const Color(0xFFD8D8DC),
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _layoutThumb(layout, selected: selected),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(layout,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? AppColors.primary
                                              : const Color(0xFF6E6E73))),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // Company info
                _settingsSectionHeader('COMPANY INFO / HEADER'),
                const SizedBox(height: 8),
                _settingsCard([
                  _settingsTextField('Company Name', _editStoreName, (v) => setState(() => _editStoreName = v)),
                  _settingsDivider(),
                  _settingsTextField('Address', _editStoreAddress, (v) => setState(() => _editStoreAddress = v)),
                  _settingsDivider(),
                  _settingsTextField('Phone Number', _editStorePhone, (v) => setState(() => _editStorePhone = v), keyboardType: TextInputType.phone),
                  _settingsDivider(),
                  _settingsTextField('Email', _editStoreEmail, (v) => setState(() => _editStoreEmail = v), keyboardType: TextInputType.emailAddress),
                  _settingsDivider(),
                  _settingsTextField('GSTIN', _editStoreGstin, (v) => setState(() => _editStoreGstin = v)),
                  _settingsDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(children: [
                      Expanded(child: Text('Company Logo', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark))),
                      if (_editLogoPath.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(File(_editLogoPath), width: 40, height: 40, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox()),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _editLogoPath = ''),
                          child: Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                        ),
                        const SizedBox(width: 8),
                      ],
                      TextButton.icon(
                        onPressed: () async {
                          final r = await FilePicker.platform.pickFiles(type: FileType.image);
                          if (r != null) {
                            final copied = await LocalDbService.copyImageToAppDir(r.files.single.path!);
                            setState(() => _editLogoPath = copied);
                          }
                        },
                        icon: const Icon(Icons.upload_rounded, size: 16),
                        label: Text(_editLogoPath.isEmpty ? 'Upload' : 'Change'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: 24),

                // Page setup
                _settingsSectionHeader('PAGE SETUP'),
                const SizedBox(height: 8),
                _settingsCard([
                  _settingsDropdownRow('Paper Size',
                    _editPrinterTab == 'Regular' ? ['A4', 'A5'] : ['2 inch', '3 inch', '4 inch', 'Custom'],
                    _editPaperSize, (v) => setState(() { _editPaperSize = v!; _previewRevision++; })),
                  _settingsDivider(),
                  _settingsDropdownRow('Orientation', ['Portrait', 'Landscape'], _editPrintOrientation, (v) => setState(() { _editPrintOrientation = v!; _previewRevision++; })),
                ]),
                const SizedBox(height: 24),

                // Receipt footer
                _settingsSectionHeader('RECEIPT FOOTER'),
                const SizedBox(height: 8),
                _settingsCard([
                  _settingsTextField('Footer Text', _editReceiptFooter, (v) => setState(() => _editReceiptFooter = v), maxLines: 2),
                ]),
                const SizedBox(height: 24),

                // Terms & Conditions (used in Tax Invoice layout)
                _settingsSectionHeader('TERMS & CONDITIONS'),
                const SizedBox(height: 8),
                _settingsCard([
                  _settingsTextField('Terms & Conditions', _editStoreTerms, (v) => setState(() => _editStoreTerms = v), maxLines: 3),
                ]),
                const SizedBox(height: 24),

                // Auto print
                _settingsSectionHeader('OPTIONS'),
                const SizedBox(height: 8),
                _settingsCard([
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Auto Print', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1D1D1F))),
                        Text('Automatically print receipt after checkout',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6E6E73))),
                      ])),
                      Switch.adaptive(value: _editAutoPrint, onChanged: (v) => setState(() => _editAutoPrint = v), activeColor: AppColors.primary),
                    ]),
                  ),
                ]),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),

        // Vertical divider
        Container(width: 1, color: const Color(0xFFD8D8DC)),

        // ── Right: live preview ────────────────────────────────────────
        Expanded(
          child: Container(
            color: const Color(0xFFE8E8ED),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Preview header bar
                Container(
                  height: 44,
                  color: const Color(0xFFF2F2F7),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF6E6E73)),
                    const SizedBox(width: 6),
                    Text('Live Preview',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6E6E73))),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _printRecord(_testReceipt()),
                      icon: const Icon(Icons.print_outlined, size: 13),
                      label: Text('Print Test', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                  ]),
                ),
                Container(height: 1, color: const Color(0xFFD8D8DC)),
                // Preview body — renders the actual PDF bytes
                Expanded(
                  child: PdfPreview(
                    key: ValueKey(_previewRevision),
                    build: (_) => ReceiptPrinter.buildPdf(
                      _testReceipt(),
                      storeName: _editStoreName,
                      storeAddress: _editStoreAddress,
                      storePhone: _editStorePhone,
                      storeEmail: _editStoreEmail,
                      storeGstin: _editStoreGstin,
                      receiptFooter: _editReceiptFooter,
                      taxLabel: _editTaxLabel,
                      taxRate: _editTaxRate,
                      currencySymbol: _editCurrencySymbol,
                      paperSize: _editPaperSize,
                      orientation: _editPrintOrientation,
                      layout: _editInvoiceLayout,
                      storeTerms: _editStoreTerms,
                      logoPath: _editLogoPath,
                    ),
                    allowPrinting: false,
                    allowSharing: false,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                    useActions: false,
                    scrollViewDecoration: const BoxDecoration(color: Color(0xFF3C3C3C)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Layout theme thumbnail widget
  Widget _layoutThumb(String layout, {required bool selected}) {
    final c = selected ? AppColors.primary : const Color(0xFFBBBBBB);
    final line = (double w, double h) => Container(
          width: w, height: h,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(1)),
        );
    final gap = const SizedBox(height: 2.5);

    switch (layout) {
      case 'Classic':
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
          line(28, 3), gap, line(36, 1.5), gap, line(36, 1.5), gap, line(36, 1.5), gap, line(24, 3),
        ]);
      case 'Simple':
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
          line(24, 2.5), const SizedBox(height: 1.5), line(36, 1), const SizedBox(height: 1.5),
          line(36, 1), const SizedBox(height: 1.5), line(36, 1), const SizedBox(height: 1.5),
          line(36, 1), const SizedBox(height: 1.5), line(20, 2.5),
        ]);
      case 'Modern':
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(border: Border.all(color: c, width: 0.7))),
            const SizedBox(width: 2),
            Container(width: 10, height: 10, decoration: BoxDecoration(border: Border.all(color: c, width: 0.7))),
            const SizedBox(width: 2),
            Container(width: 10, height: 10, decoration: BoxDecoration(border: Border.all(color: c, width: 0.7))),
          ]), gap, line(36, 1.5), gap, line(36, 1.5), gap, line(36, 1.5), gap, line(22, 3),
        ]);
      case 'GST':
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
          line(28, 2.5), gap,
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 17, height: 12, decoration: BoxDecoration(border: Border.all(color: c, width: 0.7), borderRadius: BorderRadius.circular(1))),
            const SizedBox(width: 2),
            Container(width: 17, height: 12, decoration: BoxDecoration(border: Border.all(color: c, width: 0.7), borderRadius: BorderRadius.circular(1))),
          ]), gap, line(36, 8), gap,
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 20, height: 8, decoration: BoxDecoration(border: Border.all(color: c, width: 0.7), borderRadius: BorderRadius.circular(1))),
            const SizedBox(width: 2),
            Container(width: 14, height: 8, decoration: BoxDecoration(border: Border.all(color: c, width: 0.7), borderRadius: BorderRadius.circular(1))),
          ]), gap, line(22, 2.5),
        ]);
      case 'Landscape':
        return Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
          Column(mainAxisSize: MainAxisSize.min, children: [line(16, 3), gap, line(16, 1.5), gap, line(16, 1.5)]),
          const SizedBox(width: 3),
          Column(mainAxisSize: MainAxisSize.min, children: [line(18, 1.5), gap, line(18, 1.5), gap, line(18, 1.5), gap, line(12, 3)]),
        ]);
      // ── Thermal ───────────────────────────────────────────────────────────
      case 'Theme 1':
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
          line(22, 2.5), gap, line(28, 1), gap, line(28, 1), gap, line(28, 1), gap, line(16, 2.5),
        ]);
      case 'Theme 2':
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
          line(20, 2), const SizedBox(height: 1.5), line(28, 0.8), const SizedBox(height: 1.5),
          line(28, 0.8), const SizedBox(height: 1.5), line(28, 0.8), const SizedBox(height: 1.5),
          line(28, 0.8), const SizedBox(height: 1.5), line(28, 0.8), const SizedBox(height: 1.5), line(14, 2),
        ]);
      case 'Theme 3':
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
          line(22, 3), gap, line(28, 2), gap, line(28, 2), gap, line(18, 4),
        ]);
      case 'Theme 4':
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
          line(22, 2.5), gap, line(28, 1), gap, line(28, 1), gap,
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 7, height: 5, decoration: BoxDecoration(border: Border.all(color: c, width: 0.5))),
            const SizedBox(width: 1),
            Container(width: 7, height: 5, decoration: BoxDecoration(border: Border.all(color: c, width: 0.5))),
            const SizedBox(width: 1),
            Container(width: 7, height: 5, decoration: BoxDecoration(border: Border.all(color: c, width: 0.5))),
          ]), gap, line(16, 2.5),
        ]);
      case 'Theme 5':
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
          line(22, 2.5), gap,
          Row(mainAxisSize: MainAxisSize.min, children: [
            for (int i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Container(width: i == 1 ? 9 : 4, height: 3, color: c),
            ],
          ]), gap,
          for (int r = 0; r < 3; r++) ...[
            Row(mainAxisSize: MainAxisSize.min, children: [
              for (int i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                Container(width: i == 1 ? 9 : 4, height: 2.5, color: c.withValues(alpha: 0.5)),
              ],
            ]),
            const SizedBox(height: 2),
          ],
          line(16, 2.5),
        ]);
      default:
        return line(32, 20);
    }
  }

  // Receipt preview panel (Flutter-rendered, updates instantly)
  Widget _buildReceiptPreview() {
    if (_editInvoiceLayout == 'GST') return _buildTaxInvoicePreview();
    if (_editInvoiceLayout == 'Classic') return _buildClassicInvoicePreview();

    final isNarrow = _editPrinterTab == 'Thermal';
    final w = _editPaperSize == '2 inch' ? 175.0 : isNarrow ? 220.0 : _editPaperSize == 'A5' ? 260.0 : 310.0;
    final isGst = false;
    final isCompact = _editInvoiceLayout == 'Simple';
    final double fs = isCompact ? 7.0 : (isNarrow ? 8.0 : _editPaperSize == 'A5' ? 8.8 : 9.5);

    Widget sep() => Container(height: 0.5, color: const Color(0xFF888888), margin: EdgeInsets.symmetric(vertical: isCompact ? 3 : 5));
    Widget row(String l, String r, {bool bold = false, double? fsize}) => Row(children: [
          Expanded(child: Text(l, style: TextStyle(fontSize: fsize ?? fs, color: bold ? const Color(0xFF1D1D1F) : const Color(0xFF555555)))),
          Text(r, style: TextStyle(fontSize: fsize ?? fs, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: const Color(0xFF1D1D1F))),
        ]);

    return LayoutBuilder(builder: (context, constraints) {
      final scale = ((constraints.maxWidth - 48) / w).clamp(1.0, 4.0);
      return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Center(
        child: SizedBox(
          width: w * scale,
          child: FittedBox(
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: w,
              child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          padding: EdgeInsets.all(isNarrow ? 10 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Center(child: Text(
                _editStoreName.isEmpty ? 'BillCat Store' : _editStoreName,
                style: TextStyle(fontSize: fs + 3, fontWeight: FontWeight.bold, color: const Color(0xFF1D1D1F)),
                textAlign: TextAlign.center,
              )),
              if (_editStoreAddress.isNotEmpty) ...[
                const SizedBox(height: 2),
                Center(child: Text(_editStoreAddress, style: TextStyle(fontSize: fs - 1, color: const Color(0xFF777777)), textAlign: TextAlign.center)),
              ],
              if (_editStorePhone.isNotEmpty) ...[
                const SizedBox(height: 1),
                Center(child: Text('Tel: $_editStorePhone', style: TextStyle(fontSize: fs - 1, color: const Color(0xFF777777)))),
              ],
              if (_editStoreEmail.isNotEmpty) ...[
                const SizedBox(height: 1),
                Center(child: Text(_editStoreEmail, style: TextStyle(fontSize: fs - 1, color: const Color(0xFF777777)))),
              ],
              if (isGst && _editStoreGstin.isNotEmpty) ...[
                const SizedBox(height: 1),
                Center(child: Text('GSTIN: $_editStoreGstin', style: TextStyle(fontSize: fs - 1, color: const Color(0xFF555555)))),
              ],
              sep(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Bill #A1B2C3D4', style: TextStyle(fontSize: fs - 1.5, color: const Color(0xFF888888))),
                Text('28/04/2026  14:30', style: TextStyle(fontSize: fs - 1.5, color: const Color(0xFF888888))),
              ]),
              SizedBox(height: isCompact ? 2 : 3),
              Text('Customer: Sample Customer', style: TextStyle(fontSize: fs - 1.5, color: const Color(0xFF888888))),
              sep(),
              // Column headers
              Row(children: [
                Expanded(flex: 5, child: Text('ITEM', style: TextStyle(fontSize: fs - 1, fontWeight: FontWeight.bold, color: const Color(0xFF888888)))),
                Text('QTY', style: TextStyle(fontSize: fs - 1, fontWeight: FontWeight.bold, color: const Color(0xFF888888))),
                const SizedBox(width: 8),
                Text('TOTAL', style: TextStyle(fontSize: fs - 1, fontWeight: FontWeight.bold, color: const Color(0xFF888888))),
              ]),
              SizedBox(height: isCompact ? 2 : 4),
              // Sample items
              for (final item in [('Sample Product A', 'x2', '${_editCurrencySymbol}500'), ('Sample Product B', 'x1', '${_editCurrencySymbol}180')])
                Padding(
                  padding: EdgeInsets.symmetric(vertical: isCompact ? 1 : 2),
                  child: Row(children: [
                    Expanded(flex: 5, child: Text(item.$1, style: TextStyle(fontSize: fs, color: const Color(0xFF1D1D1F)))),
                    Text(item.$2, style: TextStyle(fontSize: fs, color: const Color(0xFF555555))),
                    const SizedBox(width: 8),
                    Text(item.$3, style: TextStyle(fontSize: fs, fontWeight: FontWeight.bold, color: const Color(0xFF1D1D1F))),
                  ]),
                ),
              sep(),
              row('Subtotal', '${_editCurrencySymbol}680'),
              row('$_editTaxLabel ($_editTaxRate%)', '${_editCurrencySymbol}${(680 * (double.tryParse(_editTaxRate) ?? 18) / 100).toStringAsFixed(2)}'),
              SizedBox(height: isCompact ? 2 : 3),
              Container(height: 1, color: const Color(0xFF1D1D1F)),
              SizedBox(height: isCompact ? 2 : 3),
              row('TOTAL', '${_editCurrencySymbol}${(680 * (1 + (double.tryParse(_editTaxRate) ?? 18) / 100)).toStringAsFixed(2)}', bold: true, fsize: fs + 2),
              SizedBox(height: isCompact ? 1 : 2),
              row('Payment', 'CASH'),
              // GST table
              if (isGst) ...[
                sep(),
                Text('Tax Summary', style: TextStyle(fontSize: fs - 0.5, fontWeight: FontWeight.bold, color: const Color(0xFF555555))),
                const SizedBox(height: 3),
                Container(
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCCCCCC), width: 0.5)),
                  child: Column(children: [
                    Container(color: const Color(0xFFF5F5F5), padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(children: [
                        Expanded(child: Text('HSN', style: TextStyle(fontSize: fs - 1.5, fontWeight: FontWeight.bold))),
                        Expanded(child: Text('Taxable', style: TextStyle(fontSize: fs - 1.5, fontWeight: FontWeight.bold))),
                        Expanded(child: Text('CGST', style: TextStyle(fontSize: fs - 1.5, fontWeight: FontWeight.bold))),
                        Expanded(child: Text('SGST', style: TextStyle(fontSize: fs - 1.5, fontWeight: FontWeight.bold))),
                        Expanded(child: Text('Total', style: TextStyle(fontSize: fs - 1.5, fontWeight: FontWeight.bold))),
                      ]),
                    ),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(children: [
                        Expanded(child: Text('1234', style: TextStyle(fontSize: fs - 1.5))),
                        Expanded(child: Text('${_editCurrencySymbol}680', style: TextStyle(fontSize: fs - 1.5))),
                        Expanded(child: Text('${_editCurrencySymbol}61', style: TextStyle(fontSize: fs - 1.5))),
                        Expanded(child: Text('${_editCurrencySymbol}61', style: TextStyle(fontSize: fs - 1.5))),
                        Expanded(child: Text('${_editCurrencySymbol}122', style: TextStyle(fontSize: fs - 1.5))),
                      ]),
                    ),
                  ]),
                ),
              ],
              sep(),
              Center(child: Text(
                _editReceiptFooter.isEmpty ? 'Thank you for your purchase!' : _editReceiptFooter,
                style: TextStyle(fontSize: fs - 1, color: const Color(0xFF888888)),
                textAlign: TextAlign.center,
              )),
            ],
          ),
        ),
            ),
          ),
        ),
      ),
    );
    });
  }

  // Tax Invoice A4 preview (Flutter-rendered)
  Widget _buildTaxInvoicePreview() {
    const fs = 8.5;
    const c555 = Color(0xFF555555);
    const c888 = Color(0xFF888888);
    const c1d = Color(0xFF1D1D1F);
    const cBorder = Color(0xFFCCCCCC);

    Widget sep() => Container(height: 0.5, color: c888, margin: const EdgeInsets.symmetric(vertical: 5));

    Widget labelVal(String lbl, String val) => Row(children: [
          SizedBox(width: 70, child: Text(lbl, style: const TextStyle(fontSize: fs - 1, color: c888))),
          Text(': ', style: const TextStyle(fontSize: fs - 1, color: c888)),
          Expanded(child: Text(val, style: const TextStyle(fontSize: fs - 1, fontWeight: FontWeight.bold, color: c1d))),
        ]);

    Widget totalRow(String l, String r, {bool bold = false, double fsize = fs}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: Row(children: [
            Expanded(child: Text(l, style: TextStyle(fontSize: fsize, color: c555))),
            Text(r, style: TextStyle(fontSize: fsize, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: c1d)),
          ]),
        );

    final taxPct = double.tryParse(_editTaxRate) ?? 18.0;
    final cgst = (680 * taxPct / 100) / 2;

    return LayoutBuilder(builder: (context, constraints) {
      const cardW = 380.0;
      final scale = ((constraints.maxWidth - 48) / cardW).clamp(1.0, 4.0);
      return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Center(
        child: SizedBox(
          width: cardW * scale,
          child: FittedBox(
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: cardW,
              child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              const Center(
                child: Text('TAX INVOICE',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF2D2D2D))),
              ),
              const SizedBox(height: 8),
              // Company header
              Text(_editStoreName.isEmpty ? 'BillCat Store' : _editStoreName,
                  style: const TextStyle(fontSize: fs + 1, fontWeight: FontWeight.bold, color: c1d)),
              if (_editStoreAddress.isNotEmpty)
                Text(_editStoreAddress, style: const TextStyle(fontSize: fs - 1, color: c888)),
              if (_editStorePhone.isNotEmpty)
                Text('Phone: $_editStorePhone', style: const TextStyle(fontSize: fs - 1, color: c888)),
              if (_editStoreGstin.isNotEmpty)
                Text('GSTIN: $_editStoreGstin', style: const TextStyle(fontSize: fs, fontWeight: FontWeight.bold, color: c555)),
              sep(),
              // Bill To / Invoice Details two-column
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(border: Border.all(color: cBorder, width: 0.5), borderRadius: BorderRadius.circular(3)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Bill To:', style: TextStyle(fontSize: fs - 1.5, fontWeight: FontWeight.bold, color: c888)),
                      const SizedBox(height: 3),
                      const Text('Walk-In Customer', style: TextStyle(fontSize: fs, fontWeight: FontWeight.bold, color: c1d)),
                      const Text('9876543210', style: TextStyle(fontSize: fs - 1, color: c888)),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(border: Border.all(color: cBorder, width: 0.5), borderRadius: BorderRadius.circular(3)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Invoice Details:', style: TextStyle(fontSize: fs - 1.5, fontWeight: FontWeight.bold, color: c888)),
                      const SizedBox(height: 3),
                      labelVal('Invoice No.', 'INV-A1B2C3D4'),
                      labelVal('Date', '28/04/2026'),
                      labelVal('Time', '14:30'),
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              // Items table header
              Container(
                color: const Color(0xFF2D2D2D),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: Row(children: const [
                  SizedBox(width: 14, child: Text('#', style: TextStyle(fontSize: fs - 2, color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(flex: 4, child: Text('Item', style: TextStyle(fontSize: fs - 2, color: Colors.white, fontWeight: FontWeight.bold))),
                  SizedBox(width: 24, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontSize: fs - 2, color: Colors.white, fontWeight: FontWeight.bold))),
                  SizedBox(width: 44, child: Text('Price', textAlign: TextAlign.right, style: TextStyle(fontSize: fs - 2, color: Colors.white, fontWeight: FontWeight.bold))),
                  SizedBox(width: 44, child: Text('Amount', textAlign: TextAlign.right, style: TextStyle(fontSize: fs - 2, color: Colors.white, fontWeight: FontWeight.bold))),
                ]),
              ),
              // Items
              for (final item in [('1', 'Sample Product A', '2', '250.00', '500.00'), ('2', 'Sample Product B', '1', '180.00', '180.00')])
                Container(
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: cBorder, width: 0.5))),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: Row(children: [
                    SizedBox(width: 14, child: Text(item.$1, style: const TextStyle(fontSize: fs - 2, color: c555))),
                    Expanded(flex: 4, child: Text(item.$2, style: const TextStyle(fontSize: fs - 1, color: c1d))),
                    SizedBox(width: 24, child: Text(item.$3, textAlign: TextAlign.center, style: const TextStyle(fontSize: fs - 1, color: c555))),
                    SizedBox(width: 44, child: Text('$_editCurrencySymbol${item.$4}', textAlign: TextAlign.right, style: const TextStyle(fontSize: fs - 1, color: c555))),
                    SizedBox(width: 44, child: Text('$_editCurrencySymbol${item.$5}', textAlign: TextAlign.right, style: const TextStyle(fontSize: fs - 1, fontWeight: FontWeight.bold, color: c1d))),
                  ]),
                ),
              const SizedBox(height: 8),
              // Tax summary + totals
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Tax summary
                Expanded(
                  flex: 55,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Tax Summary:', style: TextStyle(fontSize: fs, fontWeight: FontWeight.bold, color: c555)),
                    const SizedBox(height: 3),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: cBorder, width: 0.5)),
                      child: Column(children: [
                        Container(
                          color: const Color(0xFF5A5A5A),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(children: const [
                            Expanded(child: Text('Tax%', style: TextStyle(fontSize: fs - 2.5, color: Colors.white, fontWeight: FontWeight.bold))),
                            Expanded(child: Text('CGST', textAlign: TextAlign.right, style: TextStyle(fontSize: fs - 2.5, color: Colors.white, fontWeight: FontWeight.bold))),
                            Expanded(child: Text('SGST', textAlign: TextAlign.right, style: TextStyle(fontSize: fs - 2.5, color: Colors.white, fontWeight: FontWeight.bold))),
                            Expanded(child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontSize: fs - 2.5, color: Colors.white, fontWeight: FontWeight.bold))),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(children: [
                            Expanded(child: Text('$_editTaxRate%', style: const TextStyle(fontSize: fs - 2.5, color: c555))),
                            Expanded(child: Text('$_editCurrencySymbol${cgst.toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: fs - 2.5, color: c555))),
                            Expanded(child: Text('$_editCurrencySymbol${cgst.toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: fs - 2.5, color: c555))),
                            Expanded(child: Text('$_editCurrencySymbol${(cgst * 2).toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: fs - 2.5, color: c555))),
                          ]),
                        ),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(width: 10),
                // Totals
                Expanded(
                  flex: 42,
                  child: Column(children: [
                    totalRow('Sub Total', '$_editCurrencySymbol 680.00'),
                    totalRow('CGST', '$_editCurrencySymbol${cgst.toStringAsFixed(2)}'),
                    totalRow('SGST', '$_editCurrencySymbol${cgst.toStringAsFixed(2)}'),
                    const Divider(height: 8, thickness: 0.5),
                    totalRow('Total', '$_editCurrencySymbol${(680 + cgst * 2).toStringAsFixed(2)}', bold: true, fsize: fs + 1),
                  ]),
                ),
              ]),
              sep(),
              // Amount in words
              RichText(text: TextSpan(children: [
                const TextSpan(text: 'Amount In Words: ', style: TextStyle(fontSize: fs - 1, fontWeight: FontWeight.bold, color: c555)),
                TextSpan(text: 'Six Hundred Eighty Rupees Only', style: const TextStyle(fontSize: fs - 1, color: c888)),
              ])),
              sep(),
              // Footer
              if (_editReceiptFooter.isNotEmpty || _editStoreTerms.isNotEmpty)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (_editReceiptFooter.isNotEmpty)
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Description:', style: TextStyle(fontSize: fs - 1, fontWeight: FontWeight.bold, color: c555)),
                      const SizedBox(height: 2),
                      Text(_editReceiptFooter, style: const TextStyle(fontSize: fs - 2, color: c888)),
                    ])),
                  if (_editReceiptFooter.isNotEmpty && _editStoreTerms.isNotEmpty) const SizedBox(width: 8),
                  if (_editStoreTerms.isNotEmpty)
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Terms & Conditions:', style: TextStyle(fontSize: fs - 1, fontWeight: FontWeight.bold, color: c555)),
                      const SizedBox(height: 2),
                      Text(_editStoreTerms, style: const TextStyle(fontSize: fs - 2, color: c888)),
                    ])),
                ]),
            ],
          ),
        ),
            ),
          ),
        ),
      ),
    );
    });
  }

  // Classic Tax Invoice preview (Flutter-rendered)
  Widget _buildClassicInvoicePreview() {
    const w = 310.0;
    const fs = 7.5;
    const c1d = Color(0xFF1D1D1F);
    const c55 = Color(0xFF555555);
    const c88 = Color(0xFF888888);
    const cBorder = Color(0xFFCCCCCC);
    const cGrey = Color(0xFFF0F0F0);

    final invoiceNo = 'Inv. PREVIEW';
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2,'0')}-${now.month.toString().padLeft(2,'0')}-${now.year}';

    Widget cell(String v, {bool bold = false, Color? c, TextAlign a = TextAlign.left, double? size}) =>
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: Text(v, textAlign: a,
            style: TextStyle(fontSize: size ?? fs - 1, fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: c ?? c1d)));

    Widget greyHeader(String t) => Container(color: cGrey,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(t, style: TextStyle(fontSize: fs - 0.5, fontWeight: FontWeight.w700, color: c1d)));

    Widget detLine(String lbl, String val) => Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(children: [
        Text(lbl, style: TextStyle(fontSize: fs - 1.5, color: c88)),
        Text(': ', style: TextStyle(fontSize: fs - 1.5, color: c88)),
        Text(val, style: TextStyle(fontSize: fs - 1.5, color: c1d)),
      ]));

    Widget totLine(String lbl, String val, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(lbl, style: TextStyle(fontSize: fs - 1.5, color: bold ? c1d : c55, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
        Text(val, style: TextStyle(fontSize: fs - 1.5, color: bold ? c1d : c55, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
      ]));

    return LayoutBuilder(builder: (context, constraints) {
      final scale = ((constraints.maxWidth - 48) / w).clamp(1.0, 4.0);
      return SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: w * scale,
            child: FittedBox(
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: w,
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: cBorder, width: 0.8)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    // Title
                    Container(
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cBorder))),
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Center(child: Text('Tax Invoice', style: TextStyle(fontSize: fs + 1, fontWeight: FontWeight.w700, color: c1d))),
                    ),
                    // Company info (left) | Invoice details (right)
                    IntrinsicHeight(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Expanded(flex: 55, child: Container(
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cBorder))),
                          padding: const EdgeInsets.all(8),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(width: 44, height: 44, decoration: BoxDecoration(color: cGrey, border: Border.all(color: cBorder, width: 0.5)),
                              child: _editLogoPath.isNotEmpty
                                  ? ClipRRect(child: Image.file(File(_editLogoPath), width: 44, height: 44, fit: BoxFit.cover))
                                  : Center(child: Text('IMG', style: TextStyle(fontSize: 7, color: c88)))),
                            const SizedBox(width: 8),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(_editStoreName.isNotEmpty ? _editStoreName : 'Company',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c1d)),
                              if (_editStoreAddress.isNotEmpty) Text(_editStoreAddress,
                                style: TextStyle(fontSize: fs - 2, color: c55)),
                              if (_editStorePhone.isNotEmpty) RichText(text: TextSpan(children: [
                                TextSpan(text: 'Phone: ', style: TextStyle(fontSize: fs - 2, color: c88)),
                                TextSpan(text: _editStorePhone, style: TextStyle(fontSize: fs - 2, fontWeight: FontWeight.w700, color: c1d)),
                              ])),
                              if (_editStoreEmail.isNotEmpty) RichText(text: TextSpan(children: [
                                TextSpan(text: 'Email: ', style: TextStyle(fontSize: fs - 2, color: c88)),
                                TextSpan(text: _editStoreEmail, style: TextStyle(fontSize: fs - 2, fontWeight: FontWeight.w700, color: c1d)),
                              ])),
                            ])),
                          ]),
                        )),
                        Container(width: 0.5, color: cBorder),
                        Expanded(flex: 45, child: Container(
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cBorder))),
                          padding: const EdgeInsets.all(8),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            detLine('Invoice No.', invoiceNo),
                            detLine('Date', dateStr),
                            detLine('Time', '12:00 PM'),
                            detLine('Due Date', dateStr),
                          ]),
                        )),
                      ]),
                    ),
                    // Bill To | Invoice Details
                    IntrinsicHeight(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Expanded(flex: 55, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          greyHeader('Bill To:'),
                          Padding(padding: const EdgeInsets.all(6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Sample Customer', style: TextStyle(fontSize: fs - 1, color: c1d)),
                            Text('Contact No.: 9999999999', style: TextStyle(fontSize: fs - 2, color: c55)),
                            const SizedBox(height: 8),
                          ])),
                        ])),
                        Container(width: 0.5, color: cBorder),
                        Expanded(flex: 45, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          greyHeader('Invoice Details:'),
                          Padding(padding: const EdgeInsets.all(6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            detLine('Invoice No.', invoiceNo),
                            detLine('Date', dateStr),
                            detLine('Time', '12:00 PM'),
                            detLine('Due Date', dateStr),
                          ])),
                        ])),
                      ]),
                    ),
                    Container(height: 0.5, color: cBorder),
                    // Ship To
                    greyHeader('Ship To:'),
                    Container(
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cBorder))),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: Text('—', style: TextStyle(fontSize: fs - 1, color: c55)),
                    ),
                    // Items header
                    Container(color: cGrey,
                      child: Row(children: [
                        for (final h in [('#', 14.0, TextAlign.center), ('Item name', 80.0, TextAlign.left),
                          ('HSC/SAC', 38.0, TextAlign.center), ('Qty', 28.0, TextAlign.center),
                          ('Price', 38.0, TextAlign.right), ('Disc', 36.0, TextAlign.right),
                          ('GST', 34.0, TextAlign.right), ('Amt', 36.0, TextAlign.right)])
                          SizedBox(width: h.$2, child: cell(h.$1, bold: true, a: h.$3)),
                      ])),
                    Container(height: 0.5, color: cBorder),
                    // Sample rows
                    for (final row in [('1','Sample Product A','—','2','₹250','₹0','₹0','₹500'), ('2','Sample Product B','—','1','₹180','₹0','₹0','₹180')])
                      Column(children: [
                        Row(children: [
                          SizedBox(width: 14, child: cell(row.$1, a: TextAlign.center)),
                          SizedBox(width: 80, child: cell(row.$2, bold: true)),
                          SizedBox(width: 38, child: cell(row.$3, a: TextAlign.center)),
                          SizedBox(width: 28, child: cell(row.$4, a: TextAlign.center)),
                          SizedBox(width: 38, child: cell(row.$5, a: TextAlign.right)),
                          SizedBox(width: 36, child: cell(row.$6, a: TextAlign.right)),
                          SizedBox(width: 34, child: cell(row.$7, a: TextAlign.right)),
                          SizedBox(width: 36, child: cell(row.$8, bold: true, a: TextAlign.right)),
                        ]),
                        Container(height: 0.5, color: cBorder),
                      ]),
                    // TOTAL row
                    Container(color: cGrey,
                      child: Row(children: [
                        const SizedBox(width: 14),
                        SizedBox(width: 80, child: cell('TOTAL', bold: true)),
                        const SizedBox(width: 38),
                        SizedBox(width: 28, child: cell('3', bold: true, a: TextAlign.center)),
                        const SizedBox(width: 38),
                        SizedBox(width: 36, child: cell('₹0', bold: true, a: TextAlign.right)),
                        SizedBox(width: 34, child: cell('₹0', bold: true, a: TextAlign.right)),
                        SizedBox(width: 36, child: cell('₹680', bold: true, a: TextAlign.right)),
                      ])),
                    Container(height: 0.5, color: cBorder),
                    // Tax Summary | Totals
                    IntrinsicHeight(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Expanded(flex: 55, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          // Tax table header
                          Container(color: cGrey, child: Row(children: [
                            SizedBox(width: 28, child: cell('HSN', bold: true, a: TextAlign.center, size: fs - 3)),
                            Container(width: 0.5, color: cBorder),
                            SizedBox(width: 38, child: cell('Taxable', bold: true, a: TextAlign.center, size: fs - 3)),
                            Container(width: 0.5, color: cBorder),
                            Expanded(child: Column(children: [
                              Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cBorder))),
                                child: Center(child: Text('CGST', style: TextStyle(fontSize: fs - 3, fontWeight: FontWeight.w700)))),
                              Row(children: [
                                Expanded(child: Center(child: Text('Rate', style: TextStyle(fontSize: fs - 3.5)))),
                                Container(width: 0.5, color: cBorder),
                                Expanded(child: Center(child: Text('Amt', style: TextStyle(fontSize: fs - 3.5)))),
                              ]),
                            ])),
                            Container(width: 0.5, color: cBorder),
                            Expanded(child: Column(children: [
                              Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cBorder))),
                                child: Center(child: Text('SGST', style: TextStyle(fontSize: fs - 3, fontWeight: FontWeight.w700)))),
                              Row(children: [
                                Expanded(child: Center(child: Text('Rate', style: TextStyle(fontSize: fs - 3.5)))),
                                Container(width: 0.5, color: cBorder),
                                Expanded(child: Center(child: Text('Amt', style: TextStyle(fontSize: fs - 3.5)))),
                              ]),
                            ])),
                            Container(width: 0.5, color: cBorder),
                            SizedBox(width: 32, child: cell('Total Tax', bold: true, a: TextAlign.center, size: fs - 3)),
                          ])),
                          Container(height: 0.5, color: cBorder),
                          // Data row
                          Row(children: [
                            SizedBox(width: 28, child: cell('—', a: TextAlign.center, size: fs - 2.5)),
                            Container(width: 0.5, color: cBorder),
                            SizedBox(width: 38, child: cell('₹680', a: TextAlign.right, size: fs - 2.5)),
                            Container(width: 0.5, color: cBorder),
                            Expanded(child: Row(children: [
                              Expanded(child: cell('${_editTaxRate}%', a: TextAlign.right, size: fs - 2.5)),
                              Container(width: 0.5, color: cBorder),
                              Expanded(child: cell('₹0', a: TextAlign.right, size: fs - 2.5)),
                            ])),
                            Container(width: 0.5, color: cBorder),
                            Expanded(child: Row(children: [
                              Expanded(child: cell('${_editTaxRate}%', a: TextAlign.right, size: fs - 2.5)),
                              Container(width: 0.5, color: cBorder),
                              Expanded(child: cell('₹0', a: TextAlign.right, size: fs - 2.5)),
                            ])),
                            Container(width: 0.5, color: cBorder),
                            SizedBox(width: 32, child: cell('₹0', a: TextAlign.right, size: fs - 2.5)),
                          ]),
                          Container(height: 0.5, color: cBorder),
                          // Payment mode
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: RichText(text: TextSpan(children: [
                              TextSpan(text: 'Payment Mode: ', style: TextStyle(fontSize: fs - 1.5, color: c88)),
                              TextSpan(text: 'Cash', style: TextStyle(fontSize: fs - 1.5, fontWeight: FontWeight.w700, color: c1d)),
                            ]))),
                        ])),
                        Container(width: 0.5, color: cBorder),
                        // Totals right column
                        Expanded(flex: 45, child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            totLine('Sub Total', '₹680.00'),
                            totLine('Tax ($_editTaxRate%)', '₹0.00'),
                            Container(height: 0.5, color: cBorder, margin: const EdgeInsets.symmetric(vertical: 3)),
                            totLine('Total', '$_editCurrencySymbol 680.00', bold: true),
                            const SizedBox(height: 4),
                            Text('Invoice Amount In Words:', style: TextStyle(fontSize: fs - 2, color: c55, fontWeight: FontWeight.w700)),
                            Text('Six Hundred Eighty only', style: TextStyle(fontSize: fs - 2.5, color: c88)),
                            const SizedBox(height: 3),
                            totLine('Received', '₹680.00'),
                            totLine('Balance', '₹0.00'),
                          ]),
                        )),
                      ]),
                    ),
                    Container(height: 0.5, color: cBorder),
                    // Footer
                    IntrinsicHeight(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Expanded(flex: 55, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          greyHeader('Description:'),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(_editReceiptFooter.isNotEmpty ? _editReceiptFooter : 'Sale Description',
                              style: TextStyle(fontSize: fs - 2, color: c55))),
                          Container(height: 0.5, color: cBorder),
                          greyHeader('Bank Details:'),
                          Padding(padding: const EdgeInsets.all(6),
                            child: Row(children: [
                              Container(width: 30, height: 30, color: cGrey,
                                child: Center(child: Text('QR', style: TextStyle(fontSize: 7, color: c88)))),
                              const SizedBox(width: 6),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Bank Name: —', style: TextStyle(fontSize: fs - 2.5, color: c55)),
                                Text('Account No.: —', style: TextStyle(fontSize: fs - 2.5, color: c55)),
                                Text('IFSC Code: —', style: TextStyle(fontSize: fs - 2.5, color: c55)),
                              ]),
                            ])),
                        ])),
                        Container(width: 0.5, color: cBorder),
                        Expanded(flex: 45, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          greyHeader('Terms & Conditions:'),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(_editStoreTerms.isNotEmpty ? _editStoreTerms : 'Thanks for doing business with us!',
                              style: TextStyle(fontSize: fs - 2, color: c55))),
                          Container(height: 0.5, color: cBorder),
                          greyHeader('For: ${_editStoreName.isNotEmpty ? _editStoreName : "Company"}:'),
                          Padding(padding: const EdgeInsets.all(6),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                              Container(width: 40, height: 34, color: cGrey,
                                child: Center(child: Text('Image', style: TextStyle(fontSize: 7, color: c88)))),
                              const SizedBox(height: 3),
                              Text('Authorized Signatory', style: TextStyle(fontSize: fs - 2, color: c55)),
                            ])),
                        ])),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _settingsDropdownRow(String label, List<String> options, String value, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        SizedBox(
          width: 130,
          child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1D1D1F))),
        ),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: options.map((o) => DropdownMenuItem(value: o,
                  child: Text(o, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1D1D1F))))).toList(),
              onChanged: onChanged,
              alignment: Alignment.centerRight,
              isDense: true,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1D1D1F)),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Account ──
  Widget _buildSettingsAccount() {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    final name = user?.userMetadata?['full_name'] as String? ?? 'User';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _settingsPageTitle('Account', Icons.person_outline_rounded),
        const SizedBox(height: 24),
        _settingsCard([
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1D1D1F))),
                      Text(email,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: const Color(0xFF6E6E73))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 24),
        _settingsCard([
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _manualCheckForUpdate,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    _isCheckingUpdate
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.system_update_alt_rounded,
                            size: 18, color: Color(0xFF1D1D1F)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Check for Updates',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1D1D1F))),
                    ),
                    if (_updateInfo != null && !_updateDismissed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('v${_updateInfo!.version} available',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      )
                    else
                      Text('v${_appVersion()}',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: const Color(0xFF6E6E73))),
                  ],
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _settingsCard([
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () async {
                setState(() => _showSettings = false);
                await Future.delayed(const Duration(milliseconds: 200));
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded,
                        size: 18, color: Colors.red),
                    const SizedBox(width: 12),
                    Text('Sign Out',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.red)),
                  ],
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Center(
          child: Text('BillCat v${_appVersion()}',
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF6E6E73))),
        ),
      ],
    );
  }

  Widget _buildSettingsSecurity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _settingsPageTitle('Security', Icons.shield_outlined),
        const SizedBox(height: 24),
        _settingsSectionHeader('STAFF ACCESS CONTROL'),
        const SizedBox(height: 12),
        _settingsCard([
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              const Icon(Icons.admin_panel_settings_outlined, size: 18, color: Color(0xFF1D1D1F)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Enable Staff Mode',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1D1D1F))),
                const SizedBox(height: 2),
                Text('Hide Dashboard & Reports from staff. A passcode unlocks owner access.',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6E6E73))),
              ])),
              Switch(
                value: _ownerLockEnabled,
                activeColor: AppColors.primary,
                onChanged: (val) async {
                  if (val) {
                    // Enabling — require a passcode first
                    if (_ownerPasscode.isEmpty) {
                      _showSetPasscodeDialog(isFirstTime: true, onSet: () async {
                        setState(() { _ownerLockEnabled = true; _isOwnerMode = true; });
                        await LocalDbService.saveSettings({'owner_lock_enabled': '1'});
                        ConnectivityService.instance.syncNow();
                      });
                    } else {
                      setState(() { _ownerLockEnabled = true; _isOwnerMode = true; });
                      await LocalDbService.saveSettings({'owner_lock_enabled': '1'});
                      ConnectivityService.instance.syncNow();
                    }
                  } else {
                    setState(() { _ownerLockEnabled = false; _isOwnerMode = false; });
                    await LocalDbService.saveSettings({'owner_lock_enabled': '0'});
                    ConnectivityService.instance.syncNow();
                  }
                },
              ),
            ]),
          ),
        ]),
        if (_ownerLockEnabled) ...[
          const SizedBox(height: 16),
          _settingsSectionHeader('OWNER PASSCODE'),
          const SizedBox(height: 12),
          _settingsCard([
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _showSetPasscodeDialog(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(children: [
                    const Icon(Icons.pin_outlined, size: 18, color: Color(0xFF1D1D1F)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_ownerPasscode.isEmpty ? 'Set Passcode' : 'Change Passcode',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1D1D1F)))),
                    Text(_ownerPasscode.isEmpty ? 'Not set' : '••••',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6E6E73))),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFAAAAAA)),
                  ]),
                ),
              ),
            ),
          ]),
        ],
      ],
    );
  }

  // ── Settings UI helpers ──

  Widget _settingsPageTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1D1F))),
      ],
    );
  }

  Widget _settingsSectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 6),
        child: Row(children: [
          Text(text,
              style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8E8E93),
                  letterSpacing: 0.8)),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 0.5, color: const Color(0xFFD8D8DC))),
        ]),
      );

  Widget _settingsCard(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E8ED), width: 0.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );

  Widget _settingsDivider() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Divider(height: 1, color: Color(0xFFF2F2F7)),
      );

  Widget _settingsTextField(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      constraints: BoxConstraints(minHeight: maxLines > 1 ? 0 : 46),
      padding: EdgeInsets.symmetric(
          horizontal: 16, vertical: maxLines > 1 ? 12 : 0),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13.5, color: const Color(0xFF3C3C43))),
          ),
          Expanded(
            child: TextFormField(
              initialValue: value,
              onChanged: onChanged,
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: GoogleFonts.inter(
                  fontSize: 13.5, color: const Color(0xFF1D1D1F)),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: label,
                hintStyle: GoogleFonts.inter(
                    fontSize: 13.5, color: const Color(0xFFC7C7CC)),
                isDense: true,
                contentPadding: maxLines > 1
                    ? const EdgeInsets.symmetric(vertical: 4)
                    : EdgeInsets.zero,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _appVersion() => _currentVersion.isNotEmpty ? _currentVersion : '1.0.0';

  // ── Settings dialog (legacy — kept for reference) ─────────────────────────────────────────────

  void _showSettingsDialog() {
    String storeName = _storeName;
    String storeAddress = _storeAddress;
    String receiptFooter = _receiptFooter;
    String taxLabel = _taxLabel;
    String taxRate = _taxRateDisplay;
    String currencyCode = _currencyCode;
    String currencySymbol = _currencySymbol;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.settings_rounded,
                          size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Text('Settings',
                        style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      style: IconButton.styleFrom(
                          foregroundColor: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 20),

                // Store info
                _dialogSectionLabel('STORE INFORMATION'),
                const SizedBox(height: 14),
                _dialogField('Store Name', storeName,
                    (v) => setLocal(() => storeName = v)),
                const SizedBox(height: 12),
                _dialogField('Store Address', storeAddress,
                    (v) => setLocal(() => storeAddress = v)),
                const SizedBox(height: 12),
                _dialogField('Receipt Footer', receiptFooter,
                    (v) => setLocal(() => receiptFooter = v)),
                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 20),

                // Tax config
                _dialogSectionLabel('TAX CONFIGURATION'),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                        child: _dialogField('Tax Label', taxLabel,
                            (v) => setLocal(() => taxLabel = v))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _dialogField('Tax Rate (%)', taxRate,
                            (v) => setLocal(() => taxRate = v),
                            keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 20),

                // Currency
                _dialogSectionLabel('CURRENCY'),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () async {
                    final result = await _showCurrencyPicker(ctx, currencyCode);
                    if (result != null) {
                      setLocal(() {
                        currencyCode = result.code;
                        currencySymbol = result.symbol;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _currencies.firstWhere((c) => c.code == currencyCode,
                              orElse: () => _currencies.first).flag,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$currencyCode  $currencySymbol',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                              Text(_currencies.firstWhere((c) => c.code == currencyCode,
                                  orElse: () => _currencies.first).name,
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w300, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        const Icon(Icons.unfold_more_rounded, size: 18, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel',
                          style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _storeName =
                              storeName.trim().isEmpty ? 'BillCat Store' : storeName.trim();
                          _storeAddress = storeAddress.trim();
                          _receiptFooter = receiptFooter.trim();
                          _taxLabel =
                              taxLabel.trim().isEmpty ? 'VAT' : taxLabel.trim();
                          _taxRateDisplay =
                              taxRate.trim().isEmpty ? '0' : taxRate.trim();
                          _syncTaxRate();
                          _currencyCode = currencyCode;
                          _currencySymbol = currencySymbol;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: Text('Save Changes',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogSectionLabel(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 1.0));

  Widget _dialogField(String label, String value, Function(String) onChanged,
      {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
      ],
    );
  }

  // ── Currency picker ──────────────────────────────────────────────────────────

  Future<_Currency?> _showCurrencyPicker(BuildContext ctx, String currentCode) {
    String query = '';
    return showDialog<_Currency>(
      context: ctx,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setLocal) {
          final filtered = query.isEmpty
              ? _currencies
              : _currencies.where((c) =>
                  c.name.toLowerCase().contains(query.toLowerCase()) ||
                  c.code.toLowerCase().contains(query.toLowerCase()) ||
                  c.symbol.contains(query)).toList();
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SizedBox(
              width: 420,
              height: 560,
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
                    child: Row(
                      children: [
                        Text('Select Currency',
                            style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(dlgCtx),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          style: IconButton.styleFrom(foregroundColor: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  // Search
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      onChanged: (v) => setLocal(() => query = v),
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'Search currency or code…',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w300),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  // List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        final selected = c.code == currentCode;
                        return InkWell(
                          onTap: () => Navigator.pop(dlgCtx, c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            color: selected ? AppColors.primary.withValues(alpha: 0.05) : null,
                            child: Row(
                              children: [
                                Text(c.flag, style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c.name,
                                          style: GoogleFonts.inter(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: AppColors.textDark)),
                                      Text(c.code,
                                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w300, color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                                Text(c.symbol,
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: selected ? AppColors.primary : AppColors.textMuted)),
                                if (selected) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Printer dialog ───────────────────────────────────────────────────────────

  void _showPrinterDialog() async {
    // Load real printers from OS before opening dialog
    List<Printer> systemPrinters = [];
    try {
      systemPrinters = await Printing.listPrinters();
    } catch (_) {}
    if (!mounted) return;

    const paperSizes = ['A4', 'A5', '2 inch', '3 inch', '4 inch', 'Custom'];
    Printer? selPrinter = _activePrinter;
    bool isPdfExport = _selectedPrinter == 'PDF Export';
    String paper = _paperSize;
    bool autoPrint = _autoPrint;

    Widget printerRow(String name, {bool selected = false, required VoidCallback onTap, IconData icon = Icons.print_rounded}) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Row(children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 15, color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? AppColors.primary : AppColors.textDark)),
            ),
          ]),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.print_rounded, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Text('Printer Settings',
                        style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      style: IconButton.styleFrom(foregroundColor: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 20),

                // Printer list
                _dialogSectionLabel('SELECT PRINTER'),
                const SizedBox(height: 10),

                if (systemPrinters.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text('No printers found. Add one in System Settings.',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                    ]),
                  )
                else
                  ...systemPrinters.map((p) => printerRow(
                        p.name,
                        selected: !isPdfExport && selPrinter?.url == p.url,
                        icon: Icons.print_rounded,
                        onTap: () => setLocal(() { selPrinter = p; isPdfExport = false; }),
                      )),

                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 20),

                // Paper size
                _dialogSectionLabel('PAPER SIZE'),
                const SizedBox(height: 12),
                Row(
                  children: paperSizes.map((s) {
                    final sel = paper == s;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setLocal(() => paper = s),
                        child: Container(
                          margin: EdgeInsets.only(right: s != paperSizes.last ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primary : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                          ),
                          child: Center(
                            child: Text(s,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: sel ? Colors.white : AppColors.textMuted)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 16),

                // Auto-print toggle
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Auto-print on Close Bill',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                          Text('Automatically print receipt when bill is closed',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w300, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Switch(
                      value: autoPrint,
                      onChanged: (v) => setLocal(() => autoPrint = v),
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.primary,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _printRecord(_testReceipt(), paperSize: paper);
                        },
                        icon: const Icon(Icons.print_outlined, size: 16),
                        label: Text('Print Test Page',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppColors.border),
                          foregroundColor: AppColors.textDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final printerName = isPdfExport
                              ? 'PDF Export'
                              : (selPrinter?.name ?? 'System Default');
                          setState(() {
                            _activePrinter = selPrinter;
                            _selectedPrinter = printerName;
                            _paperSize = paper;
                            _autoPrint = autoPrint;
                          });
                          LocalDbService.saveSettings({
                            'selected_printer': printerName,
                            'paper_size': paper,
                            'auto_print': autoPrint ? '1' : '0',
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Save',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────────

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Logout',
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to logout?',
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              await LocalDbService.clearAll();
              await SupabaseService.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen()),
                  (r) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Logout',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Clear Bill',
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700)),
        content: Text('Remove all items from the current bill?',
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () {
              cart.clearCart();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Clear',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Print helpers ────────────────────────────────────────────────────────────

  TransactionRecord _snapshotCart(CartProvider cart) => TransactionRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerName: cart.customerName.isEmpty ? null : cart.customerName,
        customerPhone: cart.customerPhone.isEmpty ? null : cart.customerPhone,
        items: cart.items
            .map((i) => TransactionItem(
                  productId: i.product.id,
                  productName: i.product.name,
                  price: i.product.price,
                  quantity: i.quantity,
                ))
            .toList(),
        subtotal: cart.subtotal,
        discountAmount: cart.discountAmount,
        taxAmount: cart.taxAmount,
        total: cart.total,
        paymentMethod: cart.paymentMethod.name,
        createdAt: DateTime.now(),
      );

  void _printCurrentBill(CartProvider cart) =>
      _printRecord(_snapshotCart(cart));

  void _showPrintBillDialog(CartProvider cart) {
    final hasPrinter = _activePrinter != null;
    final hasPhone = cart.customerPhone.trim().isNotEmpty;
    bool sendWhatsApp = hasPhone;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.print_rounded, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Text('Print Bill', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    style: IconButton.styleFrom(foregroundColor: AppColors.textMuted),
                  ),
                ]),
                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 16),
                // Printer info
                if (hasPrinter)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(children: [
                      const Icon(Icons.print_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_activePrinter!.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                          Text('Paper: $_paperSize  •  Layout: $_invoiceLayout',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      )),
                    ]),
                  )
                else
                  InkWell(
                    onTap: () { Navigator.pop(ctx); _showPrinterDialog(); },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3F3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFCDD2)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.print_disabled_rounded, size: 16, color: Color(0xFFE53935)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('No printer connected',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFE53935))),
                            Text('Tap to set up a printer in Settings',
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        )),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
                      ]),
                    ),
                  ),
                const SizedBox(height: 12),
                // WhatsApp toggle
                InkWell(
                  onTap: hasPhone ? () => setLocal(() => sendWhatsApp = !sendWhatsApp) : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: sendWhatsApp && hasPhone
                          ? const Color(0xFF25D366).withValues(alpha: 0.08)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sendWhatsApp && hasPhone
                            ? const Color(0xFF25D366)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(children: [
                      Icon(Icons.chat_rounded, size: 16,
                          color: (sendWhatsApp && hasPhone)
                              ? const Color(0xFF25D366)
                              : AppColors.textMuted),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Send E-Bill via WhatsApp',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: (sendWhatsApp && hasPhone) ? const Color(0xFF25D366) : AppColors.textMuted)),
                          Text(
                            hasPhone
                                ? 'To: ${cart.customerPhone.trim()}'
                                : 'Enter customer phone number to enable',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      )),
                      Switch(
                        value: sendWhatsApp && hasPhone,
                        onChanged: hasPhone ? (v) => setLocal(() => sendWhatsApp = v) : null,
                        activeTrackColor: const Color(0xFF25D366),
                        activeThumbColor: Colors.white,
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.textDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Cancel', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton.icon(
                    onPressed: !hasPrinter ? null : () {
                      Navigator.pop(ctx);
                      _printCurrentBill(cart);
                      if (sendWhatsApp && hasPhone) _showWhatsAppPanel(cart);
                    },
                    icon: const Icon(Icons.print_outlined, size: 15),
                    label: Text('Print', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  )),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showWhatsAppPanel(CartProvider cart) {
    final tx = _snapshotCart(cart);
    final phone = cart.customerPhone.trim();
    final name = cart.customerName.trim();
    final receiptName = 'Bill-${tx.id.substring(0, 6).toUpperCase()}';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => WhatsAppPanel(
        customerPhone: phone.isEmpty ? null : phone,
        customerName: name.isEmpty ? null : name,
        pdfName: receiptName,
        buildPdf: () => ReceiptPrinter.buildPdf(
          tx,
          storeName: _storeName,
          storeAddress: _storeAddress,
          storePhone: _storePhone,
          storeEmail: _storeEmail,
          storeGstin: _storeGstin,
          receiptFooter: _receiptFooter,
          taxLabel: _taxLabel,
          taxRate: _taxRateDisplay,
          currencySymbol: _currencySymbol,
          paperSize: _paperSize,
          orientation: _printOrientation,
          layout: _invoiceLayout,
          storeTerms: _storeTerms,
          logoPath: _logoPath,
        ),
      ),
    );
  }

  Future<void> _printRecord(TransactionRecord tx, {String? paperSize}) async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);

    final effectivePaperSize = paperSize ?? _paperSize;

    // Step 1: build PDF bytes while loading overlay is visible.
    Uint8List pdfBytes;
    try {
      pdfBytes = await ReceiptPrinter.buildPdf(
        tx,
        storeName: _storeName, storeAddress: _storeAddress,
        storePhone: _storePhone, storeEmail: _storeEmail,
        storeGstin: _storeGstin, receiptFooter: _receiptFooter,
        taxLabel: _taxLabel, taxRate: _taxRateDisplay,
        currencySymbol: _currencySymbol, paperSize: effectivePaperSize,
        orientation: _printOrientation, layout: _invoiceLayout,
        storeTerms: _storeTerms, logoPath: _logoPath,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isPrinting = false);
        _showToast('Print failed: $e', isError: true);
      }
      return;
    }

    // Step 2: dismiss the loading overlay before opening the print dialog.
    if (mounted) setState(() => _isPrinting = false);

    // Step 3: send to printer or export to PDF.
    try {
      final receiptName = 'Receipt-${tx.id.substring(0, 6).toUpperCase()}';
      final tmpDir = await Directory.systemTemp.createTemp('billcat_');
      final pdfFile = File('${tmpDir.path}/$receiptName.pdf');
      await pdfFile.writeAsBytes(pdfBytes);

      if (_selectedPrinter == 'PDF Export') {
        final home = Platform.environment['HOME'] ?? '';
        final folder = Directory('$home/Desktop/BillCat Receipts');
        if (!folder.existsSync()) folder.createSync(recursive: true);
        final dest = File('${folder.path}/$receiptName.pdf');
        await dest.writeAsBytes(pdfBytes);
        if (mounted) _showToast('Saved to Desktop/BillCat Receipts');
      } else {
        // Send directly to printer via printing plugin — no Preview.app, no deadlock
        if (_activePrinter == null) {
          if (mounted) _showToast('No printer selected. Go to Settings → Printer.', isError: true);
          return;
        }
        await Printing.directPrintPdf(
          printer: _activePrinter!,
          onLayout: (_) async => pdfBytes,
          name: receiptName,
        );
        if (mounted) _showToast('Sent to ${_activePrinter!.name}');
      }
    } catch (e) {
      if (mounted) _showToast('Print failed: $e', isError: true);
    }
  }

  TransactionRecord _testReceipt() => TransactionRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerName: 'Test Customer',
        items: const [
          TransactionItem(productId: '1', productName: 'Sample Product A', price: 250, quantity: 2),
          TransactionItem(productId: '2', productName: 'Sample Product B', price: 180, quantity: 1),
        ],
        subtotal: 680,
        discountAmount: 0,
        taxAmount: 102,
        total: 782,
        paymentMethod: 'cash',
        createdAt: DateTime.now(),
      );

  void _closeBill(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 24),
          const SizedBox(width: 8),
          Text('Confirm Payment',
              style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700)),
        ]),
        content: Text(
          'Charge $_currencySymbol${cart.total.toStringAsFixed(2)} for ${cart.itemCount} item(s)?',
          style: GoogleFonts.inter(
              color: AppColors.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () async {
              final snapshot = _snapshotCart(cart);
              Navigator.pop(context);
              await cart.checkout();
              _customerNameCtrl.clear();
              _customerPhoneCtrl.clear();
              _loadProducts();
              _loadDashboardData();
              if (!context.mounted) return;
              _showToast('Payment successful!');
              if (_autoPrint) _printRecord(snapshot);
              _autoSavePdf(snapshot);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Confirm',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _autoSavePdf(TransactionRecord tx) async {
    try {
      final pdfBytes = await ReceiptPrinter.buildPdf(
        tx,
        storeName: _storeName, storeAddress: _storeAddress,
        storePhone: _storePhone, storeEmail: _storeEmail,
        storeGstin: _storeGstin, receiptFooter: _receiptFooter,
        taxLabel: _taxLabel, taxRate: _taxRateDisplay,
        currencySymbol: _currencySymbol, paperSize: _paperSize,
        orientation: _printOrientation, layout: _invoiceLayout,
        storeTerms: _storeTerms, logoPath: _logoPath,
      );
      final home = Platform.environment['HOME'] ?? '';
      final folder = Directory('$home/Desktop/BillCat Receipts');
      if (!folder.existsSync()) folder.createSync(recursive: true);
      final receiptName = 'Receipt-${tx.id.substring(0, 6).toUpperCase()}';
      await File('${folder.path}/$receiptName.pdf').writeAsBytes(pdfBytes);
    } catch (_) {}
  }

  void _showCustomProductDialog(CartProvider cart) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Custom Product',
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10)))),
            const SizedBox(height: 12),
            TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9.]'))
                ],
                decoration: InputDecoration(
                    labelText: 'Price',
                    prefixText: '\$',
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10)))),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final price =
                  double.tryParse(priceCtrl.text) ?? 0;
              if (name.isNotEmpty && price > 0) {
                cart.addProduct(Product(
                  id: DateTime.now()
                      .millisecondsSinceEpoch
                      .toString(),
                  name: name,
                  price: price,
                  category: 'Custom',
                  emoji: '📦',
                  sku: 'CUSTOM',
                  stock: 99,
                ));
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Add',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Inventory View ───────────────────────────────────────────────────────────

  Widget _buildInventoryView() {
    final lowStock   = _products.where((p) => p.stock > 0 && p.stock < 10).length;
    final outOfStock = _products.where((p) => p.stock == 0).length;

    final filtered = _products.where((p) {
      final matchCat = _inventoryCategoryFilter == 'All' || p.category == _inventoryCategoryFilter;
      if (!matchCat) return false;
      if (_inventorySearchQuery.isEmpty) return true;
      final q = _inventorySearchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Inventory', style: GoogleFonts.manrope(
                  fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 2),
              Text('${_products.length} products in catalogue',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
            ]),
            const Spacer(),
            _statChip('${_products.length}', 'Total', AppColors.primary),
            const SizedBox(width: 10),
            _statChip('$lowStock', 'Low Stock', const Color(0xFFF59E0B)),
            const SizedBox(width: 10),
            _statChip('$outOfStock', 'Out of Stock', AppColors.error),
          ]),
          const SizedBox(height: 18),
          // Search bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _inventorySearchQuery = v),
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Search by name, SKU or category...',
                hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textMuted, size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Category chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _inventoryCategoryChip('All'),
              ..._userCategories.map((cat) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _inventoryCategoryChip(cat, editable: true),
              )),
            ]),
          ),
          const SizedBox(height: 16),
          // Product grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 210,
                childAspectRatio: 0.82,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
              ),
              itemCount: filtered.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) return _addProductCard();
                return _inventoryCard(filtered[i - 1]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _inventoryCategoryChip(String label, {bool editable = false}) {
    final selected = _inventoryCategoryFilter == label;
    return _InventoryCatChip(
      label: label,
      selected: selected,
      editable: editable,
      onTap: () => setState(() => _inventoryCategoryFilter = label),
      onEdit: () => _showEditCategoryDialog(label),
    );
  }


  void _showEditCategoryDialog(String category) {
    final ctrl = TextEditingController(text: category);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Edit Category', style: GoogleFonts.manrope(
            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: 'Category name',
            hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await LocalDbService.deleteCategory(category);
              final affected = _products.where((p) => p.category == category).toList();
              for (final p in affected) {
                final updated = Product(id: p.id, name: p.name, price: p.price,
                    buyingPrice: p.buyingPrice, taxPercent: p.taxPercent,
                    category: '', emoji: p.emoji, sku: p.sku, stock: p.stock);
                await LocalDbService.updateProduct(updated);
              }
              setState(() {
                _userCategories.remove(category);
                for (int i = 0; i < _products.length; i++) {
                  if (_products[i].category == category) {
                    _products[i] = Product(id: _products[i].id, name: _products[i].name,
                        price: _products[i].price, buyingPrice: _products[i].buyingPrice,
                        taxPercent: _products[i].taxPercent, category: '',
                        emoji: _products[i].emoji, sku: _products[i].sku, stock: _products[i].stock);
                  }
                }
                if (_inventoryCategoryFilter == category) _inventoryCategoryFilter = 'All';
              });
              ConnectivityService.instance.syncNow();
            },
            child: Text('Delete', style: GoogleFonts.inter(
                color: AppColors.error, fontWeight: FontWeight.w500)),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isEmpty || newName == category) {
                Navigator.pop(ctx);
                return;
              }
              Navigator.pop(ctx);
              await LocalDbService.renameCategory(category, newName);
              final affected = _products.where((p) => p.category == category).toList();
              for (final p in affected) {
                final updated = Product(id: p.id, name: p.name, price: p.price,
                    buyingPrice: p.buyingPrice, taxPercent: p.taxPercent,
                    category: newName, emoji: p.emoji, sku: p.sku, stock: p.stock);
                await LocalDbService.updateProduct(updated);
              }
              setState(() {
                final idx = _userCategories.indexOf(category);
                if (idx != -1) _userCategories[idx] = newName;
                for (int i = 0; i < _products.length; i++) {
                  if (_products[i].category == category) {
                    _products[i] = Product(id: _products[i].id, name: _products[i].name,
                        price: _products[i].price, buyingPrice: _products[i].buyingPrice,
                        taxPercent: _products[i].taxPercent, category: newName,
                        emoji: _products[i].emoji, sku: _products[i].sku, stock: _products[i].stock);
                  }
                }
                if (_inventoryCategoryFilter == category) _inventoryCategoryFilter = newName;
              });
              ConnectivityService.instance.syncNow();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text('Rename', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color)),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _colHeader(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.8));

  Widget _addProductCard() {
    return GestureDetector(
      onTap: _showAddProductDialog,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 12),
            Text('Add Product',
                style: GoogleFonts.manrope(fontSize: 13,
                    fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text('Tap to add new item',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _inventoryCard(Product p) {
    final (statusLabel, statusColor, statusBg) = p.stock == 0
        ? ('Out of Stock', AppColors.error, AppColors.error.withValues(alpha: 0.08))
        : p.stock < 10
            ? ('Low Stock', const Color(0xFFF59E0B), const Color(0xFFF59E0B).withValues(alpha: 0.08))
            : ('In Stock', AppColors.success, AppColors.success.withValues(alpha: 0.08));
    final topRank = _topProductsToday.indexWhere((t) => t.$1 == p.name);
    final topMedal = topRank == 0 ? '🥇' : topRank == 1 ? '🥈' : topRank == 2 ? '🥉' : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 44, height: 44,
                child: p.emoji.startsWith('/')
                    ? Image.file(File(p.emoji), fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Center(child: Text('📦', style: TextStyle(fontSize: 22)))))
                    : Container(
                        color: AppColors.surfaceVariant,
                        child: Center(child: Text(
                            p.emoji.isEmpty ? '📦' : p.emoji,
                            style: const TextStyle(fontSize: 22)))),
              ),
            ),
            const Spacer(),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_vert_rounded,
                  size: 16, color: AppColors.textMuted),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              color: Colors.white,
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', height: 38,
                    child: Row(children: [
                      const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('Edit', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark)),
                    ])),
                PopupMenuItem(value: 'delete', height: 38,
                    child: Row(children: [
                      const Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text('Delete', style: GoogleFonts.inter(fontSize: 13, color: AppColors.error)),
                    ])),
              ],
              onSelected: (v) async {
                if (v == 'edit') {
                  _showEditProductDialog(p);
                } else if (v == 'delete') {
                  _confirmDeleteProduct(p);
                }
              },
            ),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: statusBg, borderRadius: BorderRadius.circular(100)),
              child: Text(statusLabel, style: GoogleFonts.inter(
                  fontSize: 9, fontWeight: FontWeight.w700,
                  color: statusColor, letterSpacing: 0.2)),
            ),
            if (topMedal != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 0.8),
                ),
                child: Text('$topMedal Top', style: GoogleFonts.inter(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: const Color(0xFF9E7D00), letterSpacing: 0.2)),
              ),
            ],
          ]),
          const SizedBox(height: 10),
          Text(p.name,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(fontSize: 13,
                  fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 3),
          Text(p.sku, style: GoogleFonts.inter(
              fontSize: 11, color: AppColors.textMuted)),
          const Spacer(),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(p.category, style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: AppColors.accentBlue)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Text('$_currencySymbol${p.price.toStringAsFixed(2)}',
                style: GoogleFonts.manrope(fontSize: 14,
                    fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const Spacer(),
            Text('${p.stock} pcs', style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: p.stock < 10 ? AppColors.error : AppColors.textMuted)),
          ]),
        ],
      ),
    );
  }

  // ── Edit / Delete Product ─────────────────────────────────────────────────────

  void _confirmDeleteProduct(Product p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Delete "${p.name}"?', style: GoogleFonts.manrope(
            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        content: Text('This will permanently remove the product from your inventory.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await LocalDbService.deleteProduct(p.id);
              ConnectivityService.instance.syncNow();
              setState(() => _products.removeWhere((x) => x.id == p.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(Product p) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: p.name);
    final skuCtrl = TextEditingController(text: p.sku);
    final priceCtrl = TextEditingController(text: p.price.toStringAsFixed(2));
    final buyingPriceCtrl = TextEditingController(text: p.buyingPrice > 0 ? p.buyingPrice.toStringAsFixed(2) : '');
    final taxPercentCtrl = TextEditingController(text: p.taxPercent > 0 ? p.taxPercent.toStringAsFixed(2) : '');
    final stockCtrl = TextEditingController(text: '${p.stock}');
    String emoji = p.emoji;
    String category = _userCategories.contains(p.category) ? p.category : (_userCategories..add(p.category)).last;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Text('Edit Product', style: GoogleFonts.manrope(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                      style: IconButton.styleFrom(minimumSize: const Size(32,32), padding: EdgeInsets.zero),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _dlgLabel('IMAGE'),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () async {
                              final r = await FilePicker.platform.pickFiles(type: FileType.image);
                              if (r?.files.single.path != null) {
                                final copied = await LocalDbService.copyImageToAppDir(r!.files.single.path!);
                                setLocal(() => emoji = copied);
                              }
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 64, height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: emoji.startsWith('/')
                                    ? Image.file(File(emoji), fit: BoxFit.cover,
                                        width: 64, height: 64,
                                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted)))
                                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        emoji.isNotEmpty
                                            ? Text(emoji, style: const TextStyle(fontSize: 24))
                                            : Icon(Icons.add_photo_alternate_outlined,
                                                color: AppColors.textMuted, size: 22),
                                        if (emoji.isEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text('Photo', style: GoogleFonts.inter(fontSize: 9, color: AppColors.textMuted)),
                                        ]
                                      ]),
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _dlgLabel('PRODUCT NAME'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: nameCtrl,
                            validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Required',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                            decoration: _dlgInputDecor('e.g. Wireless Keyboard'),
                          ),
                        ])),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _dlgLabel('SKU'),
                          const SizedBox(height: 6),
                          TextFormField(controller: skuCtrl,
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                              decoration: _dlgInputDecor('e.g. WK-00123')),
                        ])),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _dlgLabel('CATEGORY'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: category.isEmpty ? null : category,
                            items: [
                              ..._userCategories.map((c) => DropdownMenuItem(value: c,
                                  child: Text(c, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark)))),
                              DropdownMenuItem(value: '__add__',
                                  child: Row(children: [
                                    const Icon(Icons.add_rounded, size: 14, color: AppColors.accentBlue),
                                    const SizedBox(width: 6),
                                    Text('Add Category', style: GoogleFonts.inter(
                                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accentBlue)),
                                  ])),
                            ],
                            onChanged: (v) async {
                              if (v == '__add__') {
                                final newCat = await _showAddCategoryDialog(ctx);
                                if (newCat != null && newCat.isNotEmpty) {
                                  if (!_userCategories.contains(newCat)) {
                                    await LocalDbService.saveCategory(newCat);
                                    ConnectivityService.instance.syncNow();
                                    setState(() => _userCategories.add(newCat));
                                  }
                                  setLocal(() => category = newCat);
                                }
                              } else if (v != null) setLocal(() => category = v);
                            },
                            decoration: _dlgInputDecor('Category'),
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                            dropdownColor: Colors.white,
                          ),
                        ])),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _dlgLabel('SELLING PRICE ($_currencySymbol)'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                            validator: (v) => v != null && v.isNotEmpty && double.tryParse(v) != null ? null : 'Required',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                            decoration: _dlgInputDecor('0.00'),
                          ),
                        ])),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _dlgLabel('STOCK QTY'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) => v != null && v.isNotEmpty ? null : 'Required',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                            decoration: _dlgInputDecor('0'),
                          ),
                        ])),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _dlgLabel('BUYING PRICE ($_currencySymbol)'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: buyingPriceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                            decoration: _dlgInputDecor('0.00'),
                          ),
                        ])),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _dlgLabel('TAX (%)'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: taxPercentCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                            decoration: _dlgInputDecor('0.00'),
                          ),
                        ])),
                      ]),
                    ]),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.border))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancel', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500))),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final updated = Product(
                          id: p.id,
                          name: nameCtrl.text.trim(),
                          price: double.parse(priceCtrl.text),
                          buyingPrice: double.tryParse(buyingPriceCtrl.text) ?? 0.0,
                          taxPercent: double.tryParse(taxPercentCtrl.text) ?? 0.0,
                          category: category,
                          emoji: emoji,
                          sku: skuCtrl.text.trim().isEmpty ? p.sku : skuCtrl.text.trim(),
                          stock: int.parse(stockCtrl.text),
                        );
                        await LocalDbService.updateProduct(updated);
                        ConnectivityService.instance.syncNow();
                        if (!ctx.mounted) return;
                        setState(() {
                          final idx = _products.indexWhere((x) => x.id == p.id);
                          if (idx != -1) _products[idx] = updated;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text('Save Changes', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Add Product Dialog ────────────────────────────────────────────────────────

  void _showAddProductDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final buyingPriceCtrl = TextEditingController();
    final taxPercentCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    String emoji = '';
    String category = _userCategories.isNotEmpty ? _userCategories.first : '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 20),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border(
                        bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_box_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Text('Add New Product',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          )),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.textMuted),
                        style: IconButton.styleFrom(
                            minimumSize: const Size(32, 32),
                            padding: EdgeInsets.zero),
                      ),
                    ],
                  ),
                ),
                // Form
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Emoji + Name row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image picker
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _dlgLabel('IMAGE'),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () async {
                                    final r = await FilePicker.platform.pickFiles(
                                        type: FileType.image);
                                    if (r?.files.single.path != null) {
                                      final copied = await LocalDbService.copyImageToAppDir(r!.files.single.path!);
                                      setLocal(() => emoji = copied);
                                    }
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: emoji.startsWith('/')
                                          ? Image.file(File(emoji), fit: BoxFit.cover,
                                              width: 64, height: 64,
                                              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted)))
                                          : Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.add_photo_alternate_outlined,
                                                    color: AppColors.textMuted, size: 22),
                                                const SizedBox(height: 3),
                                                Text('Photo', style: GoogleFonts.inter(
                                                    fontSize: 9, color: AppColors.textMuted)),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            // Name
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _dlgLabel('PRODUCT NAME'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: nameCtrl,
                                    validator: (v) =>
                                        v != null && v.trim().isNotEmpty
                                            ? null
                                            : 'Required',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.textDark),
                                    decoration: _dlgInputDecor(
                                        'e.g. Wireless Keyboard'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // SKU + Category row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _dlgLabel('SKU'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: skuCtrl,
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.textDark),
                                    decoration:
                                        _dlgInputDecor('e.g. WK-00123'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _dlgLabel('CATEGORY'),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: category.isEmpty ? null : category,
                                    items: [
                                      ..._userCategories.map((c) =>
                                          DropdownMenuItem(value: c,
                                              child: Text(c, style: GoogleFonts.inter(
                                                  fontSize: 13, color: AppColors.textDark)))),
                                      DropdownMenuItem(
                                        value: '__add__',
                                        child: Row(children: [
                                          const Icon(Icons.add_rounded, size: 14, color: AppColors.accentBlue),
                                          const SizedBox(width: 6),
                                          Text('Add Category', style: GoogleFonts.inter(
                                              fontSize: 13, fontWeight: FontWeight.w600,
                                              color: AppColors.accentBlue)),
                                        ]),
                                      ),
                                    ],
                                    onChanged: (v) async {
                                      if (v == '__add__') {
                                        final newCat = await _showAddCategoryDialog(ctx);
                                        if (newCat != null && newCat.isNotEmpty) {
                                          if (!_userCategories.contains(newCat)) {
                                            await LocalDbService.saveCategory(newCat);
                                            ConnectivityService.instance.syncNow();
                                            setState(() => _userCategories.add(newCat));
                                          }
                                          setLocal(() => category = newCat);
                                        }
                                      } else if (v != null) {
                                        setLocal(() => category = v);
                                      }
                                    },
                                    decoration: _dlgInputDecor('Category'),
                                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                                    dropdownColor: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Price + Stock row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _dlgLabel('SELLING PRICE ($_currencySymbol)'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: priceCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d{0,2}'))
                                    ],
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Required';
                                      }
                                      if (double.tryParse(v) == null) {
                                        return 'Invalid number';
                                      }
                                      return null;
                                    },
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.textDark),
                                    decoration: _dlgInputDecor('0.00'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _dlgLabel('STOCK QTY'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: stockCtrl,
                                    keyboardType:
                                        TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter
                                          .digitsOnly
                                    ],
                                    validator: (v) =>
                                        v != null && v.isNotEmpty
                                            ? null
                                            : 'Required',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.textDark),
                                    decoration: _dlgInputDecor('0'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Buying Price + Tax row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _dlgLabel('BUYING PRICE ($_currencySymbol)'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: buyingPriceCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                                    decoration: _dlgInputDecor('0.00'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _dlgLabel('TAX (%)'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: taxPercentCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                                    decoration: _dlgInputDecor('0.00'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancel',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final sku = skuCtrl.text.trim().isEmpty
                              ? '${nameCtrl.text.trim().substring(0, nameCtrl.text.trim().length.clamp(0, 3)).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch % 100000}'
                              : skuCtrl.text.trim();
                          final newProduct = Product(
                            id: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            name: nameCtrl.text.trim(),
                            price: double.parse(priceCtrl.text),
                            buyingPrice: double.tryParse(buyingPriceCtrl.text) ?? 0.0,
                            taxPercent: double.tryParse(taxPercentCtrl.text) ?? 0.0,
                            category: category,
                            emoji: emoji,
                            sku: sku,
                            stock: int.parse(stockCtrl.text),
                          );
                          await LocalDbService.insertProduct(newProduct);
                          ConnectivityService.instance.syncNow();
                          if (!ctx.mounted) return;
                          setState(() => _products.add(newProduct));
                          Navigator.pop(ctx);
                          _showToast('${newProduct.name} added to inventory');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: Text('Add Product',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Future<String?> _pickEmoji(BuildContext ctx, String current) async {
    const emojis = [
      '📦', '💻', '🖥️', '🖱️', '⌨️', '🎧', '🎮', '📷', '💾', '🧠',
      '🔌', '🗂️', '⚡', '📱', '🖨️', '📡', '🔋', '💿', '📺', '🎙️',
      '🕹️', '🔦', '🖊️', '📋', '🗃️', '🧲', '🔧', '🔩', '⚙️', '🛒',
    ];
    return showDialog<String>(
      context: ctx,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('Pick an Emoji',
                    style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: emojis.map((e) {
                    final selected = e == current;
                    return GestureDetector(
                      onTap: () => Navigator.pop(ctx, e),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: selected
                              ? Border.all(
                                  color: AppColors.primary, width: 1.5)
                              : null,
                        ),
                        child: Center(
                            child: Text(e,
                                style: const TextStyle(fontSize: 22))),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showAddCategoryDialog(BuildContext ctx) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('New Category', style: GoogleFonts.manrope(
            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: 'e.g. Electronics',
            hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text('Add', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _dlgLabel(String text) => Text(text,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 1,
      ));

  InputDecoration _dlgInputDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      );

  static String _monthName(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ][m];

  String _fmtShort(double v) {
    if (v >= 1000000) return '$_currencySymbol${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '$_currencySymbol${(v / 1000).toStringAsFixed(1)}K';
    return '$_currencySymbol${v.toStringAsFixed(0)}';
  }

  Widget _buildBarChart(List<(String, double)> bars) =>
      _PremiumBarChart(bars: bars, currencySymbol: _currencySymbol);

  // ── Dashboard View ───────────────────────────────────────────────────────────

  Widget _buildDashboardView() {
    // Active period data
    final pSales = switch (_dashPeriod) {
      'This Week'  => _dashWeekSales,
      'This Month' => _dashMonthSales,
      'This Year'  => _dashYearSales,
      _            => _dashSales,
    };
    final pTx = switch (_dashPeriod) {
      'This Week'  => _dashWeekTxCount,
      'This Month' => _dashMonthTxCount,
      'This Year'  => _dashYearTxCount,
      _            => _dashTxCount,
    };
    final pItems = switch (_dashPeriod) {
      'This Week'  => _dashWeekItems,
      'This Month' => _dashMonthItems,
      'This Year'  => _dashYearItems,
      _            => _dashItemsSold,
    };
    final pAvg = switch (_dashPeriod) {
      'This Week'  => _dashWeekAvg,
      'This Month' => _dashMonthAvg,
      'This Year'  => _dashYearAvg,
      _            => _dashAvgOrder,
    };
    final pBars = switch (_dashPeriod) {
      'This Week'  => _chartBarsWeek,
      'This Month' => _chartBarsMonth,
      'This Year'  => _chartBarsYear,
      _            => _chartBarsToday,
    };
    final _dow = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][DateTime.now().weekday];
    String _pctVs(double current, double prev, String label) {
      if (prev == 0) return 'No data last $label';
      final pct = ((current - prev) / prev * 100).round();
      return '${pct >= 0 ? '+' : ''}$pct% vs last $label';
    }
    final pVsLabel = switch (_dashPeriod) {
      'This Week'  => 'Mon – today',
      'This Month' => '1–${DateTime.now().day} ${_monthName(DateTime.now().month)}',
      'This Year'  => 'Jan–${_monthName(DateTime.now().month)} ${DateTime.now().year}',
      _ => _dashYestSales > 0
          ? '${_dashSales >= _dashYestSales ? '+' : ''}${((_dashSales - _dashYestSales) / _dashYestSales * 100).round()}% vs yesterday'
          : _pctVs(_dashSales, _dashLastWeekSameDaySales, _dow),
    };
    final pTopProducts = switch (_dashPeriod) {
      'This Week'  => _topProductsWeek,
      'This Month' => _topProductsMonth,
      'This Year'  => _topProductsYear,
      _            => _topProductsToday,
    };

    final maxCat = _dashCategories.isEmpty ? 1.0
        : _dashCategories.map((e) => e.$2).reduce((a, b) => a > b ? a : b);

    const periods = ['Today', 'This Week', 'This Month', 'This Year'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard',
                      style: GoogleFonts.manrope(
                          fontSize: 22, fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  Text(_fmtDate(DateTime.now()),
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w300,
                          color: AppColors.textMuted)),
                ],
              ),
              const Spacer(),
              // Period dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _dashPeriod,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: AppColors.textMuted),
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w500,
                        color: AppColors.textDark),
                    isDense: true,
                    onChanged: (v) { if (v != null) setState(() => _dashPeriod = v); },
                    items: periods.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p),
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Metric cards ──
          Row(children: [
            _metricCard('Total Sales', '$_currencySymbol${pSales.toStringAsFixed(2)}',
                Icons.attach_money_rounded, AppColors.accent, pVsLabel,
                currencyIcon: _currencySymbol),
            const SizedBox(width: 16),
            _metricCard('Transactions', '$pTx',
                Icons.receipt_long_rounded, AppColors.accentBlue, '$_dashPeriod'),
            const SizedBox(width: 16),
            _metricCard('Items Sold', '$pItems',
                Icons.shopping_bag_outlined, const Color(0xFF10B981), '$_dashPeriod'),
            const SizedBox(width: 16),
            _metricCard('Avg Order', '$_currencySymbol${pAvg.toStringAsFixed(2)}',
                Icons.trending_up_rounded, const Color(0xFF8B5CF6), '$_dashPeriod',
                currencyIcon: _currencySymbol),
          ]),
          const SizedBox(height: 16),

          // ── Sales Chart ──
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('Sales Overview',
                      style: GoogleFonts.manrope(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const Spacer(),
                  Text(_dashPeriod,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textMuted)),
                ]),
                const SizedBox(height: 4),
                Text('$_currencySymbol${pSales.toStringAsFixed(2)} total  •  $pTx transactions',
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w300,
                        color: AppColors.textMuted)),
                const SizedBox(height: 20),
                _buildBarChart(pBars),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Sold Products ──
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('Top Products', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                        const Spacer(),
                        Text(_dashPeriod, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                      ]),
                      Text('Best sellers by qty', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w300, color: AppColors.textMuted)),
                      const SizedBox(height: 16),
                      if (pTopProducts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('No sales $_dashPeriod',
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted))),
                        )
                      else
                        ...pTopProducts.asMap().entries.map((e) {
                          final rank = e.key + 1;
                          final p = e.value;
                          final medalColor = rank == 1 ? const Color(0xFFFFB800)
                              : rank == 2 ? const Color(0xFF9E9E9E)
                              : rank == 3 ? const Color(0xFFCD7F32)
                              : AppColors.textMuted;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 26, height: 26,
                                  decoration: BoxDecoration(
                                    color: medalColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(child: Text('$rank',
                                      style: GoogleFonts.inter(
                                          fontSize: 11, fontWeight: FontWeight.w700,
                                          color: medalColor))),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.$1,
                                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                                          overflow: TextOverflow.ellipsis),
                                      Text('${p.$2} units sold',
                                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                                Text('$_currencySymbol${_fmtShort(p.$3).replaceAll(_currencySymbol, '')}',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sales by Category', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      Text('Revenue breakdown today', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w300, color: AppColors.textMuted)),
                      const SizedBox(height: 20),
                      if (_dashCategories.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('No sales today yet',
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted))),
                        )
                      else
                        ..._dashCategories.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(c.$1, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                                const Spacer(),
                                Text('$_currencySymbol${c.$2.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                              ]),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: c.$2 / maxCat,
                                  minHeight: 6,
                                  backgroundColor: AppColors.surfaceVariant,
                                  valueColor: AlwaysStoppedAnimation<Color>(c.$3),
                                ),
                              ),
                            ],
                          ),
                        )),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('Recent Transactions', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() { _selectedTab = 3; _reportView = 'Sales'; }),
                          child: Text('View all →', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.accentBlue)),
                        ),
                      ]),
                      Text('Last ${_dashRecentTx.length} bills closed today',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w300, color: AppColors.textMuted)),
                      const SizedBox(height: 16),
                      if (_dashRecentTx.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('No transactions today yet',
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted))),
                        )
                      else ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(children: [
                            Expanded(flex: 3, child: _dashColHeader('CUSTOMER')),
                            Expanded(flex: 2, child: _dashColHeader('METHOD')),
                            Expanded(flex: 2, child: _dashColHeader('TIME')),
                            Expanded(flex: 1, child: _dashColHeader('ITEMS')),
                            Expanded(flex: 2, child: _dashColHeader('AMOUNT', right: true)),
                          ]),
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: AppColors.border),
                        ..._dashRecentTx.map((tx) {
                          final name = (tx.customerName?.isNotEmpty == true) ? tx.customerName! : 'Walk-in';
                          final timeStr = '${tx.createdAt.hour.toString().padLeft(2,'0')}:${tx.createdAt.minute.toString().padLeft(2,'0')}';
                          final method = switch (tx.paymentMethod.toLowerCase()) {
                            'cash' => 'Cash', 'card' => 'Card', 'upi' => 'UPI/QR', _ => tx.paymentMethod,
                          };
                          final itemCount = tx.items.fold(0, (s, i) => s + i.quantity);
                          return Column(children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                              child: Row(children: [
                                Expanded(flex: 3, child: Row(children: [
                                  Container(
                                    width: 28, height: 28,
                                    decoration: const BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
                                    child: Center(child: Text(name[0].toUpperCase(),
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary))),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(child: Text(name, overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textDark))),
                                ])),
                                Expanded(flex: 2, child: _paymentBadge(method)),
                                Expanded(flex: 2, child: Text(timeStr,
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w300, color: AppColors.textMuted))),
                                Expanded(flex: 1, child: Text('$itemCount',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textDark))),
                                Expanded(flex: 2, child: Text('$_currencySymbol${tx.total.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark))),
                              ]),
                            ),
                            const Divider(height: 1, color: AppColors.border),
                          ]);
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color, String sub, {String? currencyIcon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: currencyIcon != null
                    ? Center(child: Text(currencyIcon, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)))
                    : Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: sub.startsWith('+') ? AppColors.accent.withValues(alpha: 0.08)
                        : sub.startsWith('-') ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(100)),
                child: Text(sub, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500,
                    color: sub.startsWith('+') ? AppColors.accent
                        : sub.startsWith('-') ? const Color(0xFFEF4444)
                        : AppColors.textMuted)),
              ),
            ]),
            const SizedBox(height: 14),
            Text(value, style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _dashColHeader(String text, {bool right = false}) => Text(text,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.8));

  Widget _paymentBadge(String method) {
    final (color, bg) = switch (method) {
      'Cash'   => (AppColors.accent,    AppColors.accent.withValues(alpha: 0.1)),
      'Card'   => (AppColors.accentBlue, AppColors.accentBlue.withValues(alpha: 0.1)),
      'UPI/QR' => (const Color(0xFF8B5CF6), const Color(0xFF8B5CF6).withValues(alpha: 0.1)),
      _        => (AppColors.textMuted, AppColors.surfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(method, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  // ── Reports View ─────────────────────────────────────────────────────────────

  Future<void> _loadReportCustomers() async {
    final customers = await LocalDbService.getCustomers();
    if (mounted) setState(() => _reportCustomers = customers);
  }

  Widget _buildReportsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_reportView, style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  Text(_fmtDate(DateTime.now()), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w300, color: AppColors.textMuted)),
                ],
              ),
              const Spacer(),
              if (_reportView == 'Sales') ...[
                _reportPeriodBtn('Today'),
                const SizedBox(width: 6),
                _reportPeriodBtn('This Week'),
                const SizedBox(width: 6),
                _reportPeriodBtn('This Month'),
              ],
            ],
          ),
          const SizedBox(height: 24),
          if (_reportView == 'Sales')         _buildSalesReport()
          else if (_reportView == 'Customers') _buildCustomersReport()
          else                                 _buildInventoryReport(),
        ],
      ),
    );
  }

  // ── Sales sub-view ─────────────────────────────────────────────────────────

  Widget _buildSalesReport() {
    final isToday = _reportSalesPeriod == 'Today';
    final isWeek  = _reportSalesPeriod == 'This Week';

    final revenue  = isToday ? _dashSales      : isWeek ? _dashWeekSales  : _dashMonthSales;
    final txCount  = isToday ? _dashTxCount    : isWeek ? _dashWeekTxCount : _dashMonthTxCount;
    final items    = isToday ? _dashItemsSold  : isWeek ? _dashWeekItems   : _dashMonthItems;
    final profit  = isToday ? _dashProfitToday : isWeek ? _dashProfitWeek  : _dashProfitMonth;
    final txList = isToday ? _txListToday : isWeek ? _txListWeek : _txListMonth;
    final periodLabel = isToday ? 'today' : isWeek ? 'this week' : 'this month';

    String fmtAmt(double v) {
      final parts = v.toStringAsFixed(2).split('.');
      final intPart = parts[0];
      final buf = StringBuffer();
      for (int i = 0; i < intPart.length; i++) {
        if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
        buf.write(intPart[i]);
      }
      return '$_currencySymbol$buf.${parts[1]}';
    }

    String fmtDate(DateTime dt) {
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final m = dt.minute.toString().padLeft(2, '0');
        final ampm = dt.hour < 12 ? 'AM' : 'PM';
        return '$h:$m $ampm';
      }
      return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')} ${(dt.hour % 12 == 0 ? 12 : dt.hour % 12)}:${dt.minute.toString().padLeft(2,'0')} ${dt.hour < 12 ? 'AM' : 'PM'}';
    }

    return Column(
      children: [
        Row(children: [
          _reportSummaryCard('Total Sales', fmtAmt(revenue),  Icons.attach_money_rounded,  AppColors.accent,            currencyIcon: _currencySymbol),
          const SizedBox(width: 16),
          _reportSummaryCard('Transactions',  '$txCount',       Icons.receipt_long_rounded,  AppColors.accentBlue),
          const SizedBox(width: 16),
          _reportSummaryCard('Items Sold',    '$items',         Icons.shopping_bag_outlined, const Color(0xFFF59E0B)),
          const SizedBox(width: 16),
          _reportSummaryCard('Profit',          fmtAmt(profit),  Icons.trending_up_rounded,   const Color(0xFF8B5CF6),      currencyIcon: _currencySymbol),
        ]),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Transaction History', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  Text('All transactions $periodLabel', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w300, color: AppColors.textMuted)),
                ])),
                const SizedBox(width: 16),
                SizedBox(
                  width: 240,
                  height: 36,
                  child: Container(
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      const SizedBox(width: 10),
                      const Icon(Icons.search_rounded, size: 15, color: AppColors.textMuted),
                      const SizedBox(width: 7),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _salesSearchQuery = v),
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textDark),
                          decoration: InputDecoration(
                            hintText: 'Search customer, items...',
                            hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                            border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_salesSearchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() => _salesSearchQuery = ''),
                          child: const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.close_rounded, size: 13, color: AppColors.textMuted),
                          ),
                        )
                      else
                        const SizedBox(width: 8),
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              if (txList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No transactions $periodLabel', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted))),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Row(children: [
                    Expanded(flex: 3, child: _dashColHeader('DATE / TIME')),
                    Expanded(flex: 3, child: _dashColHeader('INVOICE')),
                    Expanded(flex: 4, child: _dashColHeader('CUSTOMER')),
                    Expanded(flex: 2, child: _dashColHeader('ITEMS')),
                    Expanded(flex: 2, child: _dashColHeader('PAYMENT')),
                    Expanded(flex: 2, child: _dashColHeader('TOTAL', right: true)),
                  ]),
                ),
                const Divider(height: 1, color: AppColors.border),
                ...(() {
                  final filtered = txList.where((t) {
                    if (_salesSearchQuery.isEmpty) return true;
                    final q = _salesSearchQuery.toLowerCase();
                    final inv = t.id.substring(0, 6).toUpperCase();
                    return (t.customerName?.toLowerCase().contains(q) ?? false) ||
                        t.items.any((i) => i.productName.toLowerCase().contains(q)) ||
                        t.paymentMethod.toLowerCase().contains(q) ||
                        inv.toLowerCase().contains(q) ||
                        '#$inv'.toLowerCase().contains(q);
                  }).toList();
                  return filtered.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final t = entry.value;
                    final invoiceNo = '#${t.id.substring(0, 6).toUpperCase()}';
                    final itemCount = t.items.fold(0, (s, i) => s + i.quantity);
                    final customer = (t.customerName?.isNotEmpty == true) ? t.customerName! : '—';
                    final payLabel = {'cash': 'Cash', 'card': 'Card', 'upi': 'UPI/QR', 'hybrid': 'Hybrid'}[t.paymentMethod] ?? t.paymentMethod;
                    return Column(children: [
                      InkWell(
                        onTap: () => _showTransactionDetail(t),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                          child: Row(children: [
                            Expanded(flex: 3, child: Text(fmtDate(t.createdAt), style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted))),
                            Expanded(flex: 3, child: Text(invoiceNo, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary))),
                            Expanded(flex: 4, child: Text(customer, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark), overflow: TextOverflow.ellipsis)),
                            Expanded(flex: 2, child: Text('$itemCount item${itemCount == 1 ? '' : 's'}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted))),
                            Expanded(flex: 2, child: Text(payLabel, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textDark))),
                            Expanded(flex: 2, child: Text('$_currencySymbol${t.total.toStringAsFixed(2)}', textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark))),
                          ]),
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                    ]);
                  });
                })(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showTransactionDetail(TransactionRecord t) {
    final payLabel = {'cash': 'Cash', 'card': 'Card', 'upi': 'UPI/QR', 'hybrid': 'Hybrid'}[t.paymentMethod] ?? t.paymentMethod;
    final dt = t.createdAt;
    final dateStr = '${dt.day.toString().padLeft(2,'0')} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][dt.month-1]} ${dt.year}';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final timeStr = '$h:${dt.minute.toString().padLeft(2,'0')} ${dt.hour < 12 ? 'AM' : 'PM'}';
    final invoiceNo = '#${t.id.substring(0, 6).toUpperCase()}';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(invoiceNo, style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Text('$dateStr · $timeStr', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(20)),
                    child: Text(payLabel, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ),
                ]),
              ),
              // ── Customer row ─────────────────────────────────────────────
              if (t.customerName?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(children: [
                    Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textMuted)),
                    const SizedBox(width: 10),
                    Text(t.customerName!, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    if (t.customerPhone?.isNotEmpty == true) ...[
                      const SizedBox(width: 8),
                      Text(t.customerPhone!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ]),
                ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: AppColors.border),
              // ── Items ────────────────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  child: Column(children: [
                    // Column headers
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: Row(children: [
                        Expanded(flex: 5, child: Text('Item', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted))),
                        SizedBox(width: 40, child: Text('Qty', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted))),
                        SizedBox(width: 80, child: Text('Price', textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted))),
                        SizedBox(width: 80, child: Text('Amount', textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted))),
                      ]),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    ...t.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Row(children: [
                        Expanded(flex: 5, child: Text(item.productName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark))),
                        SizedBox(width: 40, child: Text('×${item.quantity}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted))),
                        SizedBox(width: 80, child: Text('$_currencySymbol${item.price.toStringAsFixed(2)}', textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted))),
                        SizedBox(width: 80, child: Text('$_currencySymbol${item.total.toStringAsFixed(2)}', textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark))),
                      ]),
                    )),
                  ]),
                ),
              ),
              // ── Totals ───────────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
                child: Column(children: [
                  _txDetailRow('Subtotal', '$_currencySymbol${t.subtotal.toStringAsFixed(2)}'),
                  if (t.discountAmount > 0) _txDetailRow('Discount', '-$_currencySymbol${t.discountAmount.toStringAsFixed(2)}', valueColor: Colors.green),
                  if (t.taxAmount > 0) _txDetailRow('Tax ($_taxLabel)', '$_currencySymbol${t.taxAmount.toStringAsFixed(2)}'),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(child: Text('Total', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark))),
                    Text('$_currencySymbol${t.total.toStringAsFixed(2)}', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ]),
                ]),
              ),
              // ── Actions ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(children: [
                  IconButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: ctx,
                        builder: (c2) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          title: Text('Delete Transaction?', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 16)),
                          content: Text('This will permanently remove this transaction.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c2, false), child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted))),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(c2, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && ctx.mounted) {
                        Navigator.pop(ctx);
                        await _deleteTransaction(t.id);
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
                    tooltip: 'Delete',
                    style: IconButton.styleFrom(padding: const EdgeInsets.all(10)),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13), side: const BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: Text('Close', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () { Navigator.pop(ctx); _printRecord(t); },
                      icon: const Icon(Icons.print_outlined, size: 15),
                      label: Text('Print', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteTransaction(String id) async {
    await LocalDbService.deleteTransaction(id);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client
            .from('transactions')
            .delete()
            .eq('id', id)
            .eq('user_id', userId);
      }
    } catch (_) {}
    _loadDashboardData();
  }

  // ── Customer detail popup ─────────────────────────────────────────────────

  void _showCustomerDetail(Customer c) async {
    final txs = await LocalDbService.getTransactionsByCustomer(c.name, c.phone);
    if (!mounted) return;
    final totalSpent = txs.fold<double>(0, (s, t) => s + t.total);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.person_rounded, size: 22, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.name, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 2),
                    Text(
                      c.phone?.isNotEmpty == true ? c.phone! : 'No phone',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('$_currencySymbol${totalSpent.toStringAsFixed(2)}',
                        style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const SizedBox(height: 2),
                    Text('lifetime spent', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                  ]),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Row(children: [
                  _custStatChip(Icons.receipt_long_outlined, '${txs.length} orders'),
                  const SizedBox(width: 8),
                  _custStatChip(Icons.calendar_today_outlined, 'Since ${_fmtDate(c.createdAt)}'),
                ]),
              ),
              const Divider(height: 1, color: AppColors.border),
              // ── Transaction list ──────────────────────────────────────────
              if (txs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('No transactions found', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted))),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 340),
                  child: SingleChildScrollView(
                    child: Column(
                      children: txs.map((t) {
                        final dt = t.createdAt;
                        const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                        final dateStr = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
                        final timeStr = '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
                        final payLabel = t.paymentMethod == 'cash' ? 'Cash'
                            : t.paymentMethod == 'card' ? 'Card'
                            : t.paymentMethod == 'upi'  ? 'UPI'
                            : t.paymentMethod.toUpperCase();
                        return Column(children: [
                          InkWell(
                            onTap: () => _showTransactionDetail(t),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              child: Row(children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('$dateStr · $timeStr',
                                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                                  const SizedBox(height: 3),
                                  Text(
                                    t.items.map((i) => i.productName).join(', '),
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textDark),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                ])),
                                const SizedBox(width: 12),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text('$_currencySymbol${t.total.toStringAsFixed(2)}',
                                      style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(20)),
                                    child: Text(payLabel, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                  ),
                                ]),
                                const SizedBox(width: 6),
                                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
                              ]),
                            ),
                          ),
                          const Divider(height: 1, color: AppColors.border),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              // ── Actions ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Row(children: [
                  IconButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: ctx,
                        builder: (c2) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          title: Text('Delete Customer?', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 16)),
                          content: Text('This will permanently remove ${c.name} and all their data.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c2, false), child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted))),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(c2, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && ctx.mounted) {
                        Navigator.pop(ctx);
                        await _deleteCustomer(c);
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
                    tooltip: 'Delete customer',
                    style: IconButton.styleFrom(padding: const EdgeInsets.all(10)),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: Text('Close', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _custStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
      ]),
    );
  }

  Future<void> _deleteCustomer(Customer c) async {
    await LocalDbService.deleteCustomer(c.id);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client
            .from('customers')
            .delete()
            .eq('id', c.id)
            .eq('user_id', userId);
      }
    } catch (_) {}
    _loadReportCustomers();
  }

  // ── Owner / Staff access ──────────────────────────────────────────────────

  void _lockOwnerMode() {
    setState(() {
      _isOwnerMode = false;
      if (_selectedTab == 0 || _selectedTab == 3) _selectedTab = 1;
    });
  }

  void _showOwnerPasscodeDialog() {
    if (_ownerPasscode.isEmpty) {
      _showSetPasscodeDialog(isFirstTime: true);
      return;
    }
    final enteredDigits = ValueNotifier<String>('');
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: enteredDigits,
        builder: (ctx, entered, _) {
          if (entered.length == 4) {
            Future.microtask(() {
              if (entered == _ownerPasscode) {
                Navigator.pop(ctx);
                setState(() => _isOwnerMode = true);
              } else {
                enteredDigits.value = '';
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect passcode'), duration: Duration(seconds: 1)),
                );
              }
            });
          }
          return _buildPasscodeDialog('Owner Access', 'Enter 4-digit passcode', enteredDigits, ctx);
        },
      ),
    );
  }

  void _showSetPasscodeDialog({bool isFirstTime = false, VoidCallback? onSet}) {
    final firstDigits  = ValueNotifier<String>('');
    final secondDigits = ValueNotifier<String>('');
    bool confirming = false;
    showDialog(
      context: context,
      barrierDismissible: !isFirstTime,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final current = confirming ? secondDigits : firstDigits;
          return ValueListenableBuilder<String>(
            valueListenable: current,
            builder: (ctx, entered, _) {
              if (entered.length == 4 && !confirming) {
                Future.microtask(() => setDialogState(() => confirming = true));
              }
              if (entered.length == 4 && confirming) {
                Future.microtask(() {
                  if (firstDigits.value == secondDigits.value) {
                    _saveNewPasscode(firstDigits.value);
                    Navigator.pop(ctx);
                    if (onSet != null) {
                      onSet();
                    } else if (isFirstTime) {
                      setState(() => _isOwnerMode = true);
                    }
                  } else {
                    secondDigits.value = '';
                    firstDigits.value  = '';
                    setDialogState(() => confirming = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passcodes did not match, try again'), duration: Duration(seconds: 2)),
                    );
                  }
                });
              }
              return _buildPasscodeDialog(
                confirming ? 'Confirm Passcode' : 'Set Owner Passcode',
                confirming ? 'Re-enter the same 4 digits' : 'Choose a 4-digit owner passcode',
                current, ctx,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _saveNewPasscode(String code) async {
    setState(() => _ownerPasscode = code);
    await LocalDbService.saveSettings({'owner_passcode': code});
    ConnectivityService.instance.syncNow();
  }

  Widget _buildPasscodeDialog(String title, String subtitle, ValueNotifier<String> digits, BuildContext ctx) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: SizedBox(
        width: 320,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 16),
              Text(title, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 6),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted), textAlign: TextAlign.center),
              const SizedBox(height: 28),
              // 4 dot indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < digits.value.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.primary : Colors.transparent,
                      border: Border.all(color: filled ? AppColors.primary : const Color(0xFFCCCCCC), width: 2),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),
              // Number pad
              ...[
                ['1','2','3'],
                ['4','5','6'],
                ['7','8','9'],
                ['','0','⌫'],
              ].map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: row.map((key) {
                    if (key.isEmpty) return const SizedBox(width: 72);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: GestureDetector(
                        onTap: () {
                          if (key == '⌫') {
                            if (digits.value.isNotEmpty) {
                              digits.value = digits.value.substring(0, digits.value.length - 1);
                            }
                          } else if (digits.value.length < 4) {
                            digits.value = digits.value + key;
                          }
                        },
                        child: Container(
                          width: 64, height: 56,
                          decoration: BoxDecoration(
                            color: key == '⌫' ? Colors.transparent : const Color(0xFFF5F5F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: key == '⌫'
                              ? const Icon(Icons.backspace_outlined, size: 20, color: Color(0xFF6E6E73))
                              : Text(key, style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              )),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _txDetailRow(String label, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted))),
      Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: valueColor ?? AppColors.textDark)),
    ]),
  );

  // ── Customers sub-view ─────────────────────────────────────────────────────

  Widget _buildCustomersReport() {
    final total = _reportCustomers.length;
    final withPhone = _reportCustomers.where((c) => c.phone != null && c.phone!.isNotEmpty).length;
    final now = DateTime.now();
    final newThisMonth = _reportCustomers.where((c) =>
        c.createdAt.year == now.year && c.createdAt.month == now.month).length;

    return Column(
      children: [
        Row(children: [
          _reportSummaryCard('Total Customers',  '$total',        Icons.people_alt_outlined,     AppColors.accentBlue),
          const SizedBox(width: 16),
          _reportSummaryCard('With Phone',       '$withPhone',    Icons.phone_outlined,          AppColors.accent),
          const SizedBox(width: 16),
          _reportSummaryCard('New This Month',   '$newThisMonth', Icons.person_add_alt_1_outlined, const Color(0xFF8B5CF6)),
        ]),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('All Customers', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  Text('${_reportCustomers.length} records', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w300, color: AppColors.textMuted)),
                ])),
                const SizedBox(width: 16),
                SizedBox(
                  width: 240,
                  height: 36,
                  child: Container(
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      const SizedBox(width: 10),
                      const Icon(Icons.search_rounded, size: 15, color: AppColors.textMuted),
                      const SizedBox(width: 7),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _customerSearchQuery = v),
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textDark),
                          decoration: InputDecoration(
                            hintText: 'Search name or phone...',
                            hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                            border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_customerSearchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() => _customerSearchQuery = ''),
                          child: const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.close_rounded, size: 13, color: AppColors.textMuted),
                          ),
                        )
                      else
                        const SizedBox(width: 8),
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(children: [
                  Expanded(flex: 1, child: _dashColHeader('#')),
                  Expanded(flex: 4, child: _dashColHeader('NAME')),
                  Expanded(flex: 3, child: _dashColHeader('PHONE')),
                  Expanded(flex: 3, child: _dashColHeader('ADDED ON', right: true)),
                ]),
              ),
              const Divider(height: 1, color: AppColors.border),
              if (_reportCustomers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('No customers yet', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                  ),
                )
              else
                ...(() {
                  final filtered = _customerSearchQuery.isEmpty
                      ? _reportCustomers
                      : _reportCustomers.where((c) {
                          final q = _customerSearchQuery.toLowerCase();
                          return c.name.toLowerCase().contains(q) ||
                              (c.phone?.toLowerCase().contains(q) ?? false);
                        }).toList();
                  if (filtered.isEmpty) return [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('No results for "$_customerSearchQuery"', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted))),
                    )
                  ];
                  return filtered.asMap().entries.map((entry) {
                  final i = entry.key;
                  final c = entry.value;
                  return Column(children: [
                    InkWell(
                      onTap: () => _showCustomerDetail(c),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                        child: Row(children: [
                          Expanded(flex: 1, child: Text('${i + 1}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted))),
                          Expanded(flex: 4, child: Text(c.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark))),
                          Expanded(flex: 3, child: Text(
                            c.phone?.isNotEmpty == true ? c.phone! : '—',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                          )),
                          Expanded(flex: 3, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            Text(
                              _fmtDate(c.createdAt),
                              textAlign: TextAlign.right,
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
                          ])),
                        ]),
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                  ]);
                }).toList();
                })(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Inventory sub-view ─────────────────────────────────────────────────────

  Widget _buildInventoryReport() {
    final totalProducts = _products.length;
    final totalStock = _products.fold<int>(0, (sum, p) => sum + p.stock);
    final totalValue = _products.fold<double>(0, (sum, p) => sum + p.price * p.stock);
    final lowStock = _products.where((p) => p.stock > 0 && p.stock <= 5).length;
    final outOfStock = _products.where((p) => p.stock == 0).length;

    return Column(
      children: [
        Row(children: [
          _reportSummaryCard('Total Products',  '$totalProducts',                     Icons.inventory_2_outlined,    AppColors.accentBlue),
          const SizedBox(width: 16),
          _reportSummaryCard('Total Stock',     '$totalStock units',                  Icons.layers_outlined,         AppColors.accent),
          const SizedBox(width: 16),
          _reportSummaryCard('Stock Value',     '$_currencySymbol${totalValue.toStringAsFixed(2)}', Icons.attach_money_rounded, const Color(0xFF059669), currencyIcon: _currencySymbol),
          const SizedBox(width: 16),
          _reportSummaryCard('Low / Out',       '$lowStock / $outOfStock',            Icons.warning_amber_rounded,   const Color(0xFFF59E0B)),
        ]),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Product Inventory', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              Text('${_products.length} items', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w300, color: AppColors.textMuted)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(children: [
                  Expanded(flex: 1, child: _dashColHeader('#')),
                  Expanded(flex: 4, child: _dashColHeader('PRODUCT')),
                  Expanded(flex: 2, child: _dashColHeader('CATEGORY')),
                  Expanded(flex: 2, child: _dashColHeader('SKU')),
                  Expanded(flex: 2, child: _dashColHeader('PRICE')),
                  Expanded(flex: 1, child: _dashColHeader('STOCK')),
                  Expanded(flex: 2, child: _dashColHeader('VALUE', right: true)),
                ]),
              ),
              const Divider(height: 1, color: AppColors.border),
              if (_products.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('No products yet', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                  ),
                )
              else
                ..._products.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  final stockColor = p.stock == 0
                      ? AppColors.error
                      : p.stock <= 5
                          ? const Color(0xFFF59E0B)
                          : AppColors.accent;
                  return Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                      child: Row(children: [
                        Expanded(flex: 1, child: Text('${i + 1}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted))),
                        Expanded(flex: 4, child: Row(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              width: 22, height: 22,
                              child: p.emoji.startsWith('/')
                                  ? Image.file(File(p.emoji), fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Text('📦', style: TextStyle(fontSize: 16)))
                                  : Center(child: Text(p.emoji.isEmpty ? '📦' : p.emoji, style: const TextStyle(fontSize: 16))),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(child: Text(p.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark), overflow: TextOverflow.ellipsis)),
                        ])),
                        Expanded(flex: 2, child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(100)),
                          child: Text(p.category, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
                        )),
                        Expanded(flex: 2, child: Text(p.sku, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted))),
                        Expanded(flex: 2, child: Text('$_currencySymbol${p.price.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textDark))),
                        Expanded(flex: 1, child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(color: stockColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text('${p.stock}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: stockColor)),
                        )),
                        Expanded(flex: 2, child: Text(
                          '$_currencySymbol${(p.price * p.stock).toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        )),
                      ]),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                  ]);
                }),
            ],
          ),
        ),
      ],
    );
  }

  // ── Account sub-view ───────────────────────────────────────────────────────


  Widget _reportPeriodBtn(String label) {
    final active = _reportSalesPeriod == label;
    return GestureDetector(
      onTap: () => setState(() => _reportSalesPeriod = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.textMuted)),
      ),
    );
  }

  Widget _reportSummaryCard(String label, String value, IconData icon, Color color, {String? currencyIcon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: currencyIcon != null
                ? Center(child: Text(currencyIcon, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: color)))
                : Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark, letterSpacing: -0.5)),
              Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textMuted)),
            ],
          ),
        ]),
      ),
    );
  }
}

// ── Product Card ─────────────────────────────────────────────────────────────

class _ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final String currencySymbol;
  const _ProductCard({required this.product, required this.onTap, required this.currencySymbol});
  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final inCart = cart.quantityInCart(widget.product.id);
    final outOfStock = (widget.product.stock - inCart) <= 0;
    return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color:
                    _hovered ? AppColors.accentBlue : AppColors.border),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                        color: AppColors.primary
                            .withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ]
                : [
                    BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 4,
                        offset: const Offset(0, 2)),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji / image area
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: widget.product.emoji.startsWith('/')
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              child: Image.file(File(widget.product.emoji),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.surfaceVariant,
                                    child: const Center(child: Text('📦', style: TextStyle(fontSize: 52))))))
                          : Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                border: const Border(bottom: BorderSide(color: AppColors.border)),
                              ),
                              child: Center(child: Text(
                                  widget.product.emoji.isEmpty ? '📦' : widget.product.emoji,
                                  style: const TextStyle(fontSize: 52)))),
                    ),
                    Consumer<CartProvider>(
                      builder: (_, cart, __) {
                        final inCart = cart.quantityInCart(widget.product.id);
                        final remaining = (widget.product.stock - inCart).clamp(0, widget.product.stock);
                        final outOfStock = remaining == 0;
                        return Stack(children: [
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: outOfStock ? AppColors.error : AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                  outOfStock ? 'OUT OF STOCK' : 'STOCK: ${remaining.toString().padLeft(2, '0')}',
                                  style: GoogleFonts.inter(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5)),
                            ),
                          ),
                          // Add button on hover
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: _hovered ? 1.0 : 0.0,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: outOfStock ? AppColors.textMuted : AppColors.accentBlue,
                                  shape: BoxShape.circle,
                                  boxShadow: outOfStock ? [] : [
                                    BoxShadow(
                                        color: AppColors.accentBlue.withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ]);
                      },
                    ),
                  ],
                ),
              ),
              // Info area
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.1)),
                    const SizedBox(height: 2),
                    Text(
                        'SKU: ${widget.product.sku}'.toUpperCase(),
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textMuted
                                .withValues(alpha: 0.7),
                            letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    Text(
                        '${widget.currencySymbol}${widget.product.price.toStringAsFixed(2)}',
                        style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: -0.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Cart Row ─────────────────────────────────────────────────────────────────

class _CartRow extends StatelessWidget {
  final CartItem item;
  final CartProvider cart;
  final String currencySymbol;
  const _CartRow({required this.item, required this.cart, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
                const SizedBox(height: 2),
                Text(
                    'SKU: ${item.product.sku}'
                        .toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textMuted
                            .withValues(alpha: 0.6),
                        letterSpacing: 0.5)),
              ],
            ),
          ),
          // Qty controls in surface-variant container
          Container(
            width: 90,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _qtyBtn(
                    Icons.remove,
                    () => cart.decrement(item.product.id)),
                SizedBox(
                  width: 32,
                  child: Text('${item.quantity}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ),
                _qtyBtn(
                    Icons.add,
                    () => cart.increment(item.product.id, stock: item.product.stock)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 82,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                    '$currencySymbol${item.total.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                Text(
                    '$currencySymbol${item.product.price.toStringAsFixed(2)}/unit',
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        color: AppColors.textMuted
                            .withValues(alpha: 0.6),
                        fontWeight: FontWeight.w300)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => cart.removeItem(item.product.id),
            child: Icon(Icons.close_rounded,
                size: 18,
                color: AppColors.textMuted
                    .withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: AppColors.primary),
      ),
    );
  }
}

// ── Discount Toggle ──────────────────────────────────────────────────────────

class _DiscountToggle extends StatefulWidget {
  final CartProvider cart;
  final String currencySymbol;
  const _DiscountToggle({required this.cart, required this.currencySymbol});
  @override
  State<_DiscountToggle> createState() => _DiscountToggleState();
}

class _DiscountToggleState extends State<_DiscountToggle> {
  final _ctrl = TextEditingController();
  DiscountType _type = DiscountType.percent;
  bool _showInput = false;

  void _onTypeBtn(DiscountType type) {
    setState(() {
      if (_type == type && _showInput) {
        // tapping active type again collapses
        _showInput = false;
      } else {
        _type = type;
        _showInput = true;
      }
    });
  }

  void _apply() {
    final v = double.tryParse(_ctrl.text) ?? 0;
    widget.cart.applyDiscount(v, _type);
    setState(() => _showInput = false);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // %/₹ toggle
        Container(
          height: 28,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _typeBtn('%', DiscountType.percent),
              _typeBtn(widget.currencySymbol, DiscountType.fixed),
            ],
          ),
        ),
        // Animated input + apply button
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _showInput
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 52,
                      height: 28,
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                        ],
                        style: GoogleFonts.inter(fontSize: 12),
                        textAlign: TextAlign.center,
                        onSubmitted: (_) => _apply(),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: AppColors.border)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: AppColors.border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                  color: AppColors.accentBlue, width: 1.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _apply,
                      child: Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                            child: Text('APPLY',
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5))),
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _typeBtn(String label, DiscountType type) {
    final selected = _type == type;
    return GestureDetector(
      onTap: () => _onTypeBtn(type),
      child: Container(
        width: 26,
        height: 22,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: AppColors.primary
                          .withValues(alpha: 0.1),
                      blurRadius: 2)
                ]
              : null,
          border: selected
              ? Border.all(
                  color: AppColors.border.withValues(alpha: 0.5))
              : null,
        ),
        child: Center(
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textMuted
                            .withValues(alpha: 0.6)))),
      ),
    );
  }
}

// ── Premium Bar Chart ─────────────────────────────────────────────────────────

class _PremiumBarChart extends StatefulWidget {
  final List<(String, double)> bars;
  final String currencySymbol;
  const _PremiumBarChart({required this.bars, required this.currencySymbol});
  @override
  State<_PremiumBarChart> createState() => _PremiumBarChartState();
}

class _PremiumBarChartState extends State<_PremiumBarChart> {
  int? _hovered;
  static const _barH = 120.0;
  static const _tipH = 28.0;
  static const _lblH = 20.0;
  static const _yW   = 44.0;

  String _fmt(double v) {
    final s = widget.currencySymbol;
    if (v >= 10000000) return '$s${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000)   return '$s${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)     return '$s${(v / 1000).toStringAsFixed(1)}K';
    return '$s${v.toStringAsFixed(0)}';
  }

  String _fmtFull(double v) {
    final s = widget.currencySymbol;
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return '$s$intPart.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final bars = widget.bars;
    if (bars.isEmpty) {
      return SizedBox(
        height: _tipH + _barH + _lblH,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.bar_chart_rounded, size: 36, color: AppColors.border),
            const SizedBox(height: 8),
            Text('No data for this period',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
          ]),
        ),
      );
    }

    final maxVal = bars.fold(0.0, (m, b) => b.$2 > m ? b.$2 : m);
    final yTicks = List.generate(5, (i) => maxVal * (4 - i) / 4);

    return SizedBox(
      height: _tipH + _barH + _lblH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Y-axis labels
          SizedBox(
            width: _yW,
            child: Stack(
              children: yTicks.asMap().entries.map((e) {
                return Positioned(
                  top: _tipH + (e.key / 4) * _barH - 8,
                  right: 6,
                  child: Text(
                    e.key == 4 ? '0' : _fmt(e.value),
                    style: GoogleFonts.inter(fontSize: 8.5, color: AppColors.textMuted),
                    textAlign: TextAlign.right,
                  ),
                );
              }).toList(),
            ),
          ),
          // Chart area
          Expanded(
            child: Stack(
              children: [
                // Horizontal grid lines
                ...yTicks.asMap().entries.map((e) => Positioned(
                  top: _tipH + (e.key / 4) * _barH,
                  left: 0, right: 0,
                  height: e.key == 4 ? 1.5 : 1,
                  child: Container(
                    color: e.key == 4
                        ? const Color(0xFFDDDDDD)
                        : const Color(0xFFF2F2F2),
                  ),
                )),
                // Bars + labels
                Positioned.fill(
                  child: Row(
                    children: bars.asMap().entries.map((e) {
                      final idx   = e.key;
                      final label = e.value.$1;
                      final val   = e.value.$2;
                      final pct   = maxVal > 0 ? val / maxVal : 0.0;
                      final isHov = _hovered == idx;
                      final anyH  = _hovered != null;

                      return Expanded(
                        child: MouseRegion(
                          cursor: val > 0 ? SystemMouseCursors.click : MouseCursor.defer,
                          onEnter: (_) => setState(() => _hovered = idx),
                          onExit:  (_) => setState(() => _hovered = null),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Tooltip (fixed height slot, fades in/out)
                              SizedBox(
                                height: _tipH,
                                child: AnimatedOpacity(
                                  opacity: isHov && val > 0 ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 140),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.35),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        _fmtFull(val),
                                        style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Bar body
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 300 + idx * 35),
                                  curve: Curves.easeOut,
                                  height: val > 0
                                      ? (_barH * pct).clamp(3.0, _barH)
                                      : 1.5,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: val > 0
                                          ? [
                                              isHov
                                                  ? const Color(0xFF1E3A8A)
                                                  : AppColors.primary.withValues(
                                                      alpha: anyH ? 0.28 : 1.0),
                                              isHov
                                                  ? const Color(0xFF60A5FA)
                                                  : AppColors.primary.withValues(
                                                      alpha: anyH ? 0.10 : 0.42),
                                            ]
                                          : [const Color(0xFFEEEEEE), const Color(0xFFEEEEEE)],
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(6)),
                                  ),
                                ),
                              ),
                              // X label
                              SizedBox(
                                height: _lblH,
                                child: Center(
                                  child: Text(
                                    label,
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: isHov ? FontWeight.w700 : FontWeight.w400,
                                      color: isHov ? AppColors.primary : AppColors.textMuted,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryCatChip extends StatefulWidget {
  final String label;
  final bool selected;
  final bool editable;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  const _InventoryCatChip({required this.label, required this.selected, required this.editable, required this.onTap, required this.onEdit});

  @override
  State<_InventoryCatChip> createState() => _InventoryCatChipState();
}

class _InventoryCatChipState extends State<_InventoryCatChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selected ? AppColors.textDark : Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: widget.selected ? AppColors.textDark : AppColors.border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.label.toUpperCase(), style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: widget.selected ? Colors.white : AppColors.textDark,
                letterSpacing: 0.3)),
            if (widget.editable && _hovered) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: widget.onEdit,
                child: Icon(Icons.edit_rounded, size: 11,
                    color: widget.selected ? Colors.white60 : AppColors.textMuted),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

