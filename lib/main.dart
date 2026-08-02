import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projects/services/api_services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart';
import 'dart:async';



void main() async {

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BloodiFind',
      theme: ThemeData(
        primaryColor: Color(0xFF000000),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFFEF4444),
          primary: Color(0xFF000000),
          secondary: Colors.blue,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final result = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        // Success Logic
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainApp(userId: result['data']['user']['id'].toString()),
          ),
        );
      } else {
        // ERROR HANDLING LOGIC
        // This automatically displays the message sent from the server:
        // "Account deactivated by admin..." OR "Your restoration link has expired..."
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Login failed'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4), // Increased duration so user can read long messages
          ),
        );
      }
    }
  }

  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignUpPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              SizedBox(height: 40),

              // Hospital Logo and Welcome Text
              _buildHeader(),

              SizedBox(height: 48),

              // Login Form
              _buildLoginForm(),

              SizedBox(height: 32),

              // Login Button
              _buildLoginButton(),

              SizedBox(height: 24),

              // Divider
              _buildDivider(),

              SizedBox(height: 10),

              // Sign Up Link
              _buildSignUpLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Hospital Logo with Asset Image
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(
              'assets/LDH (2).jpg',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback in case image fails to load
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medical_services,
                      size: 50,
                      color: Colors.blue.shade700,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'LDH',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        SizedBox(height: 5),

        Text(
          'BloodiFind',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),

        SizedBox(height: 8),

        Text(
          'Sign in to your account',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),

          SizedBox(height: 20),

          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey.shade600,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),

          SizedBox(height: 16),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // Navigate to Forgot Password Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                );
              },
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.poppins(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Text(
          'Sign In',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey.shade300,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Or',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey.shade300,
            thickness: 1,
          ),
        ),
      ],
    );
  }


  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.grey.shade600,

          ),
        ),
        SizedBox(width: 2),
        TextButton(
          onPressed: _navigateToSignUp,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
          ),
          child: Text(
            'Sign Up',
            style: GoogleFonts.poppins(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _sendOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final email = _emailController.text.trim();
      final result = await ApiService.requestPasswordResetOtp(email);

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        // FIX: Access 'message' inside 'data', or provide a fallback string
        final message = result['data'] != null && result['data']['message'] != null
            ? result['data']['message']
            : 'OTP sent to your email.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to OTP Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyOtpScreen(email: email),
          ),
        );
      } else {
        // Error messages are usually handled at the root level by ApiService, but let's be safe
        final errorMessage = result['error'] ?? 'Error sending OTP';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Forgot Password", style: GoogleFonts.poppins())),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Reset your password",
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Enter the email associated with your account and we'll send you an OTP.",
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
              SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your email';
                  if (!value.contains('@')) return 'Invalid email format';
                  return null;
                },
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Send OTP", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Screen 2: Verify OTP
class VerifyOtpScreen extends StatefulWidget {
  final String email;
  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  void _verify() async {
    if (_otpController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a 6-digit OTP")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.verifyOtp(widget.email, _otpController.text.trim());

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OTP Verified!"), backgroundColor: Colors.green),
      );
      // Navigate to Reset Password Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(
            email: widget.email,
            otp: _otpController.text.trim(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Invalid OTP'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verify OTP", style: GoogleFonts.poppins())),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Check your email",
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "We've sent a 6-digit code to ${widget.email}",
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
            SizedBox(height: 32),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '000000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Verify Code", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Screen 3: Reset Password
class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;
  const ResetPasswordScreen({super.key, required this.email, required this.otp});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureText = true;
  bool _obscureConfirmText = true;

  void _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final result = await ApiService.resetPasswordFinal(
        widget.email,
        widget.otp,
        _passController.text,
      );

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text("Success"),
            content: Text("Your password has been reset successfully."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // Close dialog
                  Navigator.of(context).popUntil((route) => route.isFirst); // Go to Login
                },
                child: Text("Login Now", style: TextStyle(color: Color(0xFFEF4444))),
              )
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to reset password'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("New Password", style: GoogleFonts.poppins())),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create new password",
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Your new password must be different from previous used passwords.",
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
              SizedBox(height: 32),
              TextFormField(
                controller: _passController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureText ? Icons.visibility_off :  Icons.visibility),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  // Regex: At least one UPPERCASE, one number, one special char (including underscore)
                  if (!RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~_]).+$').hasMatch(value)) {
                    return 'Must contain:\n- 1 Upper\n- 1 Number\n- 1 Special Character (!@#\$&*~_)';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirmText,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmText ? Icons.visibility_off :  Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirmText = !_obscureConfirmText),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _passController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Reset Password", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final List<String> bloodType = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> barangay = [
    "Alipit", "Bagumbayan", "Bubukal", "Calios", "Duhat", "Gatid", "Jasaan",
    "Labuin", "Malinao", "Oogong", "Pagsawitan", "Palasan", "Patimbao",
    "Barangay I", "Barangay II", "Barangay III", "Barangay IV", "Barangay V",
    "San Jose", "San Juan", "San Pablo Norte", "San Pablo Sur",
    "Santisima Cruz", "Santo Angel Central", "Santo Angel Norte", "Santo Angel Sur"
  ];
  final List<String> userType = ['Donor', 'Recipient'];

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  String _selectedBloodType = 'A+';
  String _selectedBarangay = 'Alipit';
  String _selectedUserType = 'Donor';

  @override

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }



  // --- UPDATED SIGN UP FUNCTION TO SHOW VERIFICATION DIALOG ---
  void _signUp() async {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      setState(() {
        _isLoading = true;
      });

      try {
        final bool isDonor = _selectedUserType == 'Donor';

        final Map<String, dynamic> userData = {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'phone': _phoneController.text.trim(),
          'bloodType': _selectedBloodType,
          'barangay': _selectedBarangay,
          'isDonor': isDonor,
        };

        final result = await ApiService.register(userData);

        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          // 🎉 SHOW VERIFICATION DIALOG
          showDialog(
            context: context,
            barrierDismissible: false, // User must tap OK
            builder: (BuildContext context) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.mark_email_read, color: Color(0xFFEF4444)),
                    SizedBox(width: 8),
                    Text('Verify Email'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account created successfully!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('We have sent a verification link to:'),
                    SizedBox(height: 4),
                    Text(
                      _emailController.text,
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Please verify your email to log in.',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Go back to Login Page
                    },
                    child: Text(
                      'Back to Login',
                      style: TextStyle(color: Color(0xFFEF4444)),
                    ),
                  ),
                ],
              );
            },
          );
        } else {
          String errorMessage = result['error'] ?? 'Unknown error occurred';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $errorMessage'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showConfirmationDialog() {
    // 1. Validate Form First
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // 2. Validate Terms
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Helper to Capitalize Name (e.g. "juan" -> "Juan")
    String formatName(String text) {
      if (text.isEmpty) return text;
      return text.split(' ').map((word) => word.isNotEmpty
          ? '${word[0].toUpperCase()}${word.substring(1)}'
          : '').join(' ');
    }

    // 3. Show Warning Dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text(
              "Confirm Details",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Please review your details carefully.",
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Once registered, you CANNOT edit your Name, Email, or Blood Type.",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Divider(),
              // Apply formatting here
              _buildConfirmRow("First Name:", formatName(_firstNameController.text)),
              _buildConfirmRow("Last Name:", formatName(_lastNameController.text)),
              _buildConfirmRow("Blood Type:", _selectedBloodType),
              _buildConfirmRow("Email:", _emailController.text),
              Divider(),
              SizedBox(height: 8),
              Text(
                "Is this information correct?",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(), // Close dialog
            child: Text(
              "Edit",
              style: GoogleFonts.poppins(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              _signUp(); // Proceed to Sign Up
            },
            child: Text(
              "Yes, Proceed",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for the dialog rows
  Widget _buildConfirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              SizedBox(height: 20),

              // Back Button and Header
              _buildHeader(),

              SizedBox(height: 24),

              // Sign Up Form
              _buildSignUpForm(),

              SizedBox(height: 20),

              // Terms and Conditions
              _buildTermsCheckbox(),

              SizedBox(height: 24),

              // Sign Up Button
              _buildSignUpButton(),

              SizedBox(height: 24),

              // Login Link
              _buildLoginLink(),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Back Button
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),

        SizedBox(height: 20),

        // Hospital Logo Container
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(
              'assets/LDH (2).jpg',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback in case image fails to load
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medical_services,
                      size: 40,
                      color: Colors.blue.shade700,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'LDH',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        SizedBox(height: 20),

        Text(
          'BloodiFind',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),

        SizedBox(height: 8),

        Text(
          'Join Laguna Doctors Hospital',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          SizedBox(height: 16),

          // User Type Dropdown (Donor/Recipient)
          DropdownButtonFormField<String>(
            value: _selectedUserType,
            decoration: InputDecoration(
              labelText: 'I want to be a',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(Icons.person_pin),
            ),
            items: userType.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedUserType = value!;
              });
            },
          ),

          SizedBox(height: 16),

          // First Name Field
          TextFormField(
            controller: _firstNameController,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'First Name',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your first name';
              }
              if (value.length < 2) {
                return 'Name must be at least 2 characters';
              }
              // Regex: Allows only alphabets (a-z, A-Z) and spaces.
              // Rejects numbers and special characters.
              if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
                return 'Name must contain only letters';
              }
              return null;
            },
          ),

          SizedBox(height: 16),

          // Last Name Field
          TextFormField(
            controller: _lastNameController,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Last Name',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your last name';
              }
              if (value.length < 2) {
                return 'Name must be at least 2 characters';
              }
              // Regex: Allows only alphabets (a-z, A-Z) and spaces.
              if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
                return 'Name must contain only letters';
              }
              return null;
            },
          ),

          SizedBox(height: 16),

          // Blood Type Dropdown
          DropdownButtonFormField<String>(
            value: _selectedBloodType,
            decoration: InputDecoration(
              labelText: 'Blood Type',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(Icons.bloodtype),
            ),
            items: bloodType.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBloodType = value!;
              });
            },
          ),

          SizedBox(height: 16),

          // Barangay Dropdown
          DropdownButtonFormField<String>(
            value: _selectedBarangay,
            decoration: InputDecoration(
              labelText: 'Barangay',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(Icons.house_outlined),
            ),
            items: barangay.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBarangay = value!;
              });
            },
          ),

          SizedBox(height: 16),

          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),

          SizedBox(height: 16),

          // Phone Field
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.number, // Numerical keyboard
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // Only allows 0-9
              LengthLimitingTextInputFormatter(11), // Stops input at 11 characters
            ],
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: '(PH) 09', // Helpful hint
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              if (value.length != 11) {
                return 'Phone number must be exactly 11 digits';
              }
              if (!value.startsWith('09')) {
                return 'Must start with 09 (Philippine format)';
              }
              return null;
            },
          ),

          SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey.shade600,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              // Regex: At least one UPPERCASE, one number, one special char (including underscore)
              if (!RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~_]).+$').hasMatch(value)) {
                return 'Must contain:\n- 1 Upper\n- 1 Number\n- 1 Special Character (!@#\$&*~_)';
              }
              return null;
            },
          ),

          SizedBox(height: 16),

