import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'createTicketScreenSettlement.dart';

// Import your existing files
import 'package:vyappar_application/main.dart';
import 'login_screen.dart';

Color customPurple = Color(0xFF61116A);

// Global flag to prevent multiple simultaneous navigation attempts
bool _isNavigatingToLogin = false;

Future<http.Response> handleResponse(Future<http.Response> apiCall) async {
  try {
    final response = await apiCall;
    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

    if (response.statusCode == 401) {
      print('401 Unauthorized - Session expired');
      _handleUnauthorized();
      throw Exception('Unauthorized - Session expired');
    }

    return response;
  } catch (e) {
    print('Error in handleResponse: $e');

    if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
      _handleUnauthorized();
    }

    rethrow;
  }
}

void _handleUnauthorized() {
  if (_isNavigatingToLogin) {
    print('Already navigating to login, skipping...');
    return;
  }

  _isNavigatingToLogin = true;
  print('Triggering navigation to login screen');

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final navigator = MyApp.navigatorKey.currentState;
    if (navigator != null) {
      print('Navigating to login screen');
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
            (Route<dynamic> route) => false,
      ).then((_) {
        _isNavigatingToLogin = false; // Reset flag after navigation
        print('Navigation to login completed');
      }).catchError((error) {
        print('Navigation error: $error');
        _isNavigatingToLogin = false;
      });
    } else {
      print('Navigator is null, cannot navigate to login');
      _isNavigatingToLogin = false;
    }
  });
}

class TransactionReportPage extends StatefulWidget {
  final String authToken;
  final List<String> terminalIds;
  final List<String> vpaList;

  const TransactionReportPage({super.key, required this.authToken,required this.terminalIds,
    required this.vpaList,});

  @override
  State<TransactionReportPage> createState() => _TransactionReportPageState();
}

