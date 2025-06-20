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
class AppState {
  static final instance = AppState._internal();
  List<dynamic>? tidList;
  List<dynamic>? vpaList;

  AppState._internal();
}

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
  String? _selectedIssueType;
  final TextEditingController _descriptionController = TextEditingController();
  List<File> _attachedFiles = [];

  final List<String> _deviceTypes = ['POS Terminal', 'Static QR'];
  List<String> _terminalIds = [];
  List<String> _staticQRs = [];
  List<String> _issueTypes = [];
  bool _isLoadingIssues = false;
  String? _issueLoadError;
  bool _isCreatingTicket = false;

  @override
  void initState() {
    super.initState();
    _terminalIds = widget.terminalIds;
    _staticQRs = widget.staticQRs;
    if (_terminalIds.isNotEmpty) _selectedTerminalId = _terminalIds[0];
    if (_staticQRs.isNotEmpty) _selectedStaticQR = _staticQRs[0];

    // // Initialize with data from AppState
    // try {
    //   final appState = AppState.instance;
    //   _terminalIds = appState.terminalIds ?? [];
    //   _staticQRs = appState.vpaList ?? [];
    // } catch (e) {
    //   print('Error initializing AppState data: $e');
    //   _terminalIds = [];
    //   _staticQRs = [];
    // }

    // Fetch issue types
    _fetchIssueTypes();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // Fetch issue types from API
  Future<void> _fetchIssueTypes() async {
    setState(() {
      _isLoadingIssues = true;
      _issueLoadError = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://bportal.bijlipay.co.in:9027/txn/tickets/get-issue-list'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['data'] != null) {
          setState(() {
            _issueTypes = (data['data'] as List)
                .map<String>((issue) => issue['description']?.toString() ?? '')
                .where((desc) => desc.isNotEmpty)
                .toList();
          });
        } else {
          setState(() {
            _issueLoadError = data['message'] ?? 'Failed to load issues';
          });
        }
      } else {
        setState(() {
          _issueLoadError = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _issueLoadError = 'Network error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoadingIssues = false;
      });
    }
  }

  bool _isFormValid() {
    if (_selectedDeviceType == null) return false;
    if (_selectedIssueType == null) return false;
    if (_descriptionController.text.trim().isEmpty) return false;

    if (_selectedDeviceType == 'POS Terminal') {
      // Check if terminalIds list is empty or no selection made
      if (_terminalIds.isEmpty) {
        return false; // No terminal IDs available
      }
      if (_selectedTerminalId == null || _selectedTerminalId!.isEmpty) {
        return false; // No terminal ID selected
      }
    }
    if (_selectedDeviceType == 'Static QR') {
      // Check if staticQRs list is empty or no selection made
      if (_staticQRs.isEmpty) {
        return false; // No static QRs available
      }
      if (_selectedStaticQR == null || _selectedStaticQR!.isEmpty) {
        return false; // No static QR selected
      }
    }

    return true;
  }

// Add these helper methods to show proper messages when lists are empty:
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
      _selectedIssueType = null;
      _descriptionController.clear();
      _attachedFiles.clear();
    });
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          _attachedFiles.addAll(result.paths
              .where((path) => path != null)
              .map((path) => File(path!)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking files: ${e.toString()}')),
      );
    }
  }

  void _removeFile(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
  }

  // Create ticket API call
  Future<void> _createTicket() async {
    if (!_isFormValid()) return;

    setState(() => _isCreatingTicket = true);

    try {
      // Get MID from first terminal (fallback to empty string)
      final appState = AppState.instance;
      String mid = "";
      if (appState.tidList != null && appState.tidList!.isNotEmpty) {
        mid = appState.tidList![0]['mid'] ?? "";
      }

      // Prepare JSON payload
      final payload = json.encode({
        "mid": mid,
        "ticketDetails": _descriptionController.text.trim(),
        "ticketTitle": _selectedIssueType,
        "tid": _selectedDeviceType == 'POS Terminal' ? _selectedTerminalId : null,
        "vpa": _selectedDeviceType == 'Static QR' ? _selectedStaticQR : null,
      });

      // Build URL based on device type
      String url;
      if (_selectedDeviceType == 'POS Terminal') {
        url = 'https://bportal.bijlipay.co.in:9027/txn/tickets/create-ticket?tid=${Uri.encodeComponent(_selectedTerminalId!)}';
      } else {
        url = 'https://bportal.bijlipay.co.in:9027/txn/tickets/create-ticket?vpa=${Uri.encodeComponent(_selectedStaticQR!)}';
      }

      // Create multipart request
      var request = http.MultipartRequest('PUT', Uri.parse(url));

      // Add headers
      request.headers['Authorization'] = 'Bearer ${widget.authToken}';
      request.headers['Accept'] = '*/*';

      // Add JSON payload
      request.fields['request'] = payload;

      // Add image file if attached
      if (_attachedFiles.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'imageFile',
          _attachedFiles.first.path,
          filename: _attachedFiles.first.path.split('/').last,
        ));
      }

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);
      print('API Response: $jsonResponse');
      if (response.statusCode == 200 && jsonResponse['status'] == 'OK') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ticket created successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Navigate back to support screen
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to create ticket');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error creating ticket: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isCreatingTicket = false);
    }
  }

  // Build issue type dropdown with loading/error states
  Widget _buildIssueTypeDropdown() {
    if (_isLoadingIssues) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: CircularProgressIndicator(
            color: customPurple,
          ),
        ),
      );
    }

    if (_issueLoadError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Type of Issues",
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
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  _issueLoadError!,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _fetchIssueTypes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: customPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return CustomDropdownFieldWithBarrier(
      label: "Type of Issues",
      value: _selectedIssueType ?? '',
      items: _issueTypes,
      onChanged: (value) {
        setState(() {
          _selectedIssueType = value;
        });
      },
      backgroundColor: Colors.white,
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Please Describe the Issue",
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
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Describe your issue in detail...",
              hintStyle: TextStyle(
                color: Colors.grey,
                fontFamily: 'Montserrat',
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: _pickFiles,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: customPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: customPurple),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 16,
                      color: customPurple,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Attach Files",
                      style: TextStyle(
                        color: customPurple,
                        fontSize: 12,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_attachedFiles.isNotEmpty) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Attached Files:",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    fontFamily: 'Montserrat',
                  ),
                ),
                SizedBox(height: 4),
                ...(_attachedFiles.asMap().entries.map((entry) {
                  int index = entry.key;
                  File file = entry.value;
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          file.path.split('/').last,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeFile(index),
                        icon: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.red,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                      ),
                    ],
                  );
                }).toList()),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isCreatingTicket ? null : () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Cancel",
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: (_isFormValid() && !_isCreatingTicket) ? _createTicket : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: (_isFormValid() && !_isCreatingTicket) ? customPurple : Colors.grey[300],
              foregroundColor: (_isFormValid() && !_isCreatingTicket) ? Colors.white : Colors.grey,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isCreatingTicket
                ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Text(
              "Create",
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
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
              "Support Center",
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
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
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
                mainAxisSize: MainAxisSize.min,
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
                        _selectedIssueType = null;
                        _descriptionController.clear();
                        _attachedFiles.clear();
                      });
                    },
                    backgroundColor: Colors.white,
                  ),

                  if (_selectedDeviceType != null) ...[
                    SizedBox(height: 20),
                    if (_selectedDeviceType == 'POS Terminal')
                      CustomDropdownFieldWithBarrier(
                        label: "Terminal ID",
                        value: _selectedTerminalId ?? '',
                        items: _terminalIds,
                        onChanged: (value) {
                          setState(() {
                            _selectedTerminalId = value;
                          });
                        },
                        backgroundColor: Colors.white,
                      ),

                    if (_selectedDeviceType == 'Static QR')
                      CustomDropdownFieldWithBarrier(
                        label: "Static QR",
                        value: _selectedStaticQR ?? '',
                        items: _staticQRs,
                        onChanged: (value) {
                          setState(() {
                            _selectedStaticQR = value;
                          });
                        },
                        backgroundColor: Colors.white,
                      ),

                    SizedBox(height: 20),
                    _buildIssueTypeDropdown(),

                    SizedBox(height: 20),
                    _buildDescriptionField(),

                    SizedBox(height: 24),
                    _buildActionButtons(),
                  ],
                ],
              ),
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
          "Report an Issue",
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

class _CustomDropdownFieldWithBarrierState extends State<CustomDropdownFieldWithBarrier> {
  bool _isOpen = false;

  void _toggleDropdown() {
    setState(() {
      _isOpen = !_isOpen;
    });
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
                          overflow: TextOverflow.ellipsis, // Add this
                          maxLines: 1, // Add this
                        )
                      ),
                      Icon(
                        _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: _isOpen ? customPurple : Colors.grey[600],
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isOpen)
                Container(
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
                              Expanded( // Add this
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 14,
                                    color: isSelected ? customPurple : Colors.black87,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2, // Change this to 2 to allow 2 lines of text
                                ),
                              ),
                            ],
                          ),
                        )
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}