// Confirm Password Field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey.shade600,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (value) {
            setState(() {
              _agreeToTerms = value!;
            });
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          activeColor: Colors.blue.shade700,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              children: [
                Text(
                  'I agree to the ',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TermsAndConditionsScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Terms of Service',
                    style: GoogleFonts.poppins(
                      color: Colors.blue.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  ' and ',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PrivacyPolicyScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Privacy Policy',
                    style: GoogleFonts.poppins(
                      color: Colors.blue.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        // CHANGED: Call the confirmation dialog instead of direct sign up
        onPressed: _isLoading ? null : _showConfirmationDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Text(
          'Create Account',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account?",
          style: GoogleFonts.poppins(
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(width: 4),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
          ),
          child: Text(
            'Sign In',
            style: GoogleFonts.poppins(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class MainApp extends StatefulWidget {
  final String userId;

  const MainApp({super.key, required this.userId});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      HomeScreen(),
      MapScreen(),
      ProfileScreen(), // Remove userId parameter
    ];

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFFEF4444),
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Home Screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedBloodType = 'All';
  List<Donor> _donors = [];
  List<Donor> _filteredDonors = [];
  bool _isLoading = true;
  Timer? _timer; // 2. Add Timer variable

  final List<String> bloodTypes = [
    'All', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    // 3. Initial Load (shows loading spinner)
    _loadDonors(refresh: false);

    // 4. Start Auto-Refresh Timer (e.g., every 5 seconds)
    // using 'refresh: true' to update silently in the background
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _loadDonors(refresh: true);
    });

    _searchController.addListener(_filterDonors);
  }

  @override
  void dispose() {
    // 5. Cancel timer to stop updates when leaving this screen
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Modified to handle background refreshing
  Future<void> _loadDonors({bool refresh = false}) async {
    if (!refresh) {
      // Only show full loading spinner on initial load or manual pull-to-refresh
      print('🔄 Loading ALL users (donors & recipients)...');
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final result = await ApiService.getDonors();

      if (!mounted) return; // Prevent setting state if widget is disposed

      if (result['success']) {
        final innerData = result['data'];

        if (innerData is Map && innerData['success'] == true) {
          final donorsData = innerData['data'];

          if (donorsData is List) {
            final List<Donor> loadedDonors = [];

            for (var i = 0; i < donorsData.length; i++) {
              final data = donorsData[i];
              try {
                final donor = Donor.fromJson(data);
                loadedDonors.add(donor);
              } catch (e) {
                print('❌ Error converting user $i: $e');
              }
            }

            final activeDonors = loadedDonors.where((d) => !d.isArchived).toList();

            setState(() {
              _donors = activeDonors;

              if (refresh) {
                // If this is a background refresh, we re-apply the *current* filters
                // so the user's search results don't suddenly disappear or reset.
                _reapplyFiltersLocally();
              } else {
                // On initial load, just show everything
                _filteredDonors = activeDonors;
              }

              _isLoading = false;
            });
          }
        }
      } else {
        if (!refresh) {
          // Only show error snackbar on manual actions, not background loops
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load users: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('💥 Exception in _loadDonors: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper to re-run filter logic inside the same setState call during updates
  void _reapplyFiltersLocally() {
    List<Donor> filtered = List.from(_donors);

    // Filter by blood type
    if (_selectedBloodType != 'All') {
      filtered = filtered.where((donor) => donor.bloodType == _selectedBloodType).toList();
    }

    // Filter by search text
    if (_searchController.text.isNotEmpty) {
      final searchLower = _searchController.text.toLowerCase();
      filtered = filtered.where((donor) =>
      donor.userNumber.toLowerCase().contains(searchLower) ||
          donor.bloodType.toLowerCase().contains(searchLower) ||
          (donor.barangay.toLowerCase().contains(searchLower))
      ).toList();
    }

    _filteredDonors = filtered;
  }

  void _filterDonors() {
    // Standard filter method triggered by user input
    setState(() {
      _reapplyFiltersLocally();
    });
  }

  void _onBloodTypeSelected(String? type) {
    if (type != null) {
      setState(() {
        _selectedBloodType = type;
      });
      _filterDonors();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'BloodiFind',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Color(0xFFEF4444),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.message_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ConversationsScreen()),
              );
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _buildContent(),
    );
  }

  // ... (Keep your _buildLoadingState, _buildContent, _buildResultsHeader, _buildEmptyState methods exactly as they were) ...

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading users from database...',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find Blood Donors',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Emergency blood donations made simple',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by blood type or location',
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF000000)),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                width: 50,
                child: DropdownButtonFormField<String>(
                  value: _selectedBloodType,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF000000)),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  icon: Icon(
                    Icons.filter_list,
                    color: Colors.grey.shade600,
                    size: 25,
                  ),
                  items: bloodTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(
                        type,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: _onBloodTypeSelected,
                  isExpanded: false,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildResultsHeader(),
          SizedBox(height: 16),
          Expanded(
            child: _filteredDonors.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: () => _loadDonors(refresh: false), // Pull-to-refresh
              child: ListView.builder(
                itemCount: _filteredDonors.length,
                itemBuilder: (context, index) {
                  final donor = _filteredDonors[index];
                  return DonorCard(donor: donor);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_filteredDonors.length} User${_filteredDonors.length != 1 ? 's' : ''} Found',
          style: GoogleFonts.poppins(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        if (_selectedBloodType != 'All' || _searchController.text.isNotEmpty) ...[
          SizedBox(height: 4),
          Text(
            _buildFilterDescription(),
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  String _buildFilterDescription() {
    final filters = [];
    if (_selectedBloodType != 'All') {
      filters.add('Blood type: $_selectedBloodType');
    }
    if (_searchController.text.isNotEmpty) {
      filters.add('Search: "${_searchController.text}"');
    }
    return filters.join(' • ');
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              _donors.isEmpty ? 'No donors in database' : 'No matching donors found',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                _donors.isEmpty
                    ? 'There are no donors registered in the system yet.'
                    : 'Try adjusting your search or blood type filter',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            SizedBox(height: 16),
            if (_donors.isEmpty)
              ElevatedButton(
                onPressed: () => _loadDonors(refresh: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Refresh',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  // Data
  List<dynamic> _allConversations = [];
  List<dynamic> _filteredConversations = [];
  bool _isLoading = true;
  String? _currentUserId;
  Timer? _timer; // 2. Add Timer variable

  // Filter State
  final TextEditingController _searchController = TextEditingController();
  String _selectedRoleFilter = 'All'; // 'All', 'Donor', 'Recipient'

  @override
  void initState() {
    super.initState();
    // 3. Initial load (shows spinner)
    _loadConversations(refresh: false);

    // 4. Start Auto-Refresh Timer (e.g., every 5 seconds)
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _loadConversations(refresh: true);
    });

    _searchController.addListener(_filterList);
  }

  @override
  void dispose() {
    // 5. Cancel timer to stop updates when leaving this screen
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // 6. Modified to support silent background refreshing
  Future<void> _loadConversations({bool refresh = false}) async {
    // 1. Ensure we have current user ID
    if (_currentUserId == null) {
      final profile = await ApiService.getProfile(userId: '0');
      if (profile['success']) {
        final d = (profile['data'] is Map && profile['data']['data'] != null)
            ? profile['data']['data']
            : profile['data'];
        _currentUserId = d['id'].toString();
      }
    }

    if (!refresh) {
      setState(() {
        _isLoading = true;
      });
    }

    // 2. Fetch Conversations
    final result = await ApiService.getConversations();

    if (!mounted) return;

    if (result['success']) {
      final inner = result['data'];
      setState(() {
        // The server returns a list directly now, so adjust parsing
        _allConversations = (inner is List) ? inner : (inner is Map && inner['data'] is List) ? inner['data'] : [];
        _isLoading = false;
        _filterList(); // Apply filters immediately
      });
    } else {
      if (!refresh) {
        // Only show error on initial load, not during background refresh
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load chats: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // --- 🔍 FILTERING LOGIC ---
  void _filterList() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredConversations = _allConversations.where((chat) {
        // 1. Search Logic
        final name = (chat['display_name'] ?? '').toString().toLowerCase();
        final msg = (chat['last_message'] ?? '').toString().toLowerCase();
        final matchesSearch = name.contains(query) || msg.contains(query);

        // 2. Role/Status Filter Logic
        bool matchesFilter = true;

        final rawIsDonor = chat['is_donor'];
        // Check if role is Donor (server sends 1, true, or '1' string)
        final bool isDonor = (rawIsDonor == 1 || rawIsDonor == true || rawIsDonor.toString() == '1');

        // Check read status
        final bool isRead = chat['is_read'] == 1 || chat['is_read'] == true;
        final String senderId = chat['sender_id'].toString();
        // You are the sender if your ID matches the sender_id
        final bool amISender = senderId == _currentUserId;

        if (_selectedRoleFilter == 'Donor') {
          matchesFilter = isDonor;
        } else if (_selectedRoleFilter == 'Recipient') {
          matchesFilter = !isDonor;
        } else if (_selectedRoleFilter == 'Unread') {
          // Show only if I am NOT the sender AND it is NOT read
          matchesFilter = !amISender && !isRead;
        }

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _showChatOptions(String otherUserId, String originalName, String? currentNickname, String bloodType) {
    // Determine the display name
    final displayName = currentNickname ?? originalName;

    // Blood type color mapping
    final Map<String, Color> bloodColors = {
      "O+": Color(0xFFFF3B30), "O-": Color(0xFFCC2E27),
      "A+": Color(0xFFFF6633), "A-": Color(0xFFCC5326),
      "B+": Color(0xFFFF9966), "B-": Color(0xFFCC7A4D),
      "AB+": Color(0xFFFFCC99), "AB-": Color(0xFFCC9966),
    };
    final Color bgColor = bloodColors[bloodType] ?? Colors.red.shade100;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)],
          ),
          padding: EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40, height: 4,
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),

              // User Profile Preview
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: bgColor,
                    child: Text(
                      bloodType,
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (currentNickname != null)
                          Text(
                            "Original: $originalName",
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(height: 30),

              // Actions
              _buildActionTile(
                icon: Icons.edit_note_rounded,
                color: Colors.blue.shade600,
                title: 'Set Nickname',
                subtitle: 'Change how you see this user',
                onTap: () {
                  Navigator.pop(context);
                  _showNicknameDialog(
                      otherUserId,
                      displayName, // Current text displayed
                      originalName // The actual name from the DB (e.g. "John")
                  );
                },
              ),
              SizedBox(height: 10),
              _buildActionTile(
                icon: Icons.inventory_2_outlined,
                color: Colors.orange.shade700,
                title: 'Archive Chat',
                subtitle: 'Hide from your inbox',
                onTap: () async {
                  Navigator.pop(context);
                  await ApiService.archiveConversation(otherUserId);
                  _loadConversations(refresh: true); // Use refresh: true
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Conversation archived")));
                },
              ),
              SizedBox(height: 10),
              _buildActionTile(
                icon: Icons.delete_forever_rounded,
                color: Colors.red.shade400,
                title: 'Clear History',
                subtitle: 'Delete messages for you',
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(otherUserId);
                },
              ),
              SizedBox(height: 10),
              _buildActionTile(
                icon: Icons.report_problem_rounded,
                color: Colors.red.shade900,
                title: 'Report User',
                subtitle: 'Spam, harassment, etc.',
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog(otherUserId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showNicknameDialog(String partnerId, String currentDisplayName, String originalName) {
    final controller = TextEditingController(text: currentDisplayName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFFEF4444).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.edit_note_rounded, color: Color(0xFFEF4444)),
            ),
            SizedBox(width: 12),
            Text("Set Nickname", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show the original name for context
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0, left: 4),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(color: Colors.black, fontSize: 12),
                  children: [
                    TextSpan(text: "Original Name: "),
                    TextSpan(
                      text: originalName,
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),

            // Input Field
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                hintText: "Enter a custom name",
                prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFEF4444), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. RESET BUTTON (Clear Nickname)
              TextButton.icon(
                onPressed: () async {
                  await ApiService.setNickname(partnerId, "");
                  Navigator.pop(ctx);
                  _loadConversations(refresh: true); // Use refresh: true
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Nickname reset to original")),
                  );
                },
                icon: Icon(Icons.restore, size: 18, color: Colors.grey),
                label: Text("Reset", style: GoogleFonts.poppins(color: Colors.black)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),

              // Right-side actions (Cancel & Save)
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.red)),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final newNickname = controller.text.trim();
                      await ApiService.setNickname(partnerId, newNickname);
                      Navigator.pop(ctx);
                      _loadConversations(refresh: true); // Use refresh: true
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      elevation: 0,
                    ),
                    child: Text(
                      "Save",
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String partnerId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete Conversation?"),
        content: Text("This will clear the message history for you. This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel")),
          TextButton(
            onPressed: () async {
              await ApiService.deleteConversation(partnerId);
              Navigator.pop(ctx);
              _loadConversations(refresh: true); // Use refresh: true
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  void _showReportDialog(String partnerId) {
    String selectedReason = 'Harassment';
    final descController = TextEditingController();
    final reasons = ['Harassment', 'Spam', 'Inappropriate Content', 'Fake Account', 'Other'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Report User"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedReason,
                items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => selectedReason = v!),
                decoration: InputDecoration(labelText: "Reason"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(hintText: "Additional details...", border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await ApiService.reportUser(partnerId, selectedReason, descController.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Report submitted")));
              },
              child: Text("Submit", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Messages', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
        actions: [
          // 📦 ARCHIVE ICON
          IconButton(
            icon: Icon(Icons.inventory_2_outlined, color: Colors.black),
            tooltip: 'Archived Chats',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ArchivedChatsScreen()),
              ).then((_) => _loadConversations(refresh: true)); // Refresh when returning
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // --- SEARCH & FILTERS ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search name or message...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', Colors.green),
                      SizedBox(width: 8),
                      _buildFilterChip('Donor', Color(0xFFEF4444)),
                      SizedBox(width: 8),
                      _buildFilterChip('Recipient', Colors.blue),
                      SizedBox(width: 8),
                      _buildFilterChip('Unread', Colors.orange), // Added Here
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),

          // --- LIST VIEW ---
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredConversations.isEmpty
                ? Center(child: Text("No conversations found", style: GoogleFonts.poppins(color: Colors.grey)))
                : ListView.builder(
              itemCount: _filteredConversations.length,
              itemBuilder: (context, index) {
                final chat = _filteredConversations[index];
                return _buildChatTile(chat);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build chips
  Widget _buildFilterChip(String label, Color activeColor) {
    final isSelected = _selectedRoleFilter == label;

    return ChoiceChip(
      label: Text(label),
      // Dynamic label style: White text when selected, Black when not
      labelStyle: GoogleFonts.poppins(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedRoleFilter = label;
          _filterList();
        });
      },
      // Uses the passed specific color when selected
      selectedColor: activeColor,
      backgroundColor: Colors.grey.shade100,
      // Removes the default checkmark to keep it looking clean like a button
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        // Optional: Add a colored border when selected
        side: BorderSide(
          color: isSelected ? activeColor : Colors.transparent,
          width: 1,
        ),
      ),
    );
  }

  // Extracted tile builder for cleanliness
  Widget _buildChatTile(dynamic chat) {
    final rawOtherId = chat['other_user_id'];
    final otherUserId = (rawOtherId != null) ? rawOtherId.toString() : '0';

    // --- 1. NAME FORMATTING LOGIC ---
    // Get first name only
    String rawFirstName = (chat['first_name'] ?? '').toString().trim();



    // Capitalize First Name (e.g., "john" -> "John", "MARY" -> "Mary")
    final String formattedFirstName = rawFirstName.isNotEmpty
        ? rawFirstName.split(' ').map((word) => word.isNotEmpty
        ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
        : '').join(' ')
        : 'User';

    final String bType = chat['blood_type'] ?? 'O+';

    // --- 2. DISPLAY LOGIC ---
    // If a nickname exists, use it. Otherwise, use ONLY the formatted First Name.
    // We ignore chat['display_name'] here because the server defaults it to "First Last".
    final String displayName = (chat['nickname'] != null && chat['nickname'].toString().isNotEmpty)
        ? chat['nickname']
        : formattedFirstName;
    // ---------------------------

    final lastMsg = chat['last_message'];
    final isRead = chat['is_read'] == 1 || chat['is_read'] == true;
    final senderId = chat['sender_id'].toString();
    final bool amISender = senderId == _currentUserId;
    final bool isUnread = !amISender && !isRead;

    // Blood Colors
    final Map<String, Color> bloodColors = {
      "O+": Color(0xFFFF3B30), "O-": Color(0xFFCC2E27),
      "A+": Color(0xFFFF6633), "A-": Color(0xFFCC5326),
      "B+": Color(0xFFFF9966), "B-": Color(0xFFCC7A4D),
      "AB+": Color(0xFFFFCC99), "AB-": Color(0xFFCC9966),
    };

    final Color bgColor = bloodColors[bType] ?? Colors.red.shade100;
    final Color textColor = bloodColors.containsKey(bType) ? Colors.white : Colors.red;


    return ListTile(
      leading: CircleAvatar(
        backgroundColor: bgColor,
        child: Text(
          bType,
          style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold
          ),
        ),
      ),
      title: Text(
        displayName,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        amISender ? "You: $lastMsg" : lastMsg,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal),
      ),
      trailing: isUnread ? Icon(Icons.circle, color: Colors.red, size: 10) : null,
      onLongPress: () {
        // Pass the formatted First Name (not the nickname) to the options menu
        _showChatOptions(otherUserId, formattedFirstName, chat['nickname'], bType);
      },
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              otherUserId: otherUserId,
              otherUserName: displayName,
              otherUserBloodType: bType, // Passing the argument
            ),
          ),
        ).then((_) => _loadConversations(refresh: true)); // Refresh when returning
      },
    );
  }
}

class ArchivedChatsScreen extends StatefulWidget {
  const ArchivedChatsScreen({super.key});

  @override
  State<ArchivedChatsScreen> createState() => _ArchivedChatsScreenState();
}

class _ArchivedChatsScreenState extends State<ArchivedChatsScreen> {
  List<dynamic> _archivedChats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArchives();
  }

  Future<void> _loadArchives() async {
    final result = await ApiService.getArchivedConversations();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          final inner = result['data'];
          _archivedChats = (inner is Map) ? inner['data'] : (inner is List ? inner : []);
        }
      });
    }
  }

  Future<void> _unarchive(String partnerId) async {
    setState(() => _isLoading = true);
    await ApiService.unarchiveConversation(partnerId);
    await _loadArchives(); // Reload list
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Conversation restored to inbox")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Archived Chats', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _archivedChats.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
            SizedBox(height: 16),
            Text("No archived chats", style: GoogleFonts.poppins(color: Colors.grey)),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _archivedChats.length,
        itemBuilder: (context, index) {
          final chat = _archivedChats[index];

          // --- UPDATED NAME LOGIC ---
          // 1. Get raw first name
          String rawFirstName = (chat['first_name'] ?? '').toString().trim();

          // 2. Format: Remove Last Name & Capitalize (Title Case)
          final name = rawFirstName.isNotEmpty
              ? rawFirstName.split(' ').map((word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '').join(' ')
              : 'User';
          // ---------------------------

          final msg = chat['last_message'] ?? '';
          final partnerId = chat['other_user_id'].toString();
          final bType = chat['blood_type'] ?? 'O+';

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade400, // Grey to indicate archive
              child: Text(bType, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: Text(
              name, // Display the formatted First Name
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey.shade800),
            ),
            subtitle: Text(msg, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: Icon(Icons.unarchive, color: Colors.blue),
              onPressed: () => _unarchive(partnerId),
              tooltip: 'Unarchive',
            ),
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserBloodType;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserBloodType,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _currentUserId;
  Timer? _timer;
  bool _isSending = false;

  String _currentUserRole = 'Recipient';
  String _partnerRole = 'Donor';

  List<dynamic> _donationRequests = [];

  // Define the strong color map
  final Map<String, Color> _bloodColors = {
    "O+": const Color(0xFFFF3B30), "O-": const Color(0xFFCC2E27),
    "A+": const Color(0xFFFF6633), "A-": const Color(0xFFCC5326),
    "B+": const Color(0xFFFF9966), "B-": const Color(0xFFCC7A4D),
    "AB+": const Color(0xFFFFCC99), "AB-": const Color(0xFFCC9966),
  };

  @override
  void initState() {
    super.initState();
    _checkUserRoles().then((_) {
      _loadMessages();
      _loadDonationRequests();

      _timer = Timer.periodic(Duration(seconds: 3), (timer) {
        if (!_isSending) {
          _loadMessages(isBackground: true);
          _loadDonationRequests(isBackground: true);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Helper to get color (Uses the partner's blood type)
  Color _getBloodTypeColor(String? bloodType) {
    if (bloodType == null || bloodType.isEmpty) return Colors.grey;
    return _bloodColors[bloodType.toUpperCase().trim()] ?? Colors.grey;
  }

  // FIX: Helper to reliably determine role from raw data (is_donor)
  String _determineRole(dynamic rawIsDonor) {
    if (rawIsDonor == null) return 'Recipient';

    final value = rawIsDonor.toString().toLowerCase().trim();

    // The server sends the string 'Donor', 'Recipient', or potentially a legacy 'true'/'1'
    if (value == 'donor' || value == 'true' || value == '1') {
      return 'Donor';
    }
    return 'Recipient';
  }

  Future<void> _checkUserRoles() async {
    String currentRole = 'Recipient';
    String partnerRole = 'Donor';

    // 1. Get Current User's Role (Standard profile endpoint)
    if (_currentUserId == null) {
      final profile = await ApiService.getProfile(userId: '0');
      if (profile['success']) {
        final profileData = profile['data'];
        final userData = (profileData is Map && profileData.containsKey('data'))
            ? profileData['data']
            : profileData;

        if (userData != null && userData['id'] != null) {
          _currentUserId = userData['id'].toString();
        }

        currentRole = _determineRole(userData['is_donor']);
      }
    }

    // 2. Get Other User's Role (The primary fix area: uses /api/users/:id)
    final partnerResult = await ApiService.getOtherUserProfile(widget.otherUserId);

    if (partnerResult['success'] && partnerResult['data'] != null) {
      // CRITICAL REFINEMENT: Safely extract the data, handling nested structures if any.
      final rawData = partnerResult['data'];

      // Check if the actual user data is nested under 'data' key or if it's the top level.
      final Map<String, dynamic> partnerData = (rawData is Map)
          ? (rawData.containsKey('data') && rawData['data'] is Map)
          ? rawData['data'] as Map<String, dynamic>
          : rawData as Map<String, dynamic>
          : {};

      // Get the is_donor value from the determined data map
      final rawIsDonor = partnerData['is_donor'];

      // Now use the robust helper function
      partnerRole = _determineRole(rawIsDonor);

      // Optional: Print to verify the value being read before conversion
      print('DEBUG: Partner Data Map keys: ${partnerData.keys}');
      print('DEBUG: Raw is_donor value extracted: $rawIsDonor');
    }

    if (mounted) {
      setState(() {
        _currentUserRole = currentRole;
        _partnerRole = partnerRole;
      });
      print('DEBUG: Current Role: $_currentUserRole, Partner Role: $_partnerRole');
    }
  }

  Future<void> _loadMessages({bool isBackground = false}) async {
    try {
      if (_currentUserId == null) {
        final profile = await ApiService.getProfile(userId: '0');
        if (profile['success']) {
          final profileData = profile['data'];
          final userData = (profileData is Map && profileData.containsKey('data'))
              ? profileData['data']
              : profileData;

          if (userData != null && userData['id'] != null) {
            setState(() {
              _currentUserId = userData['id'].toString();
            });
          }
        }
      }

      final result = await ApiService.getChatHistory(widget.otherUserId);

      if (result['success']) {
        final innerResponse = result['data'];
        List<dynamic> rawData = [];
        if (innerResponse is Map && innerResponse['data'] is List) {
          rawData = innerResponse['data'];
        } else if (innerResponse is List) {
          rawData = innerResponse;
        }

        if (mounted) {
          final loadedMessages = rawData.map((json) => ChatMessage.fromJson(json)).toList();

          bool shouldScroll = false;
          if (loadedMessages.isNotEmpty && _messages.isNotEmpty) {
            final lastNewId = loadedMessages.last.id;
            final lastOldId = _messages.last.id;
            shouldScroll = lastNewId > lastOldId;
          } else if (loadedMessages.isNotEmpty && _messages.isEmpty) {
            shouldScroll = true;
          }


          setState(() {
            _messages = loadedMessages;
            _isLoading = false;
          });

          if (shouldScroll) {
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      print("Chat load error: $e");
      if (mounted && !isBackground) setState(() => _isLoading = false);
    }
  }

  String _formatTime(DateTime date) {
    String hour = (date.hour > 12 ? date.hour - 12 : date.hour).toString();
    if (date.hour == 0) hour = "12";
    String minute = date.minute.toString().padLeft(2, '0');
    String period = date.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    if (_currentUserId == null) {
      await _loadMessages();
      if (_currentUserId == null) return;
    }

    setState(() => _isSending = true);

    final text = _messageController.text;
    _messageController.clear();

    final tempId = DateTime.now().millisecondsSinceEpoch;
    final int senderIdInt = int.tryParse(_currentUserId ?? '0') ?? 0;
    final int receiverIdInt = int.tryParse(widget.otherUserId) ?? 0;

    final tempMsg = ChatMessage(
      id: tempId,
      senderId: senderIdInt,
      receiverId: receiverIdInt,
      message: text,
      createdAt: DateTime.now(),
      isRead: false,
      status: MessageStatus.sending,
    );

    setState(() {
      _messages.add(tempMsg);
    });
    _scrollToBottom();

    try {
      final result = await ApiService.sendMessage(widget.otherUserId, text);

      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == tempId);
          if (index != -1) {
            if (result['success'] == true) {
              final responseBody = result['data'];
              final serverData = responseBody != null ? responseBody['data'] : null;
              final int realId = serverData != null && serverData['id'] != null
                  ? (serverData['id'] is int ? serverData['id'] : int.tryParse(serverData['id'].toString()) ?? tempId)
                  : tempId;

              final String? createdAtStr = serverData != null ? serverData['created_at'] : null;
              final DateTime realTime = createdAtStr != null
                  ? (DateTime.tryParse(createdAtStr) ?? DateTime.now())
                  : DateTime.now();

              _messages[index] = ChatMessage(
                id: realId,
                senderId: senderIdInt,
                receiverId: receiverIdInt,
                message: text,
                createdAt: realTime,
                isRead: false,
                status: MessageStatus.sent,
              );
            } else {
              _messages[index] = ChatMessage(
                id: tempId,
                senderId: senderIdInt,
                receiverId: receiverIdInt,
                message: text,
                createdAt: DateTime.now(),
                isRead: false,
                status: MessageStatus.notSent,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Failed to send: ${result['error']}")),
              );
            }
          }
        });
      }
    } catch (e) {
      print("Error sending message: $e");
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildChatHead(String? bloodType, {double size = 34, double fontSize = 14}) {
    final effectiveBloodType = (bloodType != null && bloodType.isNotEmpty)
        ? bloodType
        : widget.otherUserBloodType;

    if (effectiveBloodType.isEmpty) {
      return SizedBox.shrink();
    }

    final color = _getBloodTypeColor(effectiveBloodType);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Text(
        effectiveBloodType,
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _loadDonationRequests({bool isBackground = false}) async {
    try {
      final result = await ApiService.getDonationRequestsByChat(widget.otherUserId);
      if (result['success'] && mounted) {
        final rawData = result['data'];

        List<dynamic> loadedRequests = [];
        if (rawData is List) {
          loadedRequests = rawData;
        } else if (rawData is Map && rawData['data'] is List) {
          loadedRequests = rawData['data'];
        }

        setState(() {
          _donationRequests = loadedRequests;
        });
        if (!isBackground) print('Loaded ${_donationRequests.length} donation requests.');
      }
    } catch (e) {
      print('Error loading donation requests: $e');
    }
  }


  void _onMenuSelect(String value) {
    Navigator.pop(context); // Close menu
    if (value == 'request_donation') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RequestDonationScreen(
            otherUserId: widget.otherUserId,
            otherUserName: widget.otherUserName,
            bloodType: widget.otherUserBloodType,
          ),
        ),
      ).then((needsRefresh) {
        if (needsRefresh == true) {
          _loadMessages();
          _loadDonationRequests();
        }
      });
    }
  }

  Future<void> _handleRequestAction(String requestId, String action) async {
    final result = await ApiService.updateDonationRequest(requestId, action);
    if (mounted) {
      if (result['success']) {

        // FIX: Extract the newStatus from the server response, falling back to the action name
        // The server sends 'newStatus' on all successful status updates.
        final String statusToDisplay = result['newStatus']?.toString() ?? action;

        ScaffoldMessenger.of(context).showSnackBar;
        _loadMessages();
        _loadDonationRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canRequest = _currentUserRole == 'Recipient' && _partnerRole == 'Donor';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            _buildChatHead(widget.otherUserBloodType),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.otherUserName.isNotEmpty
                    ? widget.otherUserName.split(' ').map((word) => word.isNotEmpty
                    ? '${word[0].toUpperCase()}${word.substring(1)}'
                    : '').join(' ')
                    : 'User',
                style: GoogleFonts.poppins(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _onMenuSelect,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'request_donation',
                enabled: canRequest,
                child: Text(
                  'Request Blood Donation',
                  style: GoogleFonts.poppins(
                      color: canRequest ? Colors.black : Colors.grey,
                      fontWeight: FontWeight.w500
                  ),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'block_user',
                child: Text('Block User', style: GoogleFonts.poppins(color: Colors.red)),
              ),
            ],
            icon: Icon(Icons.more_vert, color: Colors.black),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildActiveRequestCard(),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg.senderId.toString() == _currentUserId;

                Widget messageBubbleColumn = Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFFEF4444) : Colors.grey.shade200,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                          bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                        ),
                      ),
                      child: Text(
                        msg.message,
                        style: GoogleFonts.poppins(
                          color: isMe ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(msg.createdAt),
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            _buildStatusIcon(msg.status),
                          ]
                        ],
                      ),
                    ),
                  ],
                );

                if (isMe) {
                  return Align(alignment: Alignment.centerRight, child: messageBubbleColumn);
                } else {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, right: 8.0),
                          child: _buildChatHead(widget.otherUserBloodType, size: 30, fontSize: 12),
                        ),
                        Flexible(child: messageBubbleColumn),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFFEF4444),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FIX: Corrected _buildActiveRequestCard to resolve the Undefined Name error
  Widget _buildActiveRequestCard() {
    final activeRequest = _donationRequests.firstWhere(
          (r) => r['status'] == 'Pending' || r['status'] == 'Ongoing',
      orElse: () => null,
    );

    if (activeRequest == null) return const SizedBox.shrink();

    final requestId = activeRequest['id'].toString();
    final status = activeRequest['status'];
    final notes = activeRequest['notes'] ?? 'No additional notes.';
    final bloodType = activeRequest['blood_type'];
    final requesterId = activeRequest['requester_id'].toString();
    final isRequester = requesterId == _currentUserId;
    final isDonor = requesterId != _currentUserId;

    String statusText;
    Color statusColor;

    if (status == 'Pending') {
      statusText = isRequester ? 'Waiting for Donor acceptance' : 'Action Required';
      statusColor = Colors.orange;

      // Card for Pending Status
      return Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🩸 Blood Request: ${bloodType}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                  ),
                )
              ],
            ),
            SizedBox(height: 8),
            Text(
              notes,
              style: GoogleFonts.poppins(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12),

            // --- ACTION BUTTONS for Pending Status ---
            if (isDonor)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton('Decline', () => _handleRequestAction(requestId, 'Decline'), Colors.grey),
                  SizedBox(width: 8),
                  _buildActionButton('Accept', () => _handleRequestAction(requestId, 'Accept'), Colors.green),
                ],
              )
            else if (isRequester)
              Align(
                alignment: Alignment.centerRight,
                child: _buildActionButton('Cancel', () => _handleRequestAction(requestId, 'Cancel'), Colors.red),
              ),
          ],
        ),
      );

    } else if (status == 'Ongoing') {
      // FIX: Correctly declare isCompletedByMe inside the scope
      final bool isCompletedByMe = isRequester
          ? activeRequest['requester_completed'] == 1
          : activeRequest['donor_completed'] == 1;

      statusText = isCompletedByMe ? 'Waiting for other party to complete' : 'Donation is ongoing';
      statusColor = Colors.blue;

      // Card for Ongoing Status
      return Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🩸 Blood Request: ${bloodType}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                  ),
                )
              ],
            ),
            SizedBox(height: 8),
            Text(
              notes,
              style: GoogleFonts.poppins(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12),

            // --- ACTION BUTTONS for Ongoing Status ---
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton('Cancel', () => _handleRequestAction(requestId, 'Cancel'), Colors.red),
                SizedBox(width: 8),
                _buildActionButton(
                  isCompletedByMe ? 'Waiting...' : 'Complete',
                  isCompletedByMe ? null : () => _handleRequestAction(requestId, 'Complete'),
                  Colors.blue,
                ),
              ],
            )
          ],
        ),
      );
    }

    // Fallback for any other status (Cancelled, Declined, Completed)
    return const SizedBox.shrink();
  }

  Widget _buildActionButton(String label, VoidCallback? onTap, Color color) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: Size(0, 36)
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1, color: Colors.grey));
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 12, color: Colors.grey);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 12, color: Colors.blue);
      case MessageStatus.notSent:
        return const Icon(Icons.error_outline, size: 12, color: Colors.red);
      default:
        return const SizedBox.shrink();
    }
  }
}

class RequestDonationScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String bloodType;

  const RequestDonationScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.bloodType,
  });

  @override
  State<RequestDonationScreen> createState() => _RequestDonationScreenState();
}

class _RequestDonationScreenState extends State<RequestDonationScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isSending = false;

  Future<void> _submitRequest() async {
    if (_isSending) return;

    setState(() => _isSending = true);

    final notes = _notesController.text.trim();

    try {
      final result = await ApiService.requestDonation(
        widget.otherUserId,
        notes.isEmpty ? 'Emergency blood donation needed.' : notes,
      );

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Donation request sent!'),
              backgroundColor: Colors.green,
            ),
          );
          // Pass success back to ChatScreen to refresh chat history
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Donation', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Requesting blood from:',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFEF4444).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFEF4444).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: Color(0xFFEF4444)),
                  SizedBox(width: 8),
                  Text(
                    '${widget.otherUserName} (${widget.bloodType})',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Additional Notes:',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'e.g., Hospital details, urgency, specific instructions...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _submitRequest,
                icon: _isSending ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(Icons.send, color: Colors.white),
                label: Text(
                  _isSending ? 'Sending Request...' : 'Send Donation Request',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Donor Card Widget
class DonorCard extends StatelessWidget {
  final Donor donor;

  const DonorCard({super.key, required this.donor});

  // Blood type color mapping
  static const Map<String, Color> bloodColors = {
    "O+": Color(0xFFFF3B30), "O-": Color(0xFFCC2E27),
    "A+": Color(0xFFFF6633), "A-": Color(0xFFCC5326),
    "B+": Color(0xFFFF9966), "B-": Color(0xFFCC7A4D),
    "AB+": Color(0xFFFFCC99), "AB-": Color(0xFFCC9966),
  };

  Color _getBloodTypeColor(String bloodType) {
    // Default to red if blood type not found
    return bloodColors[bloodType] ?? Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final bloodTypeColor = _getBloodTypeColor(donor.bloodType);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Blood Type Badge with dynamic color
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: bloodTypeColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: bloodTypeColor),
                  ),
                  child: Text(
                    donor.bloodType,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFFFFF),
                      fontSize: 14,
                    ),
                  ),
                ),
                Spacer(),
                // Donor/Recipient Status
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: donor.isDonor ? Colors.red.shade100 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: donor.isDonor ? Colors.red : Colors.blue,
                      ),
                      SizedBox(width: 4),
                      Text(
                        donor.isDonor ? 'Donor' : 'Recipient',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: donor.isDonor ? Colors.red : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                // Availability Status
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: donor.isAvailable ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: donor.isAvailable ? Colors.green : Colors.grey,
                      ),
                      SizedBox(width: 4),
                      Text(
                        donor.isAvailable ? 'Available' : 'Unavailable',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: donor.isAvailable ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // User's First Name instead of User ID
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                SizedBox(width: 6),
                Text(
                  donor.firstName.isNotEmpty
                      ? donor.firstName.split(' ').map((word) => word.isNotEmpty
                      ? '${word[0].toUpperCase()}${word.substring(1)}'
                      : '').join(' ')
                      : 'User',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Location
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${donor.barangay}, ${donor.city}',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // View Profile Button
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                height: 36,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DonorProfileScreen(donor: donor),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_outlined, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'View Profile',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
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
    );
  }
}

