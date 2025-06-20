import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'NotificationScreen.dart';

Color customPurple = Color(0xFF61116A);

class RiskHoldScreen extends StatefulWidget {
  final String authToken;

  const RiskHoldScreen({super.key, required this.authToken});

  @override
  State<RiskHoldScreen> createState() => _RiskHoldScreenState();
}

class _RiskHoldScreenState extends State<RiskHoldScreen> {
  List<dynamic> _riskHoldData = [];
  bool _isLoading = false;
  String _errorMessage = '';
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _fetchRiskHoldData();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_hasMoreData && !_isLoading) {
        _fetchRiskHoldData();
      }
    }
  }

  Future<void> _fetchRiskHoldData() async {
    if (!_hasMoreData) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://bportal.bijlipay.co.in:9027/txn/api/risk_hold_list?page=${_currentPage + 1}&size=1000&sort=createdAt,desc'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['data'] != null) {
          final newData = data['data']['content'] as List<dynamic>;
          final bool isLastPage = data['data']['last'];

          setState(() {
            _riskHoldData.addAll(newData);
            _currentPage++;
            _hasMoreData = !isLastPage;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load risk hold data');
        }
      } else {
        throw Exception('HTTP error ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatAmount(String amount) {
    final numericAmount = double.tryParse(amount) ?? 0.0;
    return '₹${numericAmount.toStringAsFixed(2)}';
  }

  Widget _buildRiskHoldItem(Map<String, dynamic> item) {
    final bool isInProgress = item['holdRemark']?.isNotEmpty == true;
    final statusText = isInProgress ? 'In Progress' : 'Completed';
    final statusColor = isInProgress ? Colors.orange : Colors.green;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TID Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TID: ${item['tid']}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                    fontFamily: 'Montserrat',
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: statusColor),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Amount
            Text(
              _formatAmount(item['txnAmount']),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: customPurple,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 12),

            // Reason (if exists)
            if (isInProgress) ...[
              Text(
                'Reason:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item['holdRemark'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Montserrat',
                ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
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
            automaticallyImplyLeading: false, // This removes the default back button
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
              ),
            ],
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: Column(
        children: [
          // Risk Hold Header with back button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 13),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  'Risk Hold',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _currentPage = 0;
                _riskHoldData.clear();
                await _fetchRiskHoldData();
              },
              child: _isLoading && _riskHoldData.isEmpty
                  ? Center(child: CircularProgressIndicator(color: customPurple))
                  : _errorMessage.isNotEmpty
                  ? Center(child: Text(_errorMessage))
                  : ListView.builder(
                controller: _scrollController,
                itemCount: _riskHoldData.length + 1,
                itemBuilder: (context, index) {
                  if (index == _riskHoldData.length) {
                    return _buildLoadingIndicator();
                  }
                  return _buildRiskHoldItem(
                      _riskHoldData[index] as Map<String, dynamic>);
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