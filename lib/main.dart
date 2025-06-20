import 'package:flutter/material.dart';
import 'package:vyappar_application/screens/createTicketScreen.dart';
import 'screens/transactions_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/riskHold_screen.dart';
import 'screens/report_screen.dart';
import 'screens/support_screen.dart';
import 'screens/login_screen.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:flutter/services.dart';
import 'screens/transactions_details.dart';
import 'screens/Initial_login.dart';
import 'screens/NotificationScreen.dart';
import 'screens/createTicketScreen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

Color customPurple = Color(0xFF61116A);

class AppState {
  static AppState? _instance;
  static AppState get instance => _instance ??= AppState._();
  AppState._();

  // App state variables (will reset when app is closed)
  bool initialLoginDone = false;
  String? mobileNumber;
  String? merchantName;
  String? authToken;
  String? email;
  String? merchantAddress;
  String? accountNo;
  String? bankName;
  String? ifscCode;
  String? branch;
  List<String> terminalIds = [];
  List<String> vpaList = [];

  // Methods to manage state
  void setInitialLoginDone(bool value) {
    initialLoginDone = value;
  }

  void setUserData({
    String? mobile,
    String? merchant,
    String? token,
    String? userEmail,
    String? address,
    String? account,
    String? bank,
    String? ifsc,
    String? branchName,
    List<String>? terminals,
    List<String>? vpas,
  }) {
    if (mobile != null) mobileNumber = mobile;
    if (merchant != null) merchantName = merchant;
    if (token != null) authToken = token;
    if (userEmail != null) email = userEmail;
    if (address != null) merchantAddress = address;
    if (account != null) accountNo = account;
    if (bank != null) bankName = bank;
    if (ifsc != null) ifscCode = ifsc;
    if (branchName != null) branch = branchName;
    if (terminals != null) terminalIds = terminals;
    if (vpas != null) vpaList = vpas;
  }

  void clearUserData() {
    initialLoginDone = false;
    mobileNumber = null;
    merchantName = null;
    authToken = null;
    email = null;
    merchantAddress = null;
    accountNo = null;
    bankName = null;
    ifscCode = null;
    branch = null;
    terminalIds.clear();
    vpaList.clear();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app state (will always start fresh without persistence)
  final appState = AppState.instance;

  runApp(MyApp(initialLoginDone: appState.initialLoginDone));
}

class StaticQRChargeSlip extends StatefulWidget {
  final Map<String, dynamic> transactionData;

  const StaticQRChargeSlip({Key? key, required this.transactionData}) : super(key: key);

  @override
  _StaticQRChargeSlipState createState() => _StaticQRChargeSlipState();
}
class _StaticQRChargeSlipState extends State<StaticQRChargeSlip> {
  bool _isCustomerCopy = false;
  final GlobalKey _receiptKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // Safely extract values with fallbacks
    final amount = widget.transactionData['transactionAmount']?.replaceAll('₹', '') ?? '0.00';
    final timestamp = widget.transactionData['transactionTimestamp'] ?.toString() ?? 'Unknown Time';
    final txnId = widget.transactionData['merchantTransactionId'] ?? 'N/A';
    final customerVpa = widget.transactionData['customerVpa'] ?? 'N/A';
    final creditVpa = widget.transactionData['creditVpa'] ?? 'N/A';

    return Scaffold(
      backgroundColor: const Color(0xFFD5F0E0),
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
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.black, size: 20),
                    onPressed: () => _showShareOptions(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 20), // Add top spacing
                      Center( // Wrap with Center widget
                        child: RepaintBoundary(
                          key: _receiptKey,
                          child: _buildReceiptCard(
                            amount: amount,
                            timestamp: timestamp,
                            txnId: txnId,
                            customerVpa: customerVpa,
                            creditVpa: creditVpa,
                          ),
                        ),
                      ),
                      _buildCustomerCopyButton(),
                      const SizedBox(height: 20), // Add bottom spacing
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildReceiptCard({
    required String amount,
    required String timestamp,
    required String txnId,
    required String customerVpa,
    required String creditVpa,
  }) {
    const double cardPadding = 26.0;

    String formattedDate = '';
    String formattedTime = '';

    try {
      DateTime parsedDate = DateTime.parse(timestamp);
      formattedDate = DateFormat('dd-MM-yyyy').format(parsedDate);
      formattedTime = DateFormat('hh:mm:ss a').format(parsedDate);
    } catch (e) {
      print('Error parsing date: $e');
      formattedDate = 'Unknown Date';
      formattedTime = 'Unknown Time';
    }

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
            children: [
              // Header
              Image.asset("assets/bijli_logo.png", height: 80),
              const Text(
                "BIJLIPAY Skillworth Technologies Limited",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Dotted line
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: List.generate(50, (index) => Expanded(
                    child: Container(
                      height: 1,
                      color: index % 2 == 0 ? Colors.grey : Colors.transparent,
                    ),
                  )),
                ),
              ),

              // Transaction details
              _receiptRow("DATE", formattedDate),
              _receiptRow("TIME", formattedTime),
              _receiptRow("TXN ID", txnId),

              const SizedBox(height: 20),

              // Amount - Big and bold
              const Text(
                "AMOUNT",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                "₹$amount",
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 16),

              // VPA details with stacked format
              const Text(
                "CUSTOMER VPA:",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                customerVpa,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "CREDIT VPA:",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                creditVpa,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),

              // Dotted line
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: List.generate(50, (index) => Expanded(
                    child: Container(
                      height: 1,
                      color: index % 2 == 0 ? Colors.grey : Colors.transparent,
                    ),
                  )),
                ),
              ),

