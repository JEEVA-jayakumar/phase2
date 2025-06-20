import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'NotificationScreen.dart';
// Add these imports at the top
import 'package:vyappar_application/main.dart'; // For AppState access
import 'package:provider/provider.dart'; // For state management

Color customPurple = Color(0xFF61116A);

class createTicketScreen extends StatefulWidget {
  final String authToken;
  final List<String> terminalIds;  // Add this
  final List<String> staticQRs;

  const createTicketScreen({super.key, required this.authToken,required this.terminalIds,
    required this.staticQRs,    });

  @override
  State<createTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<createTicketScreen> {
  String? _selectedDeviceType;
  String? _selectedTerminalId;
  String? _selectedStaticQR;
  String _selectedReportType = 'Settlement Report';
  DateTime? _fromDate;
  DateTime? _toDate;
  String _selectedReportFormat = 'PDF';

  final List<String> _deviceTypes = ['POS Terminal', 'Static QR'];
  final List<String> _reportFormats = ['PDF', 'Excel'];
  List<String> _terminalIds = [];
  List<String> _staticQRs = [];
  bool _isGeneratingReport = false;

  @override
  void initState() {
    super.initState();
    _terminalIds = widget.terminalIds;
    _staticQRs = widget.staticQRs;
    if (_terminalIds.isNotEmpty) _selectedTerminalId = _terminalIds[0];
    if (_staticQRs.isNotEmpty) _selectedStaticQR = _staticQRs[0];
  }

  bool _isFormValid() {
    if (_selectedDeviceType == null) return false;
    if (_fromDate == null || _toDate == null) return false;

    if (_selectedDeviceType == 'POS Terminal') {
      if (_terminalIds.isEmpty || _selectedTerminalId == null || _selectedTerminalId!.isEmpty) {
        return false;
      }
    }
    if (_selectedDeviceType == 'Static QR') {
      if (_staticQRs.isEmpty || _selectedStaticQR == null || _selectedStaticQR!.isEmpty) {
        return false;
      }
    }

    return true;
  }

  Widget _buildTerminalIdDropdown() {
    if (_terminalIds.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Terminal ID",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "No Terminal IDs available",
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ],
      );
    }

