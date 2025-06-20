import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'otp_verification_screen.dart';

class ForgotPinScreen extends StatefulWidget {
  @override
  _ForgotPinScreenState createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final TextEditingController _controller = TextEditingController();
  bool isButtonEnabled = false;
  bool isLoading = false;

  void _onTextChanged(String value) {
    setState(() => isButtonEnabled = value.length == 10);
  }

  Future<void> _sendOtp() async {
    if (!isButtonEnabled || isLoading) return;
    setState(() => isLoading = true);

    final String url = "https://bportal.bijlipay.co.in:9027/auth/otp/password-reset/send-otp?mblNo=${_controller.text}";
    print("Sending OTP request to: $url");

    try {
      final response = await http.get(Uri.parse(url));
      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'OK') {
        print("OTP Sent Successfully");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OTPVerificationScreen(mobileNumber: _controller.text)),
        );
      } else {
        _showErrorDialog();
      }
    } catch (e) {
      _showSnackBar("Network error. Please try again.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.all(20),
        title: Row(
          children: [
            Icon(Icons.cancel, color: Color(0xFFCC0000), size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Invalid Number",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF383838),
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ],
        ),
        content: Text(
          "Mobile number entered is incorrect. Please contact Bijlipay customer service",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Color(0xFF383838),
            fontFamily: 'Montserrat',
          ),
        ),
        actions: [
          SizedBox(
            height: 36,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFF61116A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                "OK",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

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
                colors: [Color(0xFFFFFFFF), Color(0xFFF4D7F4)],
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
          // Compact content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.08),

                // Header
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_sharp, color: Color(0xFF383838), size: 12),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      "Forgot PIN",
                      style: TextStyle(
                        color: Color(0xFF383838),
                        fontSize: 17.5,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                // Subtitle
                Text(
                  "Please enter your number and we will send your OTP",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF383838),
                    fontFamily: 'Montserrat',
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // Compact mobile number field
                Container(
                  height: 50,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onChanged: _onTextChanged,
                    style: TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: "Mobile Number",
                      labelStyle: TextStyle(
                        color: Color(0xFF757774),
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

                SizedBox(height: 24),

                // Compact GET OTP button
                SizedBox(
                  height: 46,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isButtonEnabled && !isLoading ? _sendOtp : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isButtonEnabled ? Color(0xFF61116A) : Color(0x6661116A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                    child: isLoading
                        ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      "GET OTP",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
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