import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'createTicketScreen.dart';
import 'package:vyappar_application/main.dart';
import 'login_screen.dart';

Color customPurple = Color(0xFF61116A);

class SupportScreen extends StatefulWidget {
  final String authToken;
  final List<String> terminalIds;
  final List<String> vpaList;
  const SupportScreen({
    super.key,
    required this.authToken,
    required this.terminalIds,
    required this.vpaList,
  });

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  List<dynamic> _tickets = [];
  bool _isLoading = false;
  String _errorMessage = '';
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_hasMoreData && !_isLoading) {
        _fetchTickets();
      }
    }
  }

  Future<http.Response> handleResponse(Future<http.Response> apiCall) async {
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

  Future<void> _fetchTickets() async {
    if (!_hasMoreData) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await handleResponse(
        http.get(
          Uri.parse(
              'https://bportal.bijlipay.co.in:9027/txn/tickets/get-tickets-list?page=${_currentPage + 1}&size=1000&sort=createdAt,desc'),
          headers: {
            'Authorization': 'Bearer ${widget.authToken}',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed data: $data');

        if (data['status'] == 'OK' && data['data'] != null) {
          // Check if data structure exists
          if (data['data']['content'] != null) {
            final newData = data['data']['content'] as List<dynamic>;
            final bool isLastPage = data['data']['last'] ?? true;

            print('New tickets count: ${newData.length}');
            print('Is last page: $isLastPage');

            setState(() {
              _tickets.addAll(newData);
              _currentPage++;
              _hasMoreData = !isLastPage;
            });
          } else {
            // Handle case where content is null but status is OK
            setState(() {
              _hasMoreData = false;
            });
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to load tickets');
        }
      } else {
        throw Exception('HTTP error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error fetching tickets: $e');
      if (!e.toString().contains('Unauthorized')) {
        setState(() {
          _errorMessage = 'Failed to load data: ${e.toString()}';
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Replace the _buildTicketItem method with reduced font sizes:

  Widget _buildTicketItem(Map ticket) {
    final statusColor = ticket['status'] == 'Complete' ? Colors.green : Colors.orange;
    final hasTid = ticket['tid']?.toString().isNotEmpty == true;
    final hasVpa = ticket['vpa']?.toString().isNotEmpty == true;

    final titleStyle = TextStyle(
      fontSize: 12,  // Reduced from 15
      fontWeight: FontWeight.w600,
      color: Colors.black,
      fontFamily: 'Montserrat',
    );

    final dataStyle = TextStyle(
      fontSize: 13,  // Reduced from 15
      fontWeight: FontWeight.w500,
      color: Colors.grey[800],
      fontFamily: 'Montserrat',
    );

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16), // Reduced vertical margin
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ID Section
            Text('ID', style: titleStyle),
            const SizedBox(height: 4), // Reduced spacing
            Text('#${ticket['id'] ?? 'N/A'}', style: dataStyle),
            const SizedBox(height: 10), // Reduced spacing

            // Type and Status Row
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TYPE', style: titleStyle),
                        const SizedBox(height: 4), // Reduced spacing
                        Text(
                          ticket['ticketTitle'] ?? 'N/A',
                          style: dataStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Status Column
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('STATUS', style: titleStyle),
                      const SizedBox(height: 4), // Reduced spacing
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: statusColor), // Reduced icon size
                          const SizedBox(width: 4),
                          Text(
                            ticket['status'] ?? 'Unknown',
                            style: dataStyle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10), // Reduced spacing

            // Description Section
            Text('DESCRIPTION', style: titleStyle),
            const SizedBox(height: 4), // Reduced spacing
            Text(
              ticket['ticketDetails'] ?? 'No description available',
              style: dataStyle.copyWith(height: 1.3), // Reduced line height
            ),

            // TID/VPA Section
            if (hasTid || hasVpa) ...[
              const SizedBox(height: 10), // Reduced spacing
              Text(hasTid ? 'TID' : 'VPA', style: titleStyle),
              const SizedBox(height: 4), // Reduced spacing
              Text(
                hasTid ? ticket['tid'].toString() : ticket['vpa'].toString(),
                style: dataStyle,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return _hasMoreData
        ? Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(color: customPurple),
      ),
    )
        : Container();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.support_agent,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No support tickets found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first ticket using the + button',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onRefresh() async {
    setState(() {
      _tickets.clear();
      _currentPage = 0;
      _hasMoreData = true;
      _errorMessage = '';
    });
    await _fetchTickets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      floatingActionButton: FloatingActionButton(
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: _isLoading && _tickets.isEmpty
                  ? Center(child: CircularProgressIndicator(color: customPurple))
                  : _errorMessage.isNotEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error Loading Tickets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.red[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _onRefresh,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: customPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
                  : _tickets.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                controller: _scrollController,
                itemCount: _tickets.length + 1,
                itemBuilder: (context, index) {
                  if (index == _tickets.length) {
                    return _buildLoadingIndicator();
                  }
                  return _buildTicketItem(
                      _tickets[index] as Map<String, dynamic>);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

