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

    // Check for failed transactions or insufficient data
    if (widget.transactionStatus?.toUpperCase() == 'FAILED' ||
        widget.transactionStatus?.toUpperCase() == 'INSUFFICIENT_DATA') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFailedTransactionMessage();
      });
      return;
    }

    // Check if transaction type indicates no records available
    if (widget.transactionType.toUpperCase() == 'NO_RECORDS' ||
        widget.transactionType.toUpperCase() == 'INSUFFICIENT_DATA') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNoRecordsMessage();
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
  void _showNoRecordsMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'No records available',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.black,
        duration: const Duration(seconds: 0),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }
  void _showFailedTransactionMessage() {
    final message = widget.transactionStatus?.toUpperCase() == 'FAILED'
        ? 'Failed transactions do not have charge slips'
        : 'No records available';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

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

  int _countNAValues(Map<String, dynamic> data) {
    int count = 0;
    final keysToCheck = [
      "txn_DATE", "txn_TIME", "id", "tid", "batch_NO", "invoice_NO",
      "card_MASKED", "card_TYPE", "application_NAME", "application_ID",
      "txn_CERTIFICATE", "tvr", "tsi", "rrn", "auth_CODE", "txn_AMOUNT_TOTAL"
    ];

    for (final key in keysToCheck) {
      if (data[key] == "N/A") count++;
    }
    return count;
  }

  Future<Map<String, dynamic>> fetchTransactionDetails(String rrn, String authToken) async {
    if (rrn.isEmpty) return {"error": "Invalid RRN provided"};

    final String encodedRRN = Uri.encodeComponent(rrn);
    final String apiUrl = "https://bportal.bijlipay.co.in:9027/txn/get-chargeslip-data/$encodedRRN/SALE";

    print('Fetching details for RRN: $rrn');
    print('Encoded URL: $apiUrl');

    try {
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
            "bank_LOGO_ID": "BPL",
            "merchant_NAME": "merchantName",
            "location": "location",
          };

          if (jsonResponse['data'] != null && jsonResponse['data'].isNotEmpty) {
            print('Valid data found: ${jsonResponse['data'][0]}');

            final apiData = jsonResponse['data'][0];
            final transactionData = {
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
              "bank_LOGO_ID": apiData["bank_LOGO_ID"]?.toString() ?? "BPL",
              "merchant_NAME": apiData["merchant_NAME"]?.toString() ?? "merchantName",
              "location": apiData["location"]?.toString() ?? "location",
            };

            if (_countNAValues(transactionData) > 4) {
              return {"error": "No records available"};
            }

            return transactionData;
          }


          if (_countNAValues(defaultData) > 4) {
            _showErrorAndNavigateBack("No records available");
            return {};
          }
          return defaultData;
        } else {
          _showErrorAndNavigateBack("Unexpected response status: ${jsonResponse['status']}");
          return {};
        }
      } else {
        _showErrorAndNavigateBack("API Error: ${response.statusCode}");
        return {};
      }
    } catch (e) {
      _showErrorAndNavigateBack("Network Error: $e");
      return {};
    }
  }

  void _showErrorAndNavigateBack(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.of(context).pop();
      });
    });
  }
  String _getBankLogoAsset(String bankId) {
    switch (bankId.toUpperCase()) {
      case "ADCB": return "assets/print_adcb.png";
      case "IBB": return "assets/print_ibb.png";
      case "APCB": return "assets/print_apcb.png";
      case "AUB": return "assets/print_aub.png";
      case "AXB": return "assets/print_axis_mono.png";
      case "BCCB": return "assets/print_bccb.png";
      case "BCUB": return "assets/print_bcub.png";
      case "BMCB": return "assets/print_bmcb.png";
      case "BPL": return "assets/print_bpl.png";
      case "CGGB": return "assets/print_cggb.png";
      case "CRGB": return "assets/print_crgb.png";
      case "CSBB": return "assets/print_csbb.png";
      case "DBS": return "assets/print_dbs.png";
      case "DCB": return "assets/print_dcb.png";
      case "EQB": return "assets/print_eqb.png";
      case "EQU": return "assets/print_equ_new.png";
      case "FDB": return "assets/print_fdb.png";
      case "GCB": return "assets/print_gcb.png";
      case "IOB": return "assets/print_iob.png";
      case "JCCB": return "assets/print_jccb.png";
      case "JRGB": return "assets/print_jrgb.png";
      case "KBL": return "assets/print_kbl.png";
      case "KCUB": return "assets/print_kcub.png";
      case "KVB": return "assets/print_kvb.png";
      case "MNSB": return "assets/print_mnsb.png";
      case "NRB": return "assets/print_nrb.png";
      case "PPY": return "assets/print_ppq.png";
      case "RBL": return "assets/print_rbl.png";
      case "RNSB": return "assets/print_rnsb.png";
      case "SBI": return "assets/print_sbi.png";
      case "SCB": return "assets/print_scb.png";
      case "SCUB": return "assets/print_scub.png";
      case "SGB": return "assets/print_sgb.png";
      case "TMCC": return "assets/print_tmcc.png";
      case "UBI": return "assets/print_ubi.png";
      case "VRK": return "assets/print_vrk.png";
      case "WCL": return "assets/print_wcl.png";
      default: return "assets/print_bpl.png";
    }
  }


  Future<void> _shareReceiptImage() async {
    try {
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

      await Future.delayed(const Duration(milliseconds: 500));

      RenderRepaintBoundary boundary = _receiptKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await file.writeAsBytes(pngBytes);

      Navigator.of(context).pop();

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Transaction Receipt - RRN: ${widget.rrn}',
        subject: 'Transaction Receipt',
      );
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing receipt: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
            // ListTile(
            //   leading: const Icon(Icons.text_fields, color: Colors.blue),
            //   title: const Text('Share as Text'),
            //   subtitle: const Text('Share receipt details as formatted text'),
            //   onTap: () {
            //     Navigator.pop(context);
            //     _shareReceiptText(data);
            //   },
            // ),
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

                  // Handle errors with SnackBar
                  if (snapshot.hasError || (snapshot.data?.containsKey("error") ?? false)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            snapshot.data?["error"] ?? snapshot.error?.toString() ?? 'Unknown error',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );

                      // Navigate back after showing the error
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) Navigator.of(context).pop();
                      });
                    });

                    // Return empty container since we're showing SnackBar and navigating back
                    return Container();
                  }

                  // Normal successful case
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
              Center(
                child: Image.asset(
                  _getBankLogoAsset(data["bank_LOGO_ID"]?.toString() ?? "BPL"),
                  height: 110,
                ),
              ),
              Center(
                child: Text(
                  data["merchant_NAME"] ?? "",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 3),
              Center(
                child: Text(
                  data["location"] ?? "",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 9),
              _transactionRowLeftRight("DATE", _formatDate(data["txn_DATE"]?.toString() ?? "N/A"), "TIME", _formatTime(data["txn_TIME"]?.toString() ?? "N/A")),
              _transactionRowLeftRight("MID", data["id"]?.toString() ?? "N/A",
                  "TID", data["tid"]?.toString() ?? "N/A"),
              _transactionRowLeftRight("BATCH NO", data["batch_NO"]?.toString() ?? "N/A",
                  "INVOICE NO", data["invoice_NO"]?.toString() ?? "N/A"),
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

  Widget _transactionRowLeftRight(String label1, String value1, String label2, String value2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
        List<String> parts = date.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            parsedDate = DateTime.parse(date);
          } else {
            parsedDate = DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0])
            );
          }
        } else {
          return date;
        }
      } else if (date.contains('/')) {
        List<String> parts = date.split('/');
        if (parts.length == 3) {
          if (int.parse(parts[0]) > 12) {
            parsedDate = DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0])
            );
          } else {
            parsedDate = DateTime(
                int.parse(parts[2]),
                int.parse(parts[0]),
                int.parse(parts[1])
            );
          }
        } else {
          return date;
        }
      } else {
        parsedDate = DateTime.parse(date);
      }

      List<String> months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];

      return "${parsedDate.day} ${months[parsedDate.month - 1]} ${parsedDate.year}";
    } catch (e) {
      return date;
    }
  }

  String _formatTime(String time) {
    if (time == "N/A" || time.isEmpty) return "N/A";

    try {
      if (time.toUpperCase().contains('AM') || time.toUpperCase().contains('PM')) {
        return time;
      }

      List<String> timeParts = time.split(':');
      if (timeParts.length < 2) return time;

      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      String period = hour >= 12 ? 'PM' : 'AM';
      int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

      return "${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period";
    } catch (e) {
      return time;
    }
  }

  Widget _transactionRowAmountLeftRight(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          Text(
            '₹${_formatAmountString(amount)}',
            style: const TextStyle(
              fontSize: 16,
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