    return CustomDropdownFieldWithBarrier(
      label: "Terminal ID",
      value: _selectedTerminalId ?? '',
      items: _terminalIds,
      onChanged: (value) {
        setState(() {
          _selectedTerminalId = value;
        });
      },
      backgroundColor: Colors.white,
    );
  }

  Widget _buildStaticQRDropdown() {
    if (_staticQRs.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Static QR",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "No Static QRs available",
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ],
      );
    }

    return CustomDropdownFieldWithBarrier(
      label: "Static QR",
      value: _selectedStaticQR ?? '',
      items: _staticQRs,
      onChanged: (value) {
        setState(() {
          _selectedStaticQR = value;
        });
      },
      backgroundColor: Colors.white,
    );
  }

  void _clearAllFields() {
    setState(() {
      _selectedDeviceType = null;
      _selectedTerminalId = null;
      _selectedStaticQR = null;
      _fromDate = null;
      _toDate = null;
      _selectedReportFormat = 'PDF';
    });
  }

  Future<void> _selectDate(bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: customPurple,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          // Reset toDate if it's before the new fromDate
          if (_toDate != null && _toDate!.isBefore(picked)) {
            _toDate = null;
          }
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Widget _buildDateSelector(String label, DateTime? selectedDate, bool isFromDate) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: 8),
          InkWell(
            onTap: () => _selectDate(isFromDate),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedDate != null
                        ? "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"
                        : "Select Date",
                    style: TextStyle(
                      fontSize: 14,
                      color: selectedDate != null ? Colors.black : Colors.grey[500],
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    color: customPurple,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Generate settlement report API call
  Future<void> _generateReport() async {
    if (!_isFormValid()) return;

    setState(() {
      _isGeneratingReport = true;
    });

    try {
      String deviceType = _selectedDeviceType!;
      String reportFormat = _selectedReportFormat.toLowerCase();
      String fromDate = '${_fromDate!.millisecondsSinceEpoch ~/ 1000}';
      String toDate = '${_toDate!.millisecondsSinceEpoch ~/ 1000}';

      String url = '';
      if (deviceType == 'POS Terminal') {
        url = 'https://bportal.bijlipay.co.in:9027/txn/settlement-report?tid=$_selectedTerminalId&from=$fromDate&to=$toDate&fileType=$reportFormat';
      } else if (deviceType == 'Static QR') {
        url = 'https://bportal.bijlipay.co.in:9027/txn/settlement-report?vpa=$_selectedStaticQR&from=$fromDate&to=$toDate&fileType=$reportFormat';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Settlement report generation initiated successfully!"),
              backgroundColor: Colors.green,
            ),
          );

          // Wait for 2 seconds before navigating to the settlement tab
          await Future.delayed(Duration(seconds: 2));

          // Navigate back to the settlement tab and refresh the data
          Navigator.pop(context, true);
        } else {
          throw Exception(data['message'] ?? 'Failed to generate report');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error generating report: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGeneratingReport = false;
      });
    }
  }
  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isFormValid() && !_isGeneratingReport) ? _generateReport : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: (_isFormValid() && !_isGeneratingReport) ? customPurple : Colors.grey[300],
          foregroundColor: (_isFormValid() && !_isGeneratingReport) ? Colors.white : Colors.grey,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isGeneratingReport
            ? SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Text(
          "Generate Report",
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Important Notes:",
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          _buildFooterPoint("1. Transactions made on Friday, Saturday, Sunday settlement report will be available from Monday 11:00 AM"),
          _buildFooterPoint("2. Settlement report for current day transaction (Monday to Thursday) will be available from tomorrow 11:00 AM"),
          _buildFooterPoint("3. The downloaded reports will be available in Menu Home → My Report → Settlement Tab"),
        ],
      ),
    );
  }

  Widget _buildFooterPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 12,
          color: Colors.grey[700],
          height: 1.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(56.0),
      child: Container(
        decoration: BoxDecoration(
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
                    builder: (context) =>
                        NotificationScreen(authToken: widget.authToken),
                  ),
                );
              },
            )
          ],
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 13,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: Text(
              "Generate Settlement Report",
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w500,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(),
                SizedBox(height: 20),
                CustomDropdownFieldWithBarrier(
                  label: "Device Type",
                  value: _selectedDeviceType ?? '',
                  items: _deviceTypes,
                  onChanged: (value) {
                    setState(() {
                      _selectedDeviceType = value;
                      _selectedTerminalId = null;
                      _selectedStaticQR = null;
                    });
                  },
                  backgroundColor: Colors.white,
                ),

                if (_selectedDeviceType != null) ...[
                  SizedBox(height: 20),
                  if (_selectedDeviceType == 'POS Terminal')
                    _buildTerminalIdDropdown(),

                  if (_selectedDeviceType == 'Static QR')
                    _buildStaticQRDropdown(),

                  SizedBox(height: 20),
                  // Report Type Field (Read-only)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Report Type",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[50],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedReportType,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            Icon(
                              Icons.lock,
                              color: Colors.grey[400],
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),
                  // Date Selection Row
                  Row(
                    children: [
                      _buildDateSelector("From Date", _fromDate, true),
                      SizedBox(width: 12),
                      _buildDateSelector("To Date", _toDate, false),
                    ],
                  ),

                  SizedBox(height: 20),
                  CustomDropdownFieldWithBarrier(
                    label: "Report Format",
                    value: _selectedReportFormat,
                    items: _reportFormats,
                    onChanged: (value) {
                      setState(() {
                        _selectedReportFormat = value!;
                      });
                    },
                    backgroundColor: Colors.white,
                  ),

                  SizedBox(height: 24),
                  _buildGenerateButton(),

                  _buildFooter(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Settlement Report",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        TextButton(
          onPressed: _clearAllFields,
          child: Text(
            "Clear All",
            style: TextStyle(
              color: customPurple,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// Enhanced CustomDropdownFieldWithBarrier widget with radio button styling
class CustomDropdownFieldWithBarrier extends StatefulWidget {
  final String label;
  final String value;
  final List<String> items;
  final Function(String?) onChanged;
  final Color backgroundColor;

  const CustomDropdownFieldWithBarrier({
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  State<CustomDropdownFieldWithBarrier> createState() => _CustomDropdownFieldWithBarrierState();
}

class _CustomDropdownFieldWithBarrierState extends State<CustomDropdownFieldWithBarrier>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    setState(() {
      _isOpen = !_isOpen;
    });
    if (_isOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color customPurple = Color(0xFF61116A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
            fontFamily: 'Montserrat',
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _isOpen ? customPurple : Colors.grey[300]!,
              width: _isOpen ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: widget.backgroundColor,
            boxShadow: _isOpen ? [
              BoxShadow(
                color: customPurple.withOpacity(0.15),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ] : null,
          ),
          child: Column(
            children: [
              InkWell(
                onTap: _toggleDropdown,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.value.isEmpty ? "Select ${widget.label}" : widget.value,
                          style: TextStyle(
                            color: widget.value.isEmpty ? Colors.grey[500] : Colors.black,
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            fontWeight: widget.value.isEmpty ? FontWeight.normal : FontWeight.w500,
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _animation.value * 3.14159,
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: _isOpen ? customPurple : Colors.grey[600],
                              size: 22,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: _animation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          children: widget.items.map((String item) {
                            bool isSelected = widget.value == item;
                            return InkWell(
                              onTap: () {
                                widget.onChanged(item);
                                _toggleDropdown();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isSelected ? customPurple.withOpacity(0.08) : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[100]!,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Custom radio button indicator
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? customPurple : Colors.grey[400]!,
                                          width: 2,
                                        ),
                                        color: Colors.white,
                                      ),
                                      child: isSelected
                                          ? Container(
                                        margin: EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: customPurple,
                                        ),
                                      )
                                          : null,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 14,
                                          color: isSelected ? customPurple : Colors.black87,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
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
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}