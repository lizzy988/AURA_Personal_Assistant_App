
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost/aura_api';

  // FORMAT DATE AND TIME FOR MYSQL
  static String formatDateTime(DateTime date) {
    final d = date.toLocal();

    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}:00';
  }

  // COMMON POST REQUEST
  static Future<Map<String, dynamic>> _post(
    Map<String, dynamic> body,
    String endpoint,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/$endpoint'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response from the server.');
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        decoded['message'] ?? 'Server request failed.',
      );
    }

    return decoded;
  }

  // USER REGISTRATION
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    return _post({
      'full_name': fullName,
      'email': email,
      'password': password,
    }, 'register.php');
  }

  // USER LOGIN
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return _post({
      'email': email,
      'password': password,
    }, 'login.php');
  }

  // DAILY PLANNER
  static Future<List<dynamic>> getActivities({
    required int userId,
  }) async {
    final result = await _post({
      'action': 'list',
      'user_id': userId,
    }, 'activities.php');

    if (result['success'] != true) {
      throw Exception(
        result['message'] ?? 'Could not load activities.',
      );
    }

    final data = result['data'];
    return data is List ? data : [];
  }

  static Future<Map<String, dynamic>> createActivity({
    required int userId,
    required String title,
    required String type,
    required DateTime scheduledAt,
    required String priority,
  }) async {
    return _post({
      'action': 'create',
      'user_id': userId,
      'title': title,
      'type': type,
      'scheduled_at': formatDateTime(scheduledAt),
      'priority': priority,
    }, 'activities.php');
  }

  static Future<Map<String, dynamic>> updateActivity({
    required int userId,
    required int id,
    required String title,
    required String type,
    required DateTime scheduledAt,
    required String priority,
    required bool completed,
  }) async {
    return _post({
      'action': 'update',
      'user_id': userId,
      'id': id,
      'title': title,
      'type': type,
      'scheduled_at': formatDateTime(scheduledAt),
      'priority': priority,
      'completed': completed,
    }, 'activities.php');
  }

  static Future<Map<String, dynamic>> deleteActivity({
    required int userId,
    required int id,
    required String type,
  }) async {
    return _post({
      'action': 'delete',
      'user_id': userId,
      'id': id,
      'type': type,
    }, 'activities.php');
  }

  // INTELLIGENT REMINDERS

  // GET ALL REMINDERS
  static Future<List<dynamic>> getReminders({
    required int userId,
  }) async {
    final result = await _post({
      'action': 'list',
      'user_id': userId,
    }, 'reminders.php');

    if (result['success'] != true) {
      throw Exception(
        result['message'] ?? 'Could not load reminders.',
      );
    }

    final data = result['data'];
    return data is List ? data : [];
  }

  // CREATE REMINDER
  static Future<Map<String, dynamic>> createReminder({
    required int userId,
    required String title,
    required DateTime reminderDateTime,
    int? taskId,
    bool notificationEnabled = true,
  }) async {
    return _post({
      'action': 'create',
      'user_id': userId,
      'title': title,
      'reminder_datetime': formatDateTime(reminderDateTime),
      'task_id': taskId,
      'notification_enabled': notificationEnabled ? 1 : 0,
    }, 'reminders.php');
  }

  // UPDATE / RESCHEDULE REMINDER
  static Future<Map<String, dynamic>> updateReminder({
    required int userId,
    required int reminderId,
    required String title,
    required DateTime reminderDateTime,
    int? taskId,
    bool notificationEnabled = true,
  }) async {
    return _post({
      'action': 'update',
      'user_id': userId,
      'reminder_id': reminderId,
      'title': title,
      'reminder_datetime': formatDateTime(reminderDateTime),
      'task_id': taskId,
      'notification_enabled': notificationEnabled ? 1 : 0,
    }, 'reminders.php');
  }

  // TOGGLE NOTIFICATION PREFERENCE
  static Future<Map<String, dynamic>> setReminderNotification({
    required int userId,
    required int reminderId,
    required String title,
    required DateTime reminderDateTime,
    required bool enabled,
    int? taskId,
  }) async {
    return _post({
      'action': 'update',
      'user_id': userId,
      'reminder_id': reminderId,
      'title': title,
      'reminder_datetime': formatDateTime(reminderDateTime),
      'task_id': taskId,
      'notification_enabled': enabled ? 1 : 0,
    }, 'reminders.php');
  }

  // MARK REMINDER AS COMPLETED
  static Future<Map<String, dynamic>> completeReminder({
    required int userId,
    required int reminderId,
  }) async {
    return _post({
      'action': 'complete',
      'user_id': userId,
      'reminder_id': reminderId,
    }, 'reminders.php');
  }

  // DELETE REMINDER
  static Future<Map<String, dynamic>> deleteReminder({
    required int userId,
    required int reminderId,
  }) async {
    return _post({
      'action': 'delete',
      'user_id': userId,
      'reminder_id': reminderId,
    }, 'reminders.php');
  }
}