              // Footer
              Text(
                _isCustomerCopy ? "CUSTOMER COPY" : "MERCHANT COPY",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Version-1.0.87 Powered by bijlipay",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Helper for receipt-style rows
  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$label:",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

// Helper for stacked VPA rows
  Widget _receiptRowStacked(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label:",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
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
          backgroundColor: const Color(0xFFD5F0E0),
          foregroundColor: const Color(0xFF61116A),
          side: const BorderSide(color: Color(0xFF61116A)),
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

  // Helper method for left-right aligned rows
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
        text: 'Transaction Receipt - ID: ${widget.transactionData['rrn'] ?? 'N/A'}',
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

  void _showShareOptions() {
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

class MyApp extends StatelessWidget {
  final bool initialLoginDone;
  const MyApp({super.key, required this.initialLoginDone});
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData(
        fontFamily: 'Montserrat',
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: initialLoginDone ? const LoginScreen() : const InitialLoginScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String merchantName;
  final List<String> terminalIds;
  final List<String> vpaList;
  final String authToken;
  final String mobileNo;
  final String email;
  final String merchantAddress;
  final String accountNo;
  final String bankName;
  final String ifscCode;
  final String branch;
  final String rrn;

  const MainScreen({
    Key? key,
    required this.merchantName,
    required this.terminalIds,
    required this.vpaList,
    required this.authToken,
    required this.mobileNo,
    required this.email,
    required this.merchantAddress,
    required this.accountNo,
    required this.bankName,
    required this.ifscCode,
    required this.branch,
    required this.rrn,
  }) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HomeScreen(
        merchantName: widget.merchantName,
        terminalIds: widget.terminalIds,
        vpaList: widget.vpaList,
        authToken: widget.authToken,
        rrn: widget.rrn,
      ),
      TransactionsScreen(
        terminalIds: widget.terminalIds,
        vpaList: widget.vpaList,
        authToken: widget.authToken,
      ),

      TransactionReportPage(authToken: widget.authToken,       terminalIds: widget.terminalIds,  // Add this
        vpaList: widget.vpaList,         ),
      ProfileScreen(
          merchantName: widget.merchantName,
          mobileNo: widget.mobileNo,
          email: widget.email,
          merchantAddress: widget.merchantAddress,
          accountNo: widget.accountNo,
          bankName: widget.bankName,
          ifscCode: widget.ifscCode,
          branch: widget.branch,
          authToken: widget.authToken
      ),
      SupportScreen(authToken: widget.authToken,        terminalIds: widget.terminalIds,  // Add this
        vpaList: widget.vpaList,          ),
      RiskHoldScreen(authToken: widget.authToken),
      NotificationScreen(authToken: widget.authToken),
      createTicketScreen(authToken: widget.authToken,terminalIds: widget.terminalIds,
        staticQRs: widget.vpaList,  )
    ];
    final List<String> _titles = [
      'Home Screen',
      'Transactions',
      'My Report',
      'Profile',
      'Support Center',
      'Risk Hold',
      'Notifications',
      'Report an Issue',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8EEF2),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38383814),
                offset: const Offset(0, 4),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: AppBar(
            automaticallyImplyLeading: false,
            title: Image.asset(
              'assets/bijli_logo.png',
              height: 30,
              fit: BoxFit.contain,
            ),
            actions: [
              IconButton(
                icon:  Icon(Icons.notifications_active_outlined, color: Colors.grey, size: 21),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationScreen(authToken: widget.authToken),
                    ),
                  );
                },
              )
            ],
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            if (_selectedIndex != 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38383814),
                      offset: Offset(0, 4),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.black,size: 12),
                      onPressed: () {
                        setState(() {
                          _selectedIndex = 0;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        _titles[_selectedIndex],
                        style: const TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: _pages[_selectedIndex]),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
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
}

class HomeScreen extends StatefulWidget {
  final String merchantName;
  final List<String> terminalIds;
  final List<String> vpaList;
  final String authToken;
  final String rrn;

  const HomeScreen({
    Key? key,
    required this.merchantName,
    required this.terminalIds,
    required this.vpaList,
    required this.authToken,
    required this.rrn,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? _selectedTerminalId;
  String? _selectedStaticQR;
  ScrollController _transactionScrollController = ScrollController();
  late AnimationController _arrowAnimationController;
  late Animation<double> _arrowScaleAnimation;

  Map<String, double> _terminalTotals = {
    'todaySum': 0,
    'yesterdaySum': 0.0,
  };
  Map<String, double> _staticQRTotals = {
    'todaySum': 0.0,
    'yesterdaySum': 0.0,
  };
  Map<String, dynamic>? _responseData;
  bool _isFirstLoad = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.terminalIds.isNotEmpty) {
      _selectedTerminalId = widget.terminalIds[0];
    }
    if (widget.vpaList.isNotEmpty) {
      _selectedStaticQR = widget.vpaList[0];
    }

    _arrowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _arrowScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _arrowAnimationController,
      curve: Curves.easeInOut,
    ));

    fetchTransactionSummary(updateCarousel: true);
  }
// Add this helper method to determine card type based on BIN