class DonorProfileScreen extends StatefulWidget {
  final Donor donor;

  const DonorProfileScreen({super.key, required this.donor});

  @override
  State<DonorProfileScreen> createState() => _DonorProfileScreenState();
}

class _DonorProfileScreenState extends State<DonorProfileScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  final List<Map<String, dynamic>> _messages = [];

  // 2. Add state variables for auto-refresh
  late Donor _currentDonor;
  Timer? _timer;

  // Blood type color mapping
  static const Map<String, Color> bloodColors = {
    "O+": Color(0xFFFF3B30), "O-": Color(0xFFCC2E27),
    "A+": Color(0xFFFF6633), "A-": Color(0xFFCC5326),
    "B+": Color(0xFFFF9966), "B-": Color(0xFFCC7A4D),
    "AB+": Color(0xFFFFCC99), "AB-": Color(0xFFCC9966),
  };

  Color _getBloodTypeColor(String bloodType) {
    return bloodColors[bloodType] ?? Color(0xFFEF4444);
  }

  @override
  void initState() {
    super.initState();
    // 3. Initialize current donor with the passed widget data
    _currentDonor = widget.donor;

    // 4. Start the background refresh timer (every 5 seconds)
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _refreshProfileData();
    });
  }

  @override
  void dispose() {
    // 5. Cancel timer to prevent memory leaks
    _timer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  // 6. Background refresh logic
  Future<void> _refreshProfileData() async {
    try {
      // We use getDonors() because the single-user endpoint might be missing
      // specific fields like 'is_available' or 'barangay' in the current backend version.
      final result = await ApiService.getDonors();

      if (!mounted) return;

      if (result['success'] == true) {
        final innerData = result['data'];

        if (innerData is Map && innerData['success'] == true) {
          final List<dynamic> donorsList = innerData['data'];

          // Find the specific donor by ID from the fresh list
          final updatedDonorData = donorsList.firstWhere(
                (d) => d['id'].toString() == _currentDonor.id,
            orElse: () => null,
          );

          if (updatedDonorData != null) {
            setState(() {
              _currentDonor = Donor.fromJson(updatedDonorData);
            });
            // Uncomment for debugging:
            // print('🔄 Refreshed Profile: ${_currentDonor.firstName} is ${_currentDonor.isAvailable ? "Available" : "Unavailable"}');
          }
        }
      }
    } catch (e) {
      print('Silent refresh error on profile: $e');
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _isSending = true;
    });

    await Future.delayed(Duration(seconds: 1));

    final newMessage = {
      'text': _messageController.text.trim(),
      'timestamp': DateTime.now(),
      'isSent': true,
    };

    setState(() {
      _messages.insert(0, newMessage);
      _messageController.clear();
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 7. Use _currentDonor instead of widget.donor throughout the build method
    final bloodTypeColor = _getBloodTypeColor(_currentDonor.bloodType);

    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        actions: [],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blood Type Badge with dynamic color
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: bloodTypeColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: bloodTypeColor),
                ),
                child: Text(
                  _currentDonor.bloodType,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),

            _buildInfoRow(
                'Name',
                _currentDonor.firstName.isNotEmpty
                    ? _currentDonor.firstName.split(' ').map((word) => word.isNotEmpty
                    ? '${word[0].toUpperCase()}${word.substring(1)}'
                    : '').join(' ')
                    : 'User',
                Icons.person
            ),
            _buildInfoRow(
                'ID',
                '#U${_currentDonor.id}',
                Icons.fingerprint
            ),
            // Display User Type
            _buildInfoRow(
                'Role',
                _currentDonor.isDonor ? 'Donor' : 'Recipient',
                _currentDonor.isDonor ? Icons.volunteer_activism : Icons.medical_services
            ),
            _buildInfoRow(
                'Location',
                '${_currentDonor.barangay}, ${_currentDonor.city}',
                Icons.location_on
            ),
            SizedBox(height: 24),

            // Availability Status
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _currentDonor.isAvailable ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _currentDonor.isAvailable ? Colors.green.shade200 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _currentDonor.isAvailable ? Icons.check_circle : Icons.cancel,
                    color: _currentDonor.isAvailable ? Colors.green : Colors.grey,
                  ),
                  SizedBox(width: 12),
                  Text(
                    _currentDonor.isAvailable ? 'Available for donation' : 'Currently unavailable',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: _currentDonor.isAvailable ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Send Message Section
            _buildMessageSection(),

            Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageSection() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                otherUserId: _currentDonor.id,
                otherUserName: _currentDonor.firstName,
                otherUserBloodType: _currentDonor.bloodType,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFEF4444),
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 20, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Start Chat',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Map View
class MapScreenApp extends StatelessWidget {
  const MapScreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Donor Map View',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: const MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _DonorMapScreenState();
}

