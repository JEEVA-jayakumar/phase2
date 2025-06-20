import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String _baseUrl = 'https://bportal.bijlipay.co.in:9027/';
  static const String _posEndpoint = 'txn/get-pos-transaction-pageable';
  static const String _qrEndpoint = 'txn/getQrTransaction-pageable';

  static Map<String, String> _buildHeaders(String authToken) => {
    'Authorization': 'Bearer $authToken',
    'Content-Type': 'application/json',
  };

  static Future<Map<String, dynamic>> fetchPOSTransactions({
    required String authToken,
    int page = 0,
    int size = 20,
    String? searchTerm,
    String? tid,
    int? txnStatus,
    List<String>? txnType,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final params = {
      'page': page.toString(),
      'size': size.toString(),
      if (searchTerm != null && searchTerm.isNotEmpty) 'searchTerm': searchTerm,
      if (tid != null && tid.isNotEmpty) 'tid': tid,
      if (txnStatus != null) 'txnStatus': txnStatus.toString(),
      if (txnType != null && txnType.isNotEmpty) 'txnType': txnType.join(','),
      if (fromDate != null) 'fromDate': (fromDate.millisecondsSinceEpoch ~/ 1000).toString(),
      if (toDate != null) 'toDate': (toDate.millisecondsSinceEpoch ~/ 1000).toString(),
    };

    final uri = Uri.parse('$_baseUrl$_posEndpoint').replace(queryParameters: params);
    final response = await http.post(
      uri,
      headers: _buildHeaders(authToken),
      body: jsonEncode({}), // Send empty JSON body as in Angular
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> fetchQrTransactions({
    required String authToken,
    int page = 0,
    int size = 20,
    String? vpa,
    String? searchTerm,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final params = {
      'page': page.toString(),
      'size': size.toString(),
      if (vpa != null && vpa.isNotEmpty) 'vpa': vpa,
      if (searchTerm != null && searchTerm.isNotEmpty) 'searchTerm': searchTerm,
      if (fromDate != null) 'fromDate': (fromDate.millisecondsSinceEpoch ~/ 1000).toString(),
      if (toDate != null) 'toDate': (toDate.millisecondsSinceEpoch ~/ 1000).toString(),
    };

    final response = await http.get(
      Uri.parse('$_baseUrl$_qrEndpoint').replace(queryParameters: params),
      headers: _buildHeaders(authToken),
    );
    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load data: ${response.statusCode}');
  }
}