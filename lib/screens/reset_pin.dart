import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:vyappar_application/screens/Initial_login.dart';
import 'login_screen.dart';

class ResetPinScreen extends StatefulWidget {
  final String mobileNumber;
  ResetPinScreen({required this.mobileNumber});

  @override
  _ResetPinScreenState createState() => _ResetPinScreenState();
}

class _ResetPinScreenState extends State<ResetPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _isLoading = false;
  bool _showPin = false;
  String errorMessage = "";

  Future<void> updatePassword() async {
    String pin = _pinController.text;
    String confirmPin = _confirmPinController.text;

    if (pin.length < 4 || confirmPin.length < 4) {
      setState(() => errorMessage = "PIN must be exactly 4 digits.");
      return;
    }
    if (pin != confirmPin) {
      setState(() => errorMessage = "PINs do not match.");
      return;
    }

    setState(() {
      _isLoading = true;
      errorMessage = "";
    });

    const String xToken = 'your_token_here'; // Replace with your actual token

    try {
      final String url = "https://bportal.bijlipay.co.in:9027/auth/update-password";
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "X-DEVICE-TOKEN": xToken,
        },
        body: json.encode({
          "mobileNo": widget.mobileNumber,
          "password": _pinController.text,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == 'OK' || responseBody['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("PIN updated successfully! Redirecting to login..."),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );

          Future.delayed(Duration(milliseconds: 1500), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => InitialLoginScreen()),
            );
          });
        } else {
          setState(() => errorMessage = responseBody['message'] ?? "Failed to update PIN.");
        }
      } else {
        print("Server response: ${response.statusCode} - ${response.body}");
        setState(() => errorMessage = "Server error. Please try again.");
      }
    } catch (e) {
      print("Exception during password update: $e");
      setState(() => errorMessage = "Connection error. Please check your internet connection.");
    }

    setState(() => _isLoading = false);
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
            left: -screenWidth * 0.00001, // Adjust based on screen width
            child: Image.asset(
              'assets/thunder.png', // Ensure this path is correct
              width: screenWidth * 1.01, // Adjust based on screen width
              height: screenHeight * 0.79, // Adjust based on screen height
              fit: BoxFit.cover,
            ),
          ),
          // Foreground content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05 ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.088),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, color: Color(0xFF383838), size: 12),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      "Reset PIN",
                      style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.w500, color: Color(0xFF383838)),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.001),
                Text("Please enter a 4-digit PIN", style: TextStyle(fontSize: screenWidth * 0.035, fontWeight: FontWeight.w500, color: Color(0xFF383838))),
                SizedBox(height: screenHeight * 0.02),

                /// PIN Input Field - COMPACT SIZE
                Container(
                  height: screenHeight * 0.055, // Reduced height
                  child: TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: !_showPin,
                    maxLength: 4, // Restrict input to 4 digits
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // Allow only numbers
                      LengthLimitingTextInputFormatter(4), // Ensure max 4 characters
                    ],
                    style: TextStyle(fontSize: screenWidth * 0.04), // Smaller text
                    decoration: InputDecoration(
                      labelText: "PIN",
                      labelStyle: TextStyle(fontSize: screenWidth * 0.035), // Smaller label
                      counterText: "", // Hide character counter
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8, // Reduced padding
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8), // Smaller radius
                        borderSide: BorderSide(width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFF61116A), width: 1.5),
                      ),
                    ),
                    cursorColor: Color(0xFF61116A),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02), // Reduced spacing

                /// Confirm PIN Input Field - COMPACT SIZE
                Container(
                  height: screenHeight * 0.055, // Reduced height
                  child: TextField(
                    controller: _confirmPinController,
                    keyboardType: TextInputType.number,
                    obscureText: !_showPin,
                    maxLength: 4, // Restrict input to 4 digits
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // Allow only numbers
                      LengthLimitingTextInputFormatter(4), // Ensure max 4 characters
                    ],
                    style: TextStyle(fontSize: screenWidth * 0.04), // Smaller text
                    decoration: InputDecoration(
                      labelText: "Confirm PIN",
                      labelStyle: TextStyle(fontSize: screenWidth * 0.035), // Smaller label
                      counterText: "", // Hide character counter
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8, // Reduced padding
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8), // Smaller radius
                        borderSide: BorderSide(width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFF61116A), width: 1.5),
                      ),
                    ),
                    cursorColor: Color(0xFF61116A),
                  ),
                ),

                SizedBox(height: screenHeight * 0.01), // Reduced spacing

                /// Show PIN Checkbox - COMPACT SIZE
                Row(
                  children: [
                    Transform.scale(
                      scale: 0.8, // Make checkbox smaller
                      child: Checkbox(
                        value: _showPin,
                        onChanged: (value) => setState(() => _showPin = value!),
                        fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                          if (states.contains(MaterialState.selected)) {
                            return Color(0xFF61116A);
                          }
                          return Colors.transparent;
                        }),
                        checkColor: Color(0xFFFFFFFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                    Text(
                      "Show PIN",
                      style: TextStyle(fontSize: screenWidth * 0.035), // Smaller text
                    ),
                  ],
                ),

                /// Error Message
                SizedBox(height: screenHeight * 0.01),
                if (errorMessage.isNotEmpty)
                  Text(errorMessage, style: TextStyle(color: Colors.red, fontSize: screenWidth * 0.035)),

                SizedBox(height: screenHeight * 0.015), // Reduced spacing

                /// Create Button - COMPACT SIZE
                Container(
                  height: screenHeight * 0.045, // Reduced height
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : updatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF61116A),
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
                      "CREATE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w700,
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