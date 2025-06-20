//
// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'transactions_details.dart';
// import 'login_screen.dart';
// import 'package:vyappar_application/main.dart';
// import 'dart:async';
//
// Color customPurple = Color(0xFF61116A);
//
// Future<http.Response> handleResponse(Future<http.Response> apiCall) async {
// try {
// final response = await apiCall;
// if (response.statusCode == 401) {
// WidgetsBinding.instance.addPostFrameCallback((_) {
// MyApp.navigatorKey.currentState?.pushAndRemoveUntil(
// MaterialPageRoute(builder: (_) => LoginScreen()),
// (Route<dynamic> route) => false,
// );
// });
// throw Exception('Unauthorized');
// }
// return response;
// } catch (e) {
// if (e.toString().contains('Unauthorized')) {
// WidgetsBinding.instance.addPostFrameCallback((_) {
// MyApp.navigatorKey.currentState?.pushAndRemoveUntil(
// MaterialPageRoute(builder: (_) => LoginScreen()),
// (Route<dynamic> route) => false,
// );
// });
// }
// rethrow;
// }
// }
//
// class StaticQRChargeSlip extends StatelessWidget {
// final Map<String, dynamic> transactionData;
//
// const StaticQRChargeSlip({Key? key, required this.transactionData})
//     : super(key: key);
//
// @override
// Widget build(BuildContext context) {
// return Scaffold(
// appBar: AppBar(
// title: Text('Charge Slip'),
// ),
// body: Column(
// children: [
// // Add Bijlipay logo here
// Image.asset(
// 'assets/bijli_logo.png', // Replace with your logo asset
// height: 100,
// width: 100,
// ),
// SizedBox(height: 16),
// Text(
// 'Bijlipay Skilworth Technologies Limited',
// style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// ),
// SizedBox(height: 32),
// Text(
// '₹${transactionData['transactionAmount']}',
// style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
// ),
// SizedBox(height: 16),
// Text(
// 'Date & Time',
// style: TextStyle(fontSize: 14, color: Colors.grey),
// ),
// Text(
// transactionData['transactionTimestamp'],
// style: TextStyle(fontSize: 16),
// ),
// SizedBox(height: 16),
// Text(
// 'Transaction ID',
// style: TextStyle(fontSize: 14, color: Colors.grey),
// ),
// Text(
// transactionData['merchantTransactionId'],
// style: TextStyle(fontSize: 16),
// ),
// SizedBox(height: 16),
// Text(
// 'Customer VPA',
// style: TextStyle(fontSize: 14, color: Colors.grey),
// ),
// Text(
// transactionData['customerVpa'],
// style: TextStyle(fontSize: 16),
// ),
// SizedBox(height: 16),
// Text(
// 'Credit VPA',
// style: TextStyle(fontSize: 14, color: Colors.grey),
// ),
// Text(
// transactionData['creditVpa'],
// style: TextStyle(fontSize: 16),
// ),
// ],
// ),
// );
// }
// }
// class TransactionsScreen extends StatefulWidget {
// final List<String> terminalIds;
// final List<String> vpaList;
// final String authToken;
//
//
// const TransactionsScreen({
// Key? key,
// required this.terminalIds,
// required this.vpaList,
// required this.authToken,
//
// }) : super(key: key);
//
// @override
// _TransactionsScreenState createState() => _TransactionsScreenState();
// }
//
// class _TransactionsScreenState extends State<TransactionsScreen> {
// String selectedTab = 'POS';
// late String selectedTerminalId;
// String? selectedVPA;
// DateTime? filterStart;
// DateTime? filterEnd;
// DateTime? filterStartDate;
// DateTime? filterEndDate;
// List<Map<String, dynamic>> transactions = [];
// bool isLoading = false;
// TextEditingController searchController = TextEditingController();
// late ScrollController _scrollController;
// int currentPage = 0;
// bool isLoadingMore = false;
// bool hasMoreData = true;
// TextEditingController qrSearchController = TextEditingController();
// bool isFiltered = false;
// int selectedFilterCount = 0;
// bool successSelected = false;
// bool failedSelected = false;
// bool voidSelected = false;
// bool upiSelected = false;
// bool cardSelected = false;
// int txnStatus = 0; // Changed default to 0 (all statuses)
// List<String> txnType = [];
// int dateRange = 0;
// String? dateRangeType; // Added this missing variable
// int currentTxnStatus = 0;
// List<String> currentTxnType = [];
// int currentDateRange = 0;
// int qrDateRange = 3;
// String? qrDateRangeType;
// DateTime? qrFilterStartDate;
// DateTime? qrFilterEndDate;
// DateTime? selectedStartDate;
// DateTime? selectedEndDate;
// Timer? _posDebounce;
// Timer? _qrDebounce;
// int _computeFilterCount() {
// if (selectedTab == 'POS') {
// int count = 0;
// if (successSelected) count++;
// if (failedSelected) count++;
// if (voidSelected) count++;
// if (upiSelected) count++;
// if (cardSelected) count++;
// if (dateRangeType != null) count++;
// return count;
// } else {
// int count = 0;
// if (qrDateRangeType != null) count++;
// return count;
// }
// }
// int _getFilterCode(int txnStatus, List<String> txnType, int dateRange) {
// final hasStatusFilter = txnStatus != 0;
// final hasTypeFilter = txnType.isNotEmpty;
// final hasDateFilter = dateRange != 0;
//
// final filterCount = [hasStatusFilter, hasTypeFilter, hasDateFilter]
//     .where((filter) => filter)
//     .length;
//
// if (filterCount == 0) return 0;
// if (filterCount == 1) {
// if (hasStatusFilter) return 1;
// if (hasTypeFilter) return 2;
// if (hasDateFilter) return 3;
// }
// return 4; // Any combination of 2 or 3 filters
// }
//
//
// // Add this helper method to convert DateTime to Unix timestamp
// int _dateTimeToUnixTimestamp(DateTime dateTime) {
// return (dateTime.millisecondsSinceEpoch / 1000).floor();
// }
//
// @override
// void initState() {
// super.initState();
// selectedTerminalId = widget.terminalIds.isNotEmpty ? widget.terminalIds.first : '';
// selectedVPA = widget.vpaList.isNotEmpty ? widget.vpaList.first : null;
// _scrollController = ScrollController();
// _scrollController.addListener(_scrollListener);
//
// print('Terminal IDs: ${widget.terminalIds}');
// print('Auth Token: ${widget.authToken}');
// print('Selected VPA: $selectedVPA');
//
// // Initial fetch with default parameters
// if (selectedTab == 'POS') {
// fetchTransactions(txnStatus, txnType);
// } else {
// fetchStaticQRTransactions();
// }
// }
//
// void _scrollListener() {
// final max = _scrollController.position.maxScrollExtent;
// final current = _scrollController.position.pixels;
//
// if (current >= max - 500) {
// if (!isLoadingMore && hasMoreData) {
// if (selectedTab == 'Static QR') {
// if (qrDateRange == 3) {
// late int fromDate;
// late int toDate;
//
// if (qrDateRangeType == 'choose_date' && qrFilterStartDate != null && qrFilterEndDate != null) {
// final startOfDay = DateTime(qrFilterStartDate!.year, qrFilterStartDate!.month, qrFilterStartDate!.day, 0, 0, 0);
// final endOfDay = DateTime(qrFilterEndDate!.year, qrFilterEndDate!.month, qrFilterEndDate!.day, 23, 59, 59);
// fromDate = _dateTimeToUnixTimestamp(startOfDay);
// toDate = _dateTimeToUnixTimestamp(endOfDay);
// } else if (qrDateRangeType == 'this_month') {
// final now = DateTime.now();
// final firstDay = DateTime(now.year, now.month, 1, 0, 0, 0);
// final currentDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
// fromDate = _dateTimeToUnixTimestamp(firstDay);
// toDate = _dateTimeToUnixTimestamp(currentDay);
// } else if (qrDateRangeType == 'last_30_days') {
// final now = DateTime.now();
// final start = now.subtract(const Duration(days: 29));
// final startOfPeriod = DateTime(start.year, start.month, start.day, 0, 0, 0);
// final endOfPeriod = DateTime(now.year, now.month, now.day, 23, 59, 59);
// fromDate = _dateTimeToUnixTimestamp(startOfPeriod);
// toDate = _dateTimeToUnixTimestamp(endOfPeriod);
// } else {
// fromDate = 0;
// toDate = 0;
// }
//
// loadMoreStaticQRTransactions(fromDate: fromDate, toDate: toDate);
// }
// } else {
// loadMoreTransactions(); // POS pagination
// }
// }
// }
// }
//
//
// Future<void> loadMoreTransactions([int? dateRangeOverride]) async {
// if (isLoadingMore) return;
//
// setState(() {
// isLoadingMore = true;
// });
//
// try {
// final nextPage = currentPage + 1;
// String fromDate = '0';
// String toDate = '0';
//
// final dateRangeToUse = dateRangeOverride ?? currentDateRange;
//
// // FIXED: Same date range calculation as fetchTransactions
// if (dateRangeToUse == 3) {
// if (dateRangeType == 'choose_date' && filterStartDate != null && filterEndDate != null) {
// final startOfDay = DateTime(filterStartDate!.year, filterStartDate!.month, filterStartDate!.day, 0, 0, 0);
// final endOfDay = DateTime(filterEndDate!.year, filterEndDate!.month, filterEndDate!.day, 23, 59, 59);
// fromDate = _dateTimeToUnixTimestamp(startOfDay).toString();
// toDate = _dateTimeToUnixTimestamp(endOfDay).toString();
// } else if (dateRangeType == 'this_month') {
// final now = DateTime.now();
// final firstDay = DateTime(now.year, now.month, 1, 0, 0, 0);
// final currentDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
// fromDate = _dateTimeToUnixTimestamp(firstDay).toString();
// toDate = _dateTimeToUnixTimestamp(currentDay).toString();
// } // In loadMoreTransactions method
// else if (dateRangeType == 'last_30_days') {
// final now = DateTime.now();
// final thirtyDaysAgo = now.subtract(const Duration(days: 29));
// final startOfPeriod = DateTime(thirtyDaysAgo.year, thirtyDaysAgo.month, thirtyDaysAgo.day, 0, 0, 0);
// final endOfPeriod = DateTime(now.year, now.month, now.day, 23, 59, 59);
// fromDate = _dateTimeToUnixTimestamp(startOfPeriod).toString();
// toDate = _dateTimeToUnixTimestamp(endOfPeriod).toString();
// }
// }
// final filterCode = _getFilterCode(txnStatus, txnType, dateRange);
// final Uri uri = Uri.parse('https://bportal.bijlipay.co.in:9027/txn/get-pos-transaction-pageable/$filterCode')
//     .replace(queryParameters: {
// 'fromDate': fromDate,
// 'toDate': toDate,
// 'searchTerm': searchController.text.trim(),
// 'tid': selectedTerminalId,
// 'page': nextPage.toString(),
// 'sort': 'response_received_time,desc',
// 'size': '50',
// });
//
// Map<String, dynamic> requestBody = {
// "dateRange": dateRangeToUse,
// "txnStatus": currentTxnStatus,
// "txnType": currentTxnType,
// };
//
// final response = await handleResponse(
// http.post(
// uri,
// headers: {
// 'Content-Type': 'application/json; charset=UTF-8',
// 'Authorization': 'Bearer ${widget.authToken}',
// },
// body: jsonEncode(requestBody),
// ),
// );
//
// if (response.statusCode == 200) {
// final responseData = jsonDecode(response.body);
// if (responseData['status'] == 'OK') {
// final List<dynamic> newContent = responseData['data']['content'] ?? [];
// final bool isLastPage = responseData['data']['last'] ?? true;
//
// List<Map<String, dynamic>> filteredNewTransactions = [];
//
// for (var transaction in newContent) {
// final processedTransaction = {
// "cardNumber": "**** ${transaction['maskedCardNumber'] != null && transaction['maskedCardNumber'] != '' ? transaction['maskedCardNumber'] : 'XXXX'}",
// "time": transaction['responseReceivedTime'] ?? 'Unknown Time',
// "amount": "₹${transaction['txnAmount'].toString()}",
// "status": _getTransactionStatus(transaction['txnType'],
// transaction['txnResponseCode'] ?? 'Unknown'),
// "type": _getCardType(transaction['bin']),
// "rrn": transaction['rRNumber']?.toString() ?? '',
// "rawTxnType": transaction['txnType']?.toString() ?? '',
// "rawResponseCode": transaction['txnResponseCode']?.toString() ?? '',
// };
//
// if (_shouldIncludeTransaction(processedTransaction, currentTxnStatus, currentTxnType)) {
// filteredNewTransactions.add(processedTransaction);
// }
// }
//
// setState(() {
// transactions.addAll(filteredNewTransactions);
// currentPage = nextPage;
// hasMoreData = !isLastPage;
// });
// }
// }
// } catch (e) {
// print('Error loading more transactions: $e');
// } finally {
// setState(() => isLoadingMore = false);
// }
// }
//
//
// Future<void> fetchTransactions(int txnStatus, List<String> txnType, [int dateRange = 0]) async {
// setState(() {
// isLoading = true;
// currentPage = 0;
// transactions.clear();
// hasMoreData = true;
// currentTxnStatus = txnStatus;
// currentTxnType = List.from(txnType);
// currentDateRange = dateRange;
// });
//
// try {
// String fromDate = '0';
// String toDate = '0';
//
// // FIXED: Proper date range calculation
// if (dateRange == 3) {
// if (dateRangeType == 'choose_date' && filterStartDate != null && filterEndDate != null) {
// // For custom date range, use start of day for fromDate and end of day for toDate
// final startOfDay = DateTime(filterStartDate!.year, filterStartDate!.month, filterStartDate!.day, 0, 0, 0);
// final endOfDay = DateTime(filterEndDate!.year, filterEndDate!.month, filterEndDate!.day, 23, 59, 59);
// fromDate = _dateTimeToUnixTimestamp(startOfDay).toString();
// toDate = _dateTimeToUnixTimestamp(endOfDay).toString();
// } else if (dateRangeType == 'this_month') {
// final now = DateTime.now();
// final firstDay = DateTime(now.year, now.month, 1, 0, 0, 0); // Start of month
// final currentDay = DateTime(now.year, now.month, now.day, 23, 59, 59); // End of current day
// fromDate = _dateTimeToUnixTimestamp(firstDay).toString();
// toDate = _dateTimeToUnixTimestamp(currentDay).toString();
// } // In fetchTransactions method
// else if (dateRangeType == 'last_30_days') {
// final now = DateTime.now();
// // Use 29 days ago to get exactly 30 days including today
// final thirtyDaysAgo = now.subtract(const Duration(days: 29));
// final startOfPeriod = DateTime(thirtyDaysAgo.year, thirtyDaysAgo.month, thirtyDaysAgo.day, 0, 0, 0);
// final endOfPeriod = DateTime(now.year, now.month, now.day, 23, 59, 59);
// fromDate = _dateTimeToUnixTimestamp(startOfPeriod).toString();
// toDate = _dateTimeToUnixTimestamp(endOfPeriod).toString();
// }
// // Debug prints to verify date ranges
// print('Date Range Type: $dateRangeType');
// print('From Date Unix: $fromDate (${DateTime.fromMillisecondsSinceEpoch(int.parse(fromDate) * 1000)})');
// print('To Date Unix: $toDate (${DateTime.fromMillisecondsSinceEpoch(int.parse(toDate) * 1000)})');
// }
// final filterCode = _getFilterCode(txnStatus, txnType, dateRange);
// final Uri uri = Uri.parse('https://bportal.bijlipay.co.in:9027/txn/get-pos-transaction-pageable/$filterCode')
//     .replace(queryParameters: {
// 'fromDate': fromDate,
// 'toDate': toDate,
// 'searchTerm': searchController.text.trim(),
// 'tid': selectedTerminalId,
// 'page': '1',
// 'sort': 'response_received_time,desc',
// 'size': '50',
// });
//
// Map<String, dynamic> requestBody = {
// "dateRange": dateRange,
// "txnStatus": txnStatus,
// "txnType": txnType,
// };
//
// print('Request URL: ${uri.toString()}');
// print('Request Body: ${jsonEncode(requestBody)}');
//
// final response = await handleResponse(
// http.post(
// uri,
// headers: {
// 'Authorization': 'Bearer ${widget.authToken}',
// 'Content-Type': 'application/json',
// },
// body: jsonEncode(requestBody),
// ),
// );
//
// if (response.statusCode == 200) {
// final responseData = jsonDecode(response.body);
// if (responseData['status'] == 'OK') {
// final List<dynamic> content = responseData['data']['content'] ?? [];
// final bool isLastPage = responseData['data']['last'] ?? true;
//
// print('API returned ${content.length} transactions');
//
// // Process transactions
// List<Map<String, dynamic>> filteredTransactions = [];
//
// for (var transaction in content) {
// final processedTransaction = {
// "cardNumber": "**** ${transaction['maskedCardNumber'] != null && transaction['maskedCardNumber'] != '' ? transaction['maskedCardNumber'] : 'XXXX'}",
// "time": transaction['responseReceivedTime'] ?? 'Unknown Time',
// "amount": "₹${transaction['txnAmount'].toString()}",
// "status": _getTransactionStatus(
// transaction['txnType'],
// transaction['txnResponseCode'] ?? 'Unknown'
// ),
// "type": _getCardType(transaction['bin']),
// "rrn": transaction['rRNumber']?.toString() ?? '',
// "rawTxnType": transaction['txnType']?.toString() ?? '',
// "rawResponseCode": transaction['txnResponseCode']?.toString() ?? '',
// };
//
// // Apply client-side filtering (if needed as backup)
// if (_shouldIncludeTransaction(processedTransaction, txnStatus, txnType)) {
// filteredTransactions.add(processedTransaction);
// }
// }
//
// print('After filtering: ${filteredTransactions.length} transactions');
//
// setState(() {
// transactions = filteredTransactions;
// currentPage = 1;
// hasMoreData = !isLastPage;
// });
// } else {
// print('API Error: ${responseData['message'] ?? 'Unknown error'}');
// setState(() {
// transactions = [];
// });
// }
// } else {
// print('HTTP Error: ${response.statusCode}');
// setState(() {
// transactions = [];
// });
// }
// } catch (e) {
// print('Error fetching transactions: $e');
// setState(() {
// transactions = [];
// });
// } finally {
// setState(() => isLoading = false);
// }
// }
//
// bool _isWithinDateRange(String dateString, DateTime startDate, DateTime endDate) {
// try {
// final transactionDate = _parseDateTime(dateString);
// final start = DateTime(startDate.year, startDate.month, startDate.day);
// final end = DateTime(endDate.year, endDate.month, endDate.day).add(Duration(days: 1));
//
// return transactionDate.isAfter(start) && transactionDate.isBefore(end);
// } catch (e) {
// print('Error parsing date: $dateString - $e');
// return false;
// }
// }
// bool _shouldIncludeTransaction(Map<String, dynamic> transaction, int txnStatus, List<String> txnType) {
// final status = transaction['status'];
// final rawTxnType = transaction['rawTxnType'];
//
// // Check transaction status filter
// if (txnStatus != 0) {
// bool statusMatch = false;
//
// if (txnStatus == 1 && status == "Success") statusMatch = true;
// if (txnStatus == 2 && status == "Failed") statusMatch = true;
// if (txnStatus == 3 && (status == "Success" || status == "Failed")) statusMatch = true;
//
// if (!statusMatch) return false;
// }
//
// // Check transaction type filter
// if (txnType.isNotEmpty) {
// bool typeMatch = false;
//
// // Check if transaction type matches any selected types
// if (txnType.contains(rawTxnType)) {
// typeMatch = true;
// }
//
// // Special handling for UPI types
// if (txnType.any((type) => ["37", "39", "38", "48"].contains(type))) {
// if (["37", "39", "38", "48"].contains(rawTxnType)) {
// typeMatch = true;
// }
// }
//
// if (!typeMatch) return false;
// }
//
// return true;
// }
//
//
// String _getTransactionStatus(dynamic txnType, dynamic txnResponseCode) {
// if (txnType == null || txnResponseCode == null) {
// print("Missing status fields - Type: $txnType, Response: $txnResponseCode");
// return "Failed";
// }
//
// final type = txnType.toString().trim();
// final response = txnResponseCode.toString().trim();
// print("Status Check - Type: $type, Response: $response");
//
// // Check for Void first (txnType "02" is always void regardless of response code)
// if (type == "02") return "Void";
//
// // Then check response code for success/failure
// if (response == "00") return "Success";
//
// // Everything else is failed
// return "Failed";
// }
//
//
// String _getCardType(String? binStr) {
// if (binStr == null || binStr.isEmpty) return 'Unknown';
//
// // Pad to 6 digits if needed
// if (binStr.length < 6) {
// binStr = binStr.padLeft(6, '0');
// } else if (binStr.length > 6) {
// binStr = binStr.substring(0, 6);
// }
//
// int? bin = int.tryParse(binStr);
// if (bin == null) return 'qr';
//
// // Check ranges
// if (binRangeVisa(bin)) return 'visa';
// if (binRangeMaster(bin)) return 'master';
// if (binRangeDiscover(bin)) return 'rupay';
// if (binRangeUnionPay(bin)) return 'unionpay';
// if (binRangeJcb(bin)) return 'rupay';
// if (binRangeRuPay(bin)) return 'rupay';
// if (binRangeAE(bin)) return 'amex';
//
// return 'qr';
// }
//
//
// bool binRangeVisa(int bin) {
// return bin >= 400000 && bin <= 499999;
// }
//
// bool binRangeMaster(int bin) {
// return (bin >= 222100 && bin <= 272099) ||
// (bin >= 510000 && bin <= 559999) ||
// (bin >= 675920 && bin <= 675923);
// }
//
// bool binRangeDiscover(int bin) {
// return (bin >= 300000 && bin <= 305999) ||
// (bin >= 309500 && bin <= 309599) ||
// (bin >= 360000 && bin <= 369999) ||
// (bin >= 380000 && bin <= 399999) ||
// (bin >= 601100 && bin <= 601103) ||
// (bin >= 601105 && bin <= 601109) ||
// (bin >= 601120 && bin <= 601149) ||
// (bin == 601174) ||
// (bin >= 601177 && bin <= 601179) ||
// (bin >= 601186 && bin <= 601199) ||
// (bin >= 644000 && bin <= 650599) ||
// (bin >= 650601 && bin <= 650609) ||
// (bin >= 650611 && bin <= 659999) ||
// (bin >= 608001 && bin <= 608500) ||
// (bin == 820199);
// }
//
// bool binRangeUnionPay(int bin) {
// return (bin == 621094) ||
// (bin >= 622126 && bin <= 622925) ||
// (bin >= 622926 && bin <= 623796) ||
// (bin >= 624000 && bin <= 626999) ||
// (bin >= 628200 && bin <= 628899) ||
// (bin >= 810000 && bin <= 810999) ||
// (bin >= 811000 && bin <= 813199) ||
// (bin >= 813200 && bin <= 815199) ||
// (bin >= 815200 && bin <= 816399) ||
// (bin >= 816400 && bin <= 817199) ||
// (bin >= 309600 && bin <= 310299) ||
// (bin >= 311200 && bin <= 312099) ||
// (bin >= 315800 && bin <= 315999) ||
// (bin >= 333700 && bin <= 334999) ||
// (bin >= 352800 && bin <= 358999);
// }
// bool binRangeRuPay(int bin) {
// return (bin >= 600100 && bin <= 600109) ||
// (bin >= 601200 && bin <= 601206) ||
// (bin >= 601380 && bin <= 601399) ||
// (bin >= 601421 && bin <= 601425) ||
// (bin >= 601428 && bin <= 601429) ||
// (bin >= 601431 && bin <= 601439) ||
// (bin >= 601441 && bin <= 601449) ||
// (bin >= 601451 && bin <= 601459) ||
// (bin >= 601461 && bin <= 601469) ||
// (bin >= 601481 && bin <= 601489) ||
// (bin >= 601491 && bin <= 601499) ||
// (bin >= 602000 && bin <= 602099) ||
// (bin >= 603500 && bin <= 603599) ||
// (bin >= 604000 && bin <= 604999) ||
// (bin >= 605100 && bin <= 605199) ||
// (bin >= 607000 && bin <= 607999) ||
// (bin >= 608000 && bin <= 608999) ||
// (bin >= 652100 && bin <= 653099);
// }
//
// bool binRangeJcb(int bin) {
// return (bin >= 308800 && bin <= 309499) || (bin == 353014);
// }
//
// bool binRangeAE(int bin) {
// return (bin >= 340000 && bin <= 349999) ||
// (bin >= 370000 && bin <= 379999);
// }
//
// void _showFilterDialog() {
//
// if (selectedTab == 'POS') {
// showDialog(
// context: context,
// barrierDismissible: false,
// builder: (BuildContext context) {
// return Dialog(
// child: TransactionFilterDialog(
// initialStartDate: filterStartDate,
// initialEndDate: filterEndDate,
// initialDateRangeType: dateRangeType,
// successSelected: successSelected,
// failedSelected: failedSelected,
// voidSelected: voidSelected,
// upiSelected: upiSelected,
// cardSelected: cardSelected,
// onApply: (start, end, newTxnStatus, newTxnType, dateRange, dateRangeType) {
// setState(() {
// filterStartDate = start;
// filterEndDate = end;
// txnStatus = newTxnStatus;
// txnType = newTxnType;
// this.dateRange = dateRange;
// this.dateRangeType = dateRangeType;
// successSelected = newTxnStatus == 1 || newTxnStatus == 3;
// failedSelected = newTxnStatus == 2 || newTxnStatus == 3;
// voidSelected = newTxnType.contains("02");
// upiSelected = newTxnType.any((type) => ["37", "39", "38", "48"].contains(type));
// cardSelected = newTxnType.contains("00");
// selectedFilterCount = _computeFilterCount();
// });
// fetchTransactions(newTxnStatus, newTxnType, dateRange);
// },
// onClearAll: () {
// setState(() {
// filterStartDate = null;
// filterEndDate = null;
// dateRangeType = null;
// txnStatus = 0;
// txnType = [];
// dateRange = 0;
// successSelected = false;
// failedSelected = false;
// voidSelected = false;
// upiSelected = false;
// cardSelected = false;
// selectedFilterCount = 0;
// });
// fetchTransactions(0, []);
// },
// ),
// );
// },
// );
// } else {
// showDialog(
// context: context,
// builder: (BuildContext context) {
// return Dialog(
// child: QRFilterDialog(
// initialStartDate: qrFilterStartDate,
// initialEndDate: qrFilterEndDate,
// initialDateRangeType: qrDateRangeType,
// onApply: (start, end, dateRangeType) {
// setState(() {
// qrFilterStartDate = start;
// qrFilterEndDate = end;
// qrDateRangeType = dateRangeType;
// qrDateRange = dateRangeType != null ? 3 : 0;
// selectedFilterCount = dateRangeType != null ? 1 : 0;
// });
// fetchStaticQRTransactions();
// },
// onClearAll: () {
// setState(() {
// qrFilterStartDate = null;
// qrFilterEndDate = null;
// qrDateRangeType = null;
// qrDateRange = 0;
// selectedFilterCount = 0;
// });
// fetchStaticQRTransactions();
// },
// ),
// );
// },
// );
// }
// }
//
//
// void _updateFilterCount(int count) {
// setState(() {
// selectedFilterCount = count;
// });
// }
//
// // Add search functionality
// void _performSearch() {
// fetchTransactions(txnStatus, txnType, dateRange);
// }
//
// @override
// Widget build(BuildContext context) {
// return Scaffold(
// backgroundColor: Colors.white,
// body: Column(
// children: [
// Container(
// decoration: BoxDecoration(
// color: Colors.white,
// border: Border(
// bottom: BorderSide(color: Colors.grey.shade200),
// ),
// ),
// child: Padding(
// padding: const EdgeInsets.all(16.0),
// child: Column(
// children: [
// Row(
// children: [
// _buildTabButton('POS', selectedTab == 'POS'),
// const SizedBox(width: 16),
// _buildTabButton('Static QR', selectedTab == 'Static QR'),
// ],
// ),
// const SizedBox(height: 16),
// if (selectedTab == 'POS')
// _buildPOSControls()
// else
// _buildStaticQRControls(),
// ],
// ),
// ),
// ),
// Expanded(
// child: selectedTab == 'POS'
// ? _buildPOSTransactions()
//     : _buildStaticQRTransactions(),
// ),
// ],
// ),
// );
// }
//
// Widget _buildPOSControls() {
// if (widget.terminalIds.isEmpty) {
// return Padding(
// padding: const EdgeInsets.all(16.0),
// child: Text(
// 'No POS terminals available',
// style: TextStyle(color: Colors.grey),
// ),
// );
// }
//
// return Column(
// children: [
// Row(
// children: [
// Expanded(
// child: OverlayDropdown(
// value: selectedTerminalId,
// items: widget.terminalIds,
// onChanged: (newValue) {
// setState(() => selectedTerminalId = newValue!);
// fetchTransactions(txnStatus, txnType);
// },
// showRadio: true,
// ),
// ),
// ],
// ),
// const SizedBox(height: 16),
// Row(
// children: [
// Expanded(
// child: Container(
// padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
// decoration: BoxDecoration(
// border: Border.all(color: Colors.grey.shade300),
// borderRadius: BorderRadius.circular(10),
// ),
// child: Row(
// children: [
// Icon(Icons.search, color: Colors.grey),
// SizedBox(width: 8),
// Expanded(
// child: TextField(
// controller: searchController,
// decoration: InputDecoration(
// hintText: 'Search',
// border: InputBorder.none,
// isDense: true,
// contentPadding: EdgeInsets.zero,
// ),
// onChanged: (value) {
// if (_posDebounce?.isActive ?? false) _posDebounce?.cancel();
// _posDebounce = Timer(const Duration(milliseconds: 500), () {
// _performPOSSearch();
// });
// },
// ),
// ),
// if (searchController.text.isNotEmpty)
// GestureDetector(
// onTap: () {
// setState(() {
// searchController.clear();
// });
// _performPOSSearch();
// },
// child: Icon(Icons.close, color: Colors.grey),
// ),
// ],
// ),
// ),
// ),
// const SizedBox(width: 10),
// _buildFilterTextButton(),
// const SizedBox(width: 10),
// _buildDownloadButton(),
// ],
// ),
// ],
// );
// }
//
// Widget _buildStaticQRControls() {
// if (widget.vpaList.isEmpty) {
// return Padding(
// padding: const EdgeInsets.all(16.0),
// child: Text(
// 'No Static QR codes available',
// style: TextStyle(color: Colors.grey),
// ),
// );
// }
//
// return Column(
// children: [
// Row(
// children: [
// Expanded(
// child: OverlayDropdown(
// value: selectedVPA,
// items: widget.vpaList,
// onChanged: (newValue) {
// setState(() => selectedVPA = newValue);
// fetchStaticQRTransactions();
// },
// ),
// ),
// ],
// ),
// const SizedBox(height: 16),
// Row(
// children: [
// Expanded(
// child: Container(
// padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
// decoration: BoxDecoration(
// border: Border.all(color: Colors.grey.shade300),
// borderRadius: BorderRadius.circular(8),
// ),
// child: Row(
// children: [
// Icon(Icons.search, color: Colors.grey),
// SizedBox(width: 8),
// Expanded(
// child: TextField(
// controller: qrSearchController,
// decoration: InputDecoration(
// hintText: 'Search',
// border: InputBorder.none,
// isDense: true,
// contentPadding: EdgeInsets.zero,
// ),
// onChanged: (value) {
// if (_qrDebounce?.isActive ?? false) _qrDebounce?.cancel();
// _qrDebounce = Timer(const Duration(milliseconds: 500), () {
// _performQRSearch();
// });
// },
// ),
// ),
// if (qrSearchController.text.isNotEmpty)
// GestureDetector(
// onTap: () {
// setState(() {
// qrSearchController.clear();
// currentPage = 0;
// });
// _performQRSearch();
// },
// child: Icon(Icons.close, color: Colors.grey),
// ),
// ],
// ),
// ),
// ),
// const SizedBox(width: 10),
// _buildFilterTextButton(),
// const SizedBox(width: 10),
// _buildDownloadButton(),
// ],
// ),
// ],
// );
// }
//
// Widget _buildFilterTextButton() {
// return TextButton(
// onPressed: _showFilterDialog,
// style: TextButton.styleFrom(
// backgroundColor: selectedFilterCount > 0 ? customPurple : Colors.white,
// padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
// minimumSize: Size(40, 40),
// shape: RoundedRectangleBorder(
// borderRadius: BorderRadius.circular(10),
// side: BorderSide(color: customPurple, width: 1),
// ),
// ),
// child: Row(
// mainAxisSize: MainAxisSize.min,
// children: [
// Image.asset(
// 'assets/filter.png',
// width: 24,
// height: 24,
// color: selectedFilterCount > 0 ? Colors.white : customPurple,
// ),
// if (selectedFilterCount > 0)
// Padding(
// padding: const EdgeInsets.only(left: 4.0),
// child: Text(
// '$selectedFilterCount',
// style: TextStyle(
// color: selectedFilterCount > 0 ? Colors.white : customPurple,
// fontWeight: FontWeight.bold,
// ),
// ),
// ),
// ],
// ),
// );
// }
//
// // Add these helper methods to the _TransactionsScreenState class
// (int, int) _computeDownloadDateRange() {
// final now = DateTime.now();
// if (currentDateRange == 3) {
// if (dateRangeType == 'choose_date' && filterStartDate != null && filterEndDate != null) {
// final startOfDay = DateTime(filterStartDate!.year, filterStartDate!.month, filterStartDate!.day, 0, 0, 0);
// final endOfDay = DateTime(filterEndDate!.year, filterEndDate!.month, filterEndDate!.day, 23, 59, 59);
// return (
// (startOfDay.millisecondsSinceEpoch / 1000).floor(),
// (endOfDay.millisecondsSinceEpoch / 1000).floor()
// );
// } else if (dateRangeType == 'this_month') {
// final now = DateTime.now();
// final firstDay = DateTime(now.year, now.month, 1, 0, 0, 0);
// final lastDay = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
// return (
// (firstDay.millisecondsSinceEpoch / 1000).floor(),
// (lastDay.millisecondsSinceEpoch / 1000).floor()
// );
// } else if (dateRangeType == 'last_30_days') {
// final now = DateTime.now();
// final thirtyDaysAgo = now.subtract(const Duration(days: 29));
// final startOfPeriod = DateTime(thirtyDaysAgo.year, thirtyDaysAgo.month, thirtyDaysAgo.day, 0, 0, 0);
// final endOfPeriod = DateTime(now.year, now.month, now.day, 23, 59, 59);
// return (
// (startOfPeriod.millisecondsSinceEpoch / 1000).floor(),
// (endOfPeriod.millisecondsSinceEpoch / 1000).floor()
// );
// }
// }
//
//
// final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0);
// final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
//
// return (
// (startOfToday.millisecondsSinceEpoch / 1000).floor(),
// (endOfToday.millisecondsSinceEpoch / 1000).floor()
// );
// }
//
// String _getDownloadRangeText() {
// final now = DateTime.now();
// if (currentDateRange == 3) {
// if (dateRangeType == 'choose_date' && filterStartDate != null && filterEndDate != null) {
// return '${filterStartDate!.day}/${filterStartDate!.month}/${filterStartDate!.year} - ${filterEndDate!.day}/${filterEndDate!.month}/${filterEndDate!.year}';
// } else if (dateRangeType == 'this_month') {
// return 'This Month';
// } else if (dateRangeType == 'last_30_days') {
// return 'Last 30 Days';
// }
// }
//
// return 'Today (${now.day}/${now.month}/${now.year})';
// }
//
// // Add this method to show the confirmation dialog
// // Replace the _showDownloadConfirmation method with this enhanced version
//
//
// // Helper method to build download detail rows
// Widget _buildDownloadDetail(String label, String value) {
// return Row(
// crossAxisAlignment: CrossAxisAlignment.start,
// children: [
// SizedBox(
// width: 80,
// child: Text(
// '$label:',
// style: TextStyle(
// fontSize: 12,
// color: Colors.grey[600],
// fontFamily: 'Montserrat',
// ),
// ),
// ),
// Expanded(
// child: Text(
// value,
// style: TextStyle(
// fontSize: 12,
// fontWeight: FontWeight.w500,
// color: Colors.grey[800],
// fontFamily: 'Montserrat',
// ),
// ),
// ),
// ],
// );
// }
//
// // Helper method to get formatted date range text
// // Replace the _showDownloadConfirmation method with this enhanced version
// void _showDownloadConfirmation() {
// showDialog(
// context: context,
// barrierDismissible: false,
// builder: (context) => Dialog(
// shape: RoundedRectangleBorder(
// borderRadius: BorderRadius.circular(16),
// ),
// elevation: 8,
// child: Container(
// constraints: BoxConstraints(
// maxWidth: MediaQuery.of(context).size.width * 0.9,
// maxHeight: MediaQuery.of(context).size.height * 0.7,
// ),
// child: Column(
// mainAxisSize: MainAxisSize.min,
// children: [
// // Header
// Container(
// padding: EdgeInsets.all(20),
// decoration: BoxDecoration(
// color: customPurple.withOpacity(0.1),
// borderRadius: BorderRadius.only(
// topLeft: Radius.circular(16),
// topRight: Radius.circular(16),
// ),
// ),
// child: Row(
// children: [
// Container(
// padding: EdgeInsets.all(8),
// decoration: BoxDecoration(
// color: customPurple,
// borderRadius: BorderRadius.circular(8),
// ),
// child: Icon(
// Icons.download_rounded,
// color: Colors.white,
// size: 24,
// ),
// ),
// SizedBox(width: 12),
// Expanded(
// child: Column(
// crossAxisAlignment: CrossAxisAlignment.start,
// children: [
// Text(
// 'Download Transactions',
// style: TextStyle(
// fontSize: 18,
// fontWeight: FontWeight.bold,
// color: customPurple,
// fontFamily: 'Montserrat',
// ),
// ),
// SizedBox(height: 4),
// Text(
// selectedTab == 'POS' ? 'POS Terminal Data' : 'Static QR Data',
// style: TextStyle(
// fontSize: 12,
// color: Colors.grey[600],
// fontFamily: 'Montserrat',
// ),
// ),
// ],
// ),
// ),
// ],
// ),
// ),
//
// // Scrollable Content
// Flexible(
// child: SingleChildScrollView(
// child: Padding(
// padding: EdgeInsets.all(20),
// child: Column(
// crossAxisAlignment: CrossAxisAlignment.start,
// children: [
// // Main question
// Text(
// 'Are you sure you want to download transactions?',
// style: TextStyle(
// fontSize: 16,
// fontWeight: FontWeight.w600,
// color: Colors.grey[800],
// fontFamily: 'Montserrat',
// ),
// ),
//
// SizedBox(height: 16),
//
// // Simplified filters - only show essential ones
// Container(
// padding: EdgeInsets.all(16),
// decoration: BoxDecoration(
// color: Colors.blue[50],
// borderRadius: BorderRadius.circular(12),
// border: Border.all(color: Colors.blue[200]!),
// ),
// child: Column(
// crossAxisAlignment: CrossAxisAlignment.start,
// children: [
// Row(
// children: [
// Icon(
// Icons.filter_list,
// color: Colors.blue[700],
// size: 18,
// ),
// SizedBox(width: 8),
// Text(
// 'Download Details',
// style: TextStyle(
// fontSize: 14,
// fontWeight: FontWeight.w600,
// color: Colors.blue[700],
// fontFamily: 'Montserrat',
// ),
// ),
// ],
// ),
// SizedBox(height: 12),
// _buildFilterDetail('Date Range', _getDownloadRangeText()),
// SizedBox(height: 8),
// if (selectedTab == 'POS' && selectedTerminalId != null) ...[
// _buildFilterDetail('Terminal', selectedTerminalId!),
// SizedBox(height: 8),
// ],
// if (selectedTab != 'POS' && selectedVPA != null) ...[
// _buildFilterDetail('VPA', selectedVPA!),
// SizedBox(height: 8),
// ],
// ],
// ),
// ),
//
// SizedBox(height: 16),
//
// // Note about changing filters
// Container(
// padding: EdgeInsets.all(12),
// decoration: BoxDecoration(
// color: Colors.green[50],
// borderRadius: BorderRadius.circular(8),
// border: Border.all(color: Colors.green[200]!),
// ),
// child: Row(
// crossAxisAlignment: CrossAxisAlignment.start,
// children: [
// Icon(
// Icons.info_outline,
// color: Colors.green[700],
// size: 20,
// ),
// SizedBox(width: 8),
// Expanded(
// child: Text(
// 'You can modify filters before downloading. Cancel this dialog, adjust your filters, then try again.',
// style: TextStyle(
// fontSize: 12,
// color: Colors.green[800],
// fontFamily: 'Montserrat',
// ),
// ),
// ),
// ],
// ),
// ),
// ],
// ),
// ),
// ),
// ),
//
// // Actions - Fixed at bottom
// Container(
// padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
// decoration: BoxDecoration(
// color: Colors.grey[50],
// borderRadius: BorderRadius.only(
// bottomLeft: Radius.circular(16),
// bottomRight: Radius.circular(16),
// ),
// ),
// child: Row(
// children: [
// Expanded(
// child: TextButton(
// onPressed: () => Navigator.pop(context),
// style: TextButton.styleFrom(
// padding: EdgeInsets.symmetric(vertical: 12),
// shape: RoundedRectangleBorder(
// borderRadius: BorderRadius.circular(8),
// side: BorderSide(color: Colors.grey[300]!),
// ),
// ),
// child: Text(
// 'Cancel',
// style: TextStyle(
// color: Colors.grey[700],
// fontWeight: FontWeight.w600,
// fontFamily: 'Montserrat',
// ),
// ),
// ),
// ),
// SizedBox(width: 12),
// Expanded(
// child: ElevatedButton(
// onPressed: () {
// Navigator.pop(context);
// _downloadTransactions();
// },
// style: ElevatedButton.styleFrom(
// backgroundColor: customPurple,
// foregroundColor: Colors.white,
// padding: EdgeInsets.symmetric(vertical: 12),
// shape: RoundedRectangleBorder(
// borderRadius: BorderRadius.circular(8),
// ),
// elevation: 2,
// ),
// child: Row(
// mainAxisSize: MainAxisSize.min,
// mainAxisAlignment: MainAxisAlignment.center,
// children: [
// Icon(Icons.download_rounded, size: 18),
// SizedBox(width: 6),
// Flexible(
// child: Text(
// 'Download',
// style: TextStyle(
// fontWeight: FontWeight.w600,
// fontFamily: 'Montserrat',
// ),
// ),
// ),
// ],
// ),
// ),
// ),
// ],
// ),
// ),
// ],
// ),
// ),
// ),
// );
// }
//
// // Helper method to build filter detail rows
// Widget _buildFilterDetail(String label, String value) {
// return Row(
// crossAxisAlignment: CrossAxisAlignment.start,
// children: [
// SizedBox(
// width: 90,
// child: Text(
// '$label:',
// style: TextStyle(
// fontSize: 12,
// color: Colors.blue[700],
// fontWeight: FontWeight.w500,
// fontFamily: 'Montserrat',
// ),
// ),
// ),
// Expanded(
// child: Text(
// value,
// style: TextStyle(
// fontSize: 12,
// fontWeight: FontWeight.w600,
// color: Colors.blue[800],
// fontFamily: 'Montserrat',
// ),
// ),
// ),
// ],
// );
// }
//
// // Helper methods to get current filter status
// String _getTxnStatusText() {
// switch (currentTxnStatus) {
// case 0: return 'All Status';
// case 1: return 'Success';
// case 2: return 'Failed';
// case 3: return 'Pending';
// default: return 'All Status';
// }
// }
//
// String _getTxnTypeText() {
// switch (currentTxnType) {
// case 0: return 'All Types';
// case 1: return 'Payment';
// case 2: return 'Refund';
// default: return 'All Types';
// }
// }
//
// // Add this method to handle the actual download
// Future<void> _downloadTransactions() async {
// final (fromDate, toDate) = _computeDownloadDateRange();
//
// if (selectedTab == 'POS') {
// await _downloadPOSTransactions(fromDate, toDate);
// } else {
// await _downloadStaticQRTransactions(fromDate, toDate);
// }
// final dateRange = _computeDownloadDateRange();
// print('Download date range: ${dateRange.$1} to ${dateRange.$2}');
// print('Current date range: $currentDateRange');
// print('Date range type: $dateRangeType');
//
// // Your API call here...
// }
// Future<void> _downloadPOSTransactions(int fromDate, int toDate) async {
// try {
// print('Downloading POS transactions: fromDate=$fromDate (${DateTime.fromMillisecondsSinceEpoch(fromDate * 1000)}), toDate=$toDate (${DateTime.fromMillisecondsSinceEpoch(toDate * 1000)})');
//
// final Uri uri = Uri.parse('https://bportal.bijlipay.co.in:9027/txn/api/download-pos-txn/3').replace(
// queryParameters: {
// 'fromDate': fromDate.toString(),
// 'toDate': toDate.toString(),
// 'searchTerm': searchController.text.trim(),
// 'tid': selectedTerminalId,
// },
// );
//
// final response = await handleResponse(
// http.post(
// uri,
// headers: {
// 'Authorization': 'Bearer ${widget.authToken}',
// 'Content-Type': 'application/json',
// },
// body: jsonEncode({
// "txnStatus": currentTxnStatus,
// "txnType": currentTxnType,
// "dateRange": currentDateRange = 3 ,
// }),
// ),
// );
//
// if (response.statusCode == 200) {
// ScaffoldMessenger.of(context).showSnackBar(
// SnackBar(content: Text('POS transactions downloaded successfully')),
// );
// } else {
// ScaffoldMessenger.of(context).showSnackBar(
// SnackBar(content: Text('Failed to download POS transactions. Status: ${response.statusCode}')),
// );
// }
// } catch (e) {
// print('Error downloading POS transactions: $e');
// ScaffoldMessenger.of(context).showSnackBar(
// SnackBar(content: Text('Error downloading POS transactions: $e')),
// );
// }
// }
//
// Future<void> _downloadStaticQRTransactions(int fromDate, int toDate) async {
// try {
// final Uri uri = Uri.parse(
// 'https://bportal.bijlipay.co.in:9027/txn/api/downloadAxisQrTxnData/1/3')
//     .replace(queryParameters: {
// 'fromDate': fromDate.toString(),
// 'toDate': toDate.toString(),
// 'searchTerm': qrSearchController.text.trim(),
// 'vpa': selectedVPA,
// 'page': '',
// 'size': '',
// 'sort': 'created_at,desc',
// });
//
// final response = await handleResponse(
// http.get(
// uri,
// headers: {
// 'Authorization': 'Bearer ${widget.authToken}',
// },
// ),
// );
//
// if (response.statusCode == 200) {
// ScaffoldMessenger.of(context).showSnackBar(
// SnackBar(content: Text('Static QR transactions downloaded successfully')),
// );
// } else {
// ScaffoldMessenger.of(context).showSnackBar(
// SnackBar(content: Text('Failed to download Static QR transactions')),
// );
// }
// } catch (e) {
// ScaffoldMessenger.of(context).showSnackBar(
// SnackBar(content: Text('Error downloading Static QR transactions: $e')),
// );
// }
// }
// // Update the download button to use the confirmation dialog
// Widget _buildDownloadButton() {
// return TextButton.icon(
// onPressed: _showDownloadConfirmation,
// icon: Icon(Icons.download, color: Colors.white),
// label: Text(
// "Download",
// style: TextStyle(color: Colors.white),
// ),
// style: TextButton.styleFrom(
// backgroundColor: customPurple,
// padding: EdgeInsets.symmetric(horizontal: 17, vertical: 11),
// shape: RoundedRectangleBorder(
// borderRadius: BorderRadius.circular(10),
// ),
// ),
// );
// }
// Widget _buildPOSTransactions() {
// if (isLoading) {
// return Center(
// child: CircularProgressIndicator(
// color: const Color(0xFF61116A),
// ),
// );
// }
//
// if (transactions.isEmpty) {
// return Center(
// child: Column(
// mainAxisAlignment: MainAxisAlignment.center,
// children: [
// Icon(
// Icons.receipt_long_outlined,
// size: 48,
// color: Colors.grey[400],
// ),
// SizedBox(height: 16),
// Text(
// 'No transactions found',
// style: TextStyle(
// fontSize: 16,
// color: Colors.grey[600],
// fontWeight: FontWeight.w500,
// ),
// ),
// SizedBox(height: 8),
// Text(
// 'Try changing your filters or select a different terminal',
// style: TextStyle(
// fontSize: 14,
// color: Colors.grey[500],
// ),
// textAlign: TextAlign.center,
// ),
// ],
// ),
// );
// }
//
// // Group transactions by date
// Map<String, List<Map<String, dynamic>>> groupedTransactions = {};
//
// for (var transaction in transactions) {
// try {
// final transactionDate = _parseDateTime(transaction['time']);
// final dateKey = _formatDate(transactionDate);
//
// if (!groupedTransactions.containsKey(dateKey)) {
// groupedTransactions[dateKey] = [];
// }
// groupedTransactions[dateKey]!.add(transaction);
// } catch (e) {
// print('Error parsing date: ${transaction['time']} - $e');
// }
// }
//
// List<Widget> transactionWidgets = [];
//
// groupedTransactions.forEach((date, dateTransactions) {
// transactionWidgets.add(
// Padding(
// padding: const EdgeInsets.symmetric(vertical: 16.0),
// child: Center(
// child: Container(
// padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
// decoration: BoxDecoration(
// color: Color(0xFFF8EEF2),
// borderRadius: BorderRadius.circular(8.0),
// ),
// child: Text(
// date,
// style: TextStyle(
// color: Colors.grey[600],
// fontWeight: FontWeight.w700,
// fontSize: 14,
// ),
// ),
// ),
// ),
// ),
// );
//
// transactionWidgets.addAll(
// dateTransactions.map((transaction) => _buildTransactionItem(transaction))
// );
// });
//
// if (isLoadingMore) {
// transactionWidgets.add(
// Center(
// child: Padding(
// padding: const EdgeInsets.all(8.0),
// child: CircularProgressIndicator(
// color: const Color(0xFF61116A),
// ),
// ),
// ),
// );
// }
//
// return ListView(
// controller: _scrollController,
// children: transactionWidgets,
// );
// }
//
// DateTime _parseDateTime(String dateStr) {
// try {
// if (dateStr.contains('-')) {
// return DateTime.parse(dateStr.replaceAll('.0', ''));
// } else {
// final parts = dateStr.split(' ');
// final day = int.parse(parts[0]);
// final month = _getMonthNumber(parts[1]);
// final year = int.parse(parts[2]);
//
// final timeParts = parts[3].split('.');
// var hour = int.parse(timeParts[0]);
// final minute = int.parse(timeParts[1]);
//
// final isAM = parts[4].toUpperCase() == 'AM';
// if (!isAM && hour != 12) {
// hour += 12;
// } else if (isAM && hour == 12) {
// hour = 0;
// }
//
// return DateTime(year, month, day, hour, minute);
// }
// } catch (e) {
// print('Error parsing date: $dateStr - $e');
// return DateTime.now();
// }
// }
//
// String _formatDate(DateTime date) {
// final day = date.day.toString().padLeft(2, '0');
// final month = _getMonthName(date.month);
// final year = date.year;
// return "$day $month $year";
// }
//
// String _getMonthName(int month) {
// const months = [
// 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
// 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
// ];
// return months[month - 1];
// }
//
// int _getMonthNumber(String monthStr) {
// const months = {
// 'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
// 'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
// };
// return months[monthStr] ?? 1;
// }
//
// Widget _buildStaticQRTransactions() {
// if (isLoading) {
// return Center(
// child: CircularProgressIndicator(
// color: const Color(0xFF61116A),
// ),
// );
// }
//
// if (transactions.isEmpty) {
// return Center(
// child: Column(
// mainAxisAlignment: MainAxisAlignment.center,
// children: [
// Icon(
// Icons.qr_code_outlined,
// size: 48,
// color: Colors.grey[400],
// ),
// SizedBox(height: 16),
// Text(
// 'No transactions found',
// style: TextStyle(
// fontSize: 16,
// color: Colors.grey[600],
// fontWeight: FontWeight.w500,
// ),
// ),
// SizedBox(height: 8),
// Text(
// 'Try changing your filters or select a different VPA',
// style: TextStyle(
// fontSize: 14,
// color: Colors.grey[500],
// ),
// textAlign: TextAlign.center,
// ),
// ],
// ),
// );
// }
//
// List<Widget> transactionWidgets = [];
// Map<String, List<Map<String, dynamic>>> groupedTransactions = {};
//
// for (var transaction in transactions) {
// try {
// final transactionDate = _parseDateTime(transaction['time']);
// final dateKey = _formatDate(transactionDate);
//
// if (!groupedTransactions.containsKey(dateKey)) {
// groupedTransactions[dateKey] = [];
// }
// groupedTransactions[dateKey]!.add(transaction);
// } catch (e) {
// print('Error parsing date: ${transaction['time']} - $e');
// }
// }
//
// groupedTransactions.forEach((date, dateTransactions) {
// transactionWidgets.add(
// Padding(
// padding: const EdgeInsets.symmetric(vertical: 16.0),
// child: Center(
// child: Container(
// padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
// decoration: BoxDecoration(
// color: Color(0xFFF8EEF2),
// borderRadius: BorderRadius.circular(8.0),
// ),
// child: Text(
// date,
// style: TextStyle(
// color: Colors.grey[600],
// fontWeight: FontWeight.w700,
// fontSize: 14,
// ),
// ),
// ),
// ),
// ),
// );
//
// transactionWidgets.addAll(
// dateTransactions.map((transaction) => _buildTransactionItem(transaction))
// );
// });
//
// if (isLoadingMore) {
// transactionWidgets.add(
// Center(
// child: Padding(
// padding: const EdgeInsets.all(8.0),
// child: CircularProgressIndicator(
// color: const Color(0xFF61116A),
// ),
// ),
// ),
// );
// }
//
// return ListView(
// controller: _scrollController,
// children: transactionWidgets,
// );
// }
//
// void _resetFilters() {
// txnStatus = 0;
// txnType = [];
// dateRange = 0;
// dateRangeType = null;
// filterStartDate = null;
// filterEndDate = null;
// successSelected = false;
// failedSelected = false;
// voidSelected = false;
// upiSelected = false;
// cardSelected = false;
// selectedFilterCount = 0;
// }
//
// void _resetQRFilters() {
// qrDateRange = 0;
// qrDateRangeType = null;
// qrFilterStartDate = null;
// qrFilterEndDate = null;
// selectedFilterCount = 0;
// }
//
// Widget _buildTabButton(String text, bool isSelected) {
// return InkWell(
// onTap: () {
// setState(() {
// selectedTab = text;
// transactions.clear();
// if (text == 'Static QR') {
// _resetQRFilters();
// fetchStaticQRTransactions();
// } else {
// _resetFilters();
// fetchTransactions(txnStatus, txnType);
// }
// });
// },
// child: Container(
// width: text == 'Static QR' ? 100 : 80, // Fixed width based on content
// padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
// child: Column(
// mainAxisSize: MainAxisSize.min,
// children: [
// Text(
// text,
// style: TextStyle(
// color: isSelected ? customPurple : Colors.grey,
// fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
// fontSize: 13, // Slightly smaller font size
// ),
// maxLines: 1,
// overflow: TextOverflow.ellipsis,
// ),
// const SizedBox(height: 8),
// Container(
// height: 2,
// color: isSelected ? customPurple : Colors.transparent,
// ),
// ],
// ),
// ),
// );
// }
//
// Widget _buildTransactionItem(Map<String, dynamic> transaction) {
// // Get status directly from pre-calculated transaction data
// final statusText = transaction['status'];
// Color statusColor = (statusText == "Success") ? Colors.green[600]! :
// (statusText == "Void") ? Colors.orange[600]! : Colors.red[600]!;
//
// String amountText = transaction['amount'];
// List<String> amountParts = amountText.split('₹')[1].trim().split('.');
// String wholePart = amountParts[0];
// String decimalPart = amountParts.length > 1 ? amountParts[1].padRight(2, '0').substring(0, 2) : '00';
//
// return Material(
// color: Colors.transparent,
// child: InkWell(
// onTap: () {
// if (selectedTab == 'Static QR') {
// Navigator.push(
// context,
// MaterialPageRoute(
// builder: (context) => StaticQRChargeSlip(
// transactionData: transaction,
// ),
// ),
// );
// } else {
// Navigator.push(
// context,
// MaterialPageRoute(
// builder: (context) => TransactionDetailsScreen(
// authToken: widget.authToken,
// rrn: transaction['rrn'],
// terminalIds: widget.terminalIds,
// vpaList: widget.vpaList,
// ),
// ),
// );
// }
// },
// splashColor: Colors.grey.withOpacity(0.1),
// highlightColor: Colors.grey.withOpacity(0.05),
// child: Container(
// padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
// decoration: BoxDecoration(
// border: Border(
// bottom: BorderSide(
// color: Color(0xFFE5E7EB),
// width: 1,
// ),
// ),
// ),
// child: Row(
// children: [
// // Payment method icon with modern styling
// Container(
// width: 48,
// height: 48,
// padding: const EdgeInsets.all(10),
// decoration: BoxDecoration(
// color: Colors.grey[50],
// borderRadius: BorderRadius.circular(12),
// ),
// child: Image.asset(
// 'assets/${transaction['type']}.png',
// fit: BoxFit.contain,
// ),
// ),
//
// const SizedBox(width: 16),
//
// // Left side - Card info
// Expanded(
// child: Column(
// crossAxisAlignment: CrossAxisAlignment.start,
// children: [
// Text(
// transaction['cardNumber'],
// style: const TextStyle(
// fontWeight: FontWeight.w600,
// fontSize: 16,
// color: Color(0xFF1A1A1A),
// letterSpacing: -0.2,
// ),
// overflow: TextOverflow.ellipsis,
// maxLines: 1,
// ),
// const SizedBox(height: 4),
// Text(
// transaction['time'],
// style: TextStyle(
// color: Colors.grey[600],
// fontSize: 14,
// fontWeight: FontWeight.w400,
// ),
// overflow: TextOverflow.ellipsis,
// maxLines: 1,
// ),
// ],
// ),
// ),
//
// // Right side - Amount and status
// Column(
// crossAxisAlignment: CrossAxisAlignment.end,
// children: [
// // Amount with different font sizes for whole and decimal parts
// Row(
// mainAxisSize: MainAxisSize.min,
// crossAxisAlignment: CrossAxisAlignment.baseline,
// textBaseline: TextBaseline.alphabetic,
// children: [
// Text(
// '₹',
// style: const TextStyle(
// fontWeight: FontWeight.w600,
// fontSize: 12,
// color: Color(0xFF1A1A1A),
// ),
// ),
// Text(
// wholePart,
// style: const TextStyle(
// fontWeight: FontWeight.w700,
// fontSize: 16,
// color: Color(0xFF1A1A1A),
// letterSpacing: -0.2,
// ),
// ),
// Text(
// '.',
// style: const TextStyle(
// fontWeight: FontWeight.w600,
// fontSize: 13,
// color: Color(0xFF1A1A1A),
// letterSpacing: -0.1,
// ),
// ),
// Text(
// decimalPart,
// style: const TextStyle(
// fontWeight: FontWeight.w600,
// fontSize: 13,
// color: Color(0xFF1A1A1A),
// letterSpacing: -0.1,
// ),
// ),
// ],
// ),
// const SizedBox(height: 4),
// Text(
// statusText,
// style: TextStyle(
// color: statusColor,
// fontSize: 14,
// fontWeight: FontWeight.w600,
// ),
// ),
// ],
// ),
// ],
// ),
// ),
// ),
// );
// }
// @override
// void dispose() {
// _posDebounce?.cancel();
// _qrDebounce?.cancel();
// _scrollController.dispose();
// searchController.dispose();
// qrSearchController.dispose();
// super.dispose();
// }
// void _performPOSSearch() {
// fetchTransactions(txnStatus, txnType, dateRange);
// }
//
// void _performQRSearch() {
// fetchStaticQRTransactions();
// }
//
// Future<void> fetchStaticQRTransactions() async {
// setState(() {
// isLoading = true;
// currentPage = 0;
// transactions.clear();
// hasMoreData = true;
// });
//
// try {
// String fromDate = '0';
// String toDate = '0';
//
// if (qrDateRangeType == 'choose_date' && qrFilterStartDate != null && qrFilterEndDate != null) {
// final startOfDay = DateTime(qrFilterStartDate!.year, qrFilterStartDate!.month, qrFilterStartDate!.day, 0, 0, 0);
// final endOfDay = DateTime(qrFilterEndDate!.year, qrFilterEndDate!.month, qrFilterEndDate!.day, 23, 59, 59);
// fromDate = _dateTimeToUnixTimestamp(startOfDay).toString();
// toDate = _dateTimeToUnixTimestamp(endOfDay).toString();
// } else if (qrDateRangeType == 'this_month') {
// final now = DateTime.now();
// final firstDay = DateTime(now.year, now.month, 1, 0, 0, 0);
// final lastDay = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
// fromDate = _dateTimeToUnixTimestamp(firstDay).toString();
// toDate = _dateTimeToUnixTimestamp(lastDay).toString();
// } else if (qrDateRangeType == 'last_30_days') {
// final now = DateTime.now();
// final thirtyDaysAgo = now.subtract(Duration(days: 29));
// final startOfPeriod = DateTime(thirtyDaysAgo.year, thirtyDaysAgo.month, thirtyDaysAgo.day, 0, 0, 0);
// final endOfPeriod = DateTime(now.year, now.month, now.day, 23, 59, 59);
// fromDate = _dateTimeToUnixTimestamp(startOfPeriod).toString();
// toDate = _dateTimeToUnixTimestamp(endOfPeriod).toString();
// }
//
// final Uri uri = Uri.parse(
// qrDateRangeType != null
// ? 'https://bportal.bijlipay.co.in:9027/txn/getQrTransaction-pageable/1/3'
//     : 'https://bportal.bijlipay.co.in:9027/txn/getQrTransaction-pageable',
// ).replace(queryParameters: {
// if (qrDateRangeType != null) ...{
// 'fromDate': fromDate,
// 'toDate': toDate,
// },
// 'searchTerm': qrSearchController.text.trim(),
// 'vpa': selectedVPA,
// 'page': '1',
// 'sort': 'created_at,desc',
// 'size': '50',
// });
//
// print('Request URL: ${uri.toString()}');
//
// final response = await handleResponse(
// http.get(
// uri,
// headers: {
// 'Authorization': 'Bearer ${widget.authToken}',
// },
// ),
// );
//
// print('Response status code: ${response.statusCode}');
//
// if (response.statusCode == 200) {
// final responseData = jsonDecode(response.body);
// if (responseData['status'] == 'OK') {
// final List<dynamic> content = responseData['data']['content'] ?? [];
// final bool isLastPage = responseData['data']['last'] ?? true;
//
// print('API returned ${content.length} transactions');
//
// List<Map<String, dynamic>> newTransactions = [];
//
// for (var transaction in content) {
// newTransactions.add({
// "cardNumber": transaction['customerVpa'] ?? 'N/A',
// "time": transaction['createdAt'] ?? 'Unknown Time',
// "amount": "₹${transaction['transactionAmount'] ?? '0.0'}",
// "status": _getQRTransactionStatus(
// transaction['purposeCode'],
// transaction['gatewayResponseCode'] ?? 'Unknown'
// ),
// "type": "qr",
// "rrn": transaction['rrn']?.toString() ?? '',
// });
// }
//
// setState(() {
// transactions = newTransactions;
// currentPage = 1;
// hasMoreData = !isLastPage;
// });
// }
// }
// } catch (e) {
// print('Error fetching static QR transactions: $e');
// } finally {
// setState(() => isLoading = false);
// }
// }
// String _getQRTransactionStatus(dynamic txnType, dynamic txnResponseCode) {
// if (txnType == null || txnResponseCode == null) return "Failed";
//
// final type = txnType.toString().trim();
// final response = txnResponseCode.toString().trim();
//
// if (type == "02") return "Void";
// if (response == "00") return "Success";
// return "Failed";
// }
//
//
//
//
// // Add this helper method to format the date consistently
// String _formatDateTime(DateTime dateTime) {
// final day = dateTime.day.toString().padLeft(2, '0');
// final month = _getMonthName(dateTime.month);
// final year = dateTime.year;
// final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
// final minute = dateTime.minute.toString().padLeft(2, '0');
// final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
//
// return "$day $month $year ${hour.toString().padLeft(2, '0')}.$minute $amPm";
// }
//
// // Update loadMoreStaticQRTransactions for pagination
// Future<void> loadMoreStaticQRTransactions({
// required int fromDate,
// required int toDate,
// }) async {
// if (isLoadingMore) return;
//
// setState(() {
// isLoadingMore = true;
// });
//
// try {
// final nextPage = currentPage + 1;
//
// final Uri uri = Uri.parse(
// 'https://bportal.bijlipay.co.in:9027/txn/getQrTransaction-pageable/1/3',
// ).replace(queryParameters: {
// 'searchTerm': qrSearchController.text.trim(),
// 'vpa': selectedVPA,
// 'page': nextPage.toString(),
// 'sort': 'created_at,desc',
// 'size': '50',
// 'fromDate': fromDate.toString(),
// 'toDate': toDate.toString(),
// });
//
// final response = await handleResponse(
// http.get( // GET request
// uri,
// headers: {
// 'Authorization': 'Bearer ${widget.authToken}',
// },
// ),
// );
//
// if (response.statusCode == 200) {
// final responseData = jsonDecode(response.body);
// if (responseData['status'] == 'OK') {
// final List<dynamic> newContent = responseData['data']['content'] ?? [];
// final bool isLastPage = responseData['data']['last'] ?? true;
//
// List<Map<String, dynamic>> newTransactions = [];
//
// for (var transaction in newContent) {
// newTransactions.add({
// "cardNumber": transaction['customerVpa'] ?? 'N/A',
// "time": transaction['createdAt'] ?? 'Unknown Time',
// "amount": "₹${transaction['transactionAmount'] ?? '0.0'}",
// "status": _getQRTransactionStatus(
// transaction['purposeCode'],
// transaction['gatewayResponseCode'] ?? 'Unknown'
// ),
// "type": "qr",
// "rrn": transaction['rrn']?.toString() ?? '',
// });
// }
//
// setState(() {
// transactions.addAll(newTransactions);
// currentPage = nextPage;
// hasMoreData = !isLastPage;
// });
// }
// }
// } catch (e) {
// print('Error loading more QR transactions: $e');
// } finally {
// setState(() {
// isLoadingMore = false;
// });
// }
// }
//
// // Update the tab selection to call appropriate fetch method
// void _onTabChanged(String tab) {
// setState(() {
// selectedTab = tab;
// currentPage = 0; // Reset page when switching tabs
// transactions.clear(); // Clear existing transactions
// if (tab == 'Static QR') {
// fetchStaticQRTransactions();
// } else {
// fetchTransactions(txnStatus, txnType); // Your existing POS transactions fetch
// }
// });
// }
//
// // Update your build method to use the appropriate load more method
// // Widget _buildTransactionsList() {
// //   return NotificationListener<ScrollNotification>(
// //     onNotification: (ScrollNotification scrollInfo) {
// //       if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
// //         if (!isLoadingMore && hasMoreData) {
// //           if (selectedTab == 'Static QR') {
// //             loadMoreStaticQRTransactions();
// //           } else {
// //             loadMoreTransactions(); // Your existing POS load more
// //           }
// //         }
// //       }
// //       return true;
// //     },
// //     child: _buildPOSTransactions(), // Your existing transaction list builder
// //   );
// // }
//
// Widget _buildSearchAndFilterBar() {
// return Padding(
// padding: const EdgeInsets.all(8.0),
// child: Row(
// children: <Widget>[
// Expanded(
// child: TextField(
// decoration: InputDecoration(
// hintText: 'Search transactions',
// prefixIcon: Icon(Icons.search),
// border: OutlineInputBorder(
// borderRadius: BorderRadius.circular(8),
// borderSide: BorderSide(color: Colors.grey[300]!),
// ),
// ),
// ),
// ),
// SizedBox(width: 8),
// ElevatedButton(
// onPressed: () => _showFilterDialog(),
// style: ElevatedButton.styleFrom(
// shape: RoundedRectangleBorder(
// borderRadius: BorderRadius.circular(8),
// ),
// backgroundColor: Colors.purple,
// ),
// child: Row(
// children: <Widget>[
// Icon(Icons.filter_list, color: Colors.white),
// Text('Filter', style: TextStyle(color: Colors.white)),
// ],
// ),
// ),
// ],
// ),
// );
// }
// }
//
// class TransactionFilterDialog extends StatefulWidget {
// final DateTime? initialStartDate;
// final DateTime? initialEndDate;
// final String? initialDateRangeType;
// final bool successSelected;
// final bool failedSelected;
// final bool voidSelected;
// final bool upiSelected;
// final bool cardSelected;
// final Function(DateTime?, DateTime?, int, List<String>, int, String?) onApply;
// final Function onClearAll;
//
// const TransactionFilterDialog({
// super.key,
// this.initialStartDate,
// this.initialEndDate,
// this.initialDateRangeType,
// required this.successSelected,
// required this.failedSelected,
// required this.voidSelected,
// required this.upiSelected,
// required this.cardSelected,
// required this.onApply,
// required this.onClearAll,
// });
//
// @override
// State<TransactionFilterDialog> createState() => _TransactionFilterDialogState();
// }
//
// class _TransactionFilterDialogState extends State<TransactionFilterDialog> {
// late bool successSelected;
// late bool failedSelected;
// late bool voidSelected;
// late bool upiSelected;
// late bool cardSelected;
// String? dateRangeType;
// DateTime? startDate;
// DateTime? endDate;
//
// @override
// void initState() {
// super.initState();
// successSelected = widget.successSelected;
// failedSelected = widget.failedSelected;
// voidSelected = widget.voidSelected;
// upiSelected = widget.upiSelected;
// cardSelected = widget.cardSelected;
// dateRangeType = widget.initialDateRangeType;
// startDate = widget.initialStartDate;
// endDate = widget.initialEndDate;
// }
//
// void _clearAll() {
// setState(() {
// successSelected = false;
// failedSelected = false;
// voidSelected = false;
// upiSelected = false;
// cardSelected = false;
// dateRangeType = null;
// startDate = null;
// endDate = null;
// });
// widget.onClearAll();
// }
//
//
// void _applyFilters() {
// int newTxnStatus = 0;
//
// if (successSelected && !failedSelected) {
// newTxnStatus = 1;
// } else if (!successSelected && failedSelected) {
// newTxnStatus = 2;
// } else if (successSelected && failedSelected) {
// newTxnStatus = 3;
// }
//
// List<String> newTxnType = [];
// if (voidSelected) newTxnType.add("02");
// if (cardSelected) newTxnType.add("00");
// if (upiSelected) newTxnType.addAll(["37", "39", "38", "48"]);
//
// // Convert dateRangeType to API integer
// int dateRange = 0;
// if (dateRangeType == "this_month") {
// dateRange = 3;
// } else if (dateRangeType == "last_30_days") {
// dateRange = 3;
// } else if (dateRangeType == "choose_date") {
// dateRange = 3;
// }
//
// int? fromDateUnix;
// int? toDateUnix;
//
// if (dateRangeType == 'choose_date' && startDate != null && endDate != null) {
// fromDateUnix = startDate!.millisecondsSinceEpoch ~/ 1000;
// toDateUnix = endDate!.millisecondsSinceEpoch ~/ 1000;
// }
//
// print('Filters - Status: $newTxnStatus, Types: $newTxnType, DateRange: $dateRange');
// print('fromDate: $fromDateUnix, toDate: $toDateUnix');
//
// widget.onApply(
// startDate,
// endDate,
// newTxnStatus,
// newTxnType,
// dateRange,
// dateRangeType,
// );
//
// Navigator.of(context).pop(); // Close the dialog
// }
// @override
// Widget build(BuildContext context) {
// return Container(
// width: MediaQuery.of(context).size.width * 0.9,
// padding: EdgeInsets.all(16),
// child: Column(
// mainAxisSize: MainAxisSize.min,
// crossAxisAlignment: CrossAxisAlignment.start,
// children: [
// Row(
// mainAxisAlignment: MainAxisAlignment.spaceBetween,
// children: [
// const Text(
// 'Filters',
// style: TextStyle(
// fontSize: 16,
// fontWeight: FontWeight.bold,
// ),
// ),
// TextButton(
// onPressed: _clearAll,
// child:  Text(
// 'Clear All',
// style: TextStyle(fontSize: 12, color: customPurple),
// ),
// ),
// ],
// ),
// const SizedBox(height: 16),
// const Text(
// 'Transaction Status',
// style: TextStyle(
// fontSize: 14,
// fontWeight: FontWeight.w700,
// ),
// ),
// Row(
// children: [
// _buildCheckbox('Success', successSelected, (val) => setState(() => successSelected = val ?? false)),
// const SizedBox(width: 16),
// _buildCheckbox('Failed', failedSelected, (val) => setState(() => failedSelected = val ?? false)),
// ],
// ),
// const SizedBox(height: 12),
// const Text(
// 'Transaction Type',
// style: TextStyle(
// fontSize: 14,
// fontWeight: FontWeight.w700,
// ),
// ),
// Row(
// children: [
// _buildCheckbox('UPI', upiSelected, (val) => setState(() => upiSelected = val ?? false)),
// const SizedBox(width: 5),
// _buildCheckbox('Card', cardSelected, (val) => setState(() => cardSelected = val ?? false)),
// const SizedBox(width: 5),
// _buildCheckbox('Void', voidSelected, (val) => setState(() => voidSelected = val ?? false)),
// ],
// ),
// const SizedBox(height: 12),
// const Text(
// 'Date Range',
// style: TextStyle(
// fontSize: 14,
// fontWeight: FontWeight.w700,
// ),
// ),
// _buildRadioOption('This Month', 'this_month'),
// _buildRadioOption('Last 30 Days', 'last_30_days'),
// _buildRadioOption('Choose Date', 'choose_date'),
// if (dateRangeType == 'choose_date')
// Padding(
// padding: const EdgeInsets.only(top: 8),
// child: Row(
// children: [
// Expanded(
// child: _buildDateInput(
// 'From Date',
// startDate,
// (date) => setState(() => startDate = date),
// ),
// ),
// const SizedBox(width: 12),
// Expanded(
// child: _buildDateInput(
// 'To Date',
// endDate,
// (date) => setState(() => endDate = date),
// ),
// ),
// ],
// ),
// ),
// const SizedBox(height: 16),
// Row(
// children: [
// Expanded(
// child: OutlinedButton(
// onPressed: () => Navigator.pop(context),
// child:  Text(
// 'CANCEL',
// style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
// ),
// style: OutlinedButton.styleFrom(
// foregroundColor: customPurple,
// side: BorderSide(color: customPurple),
// padding: const EdgeInsets.symmetric(vertical: 8),
// ),
// ),
// ),
// const SizedBox(width: 12),
// Expanded(
// child: ElevatedButton(
// onPressed: _applyFilters,
// child: const Text(
// 'APPLY',
// style: TextStyle(
// fontSize: 12,
// fontWeight: FontWeight.w700,
// color: Colors.white,
// ),
// ),
// style: ElevatedButton.styleFrom(
// backgroundColor: customPurple,
// padding: const EdgeInsets.symmetric(vertical: 8),
// ),
// ),
// ),
// ],
// ),
// ],
// ),
// );
// }
//
// Widget _buildSectionTitle(String text) {
// return Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700));
// }
//
// Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
// return Row(
// mainAxisSize: MainAxisSize.min,
// children: [
// Transform.scale(
// scale: 0.9,
// child: Checkbox(
// value: value,
// onChanged: onChanged,
// activeColor: customPurple,
// shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
// ),
// ),
// Text(label, style: TextStyle(fontSize: 12)),
// ],
// );
// }
//
// Widget _buildRadioOption(String label, String value) {
// return InkWell(
// onTap: () => setState(() => dateRangeType = value),
// child: Row(
// children: [
// Transform.scale(
// scale: 0.9,
// child: Radio<String>(
// value: value,
// groupValue: dateRangeType,
// onChanged: (val) => setState(() => dateRangeType = val),
// activeColor: customPurple,
// ),
// ),
// Text(label, style: TextStyle(fontSize: 12)),
// ],
// ),
// );
// }
//
// Widget _buildDateRangePicker() {
// return Padding(
// padding: const EdgeInsets.only(top: 0),
// child: Row(
// children: [
// Expanded(child: _buildDateInput('From Date', startDate, (date) => setState(() => startDate = date))),
// SizedBox(width: 12),
// Expanded(child: _buildDateInput('To Date', endDate, (date) => setState(() => endDate = date))),
// ],
// ),
// );
// }
//
// Widget _buildDateInput(
// String label,
// DateTime? value,
// Function(DateTime?) onChanged,
// ) {
// return InkWell(
// onTap: () async {
// final DateTime? picked = await showDatePicker(
// context: context,
// initialDate: value ?? DateTime.now(),
// firstDate: DateTime.now().subtract(const Duration(days: 180)),
// lastDate: DateTime.now(),
// );
// if (picked != null) onChanged(picked);
// },
// child: Container(
// padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
// decoration: BoxDecoration(
// border: Border.all(color: Colors.grey.shade300),
// borderRadius: BorderRadius.circular(8),
// ),
// child: Row(
// children: [
// Expanded(
// child: Text(
// value != null
// ? '${value.day}/${value.month}/${value.year}'
//     : label,
// style: TextStyle(
// fontSize: 11,
// color: value != null ? Colors.black : Colors.grey,
// ),
// ),
// ),
// Icon(Icons.calendar_today, size: 16, color: Colors.grey),
// ],
// ),
// ),
// );
// }
// Widget _buildActionButtons() {
// return Row(
// children: [
// Expanded(
// child: OutlinedButton(
// onPressed: () => Navigator.pop(context),
// child: Text('CANCEL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
// style: OutlinedButton.styleFrom(
// foregroundColor: customPurple,
// side: BorderSide(color: customPurple),
// padding: EdgeInsets.symmetric(vertical: 8),
// ),
// ),
// ),
// SizedBox(width: 12),
// Expanded(
// child: ElevatedButton(
// onPressed: () {
// _applyFilters();
// Navigator.pop(context);
// },
// child: Text(
// 'APPLY',
// style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
// ),
// style: ElevatedButton.styleFrom(
// backgroundColor: customPurple,
// padding: EdgeInsets.symmetric(vertical: 8),
// ),
// ),
// ),
// ],
// );
// }
// }
//
// // Add this new dropdown widget at the top of your file, after the imports
// class OverlayDropdown extends StatefulWidget {
// final String? value;
// final List<String> items;
// final Function(String?) onChanged;
// final String? hint;
// final bool showRadio;
//
// const OverlayDropdown({
// Key? key,
// this.value,
// required this.items,
// required this.onChanged,
// this.hint,
// this.showRadio = true,
// }) : super(key: key);
//
// @override
// _OverlayDropdownState createState() => _OverlayDropdownState();
// }
//
// class _OverlayDropdownState extends State<OverlayDropdown> {
// bool _dropdownOpen = false;
// final GlobalKey _dropdownKey = GlobalKey();
// OverlayEntry? _overlayEntry;
// OverlayEntry? _barrierEntry;
//
// @override
// void dispose() {
// _closeDropdown();
// super.dispose();
// }
//
//
//
//
// void _closeDropdown() {
// _barrierEntry?.remove();
// _overlayEntry?.remove();
// _barrierEntry = null;
// _overlayEntry = null;
// if (_dropdownOpen) {
// setState(() {
// _dropdownOpen = false;
// });
// }
// }
//
// void _openDropdown() {
// if (_overlayEntry != null) return;
//
// final RenderBox? renderBox = _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
// if (renderBox == null) return;
//
// final position = renderBox.localToGlobal(Offset.zero);
// final size = renderBox.size;
// final screenHeight = MediaQuery.of(context).size.height;
// final dropdownHeight = (widget.items.length * 48.0) + 16;
// final spaceBelow = screenHeight - (position.dy + size.height + 100);
// final showAbove = spaceBelow < dropdownHeight && position.dy > dropdownHeight;
//
// // Create barrier to detect taps outside
// _barrierEntry = OverlayEntry(
// builder: (context) => GestureDetector(
// onTap: _closeDropdown,
// child: Container(
// width: double.infinity,
// height: double.infinity,
// color: Colors.transparent,
// ),
// ),
// );
//
// _overlayEntry = OverlayEntry(
// builder: (context) => Positioned(
// left: position.dx,
// top: showAbove
// ? position.dy - dropdownHeight - 8
//     : position.dy + size.height + 4,
// width: size.width,
// child: Material(
// elevation: 8,
// borderRadius: BorderRadius.circular(8),
// child: Container(
// constraints: BoxConstraints(
// maxHeight: 200,
// ),
// decoration: BoxDecoration(
// color: Colors.white,
// borderRadius: BorderRadius.circular(8),
// border: Border.all(
// color: Colors.grey.shade300,
// width: 1.0,
// ),
// boxShadow: [
// BoxShadow(
// color: Colors.black.withOpacity(0.15),
// blurRadius: 12,
// offset: const Offset(0, 4),
// ),
// ],
// ),
// child: ClipRRect(
// borderRadius: BorderRadius.circular(8),
// child: SingleChildScrollView(
// child: Column(
// mainAxisSize: MainAxisSize.min,
// children: widget.items.map((item) {
// final isSelected = widget.value == item;
// return InkWell(
// onTap: () {
// widget.onChanged(item);
// _closeDropdown();
// },
// child: Container(
// width: double.infinity,
// padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// child: Row(
// children: [
// // Radio button (only if showRadio is true)
// if (widget.showRadio) ...[
// Container(
// width: 18,
// height: 18,
// decoration: BoxDecoration(
// shape: BoxShape.circle,
// border: Border.all(
// color: isSelected ? customPurple : Colors.grey[400]!,
// width: 2,
// ),
// color: isSelected ? customPurple : Colors.transparent,
// ),
// child: isSelected
// ? Center(
// child: Container(
// width: 6,
// height: 6,
// decoration: const BoxDecoration(
// shape: BoxShape.circle,
// color: Colors.white,
// ),
// ),
// )
//     : null,
// ),
// const SizedBox(width: 12),
// ],
// // Text
// Expanded(
// child: Text(
// item,
// style: TextStyle(
// fontSize: 15,
// fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
// color: isSelected ? customPurple : Colors.black87,
// ),
// overflow: TextOverflow.ellipsis,
// ),
// ),
// ],
// ),
// ),
// );
// }).toList(),
// ),
// ),
// ),
// ),
// ),
// ),
// );
//
// Overlay.of(context)?.insert(_barrierEntry!);
// Overlay.of(context)?.insert(_overlayEntry!);
// }
//
// void _toggleDropdown() {
// if (_dropdownOpen) {
// _closeDropdown();
// } else {
// setState(() {
// _dropdownOpen = true;
// });
// _openDropdown();
// }
// }
//
// @override
// Widget build(BuildContext context) {
// return GestureDetector(
// key: _dropdownKey,
// onTap: _toggleDropdown,
// child: Container(
// padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
// decoration: BoxDecoration(
// color: Colors.white,
// border: Border.all(
// color: _dropdownOpen ? customPurple : Colors.grey.shade300,
// width: _dropdownOpen ? 1.5 : 1.0,
// ),
// borderRadius: BorderRadius.circular(10),
// ),
// child: Row(
// mainAxisAlignment: MainAxisAlignment.spaceBetween,
// children: [
// Expanded(
// child: Text(
// widget.value ?? widget.hint ?? 'Select',
// style: TextStyle(
// fontSize: 15,
// color: widget.value != null ? Colors.black : Colors.grey[600],
// ),
// overflow: TextOverflow.ellipsis,
// ),
// ),
// AnimatedRotation(
// turns: _dropdownOpen ? 0.5 : 0.0,
// duration: const Duration(milliseconds: 300),
// curve: Curves.easeInOutBack,
// child: Icon(
// Icons.keyboard_arrow_down,
// size: 20,
// color: _dropdownOpen ? customPurple : Colors.grey[600],
// ),
// ),
// ],
// ),
// ),
// );
// }
// }
// class QRFilterDialog extends StatefulWidget {
// final DateTime? initialStartDate;
// final DateTime? initialEndDate;
// final String? initialDateRangeType;
// final Function(DateTime?, DateTime?, String?) onApply;
// final Function onClearAll;
//
// const QRFilterDialog({
// super.key,
// this.initialStartDate,
// this.initialEndDate,
// this.initialDateRangeType,
// required this.onApply,
// required this.onClearAll,
// });
//
// @override
// State<QRFilterDialog> createState() => _QRFilterDialogState();
// }
//
// class _QRFilterDialogState extends State<QRFilterDialog> {
// String? dateRangeType;
// DateTime? startDate;
// DateTime? endDate;
//
// @override
// void initState() {
// super.initState();
// dateRangeType = widget.initialDateRangeType;
// startDate = widget.initialStartDate;
// endDate = widget.initialEndDate;
// }
//
// void _clearAll() {
// setState(() {
// dateRangeType = null;
// startDate = null;
// endDate = null;
// });
// widget.onClearAll();
// }
//
// @override
// Widget build(BuildContext context) {
// return Container(
// width: MediaQuery.of(context).size.width * 0.9,
// padding: const EdgeInsets.all(16),
// child: Column(
// mainAxisSize: MainAxisSize.min,
// crossAxisAlignment: CrossAxisAlignment.start,
// children: [
// Row(
// mainAxisAlignment: MainAxisAlignment.spaceBetween,
// children: [
// const Text(
// 'Filters',
// style: TextStyle(
// fontSize: 16,
// fontWeight: FontWeight.bold,
// ),
// ),
// TextButton(
// onPressed: _clearAll,
// child:  Text(
// 'Clear All',
// style: TextStyle(fontSize: 12, color: customPurple),
// ),
// ),
// ],
// ),
// const SizedBox(height: 16),
// const Text(
// 'Date Range',
// style: TextStyle(
// fontSize: 14,
// fontWeight: FontWeight.w700,
// ),
// ),
// const SizedBox(height: 8),
// _buildRadioOption('This Month', 'this_month'),
// _buildRadioOption('Last 30 Days', 'last_30_days'),
// _buildRadioOption('Choose Date', 'choose_date'),
// if (dateRangeType == 'choose_date')
// Padding(
// padding: const EdgeInsets.only(top: 8),
// child: Row(
// children: [
// Expanded(
// child: _buildDateInput(
// 'From Date',
// startDate,
// (date) => setState(() => startDate = date),
// DateTime.now().subtract(const Duration(days: 180)),
// DateTime.now(),
// ),
// ),
// const SizedBox(width: 12),
// Expanded(
// child: _buildDateInput(
// 'To Date',
// endDate,
// (date) => setState(() => endDate = date),
// DateTime.now().subtract(const Duration(days: 180)),
// DateTime.now(),
// ),
// ),
// ],
// ),
// ),
// const SizedBox(height: 16),
// Row(
// children: [
// Expanded(
// child: OutlinedButton(
// onPressed: () => Navigator.pop(context),
// child: const Text(
// 'CANCEL',
// style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
// ),
// style: OutlinedButton.styleFrom(
// foregroundColor: customPurple,
// side: BorderSide(color: customPurple),
// padding: const EdgeInsets.symmetric(vertical: 8),
// ),
// ),
// ),
// const SizedBox(width: 12),
// Expanded(
// child: ElevatedButton(
// onPressed: () {
// widget.onApply(startDate, endDate, dateRangeType);
// Navigator.pop(context);
// },
// child: const Text(
// 'APPLY',
// style: TextStyle(
// fontSize: 12,
// fontWeight: FontWeight.w700,
// color: Colors.white,
// ),
// ),
// style: ElevatedButton.styleFrom(
// backgroundColor: customPurple,
// padding: const EdgeInsets.symmetric(vertical: 8),
// ),
// ),
// ),
// ],
// ),
// ],
// ),
// );
// }
//
// Widget _buildRadioOption(String label, String value) {
// return InkWell(
// onTap: () {
// setState(() => dateRangeType = value);
// },
// child: Padding(
// padding: const EdgeInsets.symmetric(vertical: 4),
// child: Row(
// children: [
// Transform.scale(
// scale: 0.9,
// child: Radio<String>(
// value: value,
// groupValue: dateRangeType,
// onChanged: (String? newValue) {
// setState(() => dateRangeType = newValue);
// },
// activeColor: customPurple,
// ),
// ),
// Text(
// label,
// style: const TextStyle(fontSize: 12),
// ),
// ],
// ),
// ),
// );
// }
//
// Widget _buildDateInput(
// String label,
// DateTime? value,
// Function(DateTime?) onChanged,
// DateTime firstDate,
// DateTime lastDate,
// ) {
// return InkWell(
// onTap: () async {
// final DateTime? picked = await showDatePicker(
// context: context,
// initialDate: value ?? DateTime.now(),
// firstDate: firstDate,
// lastDate: lastDate,
// );
// if (picked != null) {
// onChanged(picked);
// }
// },
// child: Container(
// padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
// decoration: BoxDecoration(
// border: Border.all(color: Colors.grey.shade300),
// borderRadius: BorderRadius.circular(8),
// ),
// child: Row(
// children: [
// Expanded(
// child: Text(
// value != null
// ? '${value.day}/${value.month}/${value.year}'
//     : label,
// style: TextStyle(
// fontSize: 11,
// color: value != null ? Colors.black : Colors.grey,
// ),
// ),
// ),
// Icon(Icons.calendar_today, size: 16, color: Colors.grey),
// ],
// ),
// ),
// );
// }
// }
//
//
//
// its not showing charge slip while tapping static qr trasnactionstype 'Null' is not a subtype of type 'String'