class _TransactionReportPageState extends State<TransactionReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _transactions = [];
  List<dynamic> _settlements = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    print('Initializing TransactionReportPage with token: ${widget.authToken.substring(0, 10)}...');

    // Load initial data
    _fetchTransactionData();

    // Tab change listener - ADD setState here
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;

      print('Tab changed to index: ${_tabController.index}');

      // Add setState to rebuild FAB
      setState(() {});

      if (_tabController.index == 0 && _transactions.isEmpty && !_isLoading) {
        _fetchTransactionData();
      } else if (_tabController.index == 1 && _settlements.isEmpty && !_isLoading) {
        _fetchSettlementData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTransactionData() async => await _fetchData('Transaction');
  Future<void> _fetchSettlementData() async => await _fetchData('Settlement');

  Future<void> _fetchData(String type) async {
    print('Fetching $type data...');

    // Prevent multiple simultaneous requests
    if (_isLoading) {
      print('Already loading, skipping request for $type');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final url = 'https://bportal.bijlipay.co.in:9027/txn/getSettlementReportData/$type?page=1&size=20&sort=createdAt,desc';
      print('Making request to: $url');

      final response = await handleResponse(
        http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer ${widget.authToken}',
            'Content-Type': 'application/json',
          },
        ).timeout(
          Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timeout - Please check your internet connection');
          },
        ),
      );

      print('Response received for $type with status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Response data structure: ${data.keys}');

        // Validate response structure
        if (data['status'] == 'OK' && data['data'] != null) {
          final content = data['data']['content'] as List<dynamic>? ?? [];
          print('Content received: ${content.length} items');

          setState(() {
            if (type == 'Transaction') {
              _transactions = content.map((item) => {
                'tid': item['tid'] ,
                'vpa': item['vpa'] ,
                'fromDate': item['fromDate'] ?? 'N/A',
                'toDate': item['toDate'] ?? 'N/A',
                'fileUrl': item['fileUrl'],
              }).toList();
              print('Transactions loaded: ${_transactions.length}');
            } else {
              _settlements = content.map((item) => {
                'tid': item['tid'] ,
                'vpa': item['vpa'] ,
                'fromDate': item['fromDate'] ?? 'N/A',
                'toDate': item['toDate'] ?? 'N/A',
                'fileUrl': item['fileUrl'],
              }).toList();
              print('Settlements loaded: ${_settlements.length}');
            }
            _isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Invalid response structure - Status: ${data['status']}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error fetching $type data: $e');

      // Don't show error message for auth errors since user will be redirected
      if (e.toString().contains('Unauthorized') || e.toString().contains('Session expired')) {
        print('Auth error detected, user will be redirected to login');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load $type data: ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  Future<void> _refreshData() async {
    if (_tabController.index == 0) {
      _transactions.clear();
      await _fetchTransactionData();
    } else {
      _settlements.clear();
      await _fetchSettlementData();
    }
  }

  Future<void> _launchFile(String url) async {
    try {
      print('Attempting to launch URL: $url');
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('File URL launched successfully');
      } else {
        print('Cannot launch URL: $url');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open the file. Please check if you have a compatible app installed.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      print('Error launching file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening file: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // New method to handle settlement report generation
  Future<void> _generateSettlementReport() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: customPurple),
                  const SizedBox(width: 24),
                  Text(
                    'Generating settlement report...',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Make API call to generate settlement report
      final response = await handleResponse(
        http.post(
          Uri.parse('https://bportal.bijlipay.co.in:9027/txn/generateSettlementReport'),
          headers: {
            'Authorization': 'Bearer ${widget.authToken}',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            // Add any required parameters for settlement report generation
            'reportType': 'Settlement',
          }),
        ).timeout(
          Duration(seconds: 60),
          onTimeout: () {
            throw Exception('Request timeout - Report generation is taking longer than expected');
          },
        ),
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Settlement report generation initiated successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh the settlements data to show the new report
          await _fetchSettlementData();
        } else {
          throw Exception(data['message'] ?? 'Failed to generate settlement report');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'}');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      print('Error generating settlement report: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate settlement report: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildDataRow(String value, {bool isStatus = false, Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: isStatus
          ? Row(
        children: [
          Icon(Icons.circle, size: 8, color: statusColor ?? Colors.grey),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              color: statusColor ?? Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      )
          : Text(
        value,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> item, int index, int totalItems) {
    final String id = item['tid'] ?? item['vpa'] ?? 'N/A';
    final String fromDate = item['fromDate'] ?? 'N/A';
    final String toDate = item['toDate'] ?? 'N/A';
    final String? fileUrl = item['fileUrl'];
    final bool hasFile = fileUrl != null && fileUrl.isNotEmpty && fileUrl != 'N/A';
    final String status = hasFile ? 'Complete' : 'In Progress';
    final Color statusColor = hasFile ? Colors.green : Colors.orange;
    final String displayId = item['vpa'] ?? item['tid'] ?? 'N/A';
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with ID and Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        displayId,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.grey[900],
                        ),
                      ),
                    ),
                    if (hasFile)
                      InkWell(
                        onTap: () => _launchFile(fileUrl!),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.download, color: customPurple, size: 18),
                              SizedBox(width: 4),
                              Text(
                                '',
                                style: TextStyle(
                                  color: customPurple,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.hourglass_empty, color: Colors.grey, size: 18),
                            SizedBox(width: 4),
                            Text(
                              '',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12),

                // Data Rows
                _buildDataRow('$fromDate - $toDate'),
                _buildDataRow(status, isStatus: true, statusColor: statusColor),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey.shade300,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(List<dynamic> items) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: customPurple,
              strokeWidth: 4,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading data...',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _errorMessage = '';
                  });
                  _refreshData();
                },
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: customPurple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              "No reports available",
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Pull down to refresh",
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: customPurple,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length > 5 ? 5 : items.length,
              itemBuilder: (context, index) => _buildListItem(items[index], index, items.length > 5 ? 5 : items.length),
              physics: AlwaysScrollableScrollPhysics(),
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
            ),
            child: Text(
              'Note: Only five ${_tabController.index == 0 ? 'transaction' : 'settlement'} reports will be available at a time',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: TabBar(
            controller: _tabController,
            indicatorColor: customPurple,
            labelColor: customPurple,
            unselectedLabelColor: Colors.grey.shade500,
            labelStyle: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
            tabs: const [
              Tab(text: 'Transaction'),
              Tab(text: 'Settlement'),
            ],
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            isScrollable: false,
            labelPadding: EdgeInsets.zero,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTabContent(_transactions),
            _buildTabContent(_settlements),
          ],
        ),
        floatingActionButton: _tabController.index == 1 ? FloatingActionButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => createTicketScreen(
                      authToken: widget.authToken,
                      terminalIds: widget.terminalIds,
                      staticQRs: widget.vpaList,
                    )
                )
            );
          },
          backgroundColor: customPurple,
          child: const Icon(Icons.add, color: Colors.white),
        ) : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}

