import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:36512/api';
  static String? _token;

  static void setToken(String token) {
    _token = token;
    print('✅ Token set: ${_token?.substring(0, 20)}...');
  }

  static void clearToken() {
    _token = null;
    print('✅ Token cleared');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
    };

    // Fix: Load token from SharedPrefs if memory token is null
    if (_token == null) {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      if (_token != null) {
        print('🔄 Token restored from storage');
      }
    }

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  static dynamic _parseResponse(String responseBody) {
    try {
      return jsonDecode(responseBody);
    } catch (e) {
      print('❌ JSON parsing error: $e');
      print('❌ Response body: $responseBody');
      return null;
    }
  }

  static Future<Map<String, dynamic>> _handleRequest(
      Future<http.Response> request, {
        String operation = 'API call',
      }) async {
    try {
      final response = await request;
      print('📡 $operation response: ${response.statusCode}');

      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('text/html') ||
          response.body.trim().startsWith('<!DOCTYPE html>') ||
          response.body.trim().startsWith('<html>')) {
        return {
          'success': false,
          'error': 'Server returned HTML instead of JSON. Check server configuration.',
          'statusCode': response.statusCode,
        };
      }

      final data = _parseResponse(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': data,
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'error': data?['error'] ?? 'HTTP ${response.statusCode}',
          'statusCode': response.statusCode,
          'data': data,
        };
      }
    } catch (e) {
      print('💥 $operation error: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> testApi() async {
    print('🧪 Testing API connection to: $baseUrl/test');
    return await _handleRequest(
      http.get(
        Uri.parse('$baseUrl/test'),
        headers: await _getHeaders(),
      ),
      operation: 'Test API',
    );
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    print('📝 Registering user: ${userData['email']}');

    final result = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/register'),
        headers: await _getHeaders(),
        body: jsonEncode(userData),
      ),
      operation: 'Registration',
    );

    if (result['success'] == true) {
      final token = result['data']?['token'];
      if (token != null) {
        setToken(token);
      }
    }

    return result;
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    print('🔐 Logging in user: $email');

    final result = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      ),
      operation: 'Login',
    );

    if (result['success'] == true) {
      final token = result['data']?['token'];
      if (token != null) {
        setToken(token);
      } else {
        print('⚠️ Warning: No token in successful login response');
      }
    }

    return result;
  }

  static Future<Map<String, dynamic>> requestPasswordResetOtp(String email) async {
    print('📧 Requesting OTP for: $email');
    return await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ),
      operation: 'Request OTP',
    );
  }

  // 2. Verify OTP
  static Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    print('🔢 Verifying OTP for: $email');
    return await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      ),
      operation: 'Verify OTP',
    );
  }

  // 3. Reset Password Final
  static Future<Map<String, dynamic>> resetPasswordFinal(String email, String otp, String newPassword) async {
    print('🔐 Resetting password for: $email');
    return await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/reset-password-final'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp, // Sending OTP again to ensure security
          'newPassword': newPassword
        }),
      ),
      operation: 'Reset Password',
    );
  }

  static Future<Map<String, dynamic>> getDonors({
    String? bloodType,
    String? barangay,
    String? search
  }) async {
    print('🔄 Fetching donors...');

    final params = <String, String>{};
    if (bloodType != null && bloodType != 'All') params['blood_type'] = bloodType;
    if (barangay != null && barangay != 'All') params['barangay'] = barangay;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse('$baseUrl/donors').replace(queryParameters: params);
    print('🔄 Fetching donors from: $uri');

    return await _handleRequest(
      http.get(uri, headers: await _getHeaders()),
      operation: 'Get Donors',
    );
  }

  static Future<Map<String, dynamic>> getProfile({required String userId}) async {
    print('👤 Getting user profile...');
    return await _handleRequest(
      http.get(
        Uri.parse('$baseUrl/profile'),
        headers: await _getHeaders(),
      ),
      operation: 'Get Profile',
    );
  }

  static Future<String?> _getCurrentUserId() async {
    final token = await SharedPreferences.getInstance().then((prefs) => prefs.getString('token'));
    if (token != null) {
      // Decode JWT token to get user ID
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = json.decode(utf8.decode(base64Url.decode(parts[1])));
      return payload['userId']?.toString();
    }
    return null;
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    print('📝 Updating user profile...');
    print('📤 Profile data to send: $profileData');

    // Debug each field to ensure nothing is null/undefined
    profileData.forEach((key, value) {
      print('   - $key: $value (type: ${value.runtimeType}, isNull: ${value == null})');
    });

    // Ensure all values are properly defined
    final sanitizedData = Map<String, dynamic>.from(profileData);
    sanitizedData.removeWhere((key, value) => value == null);

    print('📤 Sanitized data: $sanitizedData');

    final jsonString = jsonEncode(sanitizedData);
    print('📤 RAW JSON string: $jsonString');

    return await _handleRequest(
      http.put(
        Uri.parse('$baseUrl/profile'),
        headers: await _getHeaders(),
        body: jsonString,
      ),
      operation: 'Update Profile',
    );
  }

  static Future<Map<String, dynamic>> getMapDonors() async {
    return await _handleRequest(
      http.get(
        Uri.parse('$baseUrl/donors/map'),
        headers: await _getHeaders(),
      ),
      operation: 'Get Map Donors',
    );
  }

  static Future<Map<String, dynamic>> logout() async {
    final result = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/logout'),
        headers: await _getHeaders(),
      ),
      operation: 'Logout',
    );

    clearToken();
    return result;
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/change-password'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ),
      operation: 'Change Password',
    );
  }

  // Send a message
  static Future<Map<String, dynamic>> sendMessage(String receiverId, String message) async {
    return await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/messages/send'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'receiverId': receiverId,
          'message': message,
        }),
      ),
      operation: 'Send Message',
    );
  }

  // Get specific chat history
  static Future<Map<String, dynamic>> getChatHistory(String otherUserId) async {
    return await _handleRequest(
      http.get(
        Uri.parse('$baseUrl/messages/chat/$otherUserId'),
        headers: await _getHeaders(),
      ),
      operation: 'Get Chat History',
    );
  }

  // Get list of conversations (inbox)
  static Future<Map<String, dynamic>> getConversations() async {
    return await _handleRequest(
      http.get(
        Uri.parse('$baseUrl/messages/conversations'),
        headers: await _getHeaders(),
      ),
      operation: 'Get Conversations',
    );
  }

  static Future<Map<String, dynamic>> deleteAccount() async {
    return await _handleRequest(
      http.delete(
        Uri.parse('$baseUrl/profile'),
        headers: await _getHeaders(),
      ),
      operation: 'Delete Account',
    );
  }

  static Future<Map<String, dynamic>> requestBlood({
    required String bloodType,
    required int units,
    required String hospital,
    required String urgency,
    String? notes,
  }) async {
    return await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/blood-requests'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'bloodType': bloodType,
          'units': units,
          'hospital': hospital,
          'urgency': urgency,
          'notes': notes,
        }),
      ),
      operation: 'Request Blood',
    );
  }

  static Future<Map<String, dynamic>> getBloodRequests() async {
    return await _handleRequest(
      http.get(
        Uri.parse('$baseUrl/blood-requests'),
        headers: await _getHeaders(),
      ),
      operation: 'Get Blood Requests',
    );
  }

  static Future<Map<String, dynamic>> getDonationHistory() async {
    return await _handleRequest(
      http.get(
        Uri.parse('$baseUrl/donation-history'),
        headers: await _getHeaders(),
      ),
      operation: 'Get Donation History',
    );
  }

  static Future<Map<String, dynamic>> updateDonorStatus({
    required String isAvailable, // Changed to String
    String? nextAvailableDate,
  }) async {
    return await _handleRequest(
      http.put(
        Uri.parse('$baseUrl/donor/status'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'isAvailable': isAvailable, // Now sends string value
          'nextAvailableDate': nextAvailableDate,
        }),
      ),
      operation: 'Update Donor Status',
    );
  }

  static Future<Map<String, dynamic>> getNotifications() async {
    return await _handleRequest(
      http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: await _getHeaders(),
      ),
      operation: 'Get Notifications',
    );
  }

  static Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) async {
    return await _handleRequest(
      http.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: await _getHeaders(),
      ),
      operation: 'Mark Notification Read',
    );
  }

  static Future<Map<String, dynamic>> getStatistics() async {
    return await _handleRequest(
      http.get(
        Uri.parse('$baseUrl/statistics'),
        headers: await _getHeaders(),
      ),
      operation: 'Get Statistics',
    );
  }

  static Future<Map<String, dynamic>> setNickname(String partnerId, String nickname) async {
    return await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/messages/nickname'),
        headers: await _getHeaders(),
        body: jsonEncode({'partnerId': partnerId, 'nickname': nickname}),
      ),
      operation: 'Set Nickname',
    );
  }

  static Future<Map<String, dynamic>> archiveConversation(String partnerId) async {
    return await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/messages/archive'),
        headers: await _getHeaders(),
        body: jsonEncode({'partnerId': partnerId}),
      ),
      operation: 'Archive Chat',
    );
  }

  static Future<Map<String, dynamic>> deleteConversation(String partnerId) async {
    return await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/messages/delete'),
        headers: await _getHeaders(),
        body: jsonEncode({'partnerId': partnerId}),
      ),
      operation: 'Delete Chat',
    );
  }

  static Future<Map<String, dynamic>> reportUser(String reportedUserId, String reason, String description) async {
    return await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/users/report'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'reportedUserId': reportedUserId,
          'reason': reason,
          'description': description
        }),
      ),
      operation: 'Report User',
    );
  }

  static Future<Map<String, dynamic>> getArchivedConversations() async {
    return await _handleRequest(
      http.get(Uri.parse('$baseUrl/messages/archived'), headers: await _getHeaders()),
      operation: 'Get Archived Chats',
    );
  }

  // Restore chat to main inbox
  static Future<Map<String, dynamic>> unarchiveConversation(String partnerId) async {
    return await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/messages/unarchive'),
        headers: await _getHeaders(),
        body: jsonEncode({'partnerId': partnerId}),
      ),
      operation: 'Unarchive Chat',
    );
  }

  static Future<Map<String, dynamic>> getOtherUserProfile(String userId) async {
    return await _handleRequest(
      http.get(
        Uri.parse('$baseUrl/users/$userId'), // Calls the new endpoint
        headers: await _getHeaders(),
      ),
      operation: 'Get Other User Profile',
    );
  }

  static Future<Map<String, dynamic>> requestDonation(
      String donorId, String notes) async {
    return await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/requests/initiate'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'donorId': donorId,
          'notes': notes,
        }),
      ),
      operation: 'Initiate Donation Request',
    );
  }

  // 2. Update Blood Donation Request Status
  static Future<Map<String, dynamic>> updateDonationRequest(
      String requestId, String action) async {
    return await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/requests/$requestId/update'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'action': action, // 'Accept', 'Decline', 'Cancel', 'Complete'
        }),
      ),
      operation: 'Update Donation Request Status',
    );
  }

  // 3. Get all Donation Requests relevant to the chat
  static Future<Map<String, dynamic>> getDonationRequestsByChat(String partnerId) async {
    return await _handleRequest(
      http.get(
        Uri.parse('$baseUrl/requests/chat/$partnerId'),
        headers: await _getHeaders(),
      ),
      operation: 'Get Donation Requests By Chat',
    );
  }

  static Future<Map<String, dynamic>> archiveAccount() async {
    return await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/archive-account'), // Matches the Node.js route defined above
        headers: await _getHeaders(),
      ),
      operation: 'Archive Account',
    );
  }




}

