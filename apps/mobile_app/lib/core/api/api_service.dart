import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _liveUrl =
      'https://habit-track-delta-three.vercel.app'; // TODO: Update later

  static String get baseUrl {
    if (kReleaseMode) return _liveUrl;

    // In debug mode, use the appropriate local address
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000'; // Android emulator access
    }
    return 'http://localhost:3000'; // iOS/Desktop/Web access
  }

  static String? _token;
  static bool _isGuest = false;

  static bool get isGuest => _isGuest;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _isGuest = prefs.getBool('is_guest') ?? false;
  }

  static void setToken(String token, {bool isGuest = false}) async {
    _token = token;
    _isGuest = isGuest;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setBool('is_guest', isGuest);
  }

  static Future<void> logout() async {
    _token = null;
    _isGuest = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('is_guest');
  }

  static bool get isAuthenticated => _token != null;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setToken(data['access_token'], isGuest: false);
      return data;
    }
    try {
      final data = jsonDecode(res.body);
      if (data is Map && data['message'] != null) {
        final msg = data['message'];
        throw msg is List ? msg.join(', ') : msg.toString();
      }
    } catch (e) {
      if (e is String) rethrow;
      if (e is! FormatException) rethrow;
    }
    throw Exception('Login failed');
  }

  static Future<Map<String, dynamic>> register(
    String email,
    String password, {
    String? firstName,
    String? lastName,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      }),
    );
    if (res.statusCode == 201) {
      final data = jsonDecode(res.body);
      setToken(data['access_token'], isGuest: false);
      return data;
    }
    try {
      final data = jsonDecode(res.body);
      if (data is Map && data['message'] != null) {
        final msg = data['message'];
        throw msg is List ? msg.join(', ') : msg.toString();
      }
    } catch (e) {
      if (e is String) rethrow;
      if (e is! FormatException) rethrow;
    }
    throw Exception('Register failed');
  }

  static Future<void> loginGuest() async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/guest'),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setToken(data['access_token'], isGuest: true);
      return;
    }
    throw Exception('Failed to login as guest');
  }

  static Future<Map<String, dynamic>> upgrade(
    String email,
    String password, {
    String? firstName,
    String? lastName,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/upgrade'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      }),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setToken(data['access_token'], isGuest: false);
      return data;
    }
    try {
      final data = jsonDecode(res.body);
      if (data is Map && data['message'] != null) {
        final msg = data['message'];
        throw msg is List ? msg.join(', ') : msg.toString();
      }
    } catch (e) {
      if (e is String) rethrow;
      if (e is! FormatException) rethrow;
    }
    throw Exception('Failed to upgrade guest account');
  }

  static Future<List<dynamic>> getHabits() async {
    final res = await http.get(Uri.parse('$baseUrl/habits'), headers: _headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load habits');
  }

  static Future<Map<String, dynamic>> createHabit(
    Map<String, dynamic> data,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/habits'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 201) return jsonDecode(res.body);
    throw Exception('Failed to create habit');
  }

  static Future<Map<String, dynamic>> updateHabit(
    String id,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/habits/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to update habit');
  }

  static Future<void> deleteHabit(String id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/habits/$id'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception('Failed to delete habit');
  }

  static Future<Map<String, dynamic>> toggleHabit(
    String id,
    String date,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/habits/$id/toggle'),
      headers: _headers,
      body: jsonEncode({'date': date}),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Failed to toggle habit');
  }

  static Future<Map<String, dynamic>> generateHabits(String message) async {
    final res = await http.post(
      Uri.parse('$baseUrl/ai/chat'),
      headers: _headers,
      body: jsonEncode({'message': message}),
    );
    if (res.statusCode == 201) {
      return jsonDecode(res.body)['aiResponse'];
    }
    throw Exception('Failed to communicate with AI');
  }

  static Future<Map<String, dynamic>> clarifyGoal(String prompt) async {
    final res = await http.post(
      Uri.parse('$baseUrl/goals/clarify'),
      headers: _headers,
      body: jsonEncode({'prompt': prompt}),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Failed to clarify goal');
  }

  static Future<Map<String, dynamic>> evaluateGoal(
    String prompt, {
    int? durationDays,
    Map<String, String>? answers,
    String? startDate,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/goals/evaluate'),
      headers: _headers,
      body: jsonEncode({
        'prompt': prompt,
        if (durationDays != null) 'durationDays': durationDays,
        if (answers != null) 'answers': answers,
        if (startDate != null) 'startDate': startDate,
      }),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Failed to evaluate goal');
  }

  static Future<Map<String, dynamic>> generateRoadmap(
    String prompt, {
    int? durationDays,
    Map<String, String>? answers,
    Map<String, dynamic>? previousPlan,
    String? refinementPrompt,
    String? startDate,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/goals/roadmap'),
      headers: _headers,
      body: jsonEncode({
        'prompt': prompt,
        if (durationDays != null) 'durationDays': durationDays,
        if (answers != null) 'answers': answers,
        if (previousPlan != null) 'previousPlan': previousPlan,
        if (refinementPrompt != null) 'refinementPrompt': refinementPrompt,
        if (startDate != null) 'startDate': startDate,
      }),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Failed to generate roadmap');
  }

  static Future<Map<String, dynamic>> createGoal(
    String prompt,
    Map<String, dynamic> aiPlan, {
    int? durationDays,
    String? category,
    String? feasibility,
    String? startDate,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/goals'),
      headers: _headers,
      body: jsonEncode({
        'prompt': prompt,
        'aiPlan': aiPlan,
        'durationDays': (durationDays != null) ? durationDays : null,
        'category': (category != null) ? category : null,
        'feasibility': (feasibility != null) ? feasibility : null,
        if (startDate != null) 'startDate': startDate,
      }),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Failed to create goal');
  }

  static Future<List<dynamic>> getGoals() async {
    final res = await http.get(Uri.parse('$baseUrl/goals'), headers: _headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load goals');
  }

  static Future<Map<String, dynamic>> getGoalDetails(String id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/goals/$id'),
      headers: _headers,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load goal details');
  }

  static Future<Map<String, dynamic>> updateActionItem(
    String id,
    bool isCompleted,
  ) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/goals/action-items/$id'),
      headers: _headers,
      body: jsonEncode({'isCompleted': isCompleted}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to update action item');
  }

  static Future<Map<String, dynamic>> generateActionItemSteps(String id) async {
    final res = await http.post(
      Uri.parse('$baseUrl/goals/action-items/$id/generate-steps'),
      headers: _headers,
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Failed to generate steps');
  }

  static Future<Map<String, dynamic>> generateTasksForMilestone(String id) async {
    final res = await http.post(
      Uri.parse('$baseUrl/goals/milestones/$id/generate-tasks'),
      headers: _headers,
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Failed to generate tasks for milestone');
  }

  static Future<Map<String, dynamic>> toggleTaskStep(
    String id,
    bool isCompleted,
  ) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/goals/steps/$id'),
      headers: _headers,
      body: jsonEncode({'isCompleted': isCompleted}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to toggle step');
  }

  // Profile API
  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to fetch profile');
  }

  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to update profile');
  }

  // Friends & Leaderboard API
  static Future<void> sendFriendRequest(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/friends/request'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Failed to send friend request');
    }
  }

  static Future<void> acceptFriendRequest(String requestId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/friends/accept/$requestId'),
      headers: _headers,
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Failed to accept request');
    }
  }

  static Future<void> rejectFriendRequest(String requestId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/friends/reject/$requestId'),
      headers: _headers,
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Failed to reject request');
    }
  }

  static Future<List<dynamic>> getFriends() async {
    final res = await http.get(
      Uri.parse('$baseUrl/friends'),
      headers: _headers,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load friends');
  }

  static Future<List<dynamic>> getPendingRequests() async {
    final res = await http.get(
      Uri.parse('$baseUrl/friends/requests'),
      headers: _headers,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load friend requests');
  }

  static Future<List<dynamic>> getLeaderboard() async {
    final res = await http.get(
      Uri.parse('$baseUrl/friends/leaderboard'),
      headers: _headers,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load leaderboard');
  }

  // XP API
  static Future<List<dynamic>> getXpHistory() async {
    final res = await http.get(
      Uri.parse('$baseUrl/xp/history'),
      headers: _headers,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load XP history');
  }
}
