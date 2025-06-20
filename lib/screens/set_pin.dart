import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:vyappar_application/screens/Initial_login.dart';
import 'login_screen.dart';

class SetPinScreen extends StatefulWidget {
  final String mobileNumber;
  SetPinScreen({required this.mobileNumber});

  @override
  _SetPinScreenState createState() => _SetPinScreenState(); // Fixed class name
}

class _SetPinScreenState extends State<SetPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _isLoading = false;
  bool _showPin = false;
  String errorMessage = "";

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  // Safe setState that checks if widget is still mounted
  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => InitialLoginScreen()),
      );
    }
  }

  void _showSuccessAndNavigate(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(Duration(milliseconds: 2000), _navigateToLogin);
  }

  void _showUserExistsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("User Already Exists"),
          content: Text("An account with this mobile number already exists. Would you like to login instead?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Login"),
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToLogin();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> createAccount() async {
    String pin = _pinController.text.trim();
    String confirmPin = _confirmPinController.text.trim();

    print("=== CREATE ACCOUNT DEBUG START ===");
    print("Original Mobile Number: '${widget.mobileNumber}'");
    print("PIN: '$pin'");
    print("Confirm PIN: '$confirmPin'");

    // Enhanced validation
    if (pin.isEmpty || confirmPin.isEmpty) {
      _safeSetState(() => errorMessage = "Please enter both PIN fields.");
      print("ERROR: Empty PIN fields");
      return;
    }

    if (pin.length != 4) {
      _safeSetState(() => errorMessage = "PIN must be exactly 4 digits.");
      print("ERROR: PIN length is ${pin.length}, expected 4");
      return;
    }

    if (confirmPin.length != 4) {
      _safeSetState(() => errorMessage = "Confirm PIN must be exactly 4 digits.");
      print("ERROR: Confirm PIN length is ${confirmPin.length}, expected 4");
      return;
    }

    if (pin != confirmPin) {
      _safeSetState(() => errorMessage = "PINs do not match.");
      print("ERROR: PINs don't match");
      return;
    }

    // Validate mobile number format
    String cleanMobileNumber = widget.mobileNumber.replaceAll(RegExp(r'[^\d]'), '');
    print("Cleaned Mobile Number: '$cleanMobileNumber' (Length: ${cleanMobileNumber.length})");

    if (cleanMobileNumber.length != 10) {
      _safeSetState(() => errorMessage = "Invalid mobile number format.");
      print("ERROR: Mobile number length is ${cleanMobileNumber.length}, expected 10");
      return;
    }

    _safeSetState(() {
      _isLoading = true;
      errorMessage = "";
    });

    try {
      final String url = "https://bportal.bijlipay.co.in:9027/auth/signup";
      print("API URL: $url");

      // Enhanced request body with proper formatting
      final Map<String, dynamic> requestBody = {
        "mobileNo": cleanMobileNumber,
        "password": pin,
      };

      print("=== API REQUEST DEBUG ===");
      print("Request URL: $url");
      print("Request Method: POST");
      print("Request Headers: {");
      print("  'Content-Type': 'application/json',");
      print("  'Accept': 'application/json',");
      print("  'x-device-token': 'ePfBz4osTYyItdN-WscIxh:APA91bFim1Mk_ygNN8Re2UO3oj5ROetwujl27fi7Nc-SR8BRjsvs31rLTJusU8IBw5uKK34vatvI9sWheHyrWtIWXrx-fEPH1ZjElwKNlme5i6XAkUwtGSfSp58xISN8zf9vD9EioYgI'");
      print("}");
      print("Request Body (JSON): ${json.encode(requestBody)}");
      print("Request Body (Pretty):");
      requestBody.forEach((key, value) {
        print("  '$key': '$value'");
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          // "Accept": "application/json",
          "x-device-token": "ePfBz4osTYyItdN-WscIxh:APA91bFim1Mk_ygNN8Re2UO3oj5ROetwujl27fi7Nc-SR8BRjsvs31rLTJusU8IBw5uKK34vatvI9sWheHyrWtIWXrx-fEPH1ZjElwKNlme5i6XAkUwtGSfSp58xISN8zf9vD9EioYgI",
        },
        body: json.encode(requestBody),
      ).timeout(Duration(seconds: 30));

      print("=== API RESPONSE DEBUG ===");
      print("Response Status Code: ${response.statusCode}");
      print("Response Status Text: ${response.reasonPhrase}");
      print("Response Headers:");
      response.headers.forEach((key, value) {
        print("  '$key': '$value'");
      });
      print("Response Body (Raw): ${response.body}");
      print("Response Body Length: ${response.body.length}");

      // Try to parse response body
      Map<String, dynamic>? responseBody;
      try {
        responseBody = json.decode(response.body);
        print("Response Body (Parsed JSON):");
        responseBody?.forEach((key, value) {
          print("  '$key': '$value'");
        });
      } catch (jsonError) {
        print("JSON Parse Error: $jsonError");
        print("Response is not valid JSON");
      }

      if (response.statusCode == 200) {
        if (responseBody != null) {
          if (responseBody['status'] == 'OK') {
            if (responseBody['message'] == 'User Already Exists') {
              print("RESULT: User already exists");
              _showUserExistsDialog(); // Show dialog instead of just error message
            } else {
              print("RESULT: Account created successfully");
              _showSuccessAndNavigate("Account created successfully!");
            }
          } else {
            print("RESULT: Registration failed - ${responseBody['message']}");
            _safeSetState(() => errorMessage = responseBody!['message'] ?? "Registration failed. Please try again.");
          }
        } else {
          print("RESULT: Invalid response format");
          _safeSetState(() => errorMessage = "Invalid server response format.");
        }
      } else if (response.statusCode == 400) {
        print("RESULT: 400 Bad Request");
        if (responseBody != null) {
          if (responseBody.containsKey('error') && responseBody['error'] == 'Bad Request') {
            print("ERROR TYPE: Generic Bad Request");
            _safeSetState(() => errorMessage = "Invalid request format. Please check your data.");
          } else if (responseBody.containsKey('message')) {
            print("ERROR TYPE: Specific message - ${responseBody['message']}");
            _safeSetState(() => errorMessage = responseBody!['message']);
          } else {
            print("ERROR TYPE: Unknown 400 error");
            _safeSetState(() => errorMessage = "Bad Request: Please check your input data.");
          }
        } else {
          print("ERROR TYPE: 400 with no parseable body");
          _safeSetState(() => errorMessage = "Bad Request: Invalid request format.");
        }
      } else if (response.statusCode == 409) {
        print("RESULT: 409 Conflict - User already exists");
        _showUserExistsDialog(); // Show dialog for conflict as well
      } else if (response.statusCode >= 500) {
        print("RESULT: Server error (${response.statusCode})");
        _safeSetState(() => errorMessage = "Server error. Please try again later.");
      } else {
        print("RESULT: Unexpected status code (${response.statusCode})");
        _safeSetState(() => errorMessage = "Unexpected error (${response.statusCode}). Please try again.");
      }
    } catch (e) {
      print("=== EXCEPTION DEBUG ===");
      print("Exception Type: ${e.runtimeType}");
      print("Exception Message: $e");
      print("Exception String: ${e.toString()}");

      String userFriendlyMessage;
      if (e.toString().contains('TimeoutException')) {
        print("ERROR TYPE: Timeout");
        userFriendlyMessage = "Request timed out. Please check your internet connection and try again.";
      } else if (e.toString().contains('SocketException')) {
        print("ERROR TYPE: Network/Socket");
        userFriendlyMessage = "Network error. Please check your internet connection and try again.";
      } else if (e.toString().contains('HandshakeException')) {
        print("ERROR TYPE: SSL/TLS");
        userFriendlyMessage = "Secure connection failed. Please try again.";
      } else {
        print("ERROR TYPE: Unknown exception");
        userFriendlyMessage = "Connection error. Please check your internet and try again.";
      }

      _safeSetState(() => errorMessage = userFriendlyMessage);
    }

    print("=== CREATE ACCOUNT DEBUG END ===\n");
    _safeSetState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF4D7F4),
                ],
                stops: [0.0864, 0.6183],
              ),
            ),
          ),
          // Thunder image
          Positioned(
            left: -screenWidth * 0.00001,
            child: Image.asset(
              'assets/thunder.png',
              width: screenWidth * 1.01,
              height: screenHeight * 0.79,
              fit: BoxFit.cover,
            ),
          ),
          // Foreground content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.088),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, color: Color(0xFF383838), size: screenWidth * 0.04),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      "Set PIN",
                      style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.w700, color: Color(0xFF383838)),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.001),
                Text("Please enter a 4-digit PIN", style: TextStyle(fontSize: screenWidth * 0.035, fontWeight: FontWeight.w500, color: Color(0xFF383838))),
                SizedBox(height: screenHeight * 0.02),

                /// PIN Input Field
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: !_showPin,
                  maxLength: 4,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: InputDecoration(
                    labelText: "PIN",
                    counterText: "",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFF61116A), width: 2),
                    ),
                  ),
                  cursorColor: Color(0xFF61116A),
                ),

                SizedBox(height: screenHeight * 0.025),

                /// Confirm PIN Input Field
                TextField(
                  controller: _confirmPinController,
                  keyboardType: TextInputType.number,
                  obscureText: !_showPin,
                  maxLength: 4,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: InputDecoration(
                    labelText: "Confirm PIN",
                    counterText: "",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFF61116A), width: 2),
                    ),
                  ),
                  cursorColor: Color(0xFF61116A),
                ),

                SizedBox(height: screenHeight * 0.001),

                /// Show PIN Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _showPin,
                      onChanged: (value) => _safeSetState(() => _showPin = value!),
                      fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return Color(0xFF61116A);
                        }
                        return Colors.transparent;
                      }),
                      checkColor: Color(0xFFFFFFFF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    Text("Show PIN"),
                  ],
                ),

                /// Error Message
                SizedBox(height: screenHeight * 0.01),
                if (errorMessage.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      errorMessage,
                      style: TextStyle(color: Colors.red.shade700, fontSize: screenWidth * 0.035),
                    ),
                  ),

                SizedBox(height: screenHeight * 0.02),

                /// Create Button
                ElevatedButton(
                  onPressed: _isLoading ? null : createAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF61116A),
                    minimumSize: Size(double.infinity, screenHeight * 0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("CREATE", style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.035, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}