  @override
  void dispose() {
    _transactionScrollController.dispose();
    _arrowAnimationController.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    HapticFeedback.lightImpact();
    _arrowAnimationController.forward().then((_) {
      _arrowAnimationController.reverse();
    });

    _transactionScrollController.animateTo(
      _transactionScrollController.offset - 140,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollRight() {
    HapticFeedback.lightImpact();
    _arrowAnimationController.forward().then((_) {
      _arrowAnimationController.reverse();
    });

    _transactionScrollController.animateTo(
      _transactionScrollController.offset + 140,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }
  void _showAddVPADialog() {
    String newVPA = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New VPA'),
        content: TextField(
          onChanged: (value) => newVPA = value,
          decoration: const InputDecoration(
            hintText: 'Enter VPA',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (newVPA.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a VPA')),
                );
                return;
              }
              Navigator.pop(context);
              await _addNewVPA(newVPA);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewVPA(String vpa) async {
    final appState = AppState.instance;
    final mobileNo = appState.mobileNumber ?? '';

    if (mobileNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mobile number not found')),
      );
      return;
    }

    try {
      final url = Uri.parse('https://bportal.bijlipay.co.in:9027/auth/user/add-vpa');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
        body: json.encode({
          "mobileNo": mobileNo,
          "vpa": vpa,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'OK') {
          // Success - update the VPA list
          setState(() {
            widget.vpaList.add(vpa);
            _selectedStaticQR = vpa;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('VPA added successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? 'Failed to add VPA')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  Future<Map<String, dynamic>> fetchTransactionDetails(String rrn,
      String authToken) async {
    if (rrn.isEmpty) {
      return {"error": "Invalid RRN provided"};
    }

    try {
      final String encodedRRN = Uri.encodeComponent(rrn);
      final String apiUrl = "https://bportal.bijlipay.co.in:9027/txn/get-chargeslip-data/$encodedRRN/SALE";

      print('\n🌐 Fetching transaction details for RRN: $rrn');
      print('Full URL: $apiUrl');

      final response = await handleResponse(
        http.get(
          Uri.parse(apiUrl),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('API Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == "OK" &&
            jsonResponse['data'] != null &&
            jsonResponse['data'].isNotEmpty) {
          return jsonResponse['data'][0];
        }
        return {"error": "No transaction details found"};
      }
      return {"error": "API Error: ${response.statusCode}"};
    } catch (e) {
      print('Error fetching details: $e');
      return {"error": "Network Error: $e"};
    }
  }
  Future<http.Response> handleResponse(Future<http.Response> apiCall) async {
    final response = await apiCall;
    if (response.statusCode == 401) {
      MyApp.navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
      throw Exception('Unauthorized');
    }
    return response;
  }
  Future<void> fetchTransactionSummary({bool updateCarousel = false}) async {
    print('\n======= API Call Debug Start =======');
    print('fetchTransactionSummary called at: ${DateTime.now()}');
    print('Selected Terminal ID: $_selectedTerminalId');
    print('Selected Static QR: $_selectedStaticQR');

    setState(() {
      _isLoading = true;
    });

    try {
      String url = 'https://bportal.bijlipay.co.in:9027/txn/fetch-transaction-summary?';

      if (_selectedTerminalId != null && _selectedTerminalId!.isNotEmpty) {
        url += 'tid=${Uri.encodeComponent(_selectedTerminalId!)}';
        if (_selectedStaticQR != null && _selectedStaticQR!.isNotEmpty) {
          url += '&vpa=${Uri.encodeComponent(_selectedStaticQR!)}';
        }
      } else if (_selectedStaticQR != null && _selectedStaticQR!.isNotEmpty) {
        url += 'tid=&vpa=${Uri.encodeComponent(_selectedStaticQR!)}';
      } else {
        // If neither tid nor vpa is available, don't make the API call
        setState(() {
          _responseData = null;
          _isLoading = false;
        });
        return;
      }

      print('\n🌐 API Request Details:');
      print('URL: $url');
      print('Auth Token: ${widget.authToken}');

      final response = await handleResponse(
        http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer ${widget.authToken}',
          },
        ),
      );

      print('\n📥 API Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('\n✅ Parsed Response Data:');
        print('Status: ${responseData['status']}');

        if (responseData['status'] == 'OK') {
          final data = responseData['data'];
          setState(() {
            _responseData = data;

            if (data['tid'] != null && data['tid'].isNotEmpty) {
              _terminalTotals = {
                'todaySum': data['tid'][0]['todaySum'] ?? 0.0,
                'yesterdaySum': data['tid'][0]['yesterdaySum'] ?? 0.0,
              };
            }

            if (data['staticQR'] != null && data['staticQR'].isNotEmpty) {
              _staticQRTotals = {
                'todaySum': data['staticQR'][0]['todaySum'] ?? 0.0,
                'yesterdaySum': data['staticQR'][0]['yesterdaySum'] ?? 0.0,
              };
            }
          });
        }
      }
    } catch (e) {
      print('\n❌ API Error:');
      print('Error fetching transaction summary: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('======= API Call Debug End =======\n');
    }
  }

  void _onTerminalIdChanged(String? newValue) {
    print('\n=== Terminal ID Change Debug ===');
    print('New Terminal ID selected: $newValue');
    setState(() {
      _selectedTerminalId = newValue;
    });

    fetchTransactionSummary(updateCarousel: true);
    print('=== End Terminal ID Change ===\n');
  }

  void _onStaticQRChanged(String? newValue) {
    print('\n=== Static QR Change Debug ===');
    print('New VPA selected: $newValue');
    setState(() {
      _selectedStaticQR = newValue;
    });

    fetchTransactionSummary(updateCarousel: true);
    print('=== End Static QR Change ===\n');
  }


  String formatCurrency(num amount) {
    if (amount < 100000) {
      return '₹${(amount * 100).round()}';
    } else {
      double lakhValue = amount / 100000;
      String formattedLakhValue = lakhValue.toStringAsFixed(1);
      if (formattedLakhValue.endsWith('.0')) {
        formattedLakhValue = formattedLakhValue.substring(0, formattedLakhValue.length - 2);
      }
      return '₹$formattedLakhValue Lakhs';
    }
  }

  final List<String> terminalIds = ['BEQ18843', 'BEQ18844', 'BEQ18845'];
  final List<String> staticQRs = [
    'vasanth@sbi',
    'vasanth@axis',
    'vasanth@hdfc'
  ];

  final List<Map<String, String>> links = [
    {"icon": "assets/transactions.png", "label": "My Transaction", "key": "transaction"},
    // {"icon": "assets/settlement.png", "label": "My Settlement", "key": "settlement"},
    {"icon": "assets/Notifications.png", "label": "My Notification", "key": "notification"},
    {"icon": "assets/baz.png", "label": "Risk Hold", "key": "Risk Hold"},
    {"icon": "assets/myreports.png", "label": "My Report", "key": "report"},
    {"icon": "assets/supportcentre.png", "label": "Support Center", "key": "support"},
  ];


  Color staticQRBackgroundColor = const Color(0xFFEBEBEB);


  @override
  Widget build(BuildContext context) {
    final hasTerminal = widget.terminalIds.isNotEmpty;
    final hasQR = widget.vpaList.isNotEmpty;
    print('\n=== Build Method Debug ===');
    print('_responseData: $_responseData');
    print('Has QR Transactions: ${_responseData?['lastFiveTxnAmountForQr'] != null}');
    print('Has Terminal Transactions: ${_responseData?['lastFiveTxnAmount'] != null}');

    return Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/home.png',
                            height: 24,
                            width: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'WELCOME ${widget.merchantName}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        ],
                      ),
                    ),
                    // Use conditional layout based on what's available
                    if (hasTerminal && hasQR)
                    // Both available - use Row with Expanded
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildTerminalContainer(false)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStaticQRContainer(false)),
                        ],
                      )
                    else if (hasTerminal)
                    // Only Terminal - full width
                      _buildTerminalContainer(true)
                    else if (hasQR || _selectedStaticQR != null)
                      // Only Static QR - full width
                        _buildStaticQRContainer(true),

                    const SizedBox(height: 16),
                    if (_responseData != null)
                      _buildTransactionCarousel(_responseData!),
                    const SizedBox(height: 16),
                    _buildQuickLinks(),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black12,
                child: Center(
                  child: CircularProgressIndicator(
                    color: customPurple,
                  ),
                ),
              ),
          ],
        )
    );
  }

// Extract Terminal container as a separate method
  Widget _buildTerminalContainer(bool isSingle) {
    return Container(
      constraints: isSingle ? null : BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        color: const Color(0xFFF8EEF2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33383838),
            offset: Offset(0, 4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomDropdownFieldWithBarrier(
            label: 'Terminal ID',
            value: _selectedTerminalId ?? '',
            items: widget.terminalIds,
            onChanged: _onTerminalIdChanged,
          ),
          const SizedBox(height: 16),

          // If single container, arrange totals side by side
          if (isSingle)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Today's Total",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildFormattedCurrency(_terminalTotals['todaySum'] ?? 0.0),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(0.5),
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Yesterday's Total",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildFormattedCurrency(_terminalTotals['yesterdaySum'] ?? 0.0),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
          // If dual containers, stack vertically
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Total",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                _buildFormattedCurrency(_terminalTotals['todaySum'] ?? 0.0),
                const SizedBox(height: 12),
                const Text(
                  "Yesterday's Total",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                _buildFormattedCurrency(_terminalTotals['yesterdaySum'] ?? 0.0),
              ],
            ),
        ],
      ),
    );
  }

