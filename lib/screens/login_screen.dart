import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:vyappar_application/screens/Initial_login.dart';
import '../main.dart';
import 'package:vyappar_application/screens/forgot_pin_screen.dart';
import 'package:vyappar_application/screens/signup_screen.dart' as signup;
import 'package:vyappar_application/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Static storage class to handle data persistence
class AppStorage {
  static const String _mobileKey = 'last_mobile';
  static const String _merchantKey = 'merchant_name';
  static const String _authTokenKey = 'auth_token';

  static Future<void> saveMobileNumber(String mobileNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mobileKey, mobileNumber);
  }

  static Future<String?> getLastMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mobileKey);
  }

  static Future<void> saveMerchantName(String merchantName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_merchantKey, merchantName);
  }

  static Future<String?> getMerchantName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_merchantKey);
  }

  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mobileKey);
    await prefs.remove(_merchantKey);
    await prefs.remove(_authTokenKey);
  }
}


// // Save mobile number to memory and file
  // static Future<void> saveMobileNumber(String mobileNumber) async {
  //   _lastMobileNumber = mobileNumber;
  //   await _saveToFile();
  // }
  //
  // // Get mobile number from memory
  // static String? getLastMobileNumber() {
  //   return _lastMobileNumber;
  // }
  //
  // // Save merchant name
  // static void saveMerchantName(String merchantName) {
  //   _merchantName = merchantName;
  // }
  //
  // // Get merchant name
  // static String? getMerchantName() {
  //   return _merchantName;
  // }

  // Clear all stored data
//   static Future<void> clearAll() async {
//     _lastMobileNumber = null;
//     _merchantName = null;
//     await _saveToFile();
//   }
//
//   // Simple file-based storage implementation
//   static Future<void> _saveToFile() async {
//     try {
//       final data = {
//         'lastMobileNumber': _lastMobileNumber,
//         'merchantName': _merchantName,
//       };
//       // In a real implementation, you'd save to app documents directory
//       // For now, we'll just keep it in memory
//       debugPrint('Data saved to memory storage');
//     } catch (e) {
//       debugPrint('Failed to save to file: $e');
//     }
//   }
//
//   static Future<void> _loadFromFile() async {
//     try {
//       // In a real implementation, you'd load from app documents directory
//       // For now, data persists only during app session
//       debugPrint('Data loaded from memory storage');
//     } catch (e) {
//       debugPrint('Failed to load from file: $e');
//     }
//   }
// }

class LoginScreen extends StatefulWidget {
  final String? initialMobileNumber;
  const LoginScreen({Key? key, this.initialMobileNumber}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _mobileFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool isButtonEnabled = false;
  String _maskedMobile = '';
  String _actualMobile = '';
  bool _isEditingMobile = false;
  bool _isLoading = false;
  String _merchantName = 'Merchant';
  bool _isLoadingData = false;

  void _setupInitialData() async {
    if (mounted) setState(() => _isLoadingData = true);

    final savedMobile = await AppStorage.getLastMobileNumber();
    final savedMerchant = await AppStorage.getMerchantName();

    if (mounted) {
      setState(() {
        _actualMobile = savedMobile ?? '';
        _merchantName = savedMerchant ?? 'Merchant';
        if (_actualMobile.isNotEmpty) {
          _updateMaskedNumber();
          _mobileController.text = _maskedMobile;
        }
        _isLoadingData = false;
      });
    }
  }
  // Add these for proper cleanup
  Timer? _debounceTimer;
  final List<StreamSubscription> _subscriptions = [];

  static const String xToken =
      'eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiIxIiwiaWF0IjoxNzQxMjY1MjkyLCJleHAiOjE3NDEyNzI0OTJ9.dc_swQD7uUCgFIlPseHuv7vZpIfljZPO3ihti8U4C5ES1Z385RRFZYRG9yaenY7yh-mOFz03hhce2FG2O8tPMA';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _setupInitialData();
    _setupListeners();
    _setupSystemUI();
  }

