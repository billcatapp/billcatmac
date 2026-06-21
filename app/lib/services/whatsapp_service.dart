import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class WhatsAppService {
  final String phoneNumberId;
  final String accessToken;

  WhatsAppService({required this.phoneNumberId, required this.accessToken});

  static String _normalize(String phone) {
    // Strip spaces, dashes, parens; ensure starts with country code digits only
    String p = phone.replaceAll(RegExp(r'[\s\-().+]'), '');
    if (p.startsWith('0')) p = p.substring(1); // drop leading 0
    return p;
  }

  // Upload PDF bytes as a WhatsApp media object; returns media_id or null
  Future<String?> uploadPdf(Uint8List pdfBytes, String filename) async {
    final uri = Uri.parse(
        'https://graph.facebook.com/v19.0/$phoneNumberId/media');

    final boundary = 'BillCatBoundary${DateTime.now().millisecondsSinceEpoch}';
    final body = StringBuffer();
    body.write('--$boundary\r\n');
    body.write('Content-Disposition: form-data; name="messaging_product"\r\n\r\nwhatsapp\r\n');
    body.write('--$boundary\r\n');
    body.write('Content-Disposition: form-data; name="type"\r\n\r\napplication/pdf\r\n');
    body.write('--$boundary\r\n');
    body.write(
        'Content-Disposition: form-data; name="file"; filename="$filename"\r\n');
    body.write('Content-Type: application/pdf\r\n\r\n');

    final headerBytes = utf8.encode(body.toString());
    final footer = utf8.encode('\r\n--$boundary--\r\n');
    final multipart = Uint8List(headerBytes.length + pdfBytes.length + footer.length);
    multipart.setRange(0, headerBytes.length, headerBytes);
    multipart.setRange(headerBytes.length, headerBytes.length + pdfBytes.length, pdfBytes);
    multipart.setRange(headerBytes.length + pdfBytes.length, multipart.length, footer);

    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      req.headers.set('Authorization', 'Bearer $accessToken');
      req.headers.set('Content-Type', 'multipart/form-data; boundary=$boundary');
      req.headers.contentLength = multipart.length;
      req.add(multipart);
      final res = await req.close();
      final respStr = await res.transform(utf8.decoder).join();
      final json = jsonDecode(respStr) as Map<String, dynamic>;
      if (res.statusCode == 200 && json.containsKey('id')) {
        return json['id'] as String;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  // Send a PDF document message to a phone number
  Future<bool> sendInvoicePdf({
    required String toPhone,
    required Uint8List pdfBytes,
    required String invoiceNo,
    required String storeName,
    String customerName = '',
    String amount = '',
    String date = '',
    String docType = 'Invoice',
    String invoiceLink = '',
  }) async {
    final phone = _normalize(toPhone);
    if (phone.isEmpty) return false;

    final mediaId = await uploadPdf(pdfBytes, '$docType-$invoiceNo.pdf');
    if (mediaId == null) return false;

    final name = customerName.isNotEmpty ? customerName : 'Valued Customer';
    final caption =
        'Hello $name,\n\n'
        'Thank you for choosing $storeName.\n'
        'Your e-bill for $docType #$invoiceNo has been generated successfully.\n\n'
        'Amount: $amount\n'
        'Date: $date\n'
        'Payment Status: Paid\n\n'
        'Please find your bill attached.\n\n'
        'For any queries, feel free to contact us.\n'
        'Thank you for your support!\n\n'
        '— $storeName'
        '${invoiceLink.isNotEmpty ? '\n\nView your bill: $invoiceLink' : ''}';

    final payload = jsonEncode({
      'messaging_product': 'whatsapp',
      'to': phone,
      'type': 'document',
      'document': {
        'id': mediaId,
        'filename': '$docType-$invoiceNo.pdf',
        'caption': caption,
      },
    });

    return await _sendMessage(payload);
  }

  // Send a template message (e.g. payment reminder)
  Future<bool> sendTemplate({
    required String toPhone,
    required String templateName,
    required String languageCode,
    List<String> bodyParams = const [],
  }) async {
    final phone = _normalize(toPhone);
    if (phone.isEmpty) return false;

    final components = <Map<String, dynamic>>[];
    if (bodyParams.isNotEmpty) {
      components.add({
        'type': 'body',
        'parameters': [
          for (final p in bodyParams) {'type': 'text', 'text': p},
        ],
      });
    }

    final payload = jsonEncode({
      'messaging_product': 'whatsapp',
      'to': phone,
      'type': 'template',
      'template': {
        'name': templateName,
        'language': {'code': languageCode},
        if (components.isNotEmpty) 'components': components,
      },
    });

    return await _sendMessage(payload);
  }

  Future<bool> _sendMessage(String jsonPayload) async {
    final uri = Uri.parse(
        'https://graph.facebook.com/v19.0/$phoneNumberId/messages');
    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      req.headers.set('Authorization', 'Bearer $accessToken');
      req.headers.contentType = ContentType('application', 'json');
      req.write(jsonPayload);
      final res = await req.close();
      return res.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }
}
