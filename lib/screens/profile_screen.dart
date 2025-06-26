import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static const String _mobileKey = 'last_mobile';
  static const String _merchantKey = 'merchant_name';

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

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mobileKey);
    await prefs.remove(_merchantKey);
  }

  // Add this new method
  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}

class ProfileScreen extends StatefulWidget {
  final String? merchantName;
  final String? mobileNo;
  final String? merchantAddress;
  final String? bankName;
  final String? accountNo;
  final String? branch;
  final String? ifscCode;
  final String? email;
  final String? authToken;

  const ProfileScreen({
    Key? key,
    this.merchantName,
    this.mobileNo,
    this.email,
    this.merchantAddress,
    this.bankName,
    this.accountNo,
    this.branch,
    this.ifscCode,
    this.authToken,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  // Constants
  static const String _baseUrl = "https://bportal.bijlipay.co.in:9027";
  static const List<String> _languages = ['English', 'Tamil', 'Hindi'];

  // Profile data
  Map<String, dynamic> _profileData = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String? _authToken;

  // UI state
  bool _isToggled = false;
  String? _selectedLanguage;
  bool _dropdownOpen = false;

  // Animation controllers
  late final AnimationController _animationController;
  late final Animation<double> _dropdownAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initializeFromWidgetData();
    _initAuthToken();
  }


  void _initializeAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _dropdownAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
  }

  void _initializeFromWidgetData() {
    _profileData = {
      'merchantName': widget.merchantName,
      'mobileNo': widget.mobileNo,
      'email': widget.email,
      'merchantAddress': widget.merchantAddress,
      'accountNo': widget.accountNo,
      'bankName': widget.bankName,
      'branch': widget.branch,
      'ifscCode': widget.ifscCode,
      'speakOutEnable': _isToggled,
      'language': _selectedLanguage,
    };
    // Save profile data to AppStorage immediately after initialization
    _saveProfileDataToStorage();
  }

  // Method to save profile data to AppStorage
  Future<void> _saveProfileDataToStorage() async {
    if (_profileData['merchantName'] != null) {
      AppStorage.saveMerchantName(_profileData['merchantName'].toString());
    }
    if (_profileData['mobileNo'] != null) {
      AppStorage.saveMobileNumber(_profileData['mobileNo'].toString());
    }
  }