class _DonorMapScreenState extends State<MapScreen> {
  String? selectedBarangay;
  List<Donor> _donors = [];
  bool _isLoading = true;
  Timer? _timer; // 2. Add Timer variable

  // 🧭 Static list of barangays in Santa Cruz, Laguna (approximate coords)
  final List<Map<String, dynamic>> barangays = [
    {'name': 'Alipit', 'location': const LatLng(14.226399323790481, 121.40116782219167)},
    {'name': 'Bagumbayan', 'location': const LatLng(14.274252691561792, 121.39664852200725)},
    {'name': 'Bubukal', 'location': const LatLng(14.263265511032774, 121.40267990242118)},
    {'name': 'Calios', 'location': const LatLng(14.280350715440953, 121.40409079902281)},
    {'name': 'Duhat', 'location': const LatLng(14.256127645402335, 121.37782252968601)},
    {'name': 'Gatid', 'location': const LatLng(14.264679770118615, 121.38212085806983)},
    {'name': 'Jasaan', 'location': const LatLng(14.22353213028224, 121.39171988386163)},
    {'name': 'Labuin', 'location': const LatLng(14.2541263325076, 121.39616498876649)},
    {'name': 'Malinao', 'location': const LatLng(14.234415399375122, 121.39712859420302)},
    {'name': 'Oogong', 'location': const LatLng(14.234584802089483, 121.41275020383485)},
    {'name': 'Pagsawitan', 'location': const LatLng(14.272339954947514, 121.42383674810337)},
    {'name': 'Palasan', 'location': const LatLng(14.252662326767435, 121.41923938791534)},
    {'name': 'Patimbao', 'location': const LatLng(14.270542675699883, 121.41474588452277)},
    {'name': 'Barangay I', 'location': const LatLng(14.277274354124549, 121.41773294426126)},
    {'name': 'Barangay II', 'location': const LatLng(14.279976753822192, 121.41615017924775)},
    {'name': 'Barangay III', 'location': const LatLng(14.28218738921623, 121.41517138507076)},
    {'name': 'Barangay IV', 'location': const LatLng(14.283933004882643, 121.41461181362807)},
    {'name': 'Barangay V', 'location': const LatLng(14.285371832834624, 121.41306412102112)},
    {'name': 'Santisima Cruz', 'location': const LatLng(14.292093674566575, 121.40957568387927)},
    {'name': 'San Juan', 'location': const LatLng(14.249701333843797, 121.40706697989344)},
    {'name': 'San Jose', 'location': const LatLng(14.23850737629517, 121.4075113651048)},
    {'name': 'Santo Angel Central', 'location': const LatLng(14.284928614735023, 121.40828199755106)},
    {'name': 'Santo Angel Norte', 'location': const LatLng(14.291755045908387, 121.4047394793485)},
    {'name': 'Santo Angel Sur', 'location': const LatLng(14.280761565626138, 121.411953113022)},
    {'name': 'San Pablo Norte', 'location': const LatLng(14.286722394804967, 121.41701540486139)},
    {'name': 'San Pablo Sur', 'location': const LatLng(14.280799394990014, 121.42157891567174)},
  ];

  static const Map<String, Color> bloodColors = {
    "O+": Color(0xFFFF3B30), "O-": Color(0xFFCC2E27),
    "A+": Color(0xFFFF6633), "A-": Color(0xFFCC5326),
    "B+": Color(0xFFFF9966), "B-": Color(0xFFCC7A4D),
    "AB+": Color(0xFFFFCC99), "AB-": Color(0xFFCC9966),
  };

  Color _getBloodTypeColor(String bloodType) {
    return bloodColors[bloodType] ?? Color(0xFFEF4444);
  }