// Extract Static QR container as a separate method
  Widget _buildStaticQRContainer(bool isSingle) {
    return Container(
      constraints: isSingle ? null : BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEBEB),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33383838),
            offset: Offset(0, 4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomDropdownFieldWithBarrier(
            label: 'Static QR',
            value: _selectedStaticQR ?? '',
            items: widget.vpaList,
            onChanged: _onStaticQRChanged,
            backgroundColor: staticQRBackgroundColor,
            onAddPressed: _showAddVPADialog,
          ),
          const SizedBox(height: 16),

          // If single container, arrange totals side by side
          if (isSingle)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Today's Total",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildFormattedCurrency(_staticQRTotals['todaySum'] ?? 0.0),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(0.5),
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Yesterday's Total",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildFormattedCurrency(_staticQRTotals['yesterdaySum'] ?? 0.0),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
          // If dual containers, stack vertically
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Total",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                _buildFormattedCurrency(_staticQRTotals['todaySum'] ?? 0.0),
                const SizedBox(height: 12),
                const Text(
                  "Yesterday's Total",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                _buildFormattedCurrency(_staticQRTotals['yesterdaySum'] ?? 0.0),
              ],
            ),
        ],
      ),
    );
  }

// Helper method to build formatted currency with larger font for main digits
  Widget _buildFormattedCurrency(num amount) {
    String formattedAmount = formatCurrency(amount);


    // Split the formatted string to identify rupee symbol and decimal parts
    RegExp regExp = RegExp(r'(₹\s*)(\d+)(\.?\d*)');
    Match? match = regExp.firstMatch(formattedAmount);

    if (match != null) {
      String rupeeSymbol = match.group(1) ?? '';
      String mainDigits = match.group(2) ?? '';
      String decimalPart = match.group(3) ?? '';

      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: rupeeSymbol,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: customPurple,
                letterSpacing: -0.5,
              ),
            ),
            TextSpan(
              text: mainDigits,
              style: TextStyle(
                fontSize: 18, // Larger font for main digits
                fontWeight: FontWeight.bold,
                color: customPurple,
                letterSpacing: -0.5,
              ),
            ),
            TextSpan(
              text: decimalPart,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: customPurple,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      );
    }

    // Fallback if regex doesn't match
    return Text(
      formattedAmount,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: customPurple,
        letterSpacing: -0.5,
      ),
    );
  }
