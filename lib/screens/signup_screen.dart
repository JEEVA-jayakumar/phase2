import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'signup_otp_verification_screen.dart';
import 'login_screen.dart';
import 'Initial_login.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _mobileController = TextEditingController();
  bool isButtonEnabled = false;
  bool isLoading = false;

  Future<void> _sendOtp() async {
    if (!isButtonEnabled || isLoading) return;
    setState(() => isLoading = true);

    final String url = "https://bportal.bijlipay.co.in:9027/auth/otp/signup/send-otp?mblNo=${_mobileController.text}";
    print("Sending OTP request to: $url");

    try {
      final response = await http.get(Uri.parse(url));
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['status'] == 'OK') {
          print("OTP Sent Successfully");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SignupOtpVerificationScreen(mobileNumber: _mobileController.text),
            ),
          );
        } else if (responseData['status'] == 'CONFLICT') {
          _showUserExistsDialog();
        } else {
          _showErrorDialog();
        }
      } else {
        _showErrorDialog();
      }
    } catch (e) {
      _showSnackBar("Network error. Please try again.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showUserExistsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Row(
          children: [
            Icon(Icons.info, color: Color(0xFF61116A)),
            SizedBox(width: 15),
            Text("User Already Exists", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Color(0xFF383838), fontFamily: 'Montserrat')),
          ],
        ),
        content: Text("User already registered, please try to login.", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF383838), fontFamily: 'Montserrat')),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Color(0xFF61116A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const InitialLoginScreen()),
              );
            },
            child: Text("LOGIN", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white, fontFamily: 'Montserrat')),
          )
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Row(
          children: [
            Icon(Icons.cancel, color: Color(0xFFCC0000)),
            SizedBox(width: 15),
            Text("Invalid Number", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Color(0xFF383838), fontFamily: 'Montserrat')),
          ],
        ),
        content: Text("Mobile number entered is incorrect. Please contact Bijlipay customer service", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF383838), fontFamily: 'Montserrat')),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Color(0xFF61116A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white, fontFamily: 'Montserrat')),
          )
        ],
      ),
    );
  }

  void _checkMobileNumber(String value) {
    setState(() {
      isButtonEnabled = value.length == 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    return Scaffold(
      body: Stack(
        children: [
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
          Positioned(
            left: -screenWidth * 0.00001,
            child: Image.asset(
              'assets/thunder.png',
              width: screenWidth * 1.01,
              height: screenHeight * 0.79,
              fit: BoxFit.cover,
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: size.height * 0.13),
                  Image.asset(
                    'assets/bijli_logo.png',
                    width: size.width * 0.45,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: size.height * 0.03),
                  Text("Sign Up", style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.w700, color: Color(0xFF383838), fontFamily: 'Montserrat')),
                  SizedBox(height: screenHeight * 0.01),
                  Text("Enter your number", style: TextStyle(fontSize: screenWidth * 0.03, fontWeight: FontWeight.w500, color: Color(0xFF383838), fontFamily: 'Montserrat')),
                  SizedBox(height: screenHeight * 0.02),
                  TextField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onChanged: _checkMobileNumber,
                    style: TextStyle(
                      fontSize: screenWidth * 0.03,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF383838),
                      fontFamily: 'Montserrat',
                    ),
                    decoration: InputDecoration(
                      labelText: "Mobile Number",
                      labelStyle: TextStyle(
                        color: Color(0xFF757774),
                        fontFamily: 'Montserrat',
                        fontSize: screenWidth * 0.03,
                        fontWeight: FontWeight.w700,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Color(0xFFDBDAE0), width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Color(0xFFDBDAE0), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Color(0xFFDBDAE0), width: 1),
                      ),
                      floatingLabelStyle: TextStyle(
                        color: Color(0xFF757774),
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    cursorColor: Color(0xFF61116A),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    child: ElevatedButton(
                      onPressed: isButtonEnabled && !isLoading ? _sendOtp : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isButtonEnabled ? Color(0xFF61116A) : Color(0x6661116A),
                        minimumSize: Size(double.infinity, screenHeight * 0.05),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text("GET OTP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const InitialLoginScreen()),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Already having an account? ",
                          style: TextStyle(color: Color(0xFF383838), fontFamily: 'Montserrat', fontSize: screenWidth * 0.03),
                          children: [
                            TextSpan(
                              text: "Login",
                              style: TextStyle(
                                color: Color(0xFF61116A),
                                fontSize: screenWidth * 0.03,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Montserrat',
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}