import 'dart:convert';
import 'dart:io';

/// Raw label-printer command language. Covers the vast majority of thermal
/// barcode printers: TSPL for GODEX / TSC / TVS-LP, ZPL for Zebra.
enum LabelLanguage { tspl, zpl }

/// How labels are delivered to the printer.
/// [pdf] uses the OS print system (the fallback path). [network] sends raw
/// TSPL/ZPL bytes over TCP :9100. [usb] sends raw bytes to a USB printer via
/// the CUPS queue with `lp -o raw`, which bypasses the (often wrong/missing)
/// driver entirely — the reliable path for USB GODEX/TSC/TVS on macOS.
enum LabelTransport { pdf, network, usb }

extension LabelLanguageX on LabelLanguage {
  String get label => this == LabelLanguage.zpl ? 'ZPL (Zebra)' : 'TSPL (GODEX / TSC / TVS)';
  String get code => this == LabelLanguage.zpl ? 'zpl' : 'tspl';
  static LabelLanguage fromCode(String? c) =>
      c == 'zpl' ? LabelLanguage.zpl : LabelLanguage.tspl;
}

/// Per-device printer configuration. Stored locally (never synced to the cloud)
/// so each machine keeps its own printer/IP without clashing with other devices
/// on the same account.
class LabelPrinterProfile {
  final LabelTransport transport;
  final LabelLanguage language;
  final String host; // IP / hostname for network printers
  final int port; // raw port, almost always 9100
  final int dpi; // 203 (common) or 300
  final String queue; // CUPS queue name for USB printers (e.g. GODEX_G500)

  const LabelPrinterProfile({
    this.transport = LabelTransport.pdf,
    this.language = LabelLanguage.tspl,
    this.host = '',
    this.port = 9100,
    this.dpi = 203,
    this.queue = '',
  });

  bool get isNetwork => transport == LabelTransport.network && host.trim().isNotEmpty;
  bool get isUsb => transport == LabelTransport.usb && queue.trim().isNotEmpty;
  bool get isRaw => isNetwork || isUsb;

  LabelPrinterProfile copyWith({
    LabelTransport? transport,
    LabelLanguage? language,
    String? host,
    int? port,
    int? dpi,
    String? queue,
  }) =>
      LabelPrinterProfile(
        transport: transport ?? this.transport,
        language: language ?? this.language,
        host: host ?? this.host,
        port: port ?? this.port,
        dpi: dpi ?? this.dpi,
        queue: queue ?? this.queue,
      );

  static String _t(LabelTransport t) => switch (t) {
        LabelTransport.network => 'network',
        LabelTransport.usb => 'usb',
        LabelTransport.pdf => 'pdf',
      };

  Map<String, dynamic> toJson() => {
        'transport': _t(transport),
        'language': language.code,
        'host': host,
        'port': port,
        'dpi': dpi,
        'queue': queue,
      };

  static LabelPrinterProfile fromJson(Map<String, dynamic> m) => LabelPrinterProfile(
        transport: switch (m['transport']) {
          'network' => LabelTransport.network,
          'usb' => LabelTransport.usb,
          _ => LabelTransport.pdf,
        },
        language: LabelLanguageX.fromCode(m['language'] as String?),
        host: (m['host'] as String?) ?? '',
        port: (m['port'] as num?)?.toInt() ?? 9100,
        dpi: (m['dpi'] as num?)?.toInt() ?? 203,
        queue: (m['queue'] as String?) ?? '',
      );
}

/// Physical label geometry, in millimetres.
class LabelSpec {
  final double labelWmm; // one label width
  final double labelHmm; // one label height
  final int columns; // labels across the liner (Per Row)
  final double gapMm; // vertical gap between label rows

  const LabelSpec({
    required this.labelWmm,
    required this.labelHmm,
    this.columns = 1,
    this.gapMm = 2.0,
  });

  double get fullWidthMm => labelWmm * columns;
}

/// A product to encode onto labels.
class LabelItem {
  final String barcodeValue;
  final String name;
  final String price;
  final int count;

  const LabelItem({
    required this.barcodeValue,
    required this.name,
    required this.price,
    this.count = 1,
  });
}

