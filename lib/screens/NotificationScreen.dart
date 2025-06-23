import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Color customPurple = Color(0xFF61116A);

class NotificationScreen extends StatefulWidget {
  final String authToken;

  const NotificationScreen({super.key, required this.authToken});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _riskHoldNotifications = [];
  List<dynamic> _settlementNotifications = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _fetchData('RiskHold');

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 0 && _riskHoldNotifications.isEmpty) {
          _fetchData('RiskHold');
        } else
        if (_tabController.index == 1 && _settlementNotifications.isEmpty) {
          _fetchData('Settlement');
        }
      }
    });
  }

  Future<void> _fetchData(String type) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://bportal.bijlipay.co.in:9027/txn/notification/$type?page=1&sort=notificationDate%2Cdesc&size=50'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            if (type == 'RiskHold') {
              _riskHoldNotifications = data['data']['content'] ?? [];
            } else {
              _settlementNotifications = data['data']['content'] ?? [];
            }
          });
        } else {
          throw Exception(
              data['message'] ?? 'Failed to load $type notifications');
        }
      } else {
        throw Exception('HTTP error ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading $type: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllNotifications() async {
    final type = _tabController.index == 0 ? 'RiskHold' : 'Settlement';
    final currentNotifications = _tabController.index == 0
        ? _riskHoldNotifications
        : _settlementNotifications;

    if (currentNotifications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No notifications to clear')),
      );
      return;
    }

    final notificationIds = currentNotifications
        .map<String>((n) => n['id'].toString())
        .toList();

    try {
      final postResponse = await http.post(
        Uri.parse(
            'https://bportal.bijlipay.co.in:9027/txn/notification-bulk-update/$type'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'notificationIds': notificationIds}),
      );

      if (postResponse.statusCode == 200) {
        await _fetchData(type);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notifications cleared successfully')),
        );
      } else {
        throw Exception('Failed to clear notifications: ${postResponse.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Clear failed: ${e.toString()}')),
      );
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';

    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return timestamp.toString();
    }
  }

  Widget _buildNotificationItem(dynamic notification) {
    // Use the correct field names from API response
    String title = notification['notificationTitle']?.toString() ?? 'No Title';
    String reason = notification['notificationReason']?.toString() ?? '';
    dynamic notificationDate = notification['notificationDate'];
    bool isRead = notification['notificationSeen'] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Handle notification tap
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isRead ? Colors.grey.shade100 : customPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.notifications,
                    color: isRead ? Colors.grey.shade400 : customPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                          fontSize: 15,
                          color: isRead ? Colors.grey[700] : Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Reason/Message
                      if (reason.isNotEmpty)
                        Text(
                          reason,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Date
                      Text(
                        _formatDate(notificationDate),
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: Colors.grey[500],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Unread indicator
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: customPurple,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(List<dynamic> items) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: customPurple,
          strokeWidth: 4,
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
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
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
              Icons.notifications_none_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              "No notifications found",
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You're all caught up!",
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (_, index) => _buildNotificationItem(items[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
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
                'assets/bijli_logo.png',
                height: 30,
                fit: BoxFit.contain,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
        ),
        body: Column(
          children: [
            // Header section with back button and title
            Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 12),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 17.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Tabs and Clear All section
            Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: customPurple,
                        labelColor: customPurple,
                        unselectedLabelColor: Colors.grey.shade500,
                        labelStyle: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: 16),
                        unselectedLabelStyle: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w500, fontSize: 15),
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.label,
                        isScrollable: false,
                        labelPadding: EdgeInsets.zero,
                        tabs: const [
                          Tab(text: 'Risk Hold'),
                          Tab(text: 'Settlement'),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _clearAllNotifications,
                      child: Text(
                        'Clear All',
                        style: TextStyle(
                          color: customPurple,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabContent(_riskHoldNotifications),
                  _buildTabContent(_settlementNotifications),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