  Future<void> _initAuthToken() async {
    // Try to get token from widget first
    if (widget.authToken != null) {
      _authToken = widget.authToken;
    } else {
      // Try to get token from shared preferences
      try {
        final prefs = await SharedPreferences.getInstance();
        _authToken = prefs.getString('auth_token');
      } catch (e) {
        debugPrint('Error loading token from preferences: $e');
      }
    }

    // Load profile data if token is available and mobile number exists
    if (_authToken != null && widget.mobileNo != null) {
      await _loadProfileData();
    } else {
      // Just use widget data if no token available
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 401 Error Handling Method
  Future<void> _handle401Error() async {
    // Clear stored token
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      debugPrint('Error clearing token: $e');
    }

    // Navigate to login screen and clear the navigation stack
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  // Enhanced HTTP Response Handler
  Future<http.Response> _handleApiResponse(Future<http.Response> apiCall) async {
    try {
      final response = await apiCall;

      if (response.statusCode == 401) {
        debugPrint('401 Unauthorized - Redirecting to login');
        await _handle401Error();
        throw Exception('Unauthorized access - redirected to login');
      }

      return response;
    } catch (e) {
      // If the error is related to unauthorized access, handle it
      if (e.toString().contains('Unauthorized') || e.toString().contains('401')) {
        await _handle401Error();
      }
      rethrow;
    }
  }

  // API Methods
  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    if (_authToken == null) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Authentication token not available';
      });
      return;
    }

    try {
      final response = await _handleApiResponse(
        http.get(
          Uri.parse("$_baseUrl/auth/user/profile"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $_authToken"
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _profileData = data['data'];
          _isToggled = _profileData['speakOutEnable'] ?? false;
          _selectedLanguage = _profileData['language'];
          _isLoading = false;
        });
        // Save updated profile data to AppStorage after successful API fetch
        await _saveProfileDataToStorage();
      } else {
        debugPrint('API Error: ${response.statusCode}, ${response.body}');
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load profile: ${response.statusCode}';
          // Revert to widget data if API fails
          _initializeFromWidgetData();
        });
      }
    } catch (e) {
      debugPrint('Exception during API call: $e');

      // Don't show error screen if user was redirected to login due to 401
      if (!e.toString().contains('Unauthorized')) {
        setState(() {
          _isLoading = false;
          _hasError = false; // Don't show error screen, just use widget data
          _errorMessage = 'Network error: $e';
          // Revert to widget data if API fails
          _initializeFromWidgetData();
        });
      }
    }
  }

  Future<void> _updateLanguage(String language) async {
    if (_profileData.isEmpty || _profileData['id'] == null) {
      _showSnackBar('Cannot update: Profile data not loaded.', isError: true);
      return;
    }

    if (_authToken == null) {
      _showSnackBar('Authentication token not available', isError: true);
      return;
    }

    final userId = _profileData['id'];
    final url = Uri.parse("$_baseUrl/auth/user/update-user/$userId");

    try {
      final response = await _handleApiResponse(
        http.put(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $_authToken"
          },
          body: jsonEncode({
            "speakOutEnable": _isToggled,
            "language": language
          }),
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _selectedLanguage = language;
          _profileData['language'] = language;
        });
        _showSnackBar('$language language selected.');
      } else {
        debugPrint('API Error: ${response.statusCode}, ${response.body}');
        _showSnackBar('Failed to update language: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      debugPrint('Exception during API call: $e');
      if (!e.toString().contains('Unauthorized')) {
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  Future<void> _updateSpeakOutEnable(bool enabled) async {
    if (_profileData.isEmpty || _profileData['id'] == null) {
      _showSnackBar('Cannot update: Profile data not loaded.', isError: true);
      return;
    }

    if (_authToken == null) {
      _showSnackBar('Authentication token not available', isError: true);
      return;
    }

    final userId = _profileData['id'];
    final url = Uri.parse("$_baseUrl/auth/user/update-user/$userId");

    try {
      final response = await _handleApiResponse(
        http.put(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $_authToken"
          },
          body: jsonEncode({
            "speakOutEnable": enabled,
            "language": _selectedLanguage ?? _profileData['language']
          }),
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isToggled = enabled;
          _profileData['speakOutEnable'] = enabled;
        });
        _showSnackBar('Sound box ${enabled ? 'enabled' : 'disabled'}.');

        // If disabling, also reset language selection UI
        if (!enabled) {
          _closeDropdown();
        }
      } else {
        debugPrint('API Error: ${response.statusCode}, ${response.body}');
        // Revert UI state on failure
        setState(() {
          _isToggled = !enabled;
        });
        _showSnackBar('Failed to update settings: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      debugPrint('Exception during API call: $e');
      // Revert UI state on error (but not for 401 errors since user will be redirected)
      if (!e.toString().contains('Unauthorized')) {
        setState(() {
          _isToggled = !enabled;
        });
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  // UI State Methods
  void _toggleDropdown() {
    if (!_isToggled) return;
    setState(() {
      _dropdownOpen = !_dropdownOpen;
      if (_dropdownOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _closeDropdown() {
    if (_dropdownOpen) {
      setState(() {
        _dropdownOpen = false;
        _animationController.reverse();
      });
    }
  }

  void _onLanguageSelected(String lang) {
    setState(() {
      _dropdownOpen = false;
      _animationController.reverse();
    });
    _updateLanguage(lang);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Utility Methods
  String _maskMobile(String? mobile) {
    if (mobile == null || mobile.length < 3) return '******';
    return '${mobile[0]}******${mobile.substring(mobile.length - 2)}';
  }

  String _maskEmail(String? email) {
    if (email == null || !email.contains('@')) return '******';
    final parts = email.split('@');
    if (parts[0].length < 3) return '******@${parts[1]}';
    return '${parts[0].substring(0, 2)}******@${parts[1]}';
  }

  String _maskAccountNumber(String? accountNo) {
    if (accountNo == null || accountNo.length < 4) return '********';
    return '********${accountNo.substring(accountNo.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_hasError) {
      return _buildErrorScreen();
    }

    return _buildMainScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF61116A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadProfileData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF61116A),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainScreen() {
    const primaryColor = Color(0xFF61116A);
    const backgroundColor = Color(0xFFFFFFFF);
    const textColor = Color(0xFF383838);
    final borderColor = Colors.grey.shade300;

    return GestureDetector(
      onTap: _closeDropdown,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // Reduced vertical padding
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Voice Out Toggle Section
                  _buildVoiceOutSection(primaryColor, textColor),
                  const SizedBox(height: 8), // Reduced from 10
                  _buildLanguageDropdown(primaryColor, borderColor, textColor),
                  const SizedBox(height: 16), // Reduced from 20
                  // Divider after QR Sticker line
                  _buildDivider(),
                  const SizedBox(height: 16),


                  // Merchant Details - Without Card
                  _buildMerchantDetails(textColor),

                  const SizedBox(height: 36),

                  // Divider before logout
                  _buildDivider(),
                  const SizedBox(height: 16),

                  // Logout Section
                  _buildLogoutSection(textColor),
                  const SizedBox(height: 16),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceOutSection(Color primaryColor, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'QR Sticker Voice Out (SoundBox)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
              letterSpacing: 0.6,
            ),
          ),
        ),
        // SizedBox wrapper around _buildCustomSwitch is removed.
        _buildCustomSwitch(primaryColor),
      ],
    );
  }

  Widget _buildCustomSwitch(Color primaryColor) { // primaryColor is passed but might not be used if we hardcode iOS colors
    return Transform.scale(
      scale: 0.8, // Scaling factor to make the switch smaller
      child: Switch(
        value: _isToggled,
        onChanged: (bool value) {
          // This line is crucial and should call the existing state update mechanism
          _updateSpeakOutEnable(value);
        },
        activeColor: Colors.white, // Thumb color when ON (standard for iOS)
        activeTrackColor: Color(0xFF61116A), // Track color when ON (standard iOS green)
        inactiveThumbColor: Colors.white, // Thumb color when OFF (standard for iOS)
        inactiveTrackColor: Colors.grey.shade300, // Track color when OFF (standard iOS light grey)
        // For a more authentic iOS feel, ensure the track has rounded ends, which is default for Flutter's Switch.
      ),
    );
  }

  Widget _buildLanguageDropdown(
      Color primaryColor,
      Color borderColor,
      Color textColor,
      ) {
    if (!_isToggled) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Language',
          style: TextStyle(
            fontSize: 15, // Increased font size
            fontWeight: FontWeight.w600,
            color: textColor,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8), // Reduced from 10
        GestureDetector(
          onTap: _toggleDropdown,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutQuart,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Reduced padding
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8), // Reduced from 10
              border: Border.all(
                color: _dropdownOpen ? primaryColor.withOpacity(0.4) : borderColor,
                width: 1.0, // Reduced from 1.2
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_dropdownOpen ? 0.04 : 0.02),
                  blurRadius: _dropdownOpen ? 8 : 4, // Reduced shadow
                  offset: const Offset(0, 2), // Reduced from 3
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedLanguage ?? 'Select Language',
                    style: TextStyle(
                      fontSize: 13, // Reduced from 15.2
                      fontWeight: FontWeight.w500,
                      color: _selectedLanguage != null
                          ? textColor
                          : textColor.withOpacity(0.6),
                      letterSpacing: -0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedRotation(
                  turns: _dropdownOpen ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutBack,
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 20, // Reduced from 24
                    color: _dropdownOpen ? primaryColor : textColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _dropdownAnimation,
          axisAlignment: -1.0,
          child: Padding(
            padding: const EdgeInsets.only(top: 6), // Reduced from 8
            child: Material(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Reduced from 10
                side: BorderSide(color: borderColor.withOpacity(0.3), width: 1.0),
              ),
              color: Colors.white,
              child: Column(
                children: _languages.map((lang) {
                  final isSelected = _selectedLanguage == lang;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutQuad,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF61116A).withOpacity(0.06) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6), // Reduced from 8
                    ),
                    child: InkWell(
                      onTap: () => _onLanguageSelected(lang),
                      borderRadius: BorderRadius.circular(6), // Reduced from 8
                      splashColor: const Color(0xFF61116A).withOpacity(0.1),
                      highlightColor: const Color(0xFF61116A).withOpacity(0.05),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12), // Reduced padding
                        child: Text(
                          lang,
                          style: TextStyle(
                            fontSize: 12.5, // Reduced from 14.8
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? const Color(0xFF61116A) : textColor,
                            letterSpacing: -0.15,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildMerchantDetails(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoTile('Merchant Name', _profileData['merchantName'], textColor),
        const SizedBox(height: 18), // Increased spacing
        _buildInfoTile('Mobile Number', _maskMobile(_profileData['mobileNo']), textColor),
        const SizedBox(height: 18), // Increased spacing
        _buildInfoTile('Email', _maskEmail(_profileData['email']), textColor),
        const SizedBox(height: 18), // Increased spacing
        _buildInfoTile('Address', _profileData['merchantAddress'], textColor),
        const SizedBox(height: 18), // Increased spacing
        _buildAccountDetails(textColor),
      ],
    );
  }

  Widget _buildAccountDetails(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Details',
          style: TextStyle(
            color: Color(0xFF383838),
            fontFamily: 'Montserrat',
            fontSize: 13, // Increased font size
            fontWeight: FontWeight.w800,
            height: 20 / 13,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _maskAccountNumber(_profileData['accountNo']) ?? 'Not available',
          style: const TextStyle(
            color: Color(0xFF383838),
            fontFamily: 'Montserrat',
            fontSize: 15, // Increased font size
            fontWeight: FontWeight.w500,
            height: 21 / 15,
          ),
        ),
        const SizedBox(height: 5), // Increased spacing
        Text(
          _profileData['bankName']?.toString() ?? 'Not available',
          style: const TextStyle(
            color: Color(0xFF383838),
            fontFamily: 'Montserrat',
            fontSize: 15, // Increased font size
            fontWeight: FontWeight.w500,
            height: 21 / 15,
          ),
        ),
        const SizedBox(height: 5), // Increased spacing
        Text(
          _profileData['branch']?.toString() ?? 'Not available',
          style: const TextStyle(
            color: Color(0xFF383838),
            fontFamily: 'Montserrat',
            fontSize: 15, // Increased font size
            fontWeight: FontWeight.w500,
            height: 21 / 15,
          ),
        ),
        const SizedBox(height: 5), // Increased spacing
        Text(
          _profileData['ifscCode']?.toString() ?? 'Not available',
          style: const TextStyle(
            color: Color(0xFF383838),
            fontFamily: 'Montserrat',
            fontSize: 15, // Increased font size
            fontWeight: FontWeight.w500,
            height: 21 / 15,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, dynamic value, Color textColor) {
    final displayValue = value?.toString() ?? 'Not available';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700, // Increased from 600
            height: 1.2, // Tighter line height
          ),
        ),
        const SizedBox(height: 4), // Reduced from 5
        Text(
          displayValue,
          style: const TextStyle(
            fontSize: 14, // Reduced from 15
            fontWeight: FontWeight.w500,
            height: 1.3, // Tighter line height
          ),
        ),
      ],
    );
  }

  // Widget _buildLogoutSection(Color textColor) {
  //   return GestureDetector(
  //     onTap: () async {
  //       // Clear stored auth token
  //       try {
  //         final prefs = await SharedPreferences.getInstance();
  //         await prefs.remove('auth_token');
  //       } catch (e) {
  //         debugPrint('Error clearing token on logout: $e');
  //       }
  //
  //       // Clear all AppStorage data on logout
  //       try {
  //         await AppStorage.clearAll();
  //         debugPrint('Cleared AppStorage data on logout');
  //       } catch (e) {
  //         debugPrint('Error clearing AppStorage on logout: $e');
  //       }
  //
  //       // Navigate to login screen
  //       if (mounted) {
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(builder: (context) => const LoginScreen()),
  //         );
  //       }
  //     },
  //     child: Row(
  //       children: [
  //         Icon(
  //           Icons.logout_rounded,
  //           size: 20,
  //           color: Color(0xFF61116A),
  //         ),
  //         const SizedBox(width: 12),
  //         const Text(
  //           'Logout',
  //           style: TextStyle(
  //             color: Color(0xFF383838),
  //             fontFamily: 'Montserrat',
  //             fontSize: 14,
  //             fontWeight: FontWeight.w700,
  //             height: 10 / 14, // line-height: 10px
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildLogoutSection(Color textColor) {
    return GestureDetector(
      onTap: () async {
        // Simple logout without heavy SharedPreferences operations
        debugPrint('Logging out...');

        // Navigate immediately to login screen
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
          );
        }

        // Clear data in background after navigation
        _clearDataInBackground();
      },
      child: Row(
        children: [
          const Icon(Icons.logout, color: Color(0xFF61116A)),
          const SizedBox(width: 12),
          Text(
            'Logout',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

// Clear data in background after logout
  void _clearDataInBackground() {
    Future.delayed(const Duration(seconds: 1), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        await prefs.remove('last_mobile');
        await prefs.remove('merchant_name');
        debugPrint('Background cleanup completed');
      } catch (e) {
        debugPrint('Background cleanup failed: $e');
      }
    });
  }
  Widget _buildDivider() {
    return Container(
      height: 1,
      width: double.infinity,
      color: Colors.grey.shade300,
    );
  }
}