class LabelPrinterService {
  // ── Device-local persistence ────────────────────────────────────────────
  static Future<String> _configDir() async {
    String base;
    if (Platform.isWindows) {
      base = Platform.environment['APPDATA'] ?? Directory.systemTemp.path;
    } else {
      final home = Platform.environment['HOME'] ?? Directory.systemTemp.path;
      base = '$home/Library/Application Support';
    }
    final dir = Directory('$base/BillCat');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  static Future<File> _profileFile() async =>
      File('${await _configDir()}/label_printer.json');

  static LabelPrinterProfile _cached = const LabelPrinterProfile();
  static LabelPrinterProfile get cached => _cached;

  static Future<LabelPrinterProfile> load() async {
    try {
      final f = await _profileFile();
      if (await f.exists()) {
        final map = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _cached = LabelPrinterProfile.fromJson(map);
      }
    } catch (_) {}
    return _cached;
  }

  static Future<void> save(LabelPrinterProfile p) async {
    _cached = p;
    try {
      final f = await _profileFile();
      await f.writeAsString(jsonEncode(p.toJson()));
    } catch (_) {}
  }

  // ── Device-local barcode settings (printer name, label size, per-row) ──────
  // Kept out of the synced cloud settings so each machine remembers its OWN
  // printer/label stock without clashing with other devices on the account.
  static Future<File> _barcodeFile() async =>
      File('${await _configDir()}/barcode_settings.json');

  static Map<String, dynamic> _barcode = {};
  static Map<String, dynamic> get barcodeSettings => _barcode;

  static Future<Map<String, dynamic>> loadBarcodeSettings() async {
    try {
      final f = await _barcodeFile();
      if (await f.exists()) {
        _barcode = (jsonDecode(await f.readAsString()) as Map).cast<String, dynamic>();
      }
    } catch (_) {}
    return _barcode;
  }

  static Future<void> saveBarcodeSettings(Map<String, dynamic> patch) async {
    _barcode = {..._barcode, ...patch};
    try {
      final f = await _barcodeFile();
      await f.writeAsString(jsonEncode(_barcode));
    } catch (_) {}
  }

  // ── Command generation ──────────────────────────────────────────────────
  static int _dots(double mm, int dpi) => (mm * dpi / 25.4).round();

  /// Sanitise text for a raw label command (ASCII only, no quotes/control).
  static String _clean(String s) => s
      .replaceAll('"', ' ')
      .replaceAll('^', ' ')
      .replaceAll('~', '-')
      .replaceAll(RegExp(r'[\x00-\x1f]'), ' ')
      .replaceAll(RegExp(r'[^\x20-\x7e]'), '')
      .trim();

  /// Flatten items into a single list honouring each item's [count].
  static List<LabelItem> _flatten(List<LabelItem> items) {
    final out = <LabelItem>[];
    for (final it in items) {
      final n = it.count < 1 ? 1 : it.count;
      for (var i = 0; i < n; i++) out.add(it);
    }
    return out;
  }

  static String buildTspl(List<LabelItem> items, LabelSpec spec, int dpi) {
    final flat = _flatten(items);
    final b = StringBuffer();
    final fullW = spec.fullWidthMm.toStringAsFixed(1);
    final labelH = spec.labelHmm.toStringAsFixed(1);
    final gap = spec.gapMm.toStringAsFixed(1);

    final colWDots = _dots(spec.labelWmm, dpi);
    final padX = _dots(2.0, dpi); // inner left padding per label
    final barH = _dots(spec.labelHmm * 0.5, dpi).clamp(20, 100000);
    final yBar = _dots(1.5, dpi);
    final yName = yBar + barH + _dots(1.0, dpi);
    final yPrice = yName + (dpi ~/ 12) + 14;

    b.writeln('SIZE $fullW mm,$labelH mm');
    b.writeln('GAP $gap mm,0 mm');
    b.writeln('DIRECTION 1');
    b.writeln('CLS');

    for (var start = 0; start < flat.length; start += spec.columns) {
      b.writeln('CLS');
      final end = (start + spec.columns).clamp(0, flat.length);
      for (var i = start; i < end; i++) {
        final it = flat[i];
        final col = i - start;
        final x = col * colWDots + padX;
        final val = _clean(it.barcodeValue);
        if (val.isEmpty) continue;
        // BARCODE x,y,"type",height,human,rotation,narrow,wide,"content"
        b.writeln('BARCODE $x,$yBar,"128",$barH,0,0,2,2,"$val"');
        final name = _clean(it.name);
        final price = _clean(it.price);
        if (name.isNotEmpty) b.writeln('TEXT $x,$yName,"1",0,1,1,"$name"');
        if (price.isNotEmpty) b.writeln('TEXT $x,$yPrice,"1",0,1,1,"$price"');
      }
      b.writeln('PRINT 1,1');
    }
    return b.toString();
  }

  static String buildZpl(List<LabelItem> items, LabelSpec spec, int dpi) {
    final flat = _flatten(items);
    final b = StringBuffer();
    final fullWDots = _dots(spec.fullWidthMm, dpi);
    final labelHDots = _dots(spec.labelHmm, dpi);
    final colWDots = _dots(spec.labelWmm, dpi);
    final padX = _dots(2.0, dpi);
    final barH = _dots(spec.labelHmm * 0.5, dpi).clamp(20, 100000);
    final yBar = _dots(1.5, dpi);
    final yName = yBar + barH + _dots(1.0, dpi);
    final yPrice = yName + 22;

    for (var start = 0; start < flat.length; start += spec.columns) {
      b.writeln('^XA');
      b.writeln('^PW$fullWDots');
      b.writeln('^LL$labelHDots');
      final end = (start + spec.columns).clamp(0, flat.length);
      for (var i = start; i < end; i++) {
        final it = flat[i];
        final col = i - start;
        final x = col * colWDots + padX;
        final val = _clean(it.barcodeValue);
        if (val.isEmpty) continue;
        b.writeln('^FO$x,$yBar^BY2^BCN,$barH,N,N,N^FD$val^FS');
        final name = _clean(it.name);
        final price = _clean(it.price);
        if (name.isNotEmpty) b.writeln('^FO$x,$yName^A0N,18,18^FD$name^FS');
        if (price.isNotEmpty) b.writeln('^FO$x,$yPrice^A0N,18,18^FD$price^FS');
      }
      b.writeln('^XZ');
    }
    return b.toString();
  }

  static String buildCommands(List<LabelItem> items, LabelSpec spec, LabelPrinterProfile p) =>
      p.language == LabelLanguage.zpl
          ? buildZpl(items, spec, p.dpi)
          : buildTspl(items, spec, p.dpi);

  // ── Transport ───────────────────────────────────────────────────────────
  /// Sends raw bytes to a network printer over TCP. Throws on failure so the
  /// caller can surface the error and fall back to PDF.
  static Future<void> sendRawNetwork(String data, LabelPrinterProfile p) async {
    final socket = await Socket.connect(
      p.host.trim(),
      p.port,
      timeout: const Duration(seconds: 6),
    );
    try {
      socket.add(latin1.encode(data));
      await socket.flush();
    } finally {
      await socket.close();
      socket.destroy();
    }
  }

  /// Sends raw bytes to a USB printer via its CUPS queue using `lp -o raw`,
  /// which bypasses the queue's driver/PPD and delivers the bytes untouched.
  static Future<void> sendRawUsb(String data, String queue) async {
    final tmp = await Directory.systemTemp.createTemp('billcat_lbl_');
    final f = File('${tmp.path}/label.prn');
    await f.writeAsString(data, encoding: latin1, flush: true);
    final res = await Process.run('/usr/bin/lp', ['-d', queue, '-o', 'raw', f.path]);
    try { await tmp.delete(recursive: true); } catch (_) {}
    if (res.exitCode != 0) {
      throw Exception((res.stderr as String?)?.trim().isNotEmpty == true
          ? (res.stderr as String).trim()
          : 'lp exited with code ${res.exitCode}');
    }
  }

  /// The CUPS queue names available on this machine (raw names, e.g. GODEX_G500).
  static Future<List<String>> listQueues() async {
    if (Platform.isWindows) return const [];
    try {
      final res = await Process.run('/usr/bin/lpstat', ['-e'])
          .timeout(const Duration(seconds: 3));
      return '${res.stdout}'.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Builds commands for [items] and sends them over the configured raw
  /// transport (network or USB). Only valid when [profile.isRaw].
  static Future<void> printBatch(
    List<LabelItem> items,
    LabelSpec spec,
    LabelPrinterProfile profile,
  ) async {
    final data = buildCommands(items, spec, profile);
    if (profile.transport == LabelTransport.usb) {
      await sendRawUsb(data, profile.queue.trim());
    } else {
      await sendRawNetwork(data, profile);
    }
  }

  /// A single calibration label so users can confirm size/alignment.
  static Future<void> printTestLabel(LabelSpec spec, LabelPrinterProfile profile) async {
    final item = LabelItem(
      barcodeValue: 'BILLCAT123',
      name: 'BillCat Test',
      price: 'OK',
      count: 1,
    );
    // Force a single label for the test regardless of columns.
    final testSpec = LabelSpec(
      labelWmm: spec.labelWmm,
      labelHmm: spec.labelHmm,
      columns: 1,
      gapMm: spec.gapMm,
    );
    await printBatch([item], testSpec, profile);
  }
}
