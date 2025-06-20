import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'signup_otp_verification_screen.dart';
import 'login_screen.dart';
import 'pin.dart';
import 'package:vyappar_application/screens/signup_screen.dart' as signup;

class InitialLoginScreen extends StatefulWidget {
  const InitialLoginScreen({Key? key}) : super(key: key);

  @override
  _InitialLoginScreenState createState() => _InitialLoginScreenState();
}

class _InitialLoginScreenState extends State<InitialLoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  bool isButtonEnabled = false;
  bool isLoading = false;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _verifyUser() async {
    if (!isButtonEnabled || isLoading) return;

    print("Calling verifyUser API...");
    setState(() => isLoading = true);

    const String url = "https://bportal.bijlipay.co.in:9027/auth/verify-user";
    final Map<String, String> headers = {"Content-Type": "application/json"};
    final Map<String, String> body = {"mobileNo": _mobileController.text};

    print("Request Body: $body");
    print("Headers: $headers");
    print("URL: $url");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (!mounted) return;

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'OK') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PinScreen(mobileNumber: _mobileController.text),
          ),
        );
      } else {
        _showErrorDialog();
      }
    } catch (e) {
      print("API Exception: $e");
      if (!mounted) return;
      _showSnackBar("Something went wrong. Please try again.");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.all(20),
        title: Row(
          children: [
            const Icon(Icons.cancel, color: Color(0xFFCC0000), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: const Text(
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
        content: const Text(
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
                backgroundColor: const Color(0xFF61116A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "OK",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _checkMobileNumber(String value) {
    // Remove any non-digit characters
    value = value.replaceAll(RegExp(r'[^0-9]'), '');

    setState(() {
      isButtonEnabled = value.length == 10;
      print("Button enabled: $isButtonEnabled");
    });
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
            decoration: const BoxDecoration(
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

          // Background image
          Positioned(
            left: -screenWidth * 0.00001,
            child: Image.asset(
              'assets/thunder.png',
              width: screenWidth * 1.01,
              height: screenHeight * 0.79,
              fit: BoxFit.cover,
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.12),

                    // Compact logo
                    Image.asset(
                      'assets/bijli_logo.png',
                      width: screenWidth * 0.38,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 16),

                    // Welcome text
                    Text(
                      "Welcome to Bijlipay's",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF383838),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    Text(
                      "merchant app",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF383838),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    SizedBox(height: 6),

                    // Subtitle
                    Text(
                      "Enter your number to get started",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF383838),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Compact mobile number input
                    Container(
                      height: 50,
                      child: TextField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        onChanged: _checkMobileNumber,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF383838),
                          fontFamily: 'Montserrat',
                        ),
                        decoration: InputDecoration(
                          labelText: "Mobile Number",
                          labelStyle: TextStyle(
                            color: const Color(0xFF757774),
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFDBDAE0),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFDBDAE0),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF61116A),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        cursorColor: const Color(0xFF61116A),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Compact continue button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: isButtonEnabled && !isLoading ? _verifyUser : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isButtonEnabled
                              ? const Color(0xFF61116A)
                              : const Color(0x6661116A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: isLoading
                            ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                            : Text(
                          "CONTINUE",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),

                    // Sign up link
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => signup.SignUpScreen(),
                            ),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have login? ",
                            style: TextStyle(
                              color: const Color(0xFF383838),
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(
                                text: "Sign Up",
                                style: TextStyle(
                                  color: const Color(0xFF61116A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}