  // void _setupInitialData() async {
  //   // Load saved data from SharedPreferences
  //   final savedMobile = await AppStorage.getLastMobileNumber();
  //   final savedMerchant = await AppStorage.getMerchantName();
  //
  //   if (mounted) {
  //     setState(() {
  //       _actualMobile = savedMobile ?? '';
  //       _merchantName = savedMerchant ?? 'Merchant';
  //       if (_actualMobile.isNotEmpty) {
  //         _updateMaskedNumber();
  //         _mobileController.text = _maskedMobile;
  //       }
  //     });
  //   }
  // }

  void _setupListeners() {
    _mobileController.addListener(_validateInput);
    _passwordController.addListener(_validateInput);

    _mobileFocusNode.addListener(() {
      if (!_mobileFocusNode.hasFocus && _isEditingMobile) {
        _onMobileFieldFocusLost();
      }
    });
  }

  void _setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Cancel any pending timers
    _debounceTimer?.cancel();

    // Cancel all subscriptions
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Dispose controllers and focus nodes
    _mobileController.dispose();
    _passwordController.dispose();
    _mobileFocusNode.dispose();
    _passwordFocusNode.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      // App is in background, save current state
        _saveCurrentState();
        break;
      case AppLifecycleState.resumed:
      // App is back in foreground, restore state if needed
        _restoreState();
        break;
      case AppLifecycleState.detached:
      // App is being terminated
        _saveCurrentState();
        break;
      default:
        break;
    }
  }

  void _saveCurrentState() {
    if (_actualMobile.isNotEmpty) {
      AppStorage.saveMobileNumber(_actualMobile);
    }
    if (_merchantName != 'Merchant') {
      AppStorage.saveMerchantName(_merchantName);
    }
  }

  void _restoreState() async {
    final savedMobile = await AppStorage.getLastMobileNumber();
    final savedMerchant = await AppStorage.getMerchantName();

    if (mounted && savedMobile != null && savedMobile != _actualMobile) {
      setState(() {
        _actualMobile = savedMobile;
        _updateMaskedNumber();
        _mobileController.text = _maskedMobile;
      });
    }

    if (mounted && savedMerchant != null && savedMerchant != _merchantName) {
      setState(() {
        _merchantName = savedMerchant;
      });
    }
  }
  Future<void> _fetchMerchantName() async {
    if (_actualMobile.isEmpty || !mounted) return;

    try {
      // Simulate API call - replace with actual implementation
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _merchantName = 'Merchant'; // Update this based on your API
        });
        AppStorage.saveMerchantName(_merchantName);
      }
    } catch (e) {
      debugPrint('Failed to fetch merchant name: $e');
      if (mounted) {
        setState(() {
          _merchantName = 'Merchant';
        });
      }
    }
  }

  void _updateMaskedNumber() {
    if (_actualMobile.isEmpty) {
      _maskedMobile = '';
      return;
    }

    String maskedNumber = '';
    for (int i = 0; i < _actualMobile.length; i++) {
      if (i < 6) {
        maskedNumber += '*';
      } else {
        maskedNumber += _actualMobile[i];
      }
    }
    _maskedMobile = maskedNumber;
  }

  void _onMobileNumberChanged(String value) {
    // Remove any non-digit characters
    value = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (value.length > 10) {
      value = value.substring(0, 10);
    }

    _actualMobile = value;

    if (!mounted) return;

    if (_isEditingMobile) {
      setState(() {
        _mobileController.value = TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        );
      });
    } else {
      _updateMaskedNumber();
      setState(() {
        _mobileController.value = TextEditingValue(
          text: _maskedMobile,
          selection: TextSelection.collapsed(offset: _maskedMobile.length),
        );
      });
    }

    _validateInput();
  }

  void _onMobileFieldTapped() {
    if (!mounted) return;

    // Navigate to a new LoginScreen to change the mobile number
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => InitialLoginScreen(),
      ),
    );
  }

  void _onMobileFieldFocusLost() {
    if (!mounted) return;

    setState(() {
      _isEditingMobile = false;
      _updateMaskedNumber();
      _mobileController.text = _maskedMobile;
    });
  }

  void _validateInput() {
    final bool isValid = _actualMobile.length == 10 &&
        _passwordController.text.length >= 4;

    if (isButtonEnabled != isValid && mounted) {
      setState(() {
        isButtonEnabled = isValid;
      });
    }
  }

  Future<void> _login() async {
    if (_isLoading || !mounted) return;

    // Validate inputs before proceeding
    if (_actualMobile.length != 10) {
      _safeShowSnackBar('Please enter a valid 10-digit mobile number', Colors.red);
      return;
    }

    if (_passwordController.text.length < 4) {
      _safeShowSnackBar('PIN must be at least 4 digits', Colors.red);
      return;
    }

    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      final response = await http.post(
        Uri.parse('https://bportal.bijlipay.co.in:9027/auth/signin'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'X-DEVICE-TOKEN': xToken,
        },
        body: jsonEncode({
          'mobileNo': _actualMobile,
          'password': _passwordController.text,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Connection timed out', const Duration(seconds: 30)),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String authToken = responseData['access_token'];
        await AppStorage.saveAuthToken(authToken);
        log("AuthToken: $authToken");
        await AppStorage.saveMobileNumber(_actualMobile);
        if (responseData['access_token'] == null) {
          throw Exception('No access token received');
        }

        // Save mobile number after successful login
        await AppStorage.saveMobileNumber(_actualMobile);

        final profileData = await _fetchUserProfile(authToken);

        if (!mounted) return;

        _safeShowSnackBar('Login Successful', Colors.green);

        // Navigate to main screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(
              merchantName: profileData['merchantName'] ?? 'Unknown Merchant',
              mobileNo: profileData['mobileNo'] ?? _actualMobile,
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
      } else if (response.statusCode == 401) {
        _safeShowSnackBar('Invalid mobile number or PIN', Colors.red);
      } else if (response.statusCode == 403) {
        _safeShowSnackBar('Account is locked or suspended', Colors.red);
      } else {
        _safeShowSnackBar('Login failed. Please try again.', Colors.red);
      }
    } on TimeoutException catch (e) {
      if (!mounted) return;
      _showNetworkIssueDialog();
    } on FormatException catch (e) {
      if (!mounted) return;
      _safeShowSnackBar('Invalid response from server', Colors.red);
    } catch (e) {
      debugPrint('Login failed: $e');
      if (!mounted) return;
      _safeShowSnackBar('Failed to connect to server', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Safe method to show snackbar that checks mounted state
  void _safeShowSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
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
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final data = responseData['data'];

        if (data == null) {
          throw Exception('No profile data received');
        }

        final List<String> terminalIds = [];
        if (data['tidList'] != null) {
          for (var tid in data['tidList']) {
            if (tid['tid'] != null) {
              terminalIds.add(tid['tid'].toString());
            }
          }
        }

        final List<String> vpaList = [];
        if (data['vpaList'] != null) {
          for (var vpa in data['vpaList']) {
            if (vpa['vpa'] != null) {
              vpaList.add(vpa['vpa'].toString());
            }
          }
        }

        return {
          'merchantName': data['merchantName'] ?? 'Unknown Merchant',
          'terminalIds': terminalIds,
          'vpaList': vpaList,
          'mobileNo': data['mobileNo'] ?? '',
          'email': data['email'] ?? '',
          'merchantAddress': data['merchantAddress'] ?? '',
          'accountNo': data['accountNo'] ?? '',
          'bankName': data['bankName'] ?? '',
          'branch': data['branch'] ?? '',
          'ifscCode': data['ifscCode'] ?? '',
          'id': data['id']?.toString() ?? '',
          'rrn': data['rrn'] ?? '',
        };
      } else {
        throw Exception('Failed to fetch profile: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Profile fetch failed: $e');
      return {
        'merchantName': 'Unknown Merchant',
        'terminalIds': <String>[],
        'vpaList': <String>[],
        'mobileNo': _actualMobile,
        'email': '',
        'merchantAddress': '',
        'accountNo': '',
        'bankName': '',
        'branch': '',
        'ifscCode': '',
        'id': '',
        'rrn': '',
      };
    }
  }

  void _showNetworkIssueDialog() {
    if (!mounted) return;

    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    final double dialogWidth = isTablet ? 480 : screenSize.width * 0.85;
    final double iconSize = isTablet ? 26.0 : 22.0;
    final double titleSize = isTablet ? 18.0 : 16.0;
    final double messageSize = isTablet ? 15.0 : 14.0;
    final double buttonTextSize = isTablet ? 15.0 : 14.0;

    const Color primaryColor = Color(0xFF61116A);
    const Color textColor = Color(0xFF383838);
    const Color subtextColor = Color(0xFF757774);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
        child: Container(
          width: dialogWidth,
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, Color(0xFF7A1E86)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon(Icons.signal_wifi_off, color: Colors.white, size: iconSize),
                    // const SizedBox(width: 12),
                    Text(
                      'Connection Failed',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4D7F4),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        color: primaryColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to Connect',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: titleSize,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We\'re having trouble connecting to our servers. Please check your internet connection and try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: messageSize,
                        fontWeight: FontWeight.w500,
                        color: subtextColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: buttonTextSize,
                            fontWeight: FontWeight.w600,
                            color: subtextColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _login();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: buttonTextSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final bool isTablet = screenSize.width > 600;

    double getResponsiveSize(double mobileSize, double tabletSize) {
      return isTablet ? tabletSize : mobileSize;
    }

    final double titleFontSize = getResponsiveSize(
        screenSize.width * 0.06, screenSize.width * 0.04);
    final double subtitleFontSize = getResponsiveSize(
        screenSize.width * 0.035, screenSize.width * 0.025);
    final double bodyFontSize = getResponsiveSize(
        screenSize.width * 0.04, screenSize.width * 0.028);
    final double labelFontSize = getResponsiveSize(
        screenSize.width * 0.028, screenSize.width * 0.022);
    final double buttonFontSize = getResponsiveSize(
        screenSize.width * 0.04, screenSize.width * 0.028);

    final double verticalSpacing = getResponsiveSize(
        screenSize.height * 0.02, screenSize.height * 0.015);
    final double horizontalPadding = getResponsiveSize(
        screenSize.width * 0.04, screenSize.width * 0.03);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double contentMaxWidth = isTablet ? 500.0 : constraints.maxWidth;

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
                colors: [Color(0xFFFFFFFF), Color(0xFFF4D7F4)],
                stops: [0.0864, 0.6183],
              ),
            ),
          ),

          // Background image
          Positioned(
            left: -screenSize.width * 0.00001,
            child: Image.asset(
              'assets/thunder.png',
              width: screenSize.width * 1.01,
              height: screenSize.height * 0.79,
              fit: BoxFit.cover,
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          const SizedBox(height: 82),

                      // Logo
                      Image.asset(
                        'assets/bijli_logo.png',
                        width: getResponsiveSize(
                            screenSize.width * 0.45, screenSize.width * 0.3),
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: verticalSpacing * 1.5),

                      // Title
                      Text(
                        'Hello $_merchantName!',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF383838),
                        ),
                      ),
                      SizedBox(height: verticalSpacing * 0.75),

                      // Subtitle
                      Text(
                        'Enter your PIN to get started',
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF383838),
                        ),
                      ),
                      SizedBox(height: verticalSpacing * 1.5),

                      // Display current mobile number if available
                      if (_actualMobile.isNotEmpty)
            //       Padding(
            //   padding: EdgeInsets.only(bottom: verticalSpacing),
            //   child: Container(
            //     padding: EdgeInsets.symmetric(
            //       horizontal: getResponsiveSize(16, 20),
            //       vertical: getResponsiveSize(12, 16),
            //     ),
            //     decoration: BoxDecoration(
            //       color: const Color(0xFFF4D7F4).withOpacity(0.3),
            //       borderRadius: BorderRadius.circular(getResponsiveSize(8, 10)),
            //       border: Border.all(
            //         color: const Color(0xFF61116A).withOpacity(0.2),
            //         width: 1,
            //       ),
            //     ),
            //     // child: Row(
            //     //   children: [
            //     //     Icon(
            //     //       Icons.phone_android,
            //     //       color: const Color(0xFF61116A),
            //     //       size: getResponsiveSize(18, 20),
            //     //     ),
            //     //     SizedBox(width: getResponsiveSize(8, 10)),
            //     //     Text(
            //     //       "Mobile: ${_actualMobile}",
            //     //       style: TextStyle(
            //     //         fontSize: subtitleFontSize,
            //     //         fontWeight: FontWeight.w600,
            //     //         color: const Color(0xFF61116A),
            //     //       ),
            //     //     ),
            //     //   ],
            //     // ),
            //   ),
            // ),

            // Mobile Number Input
                        TextFormField(
                          controller: _mobileController,
                          focusNode: _mobileFocusNode,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          onTap: _onMobileFieldTapped,
                          onChanged: _onMobileNumberChanged,
                          readOnly: true, // Make the field read-only since we're navigating to change it
                          decoration: InputDecoration(
                            labelText: "Mobile Number",
                            labelStyle: TextStyle(
                              color: const Color(0xFF757774),
                              fontFamily: 'Montserrat',
                              fontSize: labelFontSize,
                              fontWeight: FontWeight.w700,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(getResponsiveSize(10, 12)),
                              borderSide: const BorderSide(color: Color(0xFFDBDAE0), width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(getResponsiveSize(10, 12)),
                              borderSide: const BorderSide(color: Color(0xFFDBDAE0), width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(getResponsiveSize(10, 12)),
                              borderSide: const BorderSide(color: Color(0xFF61116A), width: 1.5),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: getResponsiveSize(16, 20),
                              vertical: getResponsiveSize(16, 20),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF757774)),
                              onPressed: _onMobileFieldTapped, // Same handler as the field tap
                            ),
                          ),
                          cursorColor: const Color(0xFF61116A),
                          style: TextStyle(
                            fontSize: bodyFontSize,
                            color: const Color(0xFF757774),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                SizedBox(height: verticalSpacing),

                // PIN Input
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: _obscurePassword,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: InputDecoration(
                    labelText: "PIN",
                    labelStyle: TextStyle(
                      color: const Color(0xFF757774),
                      fontFamily: 'Montserrat',
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w700,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          getResponsiveSize(10, 12)),
                      borderSide: const BorderSide(
                          color: Color(0xFFDBDAE0), width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          getResponsiveSize(10, 12)),
                      borderSide: const BorderSide(
                          color: Color(0xFFDBDAE0), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          getResponsiveSize(10, 12)),
                      borderSide: const BorderSide(
                          color: Color(0xFF61116A), width: 1.5),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: getResponsiveSize(16, 20),
                      vertical: getResponsiveSize(16, 20),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: const Color(0xFF757774),
                      ),
                      onPressed: () {
                        if (mounted) {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        }
                      },
                    ),
                  ),
                  style: TextStyle(
                    fontSize: bodyFontSize,
                    color: const Color(0xFF757774),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: verticalSpacing),

                // Forgot PIN link
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ForgotPinScreen()),
                      );
                    },
                    child: Text(
                      "Forgot PIN?",
                                style: TextStyle(
                                  fontSize: subtitleFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF61116A),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: verticalSpacing * 1.5),

                          // Login Button
                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: getResponsiveSize(50, 56),
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : (isButtonEnabled ? _login : null),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isButtonEnabled
                                      ? const Color(0xFF61116A)
                                      : const Color(0x6661116A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        getResponsiveSize(10, 12)),
                                  ),
                                  elevation: 2,
                                ),
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: buttonFontSize,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                SizedBox(height: verticalSpacing * 2),

                // Sign Up Link
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF757774),
                      ),
                                children: [
                                  TextSpan(
                                    text: 'Sign Up',
                                    style: TextStyle(
                                      fontSize: subtitleFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF61116A),
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  signup.SignUpScreen()),
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: verticalSpacing),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Loading overlay
              if (_isLoading)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF61116A)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}