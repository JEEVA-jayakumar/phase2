import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'reset_pin.dart';
import 'package:flutter/services.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String mobileNumber;

  OTPVerificationScreen({required this.mobileNumber});

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool isVerifying = false;
  bool isResending = false;
  String errorMessage = "";
  int countdown = 30;

  Future<void> verifyOTP() async {
    if (_otpController.text.length < 6) {
      setState(() {
        errorMessage = "Please enter a valid 6-digit OTP.";
      });
      return;
    }

    setState(() {
      isVerifying = true;
      errorMessage = "";
    });

    final String url =
        "https://bportal.bijlipay.co.in:9027/auth/otp/verify-otp/${widget.mobileNumber}/${_otpController.text}";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      print("OTP Verification Response: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);

        if (responseBody['status'].toString().toUpperCase() == 'OK') {
          Future.delayed(Duration(milliseconds: 500), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ResetPinScreen(mobileNumber: widget.mobileNumber),
              ),
            );
          });
        } else {
          setState(() {
            errorMessage = responseBody['message'] ?? "Invalid OTP. Please try again.";
          });

          // Clear OTP field and refresh after 1 second
          Future.delayed(Duration(seconds: 1), () {
            setState(() {
              _otpController.clear();
              errorMessage = "";
            });
          });
        }
      } else {
        setState(() {
          errorMessage = "Invalid OTP. Please try again.";
        });

        // Clear OTP field and refresh after 1 second
        Future.delayed(Duration(seconds: 1), () {
          setState(() {
            _otpController.clear();
            errorMessage = "";
          });
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Network error: $e";
      });

      // Clear OTP field and refresh after 1 second
      Future.delayed(Duration(seconds: 1), () {
        setState(() {
          _otpController.clear();
          errorMessage = "";
        });
      });
    } finally {
      setState(() {
        isVerifying = false;
      });
    }
  }

  Future<void> resendOTP() async {
    if (isResending || countdown > 0) return;

    setState(() {
      isResending = true;
      errorMessage = "";
    });

    final String resendUrl =
        "https://bportal.bijlipay.co.in:9027/auth/otp/password-reset/send-otp?mblNo=${widget.mobileNumber}";

    try {
      final response = await http.get(Uri.parse(resendUrl));

      print("Resend OTP Response: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == 'OK') {
          // Clear the OTP input field
          _otpController.clear();

          setState(() {
            countdown = 30; // Restart the timer
            isResending = false;
          });
          startCountdown();

          // Show quick-disappearing toast message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("OTP has been resent successfully!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2), // Auto-dismiss after 2 seconds
            ),
          );

        } else {
          setState(() {
            errorMessage = responseBody['message'] ?? "Failed to resend OTP.";
            isResending = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Server error: ${response.statusCode}. Please try again.";
          isResending = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Network error: $e";
        isResending = false;
      });
    }
  }

  void startCountdown() {
    Future.delayed(Duration(seconds: 1), () {
      if (countdown > 0) {
        setState(() {
          countdown--;
        });
        startCountdown();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
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
                colors: [Color(0xFFFFFFFF), Color(0xFFF4D7F4)],
                stops: [0.0864, 0.6183],
              ),
            ),
          ),
          // Thunder image
          Positioned(
            left: -screenWidth * 0.00001,
            child: Image.asset(
              'assets/thunder.png', // Ensure this path is correct
              width: screenWidth * 1.01,
              height: screenHeight * 0.79,
              fit: BoxFit.cover,
            ),
          ),
          // Foreground content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: size.height * 0.07),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios_new, color: Color(0xFF383838), size: 12),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Text(
                            "Verify OTP",
                            style: TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Montserrat',
                              color: Color(0xFF383838),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.001),
                      Text(
                        "Please enter the verification code",
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Montserrat',
                          color: Color(0xFF383838),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      // OTP Input Fields - REDUCED SIZE
                      PinCodeTextField(
                        appContext: context,
                        length: 6,
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        obscureText: false,
                        textStyle: TextStyle(fontSize: screenWidth * 0.035, fontWeight: FontWeight.bold),
                        animationType: AnimationType.fade,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(6),
                          fieldHeight: screenHeight * 0.045, // Reduced from 0.06
                          fieldWidth: screenWidth * 0.09,   // Reduced from 0.12
                          activeFillColor: Colors.transparent,
                          inactiveFillColor: Colors.transparent,
                          selectedFillColor: Colors.transparent,
                          inactiveColor: Colors.grey,
                          activeColor: Color(0xFF61116A),
                          selectedColor: Color(0xFF61116A),
                        ),
                        cursorColor: Color(0xFF61116A),
                        animationDuration: Duration(milliseconds: 300),
                        enableActiveFill: true,
                        onChanged: (value) {
                          setState(() {
                            errorMessage = "";
                          });
                        },
                        onCompleted: (value) {
                          if (value.length == 6 && !isVerifying) {
                            verifyOTP();
                          }
                        },
                      ),
                      // SizedBox(height: screenHeight * 0.01),
                      // Resend OTP Text
                      GestureDetector(
                        onTap: resendOTP,
                        child: Text(
                          countdown > 0
                              ? "Resend code in $countdown sec"
                              : "Resend OTP",
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: countdown > 0 ? Colors.grey : Color(0xFF61116A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      if (errorMessage.isNotEmpty)
                        Text(
                          errorMessage,
                          style: TextStyle(color: Colors.red, fontSize: screenWidth * 0.035),
                        ),
                      SizedBox(height: screenHeight * 0.01),
                      // Verify Button
                      ElevatedButton(
                        onPressed: isVerifying ? null : verifyOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF61116A),
                          minimumSize: Size(double.infinity, screenHeight * 0.05),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: isVerifying
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                          "VERIFY",
                          style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.035, fontWeight: FontWeight.w700),
                        ),
                      ),
                      // Logo
                    ],
                  ),
                ),
              ],
            ),
          )

        ],
      ),
    );
  }
}