void testConnection() async {
  final result = await ApiService.testApi();
  print('Test connection result: $result');
}

class ApiResponse<T> {
  final bool success;
  final String? error;
  final T? data;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.error,
    this.data,
    this.statusCode,
  });

  factory ApiResponse.fromMap(Map<String, dynamic> map) {
    return ApiResponse(
      success: map['success'] ?? false,
      error: map['error'],
      data: map['data'],
      statusCode: map['statusCode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'error': error,
      'data': data,
      'statusCode': statusCode,
    };
  }

  @override
  String toString() {
    return 'ApiResponse(success: $success, error: $error, data: $data, statusCode: $statusCode)';
  }
}

class User {
  final String id;
  final String email;
  final String name;
  final String? bloodType;
  final String? phone;
  final String? address;
  final String? barangay;
  final DateTime? dateOfBirth;
  final String isDonor; // Changed to String
  final String isAvailable; // Changed to String
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.bloodType,
    this.phone,
    this.address,
    this.barangay,
    this.dateOfBirth,
    required this.isDonor, // Now required String
    required this.isAvailable, // Now required String
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      bloodType: json['blood_type'] ?? json['bloodType'],
      phone: json['phone'],
      address: json['address'],
      barangay: json['barangay'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      isDonor: json['is_donor']?.toString() ?? json['isDonor']?.toString() ?? 'Recipient', // Convert to string
      isAvailable: json['is_available']?.toString() ?? json['isAvailable']?.toString() ?? 'Unavailable', // Convert to string
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'blood_type': bloodType,
      'phone': phone,
      'address': address,
      'barangay': barangay,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'is_donor': isDonor,
      'is_available': isAvailable,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class Donor {
  final String id;
  final String name;
  final String email;
  final String bloodType;
  final String? phone;
  final String? address;
  final String barangay;
  final double latitude;
  final double longitude;
  final String isAvailable; // Changed to String
  final String isDonor; // Changed to String
  final DateTime? lastDonationDate;
  final DateTime? nextAvailableDate;
  final double distance;

  Donor({
    required this.id,
    required this.name,
    required this.email,
    required this.bloodType,
    this.phone,
    this.address,
    required this.barangay,
    required this.latitude,
    required this.longitude,
    required this.isAvailable, // Now required String
    required this.isDonor, // Now required String
    this.lastDonationDate,
    this.nextAvailableDate,
    this.distance = 0.0,
  });

  factory Donor.fromJson(Map<String, dynamic> json) {
    return Donor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      bloodType: json['blood_type'] ?? json['bloodType'] ?? '',
      phone: json['phone'],
      address: json['address'],
      barangay: json['barangay'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      isAvailable: json['is_available']?.toString() ?? json['isAvailable']?.toString() ?? 'Unavailable', // Convert to string
      isDonor: json['is_donor']?.toString() ?? json['isDonor']?.toString() ?? 'Recipient', // Convert to string
      lastDonationDate: json['last_donation_date'] != null
          ? DateTime.parse(json['last_donation_date'])
          : json['lastDonationDate'] != null
          ? DateTime.parse(json['lastDonationDate'])
          : null,
      nextAvailableDate: json['next_available_date'] != null
          ? DateTime.parse(json['next_available_date'])
          : json['nextAvailableDate'] != null
          ? DateTime.parse(json['nextAvailableDate'])
          : null,
      distance: (json['distance'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'blood_type': bloodType,
      'phone': phone,
      'address': address,
      'barangay': barangay,
      'latitude': latitude,
      'longitude': longitude,
      'is_available': isAvailable,
      'is_donor': isDonor,
      'last_donation_date': lastDonationDate?.toIso8601String(),
      'next_available_date': nextAvailableDate?.toIso8601String(),
      'distance': distance,
    };
  }
}

class BloodRequest {
  final String id;
  final String patientName;
  final String bloodType;
  final int units;
  final String hospital;
  final String urgency;
  final String status;
  final String? notes;
  final DateTime requestedAt;
  final DateTime? fulfilledAt;

  BloodRequest({
    required this.id,
    required this.patientName,
    required this.bloodType,
    required this.units,
    required this.hospital,
    required this.urgency,
    required this.status,
    this.notes,
    required this.requestedAt,
    this.fulfilledAt,
  });

  factory BloodRequest.fromJson(Map<String, dynamic> json) {
    return BloodRequest(
      id: json['id'] ?? '',
      patientName: json['patient_name'] ?? json['patientName'] ?? '',
      bloodType: json['blood_type'] ?? json['bloodType'] ?? '',
      units: json['units'] ?? 0,
      hospital: json['hospital'] ?? '',
      urgency: json['urgency'] ?? '',
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      requestedAt: json['requested_at'] != null
          ? DateTime.parse(json['requested_at'])
          : json['requestedAt'] != null
          ? DateTime.parse(json['requestedAt'])
          : DateTime.now(),
      fulfilledAt: json['fulfilled_at'] != null
          ? DateTime.parse(json['fulfilled_at'])
          : json['fulfilledAt'] != null
          ? DateTime.parse(json['fulfilledAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_name': patientName,
      'blood_type': bloodType,
      'units': units,
      'hospital': hospital,
      'urgency': urgency,
      'status': status,
      'notes': notes,
      'requested_at': requestedAt.toIso8601String(),
      'fulfilled_at': fulfilledAt?.toIso8601String(),
    };
  }
}