// Add this helper method to determine card type based on BIN
  String _getCardType(dynamic transaction) {

    if (transaction is! Map<String, dynamic>) return 'qr';

    // Try to get the BIN directly if available
    if (transaction['bin'] != null && transaction['bin'].toString().isNotEmpty) {
      return _determineCardTypeFromBin(transaction['bin'].toString());
    }


    // Fallback to masked card number if BIN not available
    if (transaction['maskedCardNumber'] != null) {
      final masked = transaction['maskedCardNumber'].toString();
      // Extract numbers from masked card (e.g., "**** 1234" -> "1234")
      final digits = masked.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length >= 6) {
        return _determineCardTypeFromBin(digits.substring(0, 6));
      }
    }

    return 'qr'; // Default if no card info available
  }

  String _determineCardTypeFromBin(String binStr) {
    if (binStr.isEmpty) return 'qr';

    // Pad to 6 digits if needed
    if (binStr.length < 6) {
      binStr = binStr.padLeft(6, '0');
    } else if (binStr.length > 6) {
      binStr = binStr.substring(0, 6);
    }

    int? bin = int.tryParse(binStr);
    if (bin == null) return 'qr';

    // Check ranges
    if (binRangeVisa(bin)) return 'visa';
    if (binRangeMaster(bin)) return 'master';
    if (binRangeDiscover(bin)) return 'rupay';
    if (binRangeUnionPay(bin)) return 'unionpay';
    if (binRangeJcb(bin)) return 'rupay';
    if (binRangeRuPay(bin)) return 'rupay';
    if (binRangeAE(bin)) return 'amex';

    return 'qr';
  }


  bool binRangeVisa(int bin) {
    return bin >= 400000 && bin <= 499999;
  }

  bool binRangeMaster(int bin) {
    return (bin >= 222100 && bin <= 272099) ||
        (bin >= 510000 && bin <= 559999) ||
        (bin >= 675920 && bin <= 675923);
  }

  bool binRangeDiscover(int bin) {
    return (bin >= 300000 && bin <= 305999) ||
        (bin >= 309500 && bin <= 309599) ||
        (bin >= 360000 && bin <= 369999) ||
        (bin >= 380000 && bin <= 399999) ||
        (bin >= 601100 && bin <= 601103) ||
        (bin >= 601105 && bin <= 601109) ||
        (bin >= 601120 && bin <= 601149) ||
        (bin == 601174) ||
        (bin >= 601177 && bin <= 601179) ||
        (bin >= 601186 && bin <= 601199) ||
        (bin >= 644000 && bin <= 650599) ||
        (bin >= 650601 && bin <= 650609) ||
        (bin >= 650611 && bin <= 659999) ||
        (bin >= 608001 && bin <= 608500) ||
        (bin == 820199);
  }

  bool binRangeUnionPay(int bin) {
    return (bin == 621094) ||
        (bin >= 622126 && bin <= 622925) ||
        (bin >= 622926 && bin <= 623796) ||
        (bin >= 624000 && bin <= 626999) ||
        (bin >= 628200 && bin <= 628899) ||
        (bin >= 810000 && bin <= 810999) ||
        (bin >= 811000 && bin <= 813199) ||
        (bin >= 813200 && bin <= 815199) ||
        (bin >= 815200 && bin <= 816399) ||
        (bin >= 816400 && bin <= 817199) ||
        (bin >= 309600 && bin <= 310299) ||
        (bin >= 311200 && bin <= 312099) ||
        (bin >= 315800 && bin <= 315999) ||
        (bin >= 333700 && bin <= 334999) ||
        (bin >= 352800 && bin <= 358999);
  }
  bool binRangeRuPay(int bin) {
    return (bin >= 600100 && bin <= 600109) ||
        (bin >= 601200 && bin <= 601206) ||
        (bin >= 601380 && bin <= 601399) ||
        (bin >= 601421 && bin <= 601425) ||
        (bin >= 601428 && bin <= 601429) ||
        (bin >= 601431 && bin <= 601439) ||
        (bin >= 601441 && bin <= 601449) ||
        (bin >= 601451 && bin <= 601459) ||
        (bin >= 601461 && bin <= 601469) ||
        (bin >= 601481 && bin <= 601489) ||
        (bin >= 601491 && bin <= 601499) ||
        (bin >= 602000 && bin <= 602099) ||
        (bin >= 603500 && bin <= 603599) ||
        (bin >= 604000 && bin <= 604999) ||
        (bin >= 605100 && bin <= 605199) ||
        (bin >= 607000 && bin <= 607999) ||
        (bin >= 608000 && bin <= 608999) ||
        (bin >= 652100 && bin <= 653099);
  }

  bool binRangeJcb(int bin) {
    return (bin >= 308800 && bin <= 309499) || (bin == 353014);
  }

  bool binRangeAE(int bin) {
    return (bin >= 340000 && bin <= 349999) ||
        (bin >= 370000 && bin <= 379999);
  }
  String _getCardLogo(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return "assets/visa.png";
      case 'master':
      case 'mastercard':
        return "assets/master.png";
      case 'rupay':
        return "assets/rupay.png";
      case 'amex':
        return "assets/amex.png";
      case 'discover':
        return "assets/discover.png";
      case 'jcb':
        return "assets/jcb.png";
      case 'unionpay':
        return "assets/unionpay.png";
      default:
        return "assets/qr.png";
    }
  }
  String _getTransactionStatus(dynamic txnType, dynamic txnResponseCode) {
    if (txnType == null || txnResponseCode == null) return "Failed";

    final type = txnType.toString().trim();
    final response = txnResponseCode.toString().trim();

    // Check for Void first
    if (type == "02") return "Void";

    // Then check response code
    if (response == "00") return "Success";

    return "Failed";
  }

  String _getQRTransactionStatus(dynamic txnResponseCode) {
    if (txnResponseCode == null) return "Failed";

    final response = txnResponseCode.toString().trim();
    return (response == "00") ? "Success" : "Failed";
  }

  Widget _buildTransactionCarousel(Map<String, dynamic> responseData) {

    final terminalTransactions = (responseData['lastFiveTxnAmount'] as List?) ?? [];
    final qrTransactions = (responseData['lastFiveTxnAmountForQr'] as List?) ?? [];
    // For terminal transactions
    List<Map<String, dynamic>> combinedTransactions = [];
    for (var i = 0; i < min(5, terminalTransactions.length); i++) {
      final tx = terminalTransactions[i] as Map<String, dynamic>;
      final status = _getTransactionStatus(tx['txnType'], tx['txnResponseCode'] ?? 'Unknown');

      combinedTransactions.add({
        "id": tx['terminalId']?.toString() ?? '',
        "amount": formatCurrency((tx['txnAmount'] as num? ?? 0) + (tx['txnAdditionalAmount'] as num? ?? 0)),
        "status": status,
        "time": _formatTime(tx['txnTime']?.toString() ?? ''),
        "logo": _getCardLogo(_getCardType(tx)),
        "type": _getCardType(tx),
        "rrn": tx['rRNumber']?.toString() ?? '',
        "rawTxnType": tx['txnType']?.toString() ?? '',
        "rawResponseCode": tx['txnResponseCode']?.toString() ?? '',
      });
    }

    // For QR transactions
    for (var i = 0; i < min(5, qrTransactions.length); i++) {
      final tx = qrTransactions[i] as Map<String, dynamic>;
      final status = _getQRTransactionStatus(tx['gatewayResponseCode'] ?? 'Unknown');

      combinedTransactions.add({
        "id": tx['customerVpa']?.toString() ?? '',
        "amount": formatCurrency(double.parse(tx['transactionAmount']?.toString() ?? '0')),
        "status": status,
        "time": _formatTimestamp(tx['transactionTimestamp']?.toString() ?? ''),
        "logo": "assets/qr.png",
        "type": "QR",
        "rrn": tx['rRNumber']?.toString() ?? '',
        "rawTxnType": tx['purposeCode']?.toString() ?? '',
        "rawResponseCode": tx['gatewayResponseCode']?.toString() ?? '',
      });
    }


    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _scrollLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.chevron_left,
                        size: 20,
                        color: customPurple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  GestureDetector(
                    onTap: _scrollRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: customPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: ListView.builder(
            controller: _transactionScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: combinedTransactions.length + 1,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) {
              // If it's the last item, show "View All Transactions" card
              if (index == combinedTransactions.length) {
                return GestureDetector(
                  onTap: () {
                    final mainScreenState = context.findAncestorStateOfType<_MainScreenState>();
                    if (mainScreenState != null) {
                      mainScreenState._onItemTapped(1);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionsScreen(
                            terminalIds: widget.terminalIds,
                            vpaList: widget.vpaList,
                            authToken: widget.authToken,
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: customPurple.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: customPurple,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Transactions',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: customPurple,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_forward,
                                color: customPurple,
                                size: 16,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              List<TextSpan> _buildAmountSpans(String amount) {
                String numericPart = amount;
                String? lakhsSuffix;

                if (amount.endsWith(" Lakhs")) {
                  numericPart = amount.substring(0, amount.length - " Lakhs".length);
                  lakhsSuffix = " Lakhs";
                }

                final regex = RegExp(r'(₹)(\d+)(\.\d+)?');
                final match = regex.firstMatch(numericPart);

                if (match != null) {
                  final rupeeSymbol = match.group(1) ?? '';
                  final mainDigits = match.group(2) ?? '';
                  final decimalPart = match.group(3) ?? ''; // Includes '.'

                  List<TextSpan> spans = [
                    TextSpan(
                      text: rupeeSymbol,
                      style: TextStyle(
                        fontSize: 13, // Smaller rupee symbol
                        fontWeight: FontWeight.w700,
                        color: customPurple,
                      ),
                    ),
                    TextSpan(
                      text: mainDigits,
                      style: TextStyle(
                        fontSize: 16, // Larger main digits
                        fontWeight: FontWeight.w700,
                        color: customPurple,
                      ),
                    ),
                  ];

                  if (decimalPart.isNotEmpty) {
                    spans.add(
                      TextSpan(
                        text: decimalPart,
                        style: TextStyle(
                          fontSize: 13, // Smaller decimal part
                          fontWeight: FontWeight.w700,
                          color: customPurple,
                        ),
                      ),
                    );
                  }

                  if (lakhsSuffix != null) {
                    spans.add(
                      TextSpan(
                        text: lakhsSuffix,
                        style: TextStyle(
                          fontSize: 13, // Style similar to decimal part
                          fontWeight: FontWeight.w700,
                          color: customPurple,
                        ),
                      ),
                    );
                  }
                  return spans;
                } else {
                  // Fallback if regex doesn't match
                  return [
                    TextSpan(
                      text: amount,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: customPurple,
                      ),
                    ),
                  ];
                }
              }
              // Regular transaction card
              final transaction = combinedTransactions[index];
              final status = transaction["status"];
              Color statusColor = (status == "Success")
                  ? Colors.green[600]!
                  : (status == "Void")
                  ? Colors.orange[600]!
                  : (status == "Failed")
                  ? Colors.red[600]!
                  : Colors.grey[600]!;

              return GestureDetector(
                onTap: () {
                  if (status == "Failed") {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed transactions don\'t have charge slips')),
                    );
                    return;
                  }

                  if (transaction["type"] == "QR") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StaticQRChargeSlip(
                          transactionData: {
                            "transactionAmount": transaction['amount'].replaceAll('₹', ''),
                            "transactionTimestamp": transaction['time'],
                            "merchantTransactionId": transaction['rrn'],
                            "customerVpa": transaction['id'],
                            "creditVpa": _selectedStaticQR ?? 'N/A',
                          },
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionDetailsScreen(
                          authToken: widget.authToken,
                          rrn: transaction['rrn'],
                          terminalIds: widget.terminalIds,
                          vpaList: widget.vpaList,
                          transactionStatus: status,
                          transactionType: transaction["rawTxnType"],
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Professional bordered container for card/QR image
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 0.02,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            transaction["logo"]!,
                            height: 24,
                            width: 36,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          transaction["id"]!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: _buildAmountSpans(transaction["amount"]!),
                          ),
                        ),
                        Text(
                          transaction["time"]!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (status == "Success")
                              Image.asset('assets/success.png', height: 18, width: 18),
                            if (status == "Failed")
                              Image.asset('assets/failure.png', height: 18, width: 18),
                            if (status == "Void")
                              Icon(Icons.error, size: 9.7, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              status,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(String timestamp) {
    final dt = DateTime.parse(timestamp);
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute
        .toString()
        .padLeft(2, '0')}";
  }

  String _formatTime(String time) {
    return "${time.substring(0, 2)}:${time.substring(2, 4)}";
  }

  Widget _buildQuickLinks() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0x33383838),
            offset: Offset(0, 4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick Links",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: links.length,
            itemBuilder: (context, index) {
              final link = links[index];
              return GestureDetector(
                onTap: () {
                  _navigateToScreen(context, link["key"]);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(0xFFEBEBEB),
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset(
                        link["icon"]!,
                        color: customPurple,
                        width: 32,
                        height: 32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      link["label"]!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  void _navigateToScreen(BuildContext context, String? screenKey) {
    switch (screenKey) {
      case "transaction":
      // For transactions, we'll navigate through the parent MainScreen
      // Find the parent MainScreen using the context
        final mainScreenState = context.findAncestorStateOfType<_MainScreenState>();
        if (mainScreenState != null) {
          // If we found MainScreen, use its navigation method
          mainScreenState._onItemTapped(1); // Index 1 is for Transactions
        } else {
          // Fallback if not found (shouldn't happen in normal usage)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionsScreen(
                terminalIds: widget.terminalIds,
                vpaList: widget.vpaList,
                authToken: widget.authToken,
              ),
            ),
          );
        }
        break;
      case "settlement":
      // Navigate to Settlement screen
      // Navigator.push(context, MaterialPageRoute(builder: (context) => SettlementScreen()));
        break;
      case "notification":
      // Navigate to Notification screen
        Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationScreen(authToken: widget.authToken)));
        break;
      case "Risk Hold":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RiskHoldScreen(authToken: widget.authToken),
          ),
        );
      case "report":
      // Use the MainScreen navigation to report tab
        final mainScreenState = context.findAncestorStateOfType<_MainScreenState>();
        if (mainScreenState != null) {
          mainScreenState._onItemTapped(2); // Index 2 is for Report
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionReportPage(authToken: widget.authToken,       terminalIds: widget.terminalIds,  // Add this
                vpaList: widget.vpaList,         ),
            ),
          );
        }
        break;
      case "support":
      // Use the MainScreen navigation to support tab
        final mainScreenState = context.findAncestorStateOfType<_MainScreenState>();
        if (mainScreenState != null) {
          mainScreenState._onItemTapped(4); // Index 4 is for Support
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SupportScreen(authToken: widget.authToken,        terminalIds: widget.terminalIds,  // Add this
                vpaList: widget.vpaList,          ),
            ),
          );
        }
        break;
      default:
        print("Unknown screen key: $screenKey");
    }
  }
}
// Replace your CustomDropdownField with this updated version
class CustomDropdownField extends StatefulWidget {
  final String label;
  final String value;
  final List<String> items;
  final Function(String?) onChanged;
  final Color backgroundColor;

