import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import 'package:vyappar_application/screens/forgot_pin_screen.dart';

class PinScreen extends StatefulWidget {
  final String mobileNumber;
  PinScreen({required this.mobileNumber});

  @override
  _PinScreenState createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _showPin = false;
  bool _isLoading = false;
  String errorMessage = "";

  static const String xToken =
      'eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiIxIiwiaWF0IjoxNzQxMjY1MjkyLCJleHAiOjE3NDEyNzI0OTJ9.dc_swQD7uUCgFIlPseHuv7vZpIfljZPO3ihti8U4C5ES1Z385RRFZYRG9yaenY7yh-mOFz03hhce2FG2O8tPMA';

  // Enable login button only when 4-digit PIN is entered
  bool get isButtonEnabled => _pinController.text.length == 4;

  @override
  void initState() {
    super.initState();
    _pinController.addListener(() {
      setState(() {}); // Rebuild to update button state
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _loginWithPin() async {
    if (_pinController.text.length != 4) {
      setState(() => errorMessage = "PIN must be 4 digits");
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        errorMessage = "";
      });

      final response = await http.post(
        Uri.parse('https://bportal.bijlipay.co.in:9027/auth/signin'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'X-DEVICE-TOKEN': xToken,
        },
        body: jsonEncode({
          'mobileNo': widget.mobileNumber,
          'password': _pinController.text,
        }),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw TimeoutException('Connection timed out');
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String authToken = responseData['access_token'];
        log("AuthToken: $authToken");

        final profileData = await _fetchUserProfile(authToken);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login Successful'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(
              merchantName: profileData['merchantName'] ?? '',
              mobileNo: profileData['mobileNo'] ?? '',
              email: profileData['email'] ?? '',
              merchantAddress: profileData['merchantAddress'] ?? '',
              terminalIds: List<String>.from(profileData['terminalIds'] ?? []),
              vpaList: List<String>.from(profileData['vpaList'] ?? []),
              authToken: authToken,
              accountNo: profileData['accountNo'] ?? '',
              bankName: profileData['bankName'] ?? '',
              ifscCode: profileData['ifscCode'] ?? '',
              branch: profileData['branch'] ?? '',
              rrn: profileData['rrn'] ?? '',
            ),
          ),
        );
      } else {
        if (!mounted) return;
        setState(() => errorMessage = "Invalid PIN. Please try again.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid PIN'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on TimeoutException catch (e) {
      if (!mounted) return;
      _showNetworkIssueDialog();
    } catch (e) {
      debugPrint('Login failed: $e');
      if (!mounted) return;
      setState(() => errorMessage = "Failed to connect to server");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to connect to server'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNetworkIssueDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.signal_wifi_off, color: Color(0xFF61116A), size: 48),
              SizedBox(height: 16),
              Text(
                'Connection Failed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF383838),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF757774),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel', style: TextStyle(color: Color(0xFF757774))),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _loginWithPin();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF61116A)),
                      child: Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchUserProfile(String authToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://bportal.bijlipay.co.in:9027/auth/user/profile'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final data = responseData['data'];

        final List<String> terminalIds = List<String>.from(
          data['tidList']?.map((tid) => tid['tid'].toString()) ?? [],
        );

        final List<String> vpaList = List<String>.from(
          data['vpaList']?.map((vpa) => vpa['vpa'].toString()) ?? [],
        );

        return {
          'merchantName': data['merchantName'],
          'terminalIds': terminalIds,
          'vpaList': vpaList,
          'mobileNo': data['mobileNo'],
          'email': data['email'],
          'merchantAddress': data['merchantAddress'],
          'accountNo': data['accountNo'],
          'bankName': data['bankName'],
          'branch': data['branch'],
          'ifscCode': data['ifscCode'],
          'id': data['id'],
        };
      }

      return {
        'merchantName': 'Unknown Merchant',
        'terminalIds': <String>[],
        'vpaList': <String>[],
        'mobileNo': '',
        'email': '',
        'merchantAddress': '',
        'accountNo': '',
        'bankName': '',
        'branch': '',
        'ifscCode': '',
        'id': '',
      };
    } catch (e) {
      debugPrint('Profile fetch failed: $e');
      return {
        'merchantName': 'Unknown Merchant',
        'terminalIds': <String>[],
        'vpaList': <String>[],
        'mobileNo': '',
        'email': '',
        'merchantAddress': '',
        'accountNo': '',
        'bankName': '',
        'branch': '',
        'ifscCode': '',
        'id': '',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Color(0xFFF4D7F4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            left: -screenWidth * 0.00001,
            child: Image.asset(
              'assets/thunder.png',
              width: screenWidth * 1.01,
              height: screenHeight * 0.79,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.08),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, color: Color(0xFF383838), size: 12),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      "PIN",
                      style: TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF383838),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  "Enter your PIN to login",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF383838),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),

                // Compact PIN field
                Container(
                  height: 50,
                  child: TextField(
                    controller: _pinController,
                    obscureText: !_showPin,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    style: TextStyle(fontSize: 16, letterSpacing: 2),
                    decoration: InputDecoration(
                      labelText: "PIN",
                      labelStyle: TextStyle(
                        color: Color(0xFF757774),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      counterText: "",
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPin ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _showPin = !_showPin),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFFDBDAE0), width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFFDBDAE0), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFF61116A), width: 1.5),
                      ),
                    ),
                    cursorColor: Color(0xFF61116A),
                  ),
                ),

                SizedBox(height: 12),

                // Forgot PIN aligned to right
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ForgotPinScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                      minimumSize: Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      "Forgot PIN?",
                      style: TextStyle(
                        color: Color(0xFF61116A),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      errorMessage,
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),

                SizedBox(height: 12),

                // Compact login button
                SizedBox(
                  height: 46,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : (isButtonEnabled ? _loginWithPin : null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isButtonEnabled ? Color(0xFF61116A) : Color(0x6661116A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}