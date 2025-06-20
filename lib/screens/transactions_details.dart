import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vyappar_application/screens/transactions_screen.dart';
import 'package:vyappar_application/screens/profile_screen.dart';
import 'package:vyappar_application/screens/report_screen.dart';
import 'package:vyappar_application/screens/support_screen.dart';
import 'package:vyappar_application/main.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:vyappar_application/main.dart'; // For MyApp.navigatorKey
import 'package:vyappar_application/screens/login_screen.dart'; // For LoginScreen

Color customPurple = const Color(0xFF61116A);

class TransactionDetailsScreen extends StatefulWidget {
  final String authToken;
  final String rrn;
  final List<String> terminalIds;
  final List<String> vpaList;
  final String? transactionStatus;
  final String transactionType;

  const TransactionDetailsScreen({
    Key? key,
    required this.authToken,
    required this.rrn,
    required this.terminalIds,
    required this.vpaList,
    this.transactionStatus,
    required this.transactionType,

  }) : super(key: key);

  @override
  _TransactionDetailsScreenState createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  late Future<Map<String, dynamic>> _transactionData;
  int _selectedIndex = 1;
  bool _isCustomerCopy = false;
  final GlobalKey _receiptKey = GlobalKey(); // Key for capturing the receipt
  String _currentTransactionStatus = 'SUCCESS';
  late final List<Widget> _pages;
  Future<http.Response> _handleResponse(Future<http.Response> apiCall) async {
    try {
      final response = await apiCall;
      if (response.statusCode == 401) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          MyApp.navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => LoginScreen()),
                (Route<dynamic> route) => false,
          );
        });
        throw Exception('Unauthorized');
      }
      return response;
    } catch (e) {
      if (e.toString().contains('Unauthorized')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          MyApp.navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => LoginScreen()),
                (Route<dynamic> route) => false,
          );
        });
      }
      rethrow;
    }
  }
  @override
  void initState() {
    super.initState();
    _transactionData = fetchTransactionDetails(widget.rrn, widget.authToken);
    // Check if transaction is failed before proceeding
    if (widget.transactionStatus?.toUpperCase() == 'FAILED') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFailedTransactionMessage();
      });
      return;
    }

    _transactionData = fetchTransactionDetails(widget.rrn, widget.authToken);
    _currentTransactionStatus = widget.transactionStatus?.toUpperCase() ?? 'SUCCESS';

    _pages = [
      MainScreen(
        merchantName: "Merchant Name",
        terminalIds: ["BEQ18843", "BEQ18844"],
        vpaList: ["vasanth@sbi", "vasanth@axis"],
        authToken: widget.authToken,
        mobileNo: "1234567890",
        email: "merchant@example.com",
        merchantAddress: "123 Main St",
        accountNo: "123456789",
        bankName: "Bank Name",
        ifscCode: "ABCD123456",
        branch: "Branch Name",
        rrn: widget.rrn,
      ),
      TransactionsScreen(
        terminalIds: ["BEQ18843", "BEQ18844"],
        vpaList: ["vasanth@sbi", "vasanth@axis"],
        authToken: widget.authToken,
      ),
      TransactionReportPage(
        authToken: widget.authToken,
        terminalIds: widget.terminalIds,
        vpaList: widget.vpaList,
      ),
      ProfileScreen(),
      SupportScreen(
        authToken: widget.authToken,
        terminalIds: widget.terminalIds,
        vpaList: widget.vpaList,
      ),
    ];
  }

  void _showFailedTransactionMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Failed transactions do not have charge slips',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Navigate back after showing the message
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  // Get background color based on transaction status
  Color _getBackgroundColor() {
    switch (_currentTransactionStatus.toUpperCase()) {
      case 'SUCCESS':
        return const Color(0xFFD5F0E0); // Green background
      case 'VOID':
        return const Color(0xFFFFF3E0); // Orange background
      case 'FAILED':
        return const Color(0xFFFFEBEE); // Red background (though this shouldn't be reached)
      default:
        return const Color(0xFFD5F0E0); // Default green
    }
  }

  Map<String, dynamic> _getStatusInfo() {
    switch (_currentTransactionStatus.toUpperCase()) {
      case 'SUCCESS':
        return {
          'color': const Color(0xFF007E33),
          'text': 'Payment Successful',
          'icon': Icons.check_circle
        };
      case 'VOID':
        return {
          'color': const Color(0xFFFF8F00),
          'text': 'Payment Voided',
          'icon': Icons.error
        };
      case 'FAILED':
        return {
          'color': const Color(0xFFD32F2F),
          'text': 'Payment Failed',
          'icon': Icons.cancel
        };
      default:
        return {
          'color': const Color(0xFF007E33),
          'text': 'Payment Successful',
          'icon': Icons.check_circle
        };
    }
  }


  Future<Map<String, dynamic>> fetchTransactionDetails(String rrn, String authToken) async {
    if (rrn.isEmpty) return {"error": "Invalid RRN provided"};

    try {
      final String encodedRRN = Uri.encodeComponent(rrn);
      final String apiUrl = "https://bportal.bijlipay.co.in:9027/txn/get-chargeslip-data/$encodedRRN/SALE";

      print('Fetching details for RRN: $rrn');
      print('Encoded URL: $apiUrl');

      // Wrap the HTTP call with _handleResponse
      final response = await _handleResponse(
        http.get(
          Uri.parse(apiUrl),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Handle 401 Unauthorized - Navigate to login

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        print('Full API Response: $jsonResponse');

        if (jsonResponse['status'] == "OK") {
          final defaultData = {
            "transactionDate": "N/A",
            "transactionTime": "N/A",
            "merchantId": "N/A",
            "terminalId": "N/A",
            "amount": "",
            "card_MASKED": "N/A",
            "card_TYPE": "N/A",
            "application_NAME": "N/A",
            "application_ID": "N/A",
            "txn_CERTIFICATE": "N/A",
            "tvr": "N/A",
            "tsi": "N/A",
            "rrn": rrn,
            "txn_AMOUNT_TOTAL": "",
            "batch_NO": "N/A",
            "invoice_NO": "N/A",
            "auth_CODE": "N/A",
            "status": _currentTransactionStatus,
          };

          if (jsonResponse['data'] != null && jsonResponse['data'].isNotEmpty) {
            print('Valid data found: ${jsonResponse['data'][0]}');

            // Map the API response fields to our expected fields
            final apiData = jsonResponse['data'][0];
            return {
              ...defaultData,
              "id": apiData["mid"]?.toString() ?? "N/A",
              "tid": apiData["tid"]?.toString() ?? "N/A",
              "txn_DATE": apiData["txn_DATE"]?.toString() ?? "N/A",
              "txn_TIME": apiData["txn_TIME"]?.toString() ?? "N/A",
              "batch_NO": apiData["batch_NUMBER"]?.toString() ?? "N/A",
              "invoice_NO": apiData["invoice_NUMBER"]?.toString() ?? "N/A",
              "card_MASKED": apiData["card_MASKED"]?.toString() ?? "N/A",
              "card_TYPE": apiData["card_TYPE"]?.toString() ?? "N/A",
              "application_NAME": apiData["application_NAME"]?.toString() ?? "N/A",
              "application_ID": apiData["application_ID"]?.toString() ?? "N/A",
              "txn_CERTIFICATE": apiData["txn_CERTIFICATE"]?.toString() ?? "N/A",
              "tvr": apiData["tvr"]?.toString() ?? "N/A",
              "tsi": apiData["tsi"]?.toString() ?? "N/A",
              "rrn": apiData["rrn"]?.toString() ?? rrn,
              "auth_CODE": apiData["auth_CODE"]?.toString() ?? "N/A",
              "txn_AMOUNT_TOTAL": apiData["txn_AMOUNT_TOTAL"]?.toString() ?? "0",
              "status": apiData["txn_STATUS"]?.toString() ?? "Success",
              "rawTxnType": apiData["txnType"]?.toString() ?? '',
            };
          }

          print('No data found, using default structure');
          return defaultData;
        }
        return {"error": "Unexpected response status: ${jsonResponse['status']}"};
      }
      return {"error": "API Error: ${response.statusCode}"};
    } catch (e) {
      print('Error: $e');
      return {"error": "Network Error: $e"};
    }
  }

  void _navigateToLogin() {
    // Clear all previous routes and navigate to login
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login', // Replace with your actual login route
          (Route<dynamic> route) => false,
    );
  }

  Future<void> _shareReceiptText(Map<String, dynamic> data) async {
    // Helper function to pad text for alignment
    String padLine(String left, String right, int totalWidth) {
      int leftLen = left.length;
      int rightLen = right.length;
      int spacesNeeded = totalWidth - leftLen - rightLen;
      if (spacesNeeded <= 0) return '$left $right';
      return left + ' ' * spacesNeeded + right;
    }

    // Helper function to center text within width
    String centerText(String text, int width) {
      if (text.length >= width) return text;
      int spaces = (width - text.length) ~/ 2;
      return ' ' * spaces + text + ' ' * (width - text.length - spaces);
    }

    final String receiptText = '''
═══════════════════════════════════════
           BIJLIPAY
    Skillworth Technologies Limited
        S No7 GR FL GTB NGR DL
═══════════════════════════════════════

${padLine('DATE: ${_formatDate(data["txn_DATE"]?.toString() ?? "N/A")}', 'TIME: ${_formatTime(data["txn_TIME"]?.toString() ?? "N/A")}', 39)}
${padLine('MID: ${data["id"]?.toString() ?? "N/A"}', 'TID: ${data["tid"]?.toString() ?? "N/A"}', 39)}
${padLine('BATCH NO: ${data["batch_NO"]?.toString() ?? "N/A"}', 'INVOICE NO: ${data["invoice_NO"]?.toString() ?? "N/A"}', 39)}

// ${padLine('AMOUNT:', '₹${_formatAmountString(data["txn_AMOUNT_TOTAL"]?.toString() ?? "0")}', 39)}

═══════════════════════════════════════
                 SALE
───────────────────────────────────────

CARD NO: ${data["card_MASKED"] ?? "N/A"}
CARD Type: ${data["card_TYPE"] ?? "N/A"}
APP Name: ${data["application_NAME"] ?? "N/A"}
AID: ${data["application_ID"] ?? "N/A"}
TC: ${data["txn_CERTIFICATE"] ?? "N/A"}
${padLine('TVR: ${data["tvr"] ?? "N/A"}', 'TSI: ${data["tsi"] ?? "N/A"}', 39)}
${padLine('RRN: ${data["rrn"] ?? "N/A"}', 'AUTH CODE: ${data["auth_CODE"] ?? "N/A"}', 39)}

${padLine('AMOUNT:', '₹${_formatAmountString(data["txn_AMOUNT_TOTAL"]?.toString() ?? "0")}', 39)}

───────────────────────────────────────
            *PIN VERIFIED OK*
           NO Signature Required
───────────────────────────────────────

I CONFIRM THE RECEIPT OF GOODS/CASH/SERVICES
HERE WILL OBSERVE MY AGREEMENT WITH CARD ISSUER

${centerText(_isCustomerCopy ? "*** CUSTOMER COPY ***" : "*** MERCHANT COPY ***", 39)}

        Version-1.0.87 Powered by bijlipay
═══════════════════════════════════════
  ''';

    await Share.share(
      receiptText,
      subject: 'Transaction Receipt - RRN: ${data["rrn"] ?? "N/A"}',
    );
  }

  Future<void> _shareReceiptImage() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Preparing receipt...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Wait a moment for the UI to settle
      await Future.delayed(const Duration(milliseconds: 500));

      // Capture the receipt as image
      RenderRepaintBoundary boundary = _receiptKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await file.writeAsBytes(pngBytes);

      // Close loading dialog
      Navigator.of(context).pop();

      // Share the image
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Transaction Receipt - RRN: ${widget.rrn}',
        subject: 'Transaction Receipt',
      );
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing receipt: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show share options dialog
  void _showShareOptions(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share Receipt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.text_fields, color: Colors.blue),
              title: const Text('Share as Text'),
              subtitle: const Text('Share receipt details as formatted text'),
              onTap: () {
                Navigator.pop(context);
                _shareReceiptText(data);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.green),
              title: const Text('Share as Image'),
              subtitle: const Text('Share receipt as an image'),
              onTap: () {
                Navigator.pop(context);
                _shareReceiptImage();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Helper method to format amount as string
  String _formatAmountString(String amount) {
    try {
      if (amount.isEmpty) return "0.00";

      String trimmedAmount = amount.replaceFirst(RegExp(r'^0+'), '');
      if (trimmedAmount.isEmpty) return "0.00";

      if (trimmedAmount.length < 3) {
        trimmedAmount = trimmedAmount.padLeft(3, '0');
      }

      return trimmedAmount.substring(0, trimmedAmount.length - 2) +
          '.' +
          trimmedAmount.substring(trimmedAmount.length - 2);
    } catch (e) {
      return "0.00";
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => _pages[index],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0xFF38383814),
                offset: Offset(0, 4),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: AppBar(
            automaticallyImplyLeading: false,
            title: Image.asset(
              'assets/logo.png',
              height: 30,
              fit: BoxFit.contain,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF38383814),
                    offset: Offset(0, 4),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                        Icons.arrow_back_ios_outlined, color: Colors.black,
                        size: 12),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _transactionData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 20),
                          Text("Fetching transaction details..."),
                        ],
                      ),
                    );
                  }
                  final errorMessage = snapshot.data?["error"];
                  final hasError = snapshot.hasError || errorMessage != null;

                  if (hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          "Error: ${errorMessage ??
                              snapshot.error?.toString() ?? 'Unknown error'}",
                          style: const TextStyle(
                              color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildHeader(snapshot.data!),
                          RepaintBoundary(
                            key: _receiptKey,
                            child: _buildReceiptCard(snapshot.data!),
                          ),
                          _buildCustomerCopyButton(),
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(0, -1),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: customPurple,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz),
              label: 'Transaction',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              label: 'Report',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.call),
              label: 'Support',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    final statusInfo = _getStatusInfo();
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Icon(statusInfo['icon'], color: statusInfo['color'], size: 17.5),
          const SizedBox(width: 3),
          Text(
            statusInfo['text'],
            style: TextStyle(
              fontSize: 17.5,
              fontWeight: FontWeight.w700,
              color: statusInfo['color'],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showShareOptions(data),
            child: const Icon(Icons.share, color: Color(0xFF383838), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCopyButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _isCustomerCopy = !_isCustomerCopy;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFFFFF),
          foregroundColor: const Color(0xFF000000),
          side: const BorderSide(color: Color(0xFF000000)),
          padding: const EdgeInsets.symmetric(vertical: 13),
          minimumSize: const Size(double.infinity, 30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        child: Text(
          _isCustomerCopy ? "VIEW MERCHANT COPY" : "VIEW CUSTOMER COPY",
        ),
      ),
    );
  }

  Widget _buildReceiptCard(Map<String, dynamic> data) {
    const double cardPadding = 26.0;
    const double spacing = 4.0;

    return ClipPath(
      clipper: ReceiptEdgeClipper(),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Image.asset("assets/axis.png", height: 110)),
              const Center(
                child: Text(
                  "BIJLIPAY Skillworth Technologies Limited",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  "S No7 GR FL GTB NGR DL",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 5),
              _transactionRowLeftRight("DATE", _formatDate(data["txn_DATE"]?.toString() ?? "N/A"), "TIME", _formatTime(data["txn_TIME"]?.toString() ?? "N/A")),
              _transactionRowLeftRight("MID", data["id"]?.toString() ?? "N/A",
                  "TID", data["tid"]?.toString() ?? "N/A"),
              _transactionRowLeftRight("BATCH NO", data["batch_NO"]?.toString() ?? "N/A",
                  "INVOICE NO", data["invoice_NO"]?.toString() ?? "N/A"),
              // _transactionRowAmountLeftRight("AMOUNT", data["txn_AMOUNT_TOTAL"]?.toString() ?? "0"),
              const SizedBox(height: spacing),
              const Center(
                child: Text(
                  "SALE",
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 1),
              _transactionRowLeft("CARD NO", data["card_MASKED"] ?? "N/A"),
              _transactionRowLeft("CARD Type", data["card_TYPE"] ?? "N/A"),
              _transactionRowLeft("APP Name", data["application_NAME"] ?? "N/A"),
              _transactionRowLeft("AID", data["application_ID"] ?? "N/A"),
              _transactionRowLeft("TC", data["txn_CERTIFICATE"] ?? "N/A"),
              _transactionRowLeftRight("TVR", data["tvr"] ?? "N/A", "TSI", data["tsi"] ?? "N/A"),
              _transactionRowLeftRight("RRN", data["rrn"] ?? "N/A", "AUTH CODE", data["auth_CODE"] ?? "N/A"),
              _transactionRowAmountLeftRight("AMOUNT", data["txn_AMOUNT_TOTAL"]?.toString() ?? "0"),
              const Divider(height: 24),
              const Center(
                child: Text(
                  "*PIN VERIFIED OK*",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 3),
              const Center(child: Text(
                  "NO Signature Required", style: TextStyle(fontSize: 13))),
              const SizedBox(height: spacing),
              const Divider(height: 24),
              const Text(
                "I CONFIRM THE RECEIPT OF GOODS/CASH/SERVICES HERE WILL OBSERVE MY AGREEMENT WITH CARD ISSUER",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _isCustomerCopy
                      ? "*** CUSTOMER COPY ***"
                      : "*** MERCHANT COPY ***",
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 3),
              const Center(
                child: Text(
                  "Version-1.0.87 Powered by bijlipay",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for left-aligned rows
  Widget _transactionRowLeft(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for left-right aligned rows (DATE-TIME, MID-TID, TVR-TSI)
  Widget _transactionRowLeftRight(String label1, String value1, String label2, String value2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label1: ',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: value1,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          // Right side
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label2: ',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: value2,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    if (date == "N/A" || date.isEmpty) return "N/A";

    try {
      DateTime parsedDate;

      if (date.contains('-')) {
        // Handle YYYY-MM-DD or DD-MM-YYYY format
        List<String> parts = date.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            // YYYY-MM-DD format
            parsedDate = DateTime.parse(date);
          } else {
            // DD-MM-YYYY format
            parsedDate = DateTime(
                int.parse(parts[2]), // year
                int.parse(parts[1]), // month
                int.parse(parts[0])  // day
            );
          }
        } else {
          return date;
        }
      } else if (date.contains('/')) {
        // Handle MM/DD/YYYY or DD/MM/YYYY format
        List<String> parts = date.split('/');
        if (parts.length == 3) {
          // Assume MM/DD/YYYY format (American) if first part is month-like
          if (int.parse(parts[0]) > 12) {
            // DD/MM/YYYY format
            parsedDate = DateTime(
                int.parse(parts[2]), // year
                int.parse(parts[1]), // month
                int.parse(parts[0])  // day
            );
          } else {
            // MM/DD/YYYY format
            parsedDate = DateTime(
                int.parse(parts[2]), // year
                int.parse(parts[0]), // month
                int.parse(parts[1])  // day
            );
          }
        } else {
          return date;
        }
      } else {
        // Try to parse as standard format
        parsedDate = DateTime.parse(date);
      }

      // Format as DD Month YYYY (e.g., "15 January 2024")
      List<String> months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];

      return "${parsedDate.day} ${months[parsedDate.month - 1]} ${parsedDate.year}";
    } catch (e) {
      // If parsing fails, return as is
      return date;
    }
  }

// Add this new method for time formatting with AM/PM
  String _formatTime(String time) {
    if (time == "N/A" || time.isEmpty) return "N/A";

    try {
      // Check if time already has AM/PM
      if (time.toUpperCase().contains('AM') || time.toUpperCase().contains('PM')) {
        return time;
      }

      // Parse time in HH:MM:SS or HH:MM format
      List<String> timeParts = time.split(':');
      if (timeParts.length < 2) return time;

      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      // Convert to 12-hour format with AM/PM
      String period = hour >= 12 ? 'PM' : 'AM';
      int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

      return "${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period";
    } catch (e) {
      return time;
    }
  }

// Helper method for left-right aligned amount rows (title left, data right)
Widget _transactionRowAmountLeftRight(String label, String amount) {
return Padding(
padding: const EdgeInsets.symmetric(vertical: 4.0),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
// Left side - Label
Text(
'$label:',
style: const TextStyle(
fontSize: 16, // Bigger font size
fontWeight: FontWeight.w700,
color: Colors.black,
),
),
// Right side - Amount
Text(
'₹${_formatAmountString(amount)}',
style: const TextStyle(
fontSize: 16, // Bigger font size
fontWeight: FontWeight.w700,
color: Colors.black,
),
),
],
),
);
}
}

class ReceiptEdgeClipper extends CustomClipper<Path> {
@override
Path getClip(Size size) {
final path = Path();
const edgeHeight = 10.0;
const triangleWidth = 15.0;

path.moveTo(0, edgeHeight);
for (double x = 0; x < size.width; x += triangleWidth) {
path.lineTo(x + triangleWidth / 2, 0);
path.lineTo(x + triangleWidth, edgeHeight);
}

path.lineTo(size.width, size.height - edgeHeight);

for (double x = size.width; x > 0; x -= triangleWidth) {
path.lineTo(x - triangleWidth / 2, size.height);
path.lineTo(x - triangleWidth, size.height - edgeHeight);
}

path.lineTo(0, edgeHeight);
path.close();

return path;
}

@override
bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}