  const CustomDropdownField({
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.backgroundColor = const Color(0xFFF8EEF2),
  }) : super(key: key);

  @override
  _CustomDropdownFieldState createState() => _CustomDropdownFieldState();
}

class _CustomDropdownFieldState extends State<CustomDropdownField> {
  bool _dropdownOpen = false;
  final GlobalKey _dropdownKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_dropdownOpen) {
      setState(() {
        _dropdownOpen = false;
      });
    }
  }

  void _openDropdown() {
    if (_overlayEntry != null) return;

    final RenderBox? renderBox = _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;
    final dropdownHeight = (widget.items.length * 48.0) + 16;
    final spaceBelow = screenHeight - (position.dy + size.height + 100);
    final showAbove = spaceBelow < dropdownHeight && position.dy > dropdownHeight;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: showAbove
            ? position.dy - dropdownHeight - 8
            : position.dy + size.height + 4,
        width: size.width,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: 200,
            ),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: customPurple.withOpacity(0.2),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.items.map((item) {
                    final isSelected = widget.value == item;
                    return InkWell(
                      onTap: () {
                        widget.onChanged(item);
                        _closeDropdown();
                      },
                      borderRadius: BorderRadius.circular(6),
                      splashColor: customPurple.withOpacity(0.1),
                      highlightColor: customPurple.withOpacity(0.05),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? customPurple.withOpacity(0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            // Radio button
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? customPurple : Colors.grey[400]!,
                                  width: 2,
                                ),
                                color: isSelected ? customPurple : Colors.transparent,
                              ),
                              child: isSelected
                                  ? Center(
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            // Text
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? customPurple : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context)?.insert(_overlayEntry!);
  }

  void _toggleDropdown() {
    if (_dropdownOpen) {
      _closeDropdown();
    } else {
      setState(() {
        _dropdownOpen = true;
      });
      _openDropdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: customPurple,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),

        // Input Field
        GestureDetector(
          key: _dropdownKey,
          onTap: _toggleDropdown,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutQuart,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _dropdownOpen ? customPurple : customPurple.withOpacity(0.3),
                  width: _dropdownOpen ? 1.5 : 1.0,
                ),
                boxShadow: _dropdownOpen ? [
                  BoxShadow(
                    color: customPurple.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.value.isNotEmpty ? widget.value : 'Select ${widget.label}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: widget.value.isNotEmpty
                            ? Colors.black
                            : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _dropdownOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutBack,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: _dropdownOpen ? customPurple : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Optional: Add a barrier to close dropdown when tapping outside
class CustomDropdownFieldWithBarrier extends StatefulWidget {
  final String label;
  final String value;
  final List<String> items;
  final Function(String?) onChanged;
  final Color backgroundColor;
  final bool showAddButton; // New property
  final VoidCallback? onAddPressed;

  const CustomDropdownFieldWithBarrier({
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.backgroundColor = const Color(0xFFF8EEF2),
    this.showAddButton = false,
    this.onAddPressed,
  }) : super(key: key);

  @override
  _CustomDropdownFieldWithBarrierState createState() => _CustomDropdownFieldWithBarrierState();
}

class _CustomDropdownFieldWithBarrierState extends State<CustomDropdownFieldWithBarrier> {
  bool _dropdownOpen = false;
  final GlobalKey _dropdownKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  OverlayEntry? _barrierEntry;

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  void _closeDropdown() {
    _barrierEntry?.remove();
    _overlayEntry?.remove();
    _barrierEntry = null;
    _overlayEntry = null;
    if (_dropdownOpen) {
      setState(() {
        _dropdownOpen = false;
      });
    }
  }

  void _openDropdown() {
    if (_overlayEntry != null) return;

    final RenderBox? renderBox = _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;
    final dropdownHeight = (widget.items.length * 48.0) + 16;
    final spaceBelow = screenHeight - (position.dy + size.height + 100);
    final showAbove = spaceBelow < dropdownHeight && position.dy > dropdownHeight;

    // Create barrier to detect taps outside
    _barrierEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _closeDropdown,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.transparent,
        ),
      ),
    );

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: showAbove
            ? position.dy - dropdownHeight - 8
            : position.dy + size.height + 4,
        width: size.width,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: 250,
            ),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: customPurple.withOpacity(0.2),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.items.map((item) {
                    final isSelected = widget.value == item;
                    return InkWell(
                      onTap: () {
                        widget.onChanged(item);
                        _closeDropdown();
                      },
                      borderRadius: BorderRadius.circular(6),
                      splashColor: customPurple.withOpacity(0.1),
                      highlightColor: customPurple.withOpacity(0.05),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? customPurple.withOpacity(0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            // Radio button
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? customPurple : Colors.grey[400]!,
                                  width: 2,
                                ),
                                color: isSelected ? customPurple : Colors.transparent,
                              ),
                              child: isSelected
                                  ? Center(
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            // Text
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? customPurple : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context)?.insert(_barrierEntry!);
    Overlay.of(context)?.insert(_overlayEntry!);
  }

  void _toggleDropdown() {
    if (_dropdownOpen) {
      _closeDropdown();
    } else {
      setState(() {
        _dropdownOpen = true;
      });
      _openDropdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: customPurple,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        // Only the dropdown trigger field
        GestureDetector(
          key: _dropdownKey,
          onTap: _toggleDropdown,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutQuart,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _dropdownOpen ? customPurple : customPurple.withOpacity(0.3),
                  width: _dropdownOpen ? 1.5 : 1.0,
                ),
                boxShadow: _dropdownOpen ? [
                  BoxShadow(
                    color: customPurple.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.value.isNotEmpty ? widget.value : 'Select ${widget.label}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: widget.value.isNotEmpty
                            ? Colors.black
                            : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _dropdownOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutBack,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: _dropdownOpen ? customPurple : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