  @override
  void initState() {
    super.initState();
    // 3. Initial load (shows spinner)
    _loadDonors(refresh: false);

    // 4. Start Timer for background updates (every 5 seconds)
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _loadDonors(refresh: true);
    });
  }

  @override
  void dispose() {
    // 5. Cancel timer when widget is destroyed
    _timer?.cancel();
    super.dispose();
  }

  // 6. Modified to handle background refreshing
  Future<void> _loadDonors({bool refresh = false}) async {
    // Only show loading indicator if it's NOT a background refresh
    if (!refresh) {
      print('🗺️ Loading users for map...');
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final result = await ApiService.getDonors();

      // Ensure widget is still on screen
      if (!mounted) return;

      if (result['success']) {
        final innerData = result['data'];

        if (innerData is Map && innerData['success'] == true) {
          final donorsData = innerData['data'];

          if (donorsData is List) {
            final List<Donor> loadedDonors = [];

            for (var i = 0; i < donorsData.length; i++) {
              final data = donorsData[i];
              try {
                final donor = Donor.fromJson(data);
                loadedDonors.add(donor);
              } catch (e) {
                print('❌ Error converting map donor $i: $e');
              }
            }

            setState(() {
              _donors = loadedDonors;
              _isLoading = false;
            });

            if (!refresh) {
              print('🎉 Map ready with ${_donors.length} donors');
            }
          }
        }
      } else {
        if (!refresh) {
          print('❌ Failed to load donors for map: ${result['error']}');
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('💥 Error loading users for map: $e');
      if (mounted && !refresh) {
        setState(() => _isLoading = false);
      }
    }
  }


  List<Donor> getSelectedBarangayDonors() {
    if (selectedBarangay == null) return [];
    return _donors.where((donor) => donor.barangay == selectedBarangay).toList();
  }

  bool hasDonorsInBarangay(String barangayName) {
    return _donors.any((donor) => donor.barangay == barangayName);
  }

  @override
  Widget build(BuildContext context) {
    // Filter out archived donors immediately
    final activeDonors = _donors.where((d) => !d.isArchived).toList();

    // Update selected list to exclude archived users
    final selectedDonors = getSelectedBarangayDonors()
        .where((d) => !d.isArchived)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donor Map View'),
        centerTitle: true,
        actions: [],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading users from database...'),
          ],
        ),
      )
          : Column(
        children: [
          // 🗺️ Map section
          Expanded(
            flex: 3,
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(14.285, 121.420),
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  // Filter markers: Only show Red if ACTIVE donors exist in that barangay
                  markers: barangays.map<Marker>((bgy) {
                    final hasDonors = activeDonors
                        .any((d) => d.barangay == bgy['name']);

                    return Marker(
                      point: bgy['location'],
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedBarangay = bgy['name'];
                          });
                        },
                        child: Icon(
                          Icons.location_pin,
                          color: hasDonors ? Colors.red : Colors.grey,
                          size: hasDonors ? 42 : 32,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // 👥 Donor list / info section
          Expanded(
            flex: 2,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: selectedBarangay == null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined,
                        size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      "Tap a location marker to view donors",
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Red markers have available donors",
                      style: TextStyle(
                          color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    // Enhanced user count display
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border:
                        Border.all(color: Colors.green.shade100),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_alt_outlined,
                                  size: 20, color: Colors.black),
                              SizedBox(width: 8),
                              Text(
                                "Total Users",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 3),
                          // Use activeDonors.length for accurate count
                          Text(
                            activeDonors.length.toString(),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          if (activeDonors.isNotEmpty)
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildUserTypeCount(
                                    "Donors",
                                    activeDonors
                                        .where((d) => d.isDonor)
                                        .length,
                                    Colors.red),
                                _buildUserTypeCount(
                                    "Recipients",
                                    activeDonors
                                        .where((d) => !d.isDonor)
                                        .length,
                                    Colors.blue),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barangay header
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          color: Color(0xFFEF4444)),
                      SizedBox(width: 8),
                      Text(
                        selectedBarangay!,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            selectedBarangay = null;
                          });
                        },
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Donor count
                  Text(
                    selectedDonors.isEmpty
                        ? "No donors available in this area"
                        : "${selectedDonors.length} User${selectedDonors.length != 1 ? 's' : ''} Available",
                    style: GoogleFonts.poppins(
                      color: selectedDonors.isEmpty
                          ? Colors.grey
                          : Color(0xFFEF4444),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Donor list
                  Expanded(
                    child: selectedDonors.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 48,
                              color: Colors.grey.shade400),
                          SizedBox(height: 16),
                          Text(
                            "No donors in this barangay",
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Be the first to register as a donor!",
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      itemCount: selectedDonors.length,
                      itemBuilder: (context, index) {
                        final donor = selectedDonors[index];
                        final bloodTypeColor =
                        _getBloodTypeColor(donor.bloodType);

                        return Card(
                          margin: EdgeInsets.only(bottom: 8),
                          elevation: 1,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DonorProfileScreen(
                                          donor: donor),
                                ),
                              );
                            },
                            borderRadius:
                            BorderRadius.circular(4),
                            child: ListTile(
                              leading: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: bloodTypeColor,
                                  borderRadius:
                                  BorderRadius.circular(8),
                                ),
                                child: Text(
                                  donor.bloodType,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(
                                donor.firstName.isNotEmpty
                                    ? donor.firstName
                                    .split(' ')
                                    .map((word) => word
                                    .isNotEmpty
                                    ? '${word[0].toUpperCase()}${word.substring(1)}'
                                    : '')
                                    .join(' ')
                                    : 'User',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                donor.city,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                crossAxisAlignment:
                                CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 1. Donor/Recipient Badge
                                  Container(
                                    padding:
                                    EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4),
                                    decoration: BoxDecoration(
                                      color: donor.isDonor
                                          ? Colors.red.withOpacity(0.2)
                                          : Colors.blue.withOpacity(0.2),
                                      borderRadius:
                                      BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      donor.isDonor
                                          ? 'Donor'
                                          : 'Recipient',
                                      style:
                                      GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: donor.isDonor
                                            ? Colors.red
                                            : Colors.blue,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  // 2. Availability Badge
                                  Container(
                                    padding:
                                    EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4),
                                    decoration: BoxDecoration(
                                      color: donor.isAvailable
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.grey.withOpacity(0.2),
                                      borderRadius:
                                      BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      donor.isAvailable
                                          ? 'Available'
                                          : 'Unavailable',
                                      style:
                                      GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: donor.isAvailable
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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

  Widget _buildUserTypeCount(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            label == "Donors" ? Icons.bloodtype_outlined : Icons.medical_services_outlined,
            size: 16,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

// Profile Screen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  Timer? _timer; // 2. Add Timer variable

  @override
  void initState() {
    super.initState();
    // 3. Initial load (shows spinner)
    _loadUserProfile(refresh: false);

    // 4. Start background refresh timer (every 5 seconds)
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _loadUserProfile(refresh: true);
    });
  }

  @override
  void dispose() {
    // 5. Cancel timer to stop updates when leaving screen
    _timer?.cancel();
    super.dispose();
  }

  // 6. Modified to support silent background refreshing
  Future<void> _loadUserProfile({bool refresh = false}) async {
    if (!refresh) {
      print('👤 Loading user profile from database...');
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Get the current user ID (Implementation depends on your auth logic)
      final String? currentUserId = await _getCurrentUserId();

      if (currentUserId == null) {
        if (!refresh) {
          print('❌ No user ID found');
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final result = await ApiService.getProfile(userId: currentUserId);

      // Check if widget is still mounted before calling setState
      if (!mounted) return;

      if (result['success']) {
        final userData = result['data'];

        // Only log on initial load to reduce console noise
        if (!refresh) print('✅ User profile loaded: $userData');

        setState(() {
          _userData = userData ?? {};
          _isLoading = false;
        });

        if (!refresh) _debugUserData();
      } else {
        if (!refresh) {
          print('❌ Failed to load profile: ${result['error']}');
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('💥 Error loading profile: $e');
      if (mounted && !refresh) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Method to get current user ID
  Future<String?> _getCurrentUserId() async {
    // For now, return a placeholder - ensures the API call proceeds
    // The actual API call uses the Token in header, so this ID param is often ignored by the backend
    return 'current_user_id_placeholder';
  }

  void _navigateToSwitchRole() {
    if (_userData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SwitchRoleScreen(userData: _userData!),
        ),
      ).then((roleChanged) {
        // Refresh profile data immediately if role was changed
        if (roleChanged == true) {
          _loadUserProfile(refresh: false); // Show loading spinner for immediate feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Role updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    } else {
      print('❌ Cannot navigate to Switch Role: userData is null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load user data'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _debugUserData() {
    if (_userData != null) {
      print('🔍 DEBUG USER DATA:');
      print('📊 Full user data: $_userData');
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade200,
          title: Text('Sign Out'),
          content: Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog

                // CALL THE SERVER FIRST
                await ApiService.logout();

                // Stop the timer since we are logging out
                _timer?.cancel();

                // Navigate back to login
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                        (route) => false,
                  );
                }
              },
              child: Text(
                'Sign Out',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToPersonalDetails() {
    if (_userData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PersonalDetailsScreen(userData: _userData!),
        ),
      ).then((_) {
        // Refresh profile when returning from details screen
        _loadUserProfile(refresh: true);
      });
    } else {
      print('❌ Cannot navigate: userData is null in ProfileScreen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _userData == null || _userData!.isEmpty
          ? _buildErrorState()
          : _buildProfileView(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'No profile data found',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadUserProfile(refresh: false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFEF4444),
            ),
            child: Text(
              'Try Again',
              style: GoogleFonts.poppins(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const Map<String, Color> bloodColors = {
    "O+": Color(0xFFFF3B30), "O-": Color(0xFFCC2E27),
    "A+": Color(0xFFFF6633), "A-": Color(0xFFCC5326),
    "B+": Color(0xFFFF9966), "B-": Color(0xFFCC7A4D),
    "AB+": Color(0xFFFFCC99), "AB-": Color(0xFFCC9966),
  };

  Widget _buildProfileView() {
    final Map<String, dynamic> user = _userData!;

    // Helper to find data in nested structures
    dynamic getField(String field) {
      if (user['user'] != null && user['user'] is Map) return user['user'][field];
      if (user['data'] != null && user['data'] is Map) return user['data'][field];
      return user[field];
    }

    String firstName = getField('first_name')?.toString() ?? 'N/A';
    String lastName = getField('last_name')?.toString() ?? 'N/A';

    // Extract Blood Type
    String bloodType = getField('blood_type')?.toString() ?? 'O+';

    // Extract Role (is_donor)
    dynamic rawIsDonor = getField('is_donor');
    bool isDonor = false;
    if (rawIsDonor != null) {
      if (rawIsDonor is bool) {
        isDonor = rawIsDonor;
      } else if (rawIsDonor is int) {
        isDonor = rawIsDonor == 1;
      } else if (rawIsDonor is String) {
        isDonor = rawIsDonor.toLowerCase() == 'true' ||
            rawIsDonor == '1' ||
            rawIsDonor == 'Donor';
      }
    }

    final String userType = isDonor ? 'Donor' : 'Recipient';
    // Role Border Color: Red for Donor, Blue for Recipient
    final Color roleColor = isDonor ? Color(0xFFEF4444) : Colors.blue;

    final String rawFullName = '$firstName $lastName'.trim();

    final String fullName = rawFullName.isNotEmpty
        ? rawFullName.split(' ').map((word) => word.isNotEmpty
        ? '${word[0].toUpperCase()}${word.substring(1)}'
        : '').join(' ')
        : 'User';

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildProfileHeader(fullName, userType, roleColor, bloodType),

          SizedBox(height: 32),

          _buildSectionTitle('Account Settings'),
          SizedBox(height: 16),
          _buildSettingsCard(),

          SizedBox(height: 32),
          _buildSignOutButton(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String name, String userType, Color roleColor, String bloodType) {
    final Color bloodColor = bloodColors[bloodType] ?? Color(0xFFFF3B30);

    return Column(
      children: [
        // User Avatar / Blood Type Badge
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: bloodColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              bloodType,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 2.0,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 16),

        // User Name
        Text(
          name,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),

        // User Type Badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: roleColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: roleColor.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Text(
            userType,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            title: 'Personal Details',
            icon: Icons.person_outline,
            onTap: _navigateToPersonalDetails,
          ),
          _buildDivider(),
          _buildSettingsItem(
            title: 'Switch Role',
            icon: Icons.swap_horiz,
            onTap: _navigateToSwitchRole,
          ),
          _buildDivider(),
          _buildSettingsItem(
            title: 'About Us',
            icon: Icons.help_outline,
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutUsScreen())
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.grey.shade700,
        size: 24,
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade800,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade500,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: Colors.grey.shade300,
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _showSignOutDialog,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: Colors.grey.shade400),
        ),
        child: Text(
          'Log Out',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'About Us',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. App Logo/Header
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.asset(
                    'assets/LDH (2).jpg',
                    fit: BoxFit.contain,
                    errorBuilder: (c, o, s) => Icon(Icons.bloodtype, size: 50, color: Color(0xFFEF4444)),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'BloodiFind',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
            Center(
              child: Text(
                'v1.0.0',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ),
            SizedBox(height: 32),

            // 2. About Description
            Text(
              "About Bloodifind",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                "Bloodifind is a dedicated platform designed to streamline the search for blood donors. We connect recipients with donors in real-time through secure profiles and interactive mapping, ensuring help is always within reach.",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 32),

            // 3. Contact Us Section
            Text(
              "Contact Us",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.location_on_outlined,
              title: "Address",
              content: "Sitio Mapagmahal, Brgy. Pagsawitan, Sta. Cruz, Laguna, Philippines",
            ),
            SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.email_outlined,
              title: "Email",
              content: "bloodifind.app@gmail.com",
            ),
            SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.facebook,
              title: "Facebook",
              content: "Laguna Doctors Hospital, Inc.",
            ),

            SizedBox(height: 32),

            // 4. FAQs Section
            Text(
              "Frequently Asked Questions",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12),
            _buildFAQItem(
              "How do I become a donor?",
              "Go to your Profile settings and toggle the 'Available to Donate' switch. You can also edit your details to ensure your location and blood type are accurate.",
            ),
            _buildFAQItem(
              "Is my location visible to everyone?",
              "Your approximate location (Barangay level) is visible on the map to help recipients find nearby donors. Your exact address is kept private.",
            ),
            _buildFAQItem(
              "How do I contact a donor?",
              "You can use the in-app chat feature to send a message to a donor. Go to the donor's profile and tap 'Chat with Donor'.",
            ),
            _buildFAQItem(
              "Is this service free?",
              "Yes, Bloodifind is a free platform dedicated to saving lives by connecting donors and recipients.",
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    // Removed InkWell and onTap since interactions are disabled
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFFEF4444).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Color(0xFFEF4444), size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  content,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87, // Standard text color
                    // Removed decoration (underline)
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              answer,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Fixed Header
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terms of Service',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Last Updated: November 2025',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Terms Page 1
                    _buildTermsPage1(),
                    SizedBox(height: 20),

                    // Terms Page 2
                    _buildTermsPage2(),
                    SizedBox(height: 20),

                    // Terms Page 3
                    _buildTermsPage3(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsPage1() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Important Medical Disclaimer:',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Bloodifind is a technology platform designed to connect donors and recipients. We are not a medical institution. We do not test, screen, or collect blood. All medical procedures must be handled by certified medical professionals and hospitals.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 20),
          Text(
            '1. Acceptance of Terms',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'By accessing or using the Bloodifind web application, you agree to be bound by these Terms of Service. If you disagree with any part of the terms, you may not access the service.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 20),
          Text(
            '2. User Eligibility',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You must be at least 18 years old to register as a donor independently. Users under 18 may use the service only with the involvement of a parent or guardian. By registering, you represent that the information you provide (including age and blood type) is accurate and truthful.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 20),
          Text(
            '3. User Responsibilities',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBulletPoint('Accuracy: You agree to provide accurate medical information regarding your blood type and health status. False information may endanger lives and will result in immediate account termination.'),
              SizedBox(height: 8),
              _buildBulletPoint('Safety: You agree to use the contact information provided by other users solely for the purpose of blood donation. Harassment, spamming, or misuse of data is strictly prohibited.'),
              SizedBox(height: 8),
              _buildBulletPoint('Commitment: If you agree to donate, please communicate effectively with the recipient. If you cannot make it, inform them immediately.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTermsPage2() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '4. Limitation of Liability',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Bloodifind acts solely as a connector. We are not responsible for:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBulletPoint('The medical suitability of any donor.'),
              _buildBulletPoint('The outcome of any medical procedure or transfusion.'),
              _buildBulletPoint('The conduct of any user, online or offline.'),
              _buildBulletPoint('Any failure of a donor to attend a scheduled donation.'),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Always verify donor eligibility through official hospital screening processes before proceeding with any transfusion.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade800,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 20),
          Text(
            '5. Account Termination',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'We reserve the right to suspend or terminate your account at our sole discretion, without notice, for conduct that we believe violates these Terms or is harmful to other users of the Service, or for any other reason.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsPage3() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '6. Governing Law',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'These Terms shall be governed by and construed in accordance with the laws of the Philippines.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 20),
          Text(
            '7. Contact Us',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'If you have any questions about these Terms, please contact us at bloodifind.app@gmail.com.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 8),
            child: Icon(
              Icons.circle,
              size: 6,
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Fixed Header
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Policy',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Last Updated: November 2025',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Privacy Policy Page 1
                    _buildPrivacyPage1(),
                    SizedBox(height: 20),

                    // Privacy Policy Page 2
                    _buildPrivacyPage2(),
                    SizedBox(height: 20),

                    // Privacy Policy Page 3
                    _buildPrivacyPage3(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyPage1() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to Bloodifind.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'We respect your privacy and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, and safeguard your information when you use our web application.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 20),
          Text(
            '1. Information We Collect',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'To facilitate blood donation connections, we collect the following types of information:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBulletPoint('Personal Identity Information: Name, age, and gender.'),
              _buildBulletPoint('Contact Information: Email address (bloodifind.app@gmail.com), phone numbers, and social media handles (if provided).'),
              _buildBulletPoint('Health Information: Blood type (A, B, AB, O) and Rh factor.'),
              _buildBulletPoint('Location Data: Your city, municipality, or specific geolocation coordinates. This is used to display your rough location on our interactive map to help nearby users find you.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPage2() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2. How We Use Your Information',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'We use the collected data for the following purposes:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBulletPoint('To register you as a Donor or Recipient in our system.'),
              _buildBulletPoint('To visualize donor availability on the Bloodifind Map.'),
              _buildBulletPoint('To enable communication between potential donors and recipients.'),
              _buildBulletPoint('To verify accounts and prevent fraud.'),
            ],
          ),
          SizedBox(height: 20),
          Text(
            '3. Data Sharing and Visibility',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Public Visibility: By default, limited information (Blood Type, City/Location, and First Name) may be visible to other registered users on the map to facilitate finding a match.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Private Contact Info: Your specific contact details (Phone Number/Email) are only shared when you explicitly agree to connect with another user or strictly for the purpose of emergency blood donation coordination.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'We do not sell, trade, or rent your personal identification information to others.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPage3() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '4. Data Security',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'We implement appropriate technical and organizational security measures to protect your data against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the Internet is 100% secure, and we cannot guarantee absolute security.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 20),
          Text(
            '5. Your Rights',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You have the right to access, update, or delete your account information at any time via your Dashboard settings. If you wish to remove your data completely from our system, please contact support.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 20),
          Text(
            '6. Changes to This Policy',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Contact Us',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'If you have any questions about this Privacy Policy, please contact us:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Email: bloodifind.app@gmail.com',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 8),
            child: Icon(
              Icons.circle,
              size: 6,
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class SwitchRoleScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const SwitchRoleScreen({super.key, required this.userData});

  @override
  State<SwitchRoleScreen> createState() => _SwitchRoleScreenState();
}

class _SwitchRoleScreenState extends State<SwitchRoleScreen> {
  bool _isDonor = true;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentRole();
  }

  void _loadCurrentRole() {
    print('🔄 Loading current role from user data...');
    final user = widget.userData;

    // Extract current role from user data
    final isDonorValue = _getField('is_donor');
    print('📊 Raw isDonor value from DB: $isDonorValue');
    print('📊 Raw isDonor type: ${isDonorValue?.runtimeType}');

    // Convert to boolean
    if (isDonorValue is int) {
      _isDonor = isDonorValue == 1;
    } else if (isDonorValue is bool) {
      _isDonor = isDonorValue;
    } else if (isDonorValue is String) {
      _isDonor = isDonorValue == 'true' || isDonorValue == '1' || isDonorValue == 'Donor';
    } else {
      _isDonor = true; // Default to Donor
    }

    print('✅ Current role: ${_isDonor ? 'Donor' : 'Recipient'}');

    setState(() {
      _isLoading = false;
    });
  }

  // MODIFIED _switchRole FUNCTION
  Future<void> _switchRole(bool newRole) async {
    if (_isUpdating) return;

    // 1. Prevent unnecessary update if already in the desired role
    if (newRole == _isDonor) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are already a ${newRole ? 'Donor' : 'Recipient'}'),
          backgroundColor: Colors.blueGrey,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 2. Start update process
    setState(() {
      _isUpdating = true;
    });

    try {
      print('🔄 Switching role to: ${newRole ? 'Donor' : 'Recipient'}');

      final user = widget.userData;

      // Extract current values to send all required fields
      String getField(String fieldName) {
        if (user?[fieldName] != null) return user![fieldName]?.toString() ?? '';
        if (user?['user'] != null && user?['user'] is Map) {
          return (user!['user'] as Map<String, dynamic>)[fieldName]?.toString() ?? '';
        }
        if (user?['data'] != null && user?['data'] is Map) {
          return (user!['data'] as Map<String, dynamic>)[fieldName]?.toString() ?? '';
        }
        final camelCaseField = _toCamelCase(fieldName);
        return user?[camelCaseField]?.toString() ?? '';
      }

      final updateData = {
        'firstName': getField('first_name'),
        'lastName': getField('last_name'),
        'phone': getField('phone'),
        'bloodType': getField('blood_type'),
        'barangay': getField('barangay'),
        'isDonor': newRole, // Send the target role
      };

      updateData.removeWhere((key, value) => value == null || value == '');

      final result = await ApiService.updateProfile(updateData);

      if (result['success']) {
        // --- SUCCESS PATH (Restriction was removed or switching to Recipient) ---
        print('✅ Role switched successfully in database');
        setState(() {
          _isDonor = newRole;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You are now a ${newRole ? 'Donor' : 'Recipient'}',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Future.delayed(Duration(seconds: 1), () {
          Navigator.pop(context, true);
        });
      } else {
        // --- FAILURE PATH (Server returned 403 Forbidden or 500 Internal Server Error) ---
        print('❌ Failed to switch role: ${result['error']}');

        final errorReason = result['data']?['reason'];
        String displayError = result['error'] ?? 'Failed to switch role.';

        // Handle all 403 denials (health restriction OR active request)
        if (newRole == true && result['statusCode'] == 403) {

          if (displayError.startsWith('Role switch denied')) {
            // Use the detailed server error message
            displayError = displayError;
          } else if (errorReason != null && errorReason != 'Database error on restriction check') {
            // Fallback for custom reason format
            displayError = "Role switch denied: Health restriction. Reason: ${errorReason}";
          } else {
            // This captures generic 403s without a clear custom message, though the server should provide one
            displayError = "Role switch denied: Check your active requests or health status.";
          }

          setState(() {
            _isDonor = false; // Ensure UI reflects Recipient role (the denied role)
          });
        }

        // If it's a 500 error, ApiService will usually map it to 'Internal server error'.

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayError),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('💥 Error switching role: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  dynamic _getField(String fieldName) {
    final user = widget.userData;
    if (user?[fieldName] != null) return user![fieldName];
    if (user?['user'] != null && user?['user'] is Map) {
      return (user!['user'] as Map<String, dynamic>)[fieldName];
    }
    if (user?['data'] != null && user?['data'] is Map) {
      return (user!['data'] as Map<String, dynamic>)[fieldName];
    }
    final camelCaseField = _toCamelCase(fieldName);
    return user?[camelCaseField];
  }

  String _toCamelCase(String snakeCase) {
    final parts = snakeCase.split('_');
    if (parts.length == 1) return parts[0];
    return parts[0] + parts.sublist(1).map((part) {
      return part[0].toUpperCase() + part.substring(1);
    }).join('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Switch Role',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading your current role...',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Select Your Role',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Choose whether you want to be a blood donor or recipient.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 32),

          // Current Role Indicator
          _buildCurrentRoleIndicator(),
          SizedBox(height: 24),

          // Role Selection
          _buildRoleSelection(),

          SizedBox(height: 40),

          // Update Button
          _buildUpdateButton(),
        ],
      ),
    );
  }

  Widget _buildCurrentRoleIndicator() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue.shade600,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your current role: ${_isDonor ? 'Donor' : 'Recipient'}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      children: [
        // Donor Option
        _buildRoleOption(
          title: 'Blood Donor',
          description: 'I want to donate blood and help save lives',
          icon: Icons.bloodtype,
          isSelected: _isDonor,
          onTap: () => _switchRole(true), // Call with true for Donor
          color: Color(0xFFEF4444),
        ),
        SizedBox(height: 16),

        // Recipient Option
        _buildRoleOption(
          title: 'Recipient',
          description: 'I need to request blood donations',
          icon: Icons.medical_services,
          isSelected: !_isDonor,
          onTap: () => _switchRole(false), // Call with false for Recipient
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildRoleOption({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: _isUpdating ? null : onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) ...[
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isUpdating ? null : () {
          // This button is mainly for visual consistency
          // The actual role switching happens when tapping the options
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tap on a role option above to switch'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isUpdating
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
          ),
        )
            : Text(
          'Tap a role above to select',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class PersonalDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const PersonalDetailsScreen({super.key, required this.userData});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // 2. Add state variable for the fetched data
  Map<String, dynamic>? _liveUserData;
  Timer? _timer;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedBloodType = 'A+';
  String _selectedBarangay = 'Bagumbayan';
  bool _isAvailable = false;
  String _capitalize(String s) => s.isNotEmpty
      ? s.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ')
      : '';

  final List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> barangays = [
    "Alipit", "Bagumbayan", "Bubukal", "Calios", "Duhat", "Gatid", "Jasaan",
    "Labuin", "Malinao", "Oogong", "Pagsawitan", "Palasan", "Patimbao",
    "Barangay I", "Barangay II", "Barangay III", "Barangay IV", "Barangay V",
    "San Jose", "San Juan", "San Pablo Norte", "San Pablo Sur",
    "Santisima Cruz", "Santo Angel Central", "Santo Angel Norte", "Santo Angel Sur"
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with passed data first
    _liveUserData = widget.userData;
    _initializeData(_liveUserData!);

    // 3. Start timer for background refresh
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _refreshProfileData();
    });
  }

  @override
  void dispose() {
    // 4. Cancel timer
    _timer?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // New method to fetch and update data
  Future<void> _refreshProfileData() async {
    // Only refresh if the user is in View Mode
    if (_isEditing) return;

    // We need to get the current user ID to call getProfile
    final currentUserId = await _getCurrentUserId();

    if (currentUserId == null) return;

    try {
      final result = await ApiService.getProfile(userId: currentUserId);

      if (!mounted) return;

      if (result['success'] && result['data'] != null) {
        final newUserData = result['data'] as Map<String, dynamic>;

        // Only update if the data has actually changed to prevent unnecessary rebuilds
        if (_liveUserData.toString() != newUserData.toString()) {
          setState(() {
            _liveUserData = newUserData;
            // Re-initialize form data from the new live data (in View Mode)
            _initializeData(_liveUserData!);
          });
        }
      }
    } catch (e) {
      print('Silent profile refresh error: $e');
    }
  }

  // Method to get current user ID (copied from ProfileScreen)
  Future<String?> _getCurrentUserId() async {
    // This uses a placeholder ID, assuming the token handles auth.
    return 'current_user_id_placeholder';
  }


  // Refactored to accept user data dynamically
  void _initializeData(Map<String, dynamic> user) {
    // Function to safely extract data from different possible structures
    dynamic getField(String fieldName) {
      if (user?[fieldName] != null) return user![fieldName];
      if (user?['user'] != null && user?['user'] is Map) {
        return (user!['user'] as Map<String, dynamic>)[fieldName];
      }
      if (user?['data'] != null && user?['data'] is Map) {
        return (user!['data'] as Map<String, dynamic>)[fieldName];
      }
      final camelCaseField = _toCamelCase(fieldName);
      return user?[camelCaseField];
    }

    final availabilityValue = getField('is_available');

    if (availabilityValue is int) {
      _isAvailable = availabilityValue == 1;
    } else if (availabilityValue is bool) {
      _isAvailable = availabilityValue;
    } else if (availabilityValue is String) {
      _isAvailable = availabilityValue == 'true' || availabilityValue == '1' || availabilityValue == 'Available';
    } else {
      _isAvailable = false;
    }

    _firstNameController.text = _capitalize(getField('first_name')?.toString() ?? '');
    _lastNameController.text = _capitalize(getField('last_name')?.toString() ?? '');
    _emailController.text = getField('email')?.toString() ?? '';
    _phoneController.text = getField('phone')?.toString() ?? '';
    _selectedBloodType = getField('blood_type')?.toString() ?? 'A+';
    _selectedBarangay = getField('barangay')?.toString() ?? 'Bagumbayan';

    // Force setState in case data changed but we are in View Mode
    if (!_isEditing) {
      setState(() {});
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      // When entering edit mode, ensure controllers are fully synchronized
      if (_isEditing) {
        _initializeData(_liveUserData!);
      }
    });
  }

  void _cancelEdit() {
    _initializeData(_liveUserData!);
    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      print('💾 Saving profile changes...');

      // Prepare the updated data
      final updatedData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bloodType': _selectedBloodType,
        'barangay': _selectedBarangay,
        'isAvailable': _isAvailable,
      };

      print('📤 Sending update data: $updatedData');

      try {
        final result = await ApiService.updateProfile(updatedData);

        print('📥 Backend response: $result');

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Set to View Mode and pop
          setState(() => _isEditing = false);
          Navigator.pop(context, true); // Return true to trigger ProfileScreen refresh
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('💥 Error saving changes: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Network error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Please fix the errors in the form'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    // If live data hasn't been fetched yet, use the initial widget data
    final user = _liveUserData ?? widget.userData;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Account Setting',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit, color: Color(0xFF000001)),
              onPressed: _toggleEditMode,
            ),
        ],
      ),
      body: _isEditing ? _buildEditForm(user) : _buildViewMode(user),
    );
  }

  Widget _buildViewMode(Map<String, dynamic> user) {

    // Function to safely extract data from different possible structures
    dynamic getField(String fieldName) {
      if (user?[fieldName] != null) return user![fieldName];
      if (user?['user'] != null && user?['user'] is Map) {
        return (user!['user'] as Map<String, dynamic>)[fieldName];
      }
      if (user?['data'] != null && user?['data'] is Map) {
        return (user!['data'] as Map<String, dynamic>)[fieldName];
      }
      final camelCaseField = _toCamelCase(fieldName);
      return user?[camelCaseField];
    }

    // Extract all fields
    final String firstName = getField('first_name')?.toString() ?? 'Not set';
    final String lastName = getField('last_name')?.toString() ?? 'Not set';
    final String email = getField('email')?.toString() ?? 'Not set';
    final String phone = getField('phone')?.toString() ?? 'Not set';
    final String bloodType = getField('blood_type')?.toString() ?? 'Not set';
    final String barangay = getField('barangay')?.toString() ?? 'Not set';

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Personal Details'),
          SizedBox(height: 16),
          _buildDetailItem(
            'First Name:',
            firstName.isNotEmpty
                ? firstName.split(' ').map((word) => word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1)}'
                : '').join(' ')
                : firstName,
          ),
          _buildDetailItem(
            'Last Name:',
            lastName.isNotEmpty
                ? lastName.split(' ').map((word) => word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1)}'
                : '').join(' ')
                : lastName,
          ),
          _buildDetailItem('Email:', _maskEmail(email)),
          _buildDetailItem('Phone Number:', _maskPhone(phone)),
          _buildDetailItem('Blood Type:', bloodType),
          _buildDetailItem('Barangay:', barangay),

          Divider(height: 40),
          _buildAvailabilitySection(),
          Divider(height: 40),
          _buildPasswordSection(),
          SizedBox(height: 40),
          _buildArchiveSection(),
        ],
      ),
    );
  }

// Helper function to convert snake_case to camelCase
  String _toCamelCase(String snakeCase) {
    final parts = snakeCase.split('_');
    if (parts.length == 1) return parts[0];

    return parts[0] + parts.sublist(1).map((part) {
      return part[0].toUpperCase() + part.substring(1);
    }).join('');
  }



  Widget _buildEditForm(Map<String, dynamic> user) {
    // Function to safely extract data from different possible structures
    dynamic getField(String fieldName) {
      if (user?[fieldName] != null) return user![fieldName];
      if (user?['user'] != null && user?['user'] is Map) {
        return (user!['user'] as Map<String, dynamic>)[fieldName];
      }
      if (user?['data'] != null && user?['data'] is Map) {
        return (user!['data'] as Map<String, dynamic>)[fieldName];
      }
      final camelCaseField = _toCamelCase(fieldName);
      return user?[camelCaseField];
    }

    // Extract current values for initialization if needed (should be done in _initializeData)
    final String currentFirstName = getField('first_name')?.toString() ?? '';
    final String currentLastName = getField('last_name')?.toString() ?? '';
    final String currentEmail = getField('email')?.toString() ?? '';

    // Initialize controllers with current values ONLY if they're empty
    if (_firstNameController.text.isEmpty) _firstNameController.text = currentFirstName;
    if (_lastNameController.text.isEmpty) _lastNameController.text = currentLastName;
    if (_emailController.text.isEmpty) _emailController.text = currentEmail;


    return Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Personal Details'),
                      SizedBox(height: 16),

                      // First Name Field (Read-only)
                      TextFormField(
                        controller: _firstNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'First Name (Cannot Edit)',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        readOnly: true,
                        enabled: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),

                      // Last Name Field (Read-only)
                      TextFormField(
                        controller: _lastNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Last Name (Cannot Edit)',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        readOnly: true,
                        enabled: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),

                      // Email Field (Read-only)
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email (Cannot Edit)',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        readOnly: true,
                        enabled: false,
                      ),
                      SizedBox(height: 12),

                      // Phone Number Field (Editable)
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '(PH) 09',
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (value.length != 11) {
                            return 'Phone number must be exactly 11 digits';
                          }
                          if (!value.startsWith('09')) {
                            return 'Must start with 09 (Philippine format)';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),

                      // Blood Type Dropdown (Read-only)
                      DropdownButtonFormField<String>(
                        value: _selectedBloodType,
                        decoration: InputDecoration(
                          labelText: 'Blood Type (Cannot Edit)',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        items: bloodTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: null, // Disabled
                      ),
                      SizedBox(height: 12),

                      // Barangay Dropdown (Editable)
                      DropdownButtonFormField<String>(
                        value: _selectedBarangay,
                        decoration: InputDecoration(
                          labelText: 'Barangay',
                          border: OutlineInputBorder(),
                        ),
                        items: barangays.map((String barangay) {
                          return DropdownMenuItem<String>(
                            value: barangay,
                            child: Text(barangay),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBarangay = value!;
                          });
                        },
                      ),

                      SizedBox(height: 24),
                      _buildEditAvailabilitySection(),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),
              _buildEditActionButtons(),
            ],
          ),
        )
    );
  }

  Widget _buildEditAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Availability',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Set your current availability.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 16),
        // Toggle Switch
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
              // Toggle Switch
              GestureDetector(
                onTap: _toggleAvailability,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: 60,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: _isAvailable ? Color(0xFFEF4444) : Colors.grey.shade400,
                  ),
                  child: Stack(
                    children: [
                      // Background text
                      AnimatedPositioned(
                        duration: Duration(milliseconds: 200),
                        left: _isAvailable ? 8 : 32,
                        right: _isAvailable ? 32 : 8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            _isAvailable ? 'ON' : 'OFF',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Thumb
                      AnimatedAlign(
                        duration: Duration(milliseconds: 200),
                        alignment: _isAvailable ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: 24,
                          height: 24,
                          margin: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        // Status indicator
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isAvailable ? Colors.green.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isAvailable ? Colors.green.shade200 : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isAvailable ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: _isAvailable ? Colors.green : Colors.grey,
              ),
              SizedBox(width: 6),
              Text(
                _isAvailable ? 'You are available' : 'You are currently unavailable',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: _isAvailable ? Colors.green.shade700 : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

// Add this method to handle the toggle and database update
  void _toggleAvailability() async {
    final newAvailability = !_isAvailable;

    // First update UI immediately for better UX
    setState(() {
      _isAvailable = newAvailability;
    });

    // Then update the database
    await _updateAvailabilityInDatabase(newAvailability);
  }

// Method to update availability in database
  Future<void> _updateAvailabilityInDatabase(bool isAvailable) async {
    try {
      print('🔄 Updating availability in database: $isAvailable');

      // Send all required fields to avoid missing parameter errors
      final updateData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bloodType': _selectedBloodType,
        'barangay': _selectedBarangay,
        'isAvailable': isAvailable, // Include availability
      };

      // Remove any null values
      updateData.removeWhere((key, value) => value == null);

      print('📤 Update data: $updateData');

      final result = await ApiService.updateProfile(updateData);

      if (result['success']) {
        print('✅ Availability updated successfully in database');
        // Since we already updated the UI locally, just ensure the timer
        // picks up the latest state next time.
      } else {
        print('❌ Failed to update availability: ${result['error']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update availability'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('💥 Error updating availability: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    print('🏷️ Building detail item: $label = $value');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? 'Not set' : value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Set your current availability.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Checkbox(
              value: _isAvailable,
              onChanged: _isEditing
                  ? (value) {
                setState(() {
                  _isAvailable = value ?? false;
                });
                // Update database when checkbox changes
                if (_isEditing) {
                  _updateAvailabilityInDatabase(value ?? false);
                }
              }
                  : null,
              activeColor: Color(0xFFEF4444),
            ),
            Text(
              _isAvailable ? 'Available' : 'Currently unavailable',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: _isAvailable ? Colors.green.shade700 : Colors.grey.shade700,
                fontWeight: _isAvailable ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        // Status indicator
        if (!_isEditing)
          Container(
            margin: EdgeInsets.only(left: 40),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isAvailable ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isAvailable ? Colors.green.shade200 : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isAvailable ? Icons.check_circle : Icons.cancel,
                  size: 14,
                  color: _isAvailable ? Colors.green : Colors.grey,
                ),
                SizedBox(width: 6),
                Text(
                  _isAvailable ? 'Ready' : 'Not Ready',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: _isAvailable ? Colors.green.shade700 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Manage your password settings.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 12),
        if (!_isEditing)
          ElevatedButton(
            onPressed: () {
              // NAVIGATE TO CHANGE PASSWORD SCREEN HERE
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF038043),
              side: BorderSide(color: Color(0xFF038043)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Change Password',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  void _handleArchiveAccount() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Deactivate Account',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to archive your account?',
                style: GoogleFonts.poppins(),
              ),
              SizedBox(height: 12),
              Text(
                '• You will be logged out immediately.\n• You will receive an email with a link to restore your account within 30 days.',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                // 1. Close the confirmation dialog
                Navigator.of(dialogContext).pop();

                // 2. Show Loading Dialog
                if (!mounted) return;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => Center(
                    child: CircularProgressIndicator(color: Color(0xFFEF4444)),
                  ),
                );

                try {
                  // 3. Perform API Call
                  final result = await ApiService.archiveAccount();

                  // 4. Close Loading Dialog
                  if (mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }

                  if (result['success'] == true) {
                    // 5. Success Logic: Logout and Redirect
                    await ApiService.logout();

                    if (!mounted) return;

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? 'Account archived. Check your email to restore.'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 4),
                      ),
                    );

                    // Redirect to Login
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                          (route) => false,
                    );
                  } else {
                    // Failure Logic
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['error'] ?? 'Failed to archive account'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  // Error Logic
                  if (mounted) {
                    // Ensure loading dialog is closed if error occurs
                    if (Navigator.of(context).canPop()) Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('An error occurred: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: Text(
                'Yes, Archive',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildArchiveSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Archive This Account',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleArchiveAccount, // Connect the function here
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade400),
            ),
            child: Text('Archive Account'),
          ),
        ),
      ],
    );
  }

  Widget _buildEditActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _cancelEdit,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFEF4444), // Changed to your app's red color
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Save Changes',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _maskEmail(String email) {
    if (email.length <= 2) return email;
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 1) return email;

    final maskedUsername = username[0] + '*' * (username.length - 1);
    return '$maskedUsername@$domain';
  }

  String _maskPhone(String phone) {
    if (phone.length <= 4) return phone;
    return '*' * (phone.length - 4) + phone.substring(phone.length - 4);
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  // Loading state
  bool _isLoading = false;

  // Visibility states
  bool _isCurrentVisible = false;
  bool _isNewVisible = false;
  bool _isConfirmVisible = false;

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Call the API
      final result = await ApiService.changePassword(
        currentPassword: _currentPassController.text,
        newPassword: _newPassController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to previous screen
      } else {
        // Show error message (e.g., Incorrect current password)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to change password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Change Password',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create new password',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your new password must be different from previous used passwords.',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 32),

              // 1. Current Password
              _buildPasswordField(
                controller: _currentPassController,
                label: 'Current Password',
                isVisible: _isCurrentVisible,
                onVisibilityChanged: () {
                  setState(() => _isCurrentVisible = !_isCurrentVisible);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter current password';
                  return null;
                },
              ),
              SizedBox(height: 20),

              // 2. New Password
              _buildPasswordField(
                controller: _newPassController,
                label: 'New Password',
                isVisible: _isNewVisible,
                onVisibilityChanged: () {
                  setState(() => _isNewVisible = !_isNewVisible);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter new password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  // Regex: At least one UPPERCASE, one number, one special char (including underscore)
                  if (!RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~_]).+$').hasMatch(value)) {
                    return 'Must contain:\n- 1 Upper\n- 1 Number\n- 1 Special Character (!@#\$&*~_)';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

// 3. Confirm New Password
              _buildPasswordField(
                controller: _confirmPassController,
                label: 'Confirm New Password',
                isVisible: _isConfirmVisible,
                onVisibilityChanged: () {
                  setState(() => _isConfirmVisible = !_isConfirmVisible);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm new password';
                  }
                  if (value != _newPassController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 40),

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : Text(
                    'Update Password',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onVisibilityChanged,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade700),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey.shade600,
          ),
          onPressed: onVisibilityChanged,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
    );
  }
}

// Donor Model
class Donor {
  final String id;
  final String name;
  final String firstName;
  final String lastName;
  final String bloodType;
  final String email;
  final String phone;
  final String city;
  final String barangay;
  final bool isAvailable;
  final bool isDonor;
  final String userId;
  final String userNumber;
  final bool isArchived; // 1. ADD THIS FIELD

  Donor({
    required this.id,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.bloodType,
    required this.email,
    required this.phone,
    required this.city,
    required this.barangay,
    required this.isAvailable,
    required this.isDonor,
    required this.userId,
    required this.userNumber,
    this.isArchived = false, // 2. ADD THIS TO CONSTRUCTOR
  });

  // Helper method to convert string to boolean
  static bool _stringToBool(String value) {
    return value == 'Donor' || value == 'Available' || value == 'true' || value == '1';
  }

  factory Donor.fromJson(Map<String, dynamic> json) {
    // Convert string values to boolean
    final isAvailableString = json['isAvailable']?.toString() ??
        json['is_available']?.toString() ?? 'Unavailable';
    final isDonorString = json['isDonor']?.toString() ??
        json['is_donor']?.toString() ?? 'Recipient';

    final rawArchived = json['isArchived'] ?? json['is_archived'];

    bool archivedStatus = false;
    if (rawArchived != null) {
      if (rawArchived is bool) {
        archivedStatus = rawArchived;
      } else if (rawArchived is int) {
        archivedStatus = rawArchived == 1;
      } else if (rawArchived is String) {
        archivedStatus = rawArchived == '1' || rawArchived.toLowerCase() == 'true';
      }
    }

    return Donor(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      bloodType: json['bloodType']?.toString() ?? json['blood_type']?.toString() ?? 'Unknown',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      city: json['city']?.toString() ?? 'Santa Cruz',
      barangay: json['barangay']?.toString() ?? 'Unknown',
      isAvailable: _stringToBool(isAvailableString),
      isDonor: _stringToBool(isDonorString),
      userId: json['id']?.toString() ?? json['userId']?.toString() ?? '',
      userNumber: json['userNumber']?.toString() ?? '',
      isArchived: archivedStatus, // 4. ASSIGN PARSED VALUE
    );
  }
}

enum MessageStatus { sending, sent, notSent, read }

class ChatMessage {
  final int id;
  final int senderId;
  final int receiverId;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  MessageStatus status; // Added field for UI state

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.status = MessageStatus.sent, // Default to sent for loaded messages
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    bool read = json['is_read'] == 1 || json['is_read'] == true;

    return ChatMessage(
      id: json['id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      receiverId: json['receiver_id'] ?? 0,
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? json['formatted_date'] ?? DateTime.now().toString()),
      isRead: read,
      // If it's loaded from DB and is_read is true, status is read. Otherwise sent.
      status: read ? MessageStatus.read : MessageStatus.sent,
    );
  }
}



