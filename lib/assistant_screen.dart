
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'offline_assistant.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class AssistantScreen extends StatefulWidget {
  final dynamic userId;

  const AssistantScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _messageController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _speechEnabled = false;
  bool _isListening = false;
  bool _speakResponses = true;
  bool _isSpeaking = false;
  bool _isThinking = false;

  List<dynamic> activities = [];
  bool isLoadingActivities = false;
  String? activityError;

  // Stores an action that AURA is waiting for the user to confirm.
  Map<String, dynamic>? _pendingAction;

  // Stores whether AURA is waiting for a date or time.
  String? _waitingFor;

  final List<Map<String, dynamic>> messages = [
    {
      'text':
          "Hello! I'm AURA, your personal planning assistant. ✨\n\n"
          "I'm here to help you organise your day, manage your tasks "
          "and find balance when plans change.\n\n"
          "You can type to me or tap the microphone to speak. "
          "What would you like help with today?",
      'isUser': false,
    },
  ];

  final Color purple = const Color(0xFF7950F2);
  final Color teal = const Color(0xFF00C4C7);
  final Color navy = const Color(0xFF19172F);

  @override
  void initState() {
    super.initState();
    loadActivities();
    initializeVoice();
  }

  Future<void> initializeVoice() async {
    try {
      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          if (mounted) {
            setState(() => _isListening = false);
          }
        },
      );

      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        if (mounted) setState(() => _isSpeaking = true);
      });

      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });

      _flutterTts.setCancelHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Voice initialisation error: $e');
    }
  }

  Future<void> toggleListening() async {
    if (_isThinking) return;

    if (!_speechEnabled) {
      await initializeVoice();

      if (!_speechEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Speech recognition is unavailable. '
              'Please check your microphone permissions in Chrome.',
            ),
          ),
        );
        return;
      }
    }

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    await _flutterTts.stop();
    if (!mounted) return;

    setState(() => _isListening = true);

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;

          setState(() {
            _messageController.text = result.recognizedWords;
            _messageController.selection = TextSelection.fromPosition(
              TextPosition(
                offset: _messageController.text.length,
              ),
            );
          });

          if (result.finalResult) {
            setState(() => _isListening = false);
            if (result.recognizedWords.trim().isNotEmpty) {
              sendMessage(result.recognizedWords);
            }
          }
        },
      );
    } catch (e) {
      debugPrint('Microphone error: $e');
      if (mounted) setState(() => _isListening = false);
    }
  }

  Future<void> speakResponse(String response) async {
    if (!_speakResponses || !mounted) return;

    try {
      await _flutterTts.stop();
      if (!_speakResponses || !mounted) return;
      await _flutterTts.speak(response);
    } catch (e) {
      debugPrint('Text to speech error: $e');
    }
  }

  Future<void> toggleVoiceOutput() async {
    setState(() => _speakResponses = !_speakResponses);
    if (!_speakResponses) await _flutterTts.stop();
  }

  Future<void> loadActivities() async {
    if (!mounted) return;

    setState(() {
      isLoadingActivities = true;
      activityError = null;
    });

    try {
      final userId = int.tryParse(widget.userId.toString());
      if (userId == null || userId <= 0) {
        throw Exception('Invalid user ID.');
      }

      final result = await ApiService.getActivities(userId: userId);

      if (!mounted) return;
      setState(() {
        activities = result;
        isLoadingActivities = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingActivities = false;
        activityError = 'Could not load your planner activities.';
      });
      debugPrint('Planner loading error: $e');
    }
  }

  bool isActivityCompleted(dynamic activity) {
    final completed = activity['completed'];
    final status = activity['status']?.toString().toLowerCase();

    return completed == true ||
        completed == 1 ||
        completed == '1' ||
        status == 'completed';
  }

  List<dynamic> get pendingActivities {
    return activities.where((activity) {
      return !isActivityCompleted(activity);
    }).toList();
  }

  List<dynamic> get completedActivities {
    return activities.where((activity) {
      return isActivityCompleted(activity);
    }).toList();
  }

  List<Map<String, String>> getConversationHistory() {
    return messages.map((message) {
      return {
        'role': message['isUser'] == true ? 'user' : 'assistant',
        'content': message['text'].toString(),
      };
    }).toList();
  }

  // ---------------------------------------------------------
  // PLANNER ACTION HELPERS
  // ---------------------------------------------------------

  void addAssistantMessage(String text) {
    if (!mounted) return;

    setState(() {
      messages.add({
        'text': text,
        'isUser': false,
      });
      _isThinking = false;
    });

    scrollToBottom();
    speakResponse(text);
  }

  DateTime? parseDate(String message) {
    final text = message.toLowerCase();
    final now = DateTime.now();

    if (text.contains('day after tomorrow')) {
      return DateTime(now.year, now.month, now.day + 2);
    }

    if (text.contains('tomorrow')) {
      return DateTime(now.year, now.month, now.day + 1);
    }

    if (text.contains('today')) {
      return DateTime(now.year, now.month, now.day);
    }

    final iso = RegExp(r'\b(\d{4})-(\d{1,2})-(\d{1,2})\b')
        .firstMatch(text);

    if (iso != null) {
      return DateTime(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
      );
    }

    final slash = RegExp(r'\b(\d{1,2})/(\d{1,2})/(\d{4})\b')
        .firstMatch(text);

    if (slash != null) {
      return DateTime(
        int.parse(slash.group(3)!),
        int.parse(slash.group(2)!),
        int.parse(slash.group(1)!),
      );
    }

    const weekdays = {
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
    };

    for (final entry in weekdays.entries) {
      if (text.contains(entry.key)) {
        int difference = (entry.value - now.weekday) % 7;
        if (difference == 0) difference = 7;
        return DateTime(now.year, now.month, now.day + difference);
      }
    }

    return null;
  }

  Map<String, int>? parseTime(String message) {
    final text = message.toLowerCase();

    final twelveHour = RegExp(
      r'\b(?:at\s*)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
    ).firstMatch(text);

    if (twelveHour != null) {
      int hour = int.parse(twelveHour.group(1)!);
      final minute = int.parse(twelveHour.group(2) ?? '0');
      final period = twelveHour.group(3);

      if (hour < 1 || hour > 12 || minute > 59) return null;

      if (period == 'pm' && hour != 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;

      return {'hour': hour, 'minute': minute};
    }

    final twentyFourHour = RegExp(
      r'\b(?:at\s+)(\d{1,2}):(\d{2})\b',
    ).firstMatch(text);

    if (twentyFourHour != null) {
      final hour = int.parse(twentyFourHour.group(1)!);
      final minute = int.parse(twentyFourHour.group(2)!);

      if (hour > 23 || minute > 59) return null;
      return {'hour': hour, 'minute': minute};
    }

    return null;
  }

  DateTime? readActivityDate(dynamic activity) {
    final value = activity['scheduled_at'] ??
        activity['due_date'] ??
        activity['start_time'] ??
        activity['date'];

    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String formatDateTimeForUser(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];

    return '${dateTime.day} ${months[dateTime.month - 1]} '
        '${dateTime.year} at $hour:$minute $period';
  }

  String extractNewActivityTitle(String message) {
    String title = message.trim();

    final patterns = [
      r'^(please\s+)?(add|create|schedule|plan)\s+(a\s+)?(new\s+)?(task|appointment|meeting|event)?\s*(to\s+)?',
      r'^(please\s+)?remind me to\s+',
      r'^(please\s+)?i need to\s+',
      r'^(please\s+)?put\s+',
    ];

    for (final pattern in patterns) {
      title = title.replaceFirst(
        RegExp(pattern, caseSensitive: false),
        '',
      );
    }

    title = title
        .replaceAll(
          RegExp(
            r'\b(today|tomorrow|day after tomorrow|'
            r'monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(r'\b(at\s*)?\d{1,2}(:\d{2})?\s*(am|pm)\b',
              caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'\b\d{4}-\d{1,2}-\d{1,2}\b'),
          '',
        )
        .replaceAll(
          RegExp(r'\b(low|medium|high)\s+priority\b',
              caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return title.replaceAll(RegExp(r'[,.\s]+$'), '').trim();
  }

  String extractPriority(String message) {
    final text = message.toLowerCase();
    if (text.contains('high priority')) return 'High';
    if (text.contains('low priority')) return 'Low';
    return 'Medium';
  }

  dynamic findActivity(String message) {
    final text = message.toLowerCase();

    // First try to find an activity whose full title appears in the message.
    for (final activity in activities) {
      final title = activity['title']?.toString().toLowerCase() ?? '';
      if (title.isNotEmpty && text.contains(title)) {
        return activity;
      }
    }

    // Otherwise compare meaningful words in the message and activity title.
    final ignored = {
      'delete', 'remove', 'cancel', 'update', 'edit', 'change',
      'reschedule', 'move', 'my', 'the', 'a', 'an', 'please',
      'task', 'appointment', 'meeting', 'activity', 'schedule',
      'to', 'for', 'on', 'from', 'it',
    };

    final words = text
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .split(' ')
        .where((word) => word.length > 2 && !ignored.contains(word))
        .toSet();

    dynamic bestMatch;
    int bestScore = 0;

    for (final activity in activities) {
      final title = activity['title']?.toString().toLowerCase() ?? '';
      final titleWords = title
          .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
          .split(' ')
          .toSet();

      final score = words.intersection(titleWords).length;
      if (score > bestScore) {
        bestScore = score;
        bestMatch = activity;
      }
    }

    return bestScore > 0 ? bestMatch : null;
  }

  String activityDescription(dynamic activity) {
    final title = activity['title']?.toString() ?? 'Untitled activity';
    final date = readActivityDate(activity);

    if (date == null) return title;
    return '$title (${formatDateTimeForUser(date)})';
  }

  Future<void> askForMissingDetails() async {
    if (_pendingAction == null) return;

    final action = _pendingAction!;
    final date = action['date'] as DateTime?;
    final time = action['time'] as Map<String, int>?;

    if (date == null) {
      _waitingFor = 'date';
      addAssistantMessage(
        'What date would you like to schedule this activity? '
        'You can say today, tomorrow, Friday, or give me a date.',
      );
      return;
    }

    if (time == null) {
      _waitingFor = 'time';
      addAssistantMessage(
        'What time would you like? For example, 9:00 AM or 2:30 PM.',
      );
      return;
    }

    _waitingFor = null;
    await showActionConfirmation();
  }

  Future<void> showActionConfirmation() async {
    if (_pendingAction == null) return;

    final action = _pendingAction!;
    final type = action['action'];

    if (type == 'delete') {
      addAssistantMessage(
        'Please confirm: do you want me to delete '
        '"${activityDescription(action['activity'])}" '
        'from your planner?\n\nReply YES to delete or NO to cancel.',
      );
      return;
    }

    final date = action['date'] as DateTime;
    final time = action['time'] as Map<String, int>;

    final scheduledAt = DateTime(
      date.year,
      date.month,
      date.day,
      time['hour']!,
      time['minute']!,
    );

    action['scheduledAt'] = scheduledAt;

    if (type == 'create') {
      addAssistantMessage(
        'Here is what I understood:\n\n'
        'Activity: ${action['title']}\n'
        'Type: ${action['type']}\n'
        'Date and time: ${formatDateTimeForUser(scheduledAt)}\n'
        'Priority: ${action['priority']}\n\n'
        'Should I save this to your planner?\n'
        'Reply YES to confirm or NO to cancel.',
      );
    } else {
      final activity = action['activity'];
      addAssistantMessage(
        'Here is the updated schedule I understood:\n\n'
        'Activity: ${activity['title']}\n'
        'New date and time: ${formatDateTimeForUser(scheduledAt)}\n\n'
        'Should I save this change?\n'
        'Reply YES to confirm or NO to cancel.',
      );
    }
  }

  Future<void> handlePendingReply(String message) async {
    final text = message.trim().toLowerCase();

    if (_pendingAction == null) {
      addAssistantMessage('There is no pending planner action.');
      return;
    }

    if (_waitingFor != null) {
      final action = _pendingAction!;

      final date = parseDate(message);
      final time = parseTime(message);

      if (date != null) action['date'] = date;
      if (time != null) action['time'] = time;

      if (_waitingFor == 'date' && date == null) {
        addAssistantMessage(
          'I could not understand that date. '
          'Please try something like tomorrow or Friday.',
        );
        return;
      }

      if (_waitingFor == 'time' && time == null) {
        addAssistantMessage(
          'I could not understand that time. '
          'Please try something like 9:00 AM or 2:30 PM.',
        );
        return;
      }

      await askForMissingDetails();
      return;
    }

    if (['yes', 'yes please', 'confirm', 'confirm it', 'save it', 'do it']
        .contains(text)) {
      await executePendingAction();
      return;
    }

    if (['no', 'no thanks', 'cancel', 'cancel it', 'stop']
        .contains(text)) {
      _pendingAction = null;
      _waitingFor = null;
      addAssistantMessage('No problem. I have cancelled that action. 💜');
      return;
    }

    addAssistantMessage(
      'I am waiting for your confirmation. '
      'Please reply YES to continue or NO to cancel.',
    );
  }

  Future<void> executePendingAction() async {
    final action = _pendingAction;
    if (action == null) return;

    final userId = int.tryParse(widget.userId.toString());
    if (userId == null || userId <= 0) {
      _pendingAction = null;
      addAssistantMessage('Your account session is invalid. Please log in again.');
      return;
    }

    try {
      final actionType = action['action'];
      Map<String, dynamic> result;

      if (actionType == 'create') {
        result = await ApiService.createActivity(
          userId: userId,
          title: action['title'],
          type: action['type'],
          scheduledAt: action['scheduledAt'],
          priority: action['priority'],
        );
      } else if (actionType == 'update') {
        final activity = action['activity'];

        result = await ApiService.updateActivity(
          userId: userId,
          id: int.parse(activity['id'].toString()),
          title: activity['title'].toString(),
          type: activity['type'].toString(),
          scheduledAt: action['scheduledAt'],
          priority: activity['priority']?.toString() ?? 'Medium',
          completed: isActivityCompleted(activity),
        );
      } else {
        final activity = action['activity'];

        result = await ApiService.deleteActivity(
          userId: userId,
          id: int.parse(activity['id'].toString()),
          type: activity['type'].toString(),
        );
      }

      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'The planner action failed.');
      }

      _pendingAction = null;
      _waitingFor = null;

      await loadActivities();

      if (actionType == 'create') {
        addAssistantMessage(
          'Done! ✨ "${action['title']}" has been added to your planner.',
        );
      } else if (actionType == 'update') {
        addAssistantMessage(
          'Done! ✨ "${action['activity']['title']}" has been rescheduled.',
        );
      } else {
        addAssistantMessage(
          'Done! "${action['activity']['title']}" has been deleted from your planner.',
        );
      }
    } catch (e) {
      _pendingAction = null;
      _waitingFor = null;
      addAssistantMessage(
        'I could not complete that planner action. '
        'Please check your connection and try again.\n\n$e',
      );
      debugPrint('Planner action error: $e');
    }
  }

  Future<bool> handlePlannerCommand(String message) async {
    final text = message.toLowerCase().trim();

    // Handle replies to an action that AURA is already waiting for.
    if (_pendingAction != null) {
      await handlePendingReply(message);
      return true;
    }

    // CREATE
    final createIntent = RegExp(
      r'\b(add|create|schedule|remind me|put|plan)\b',
    ).hasMatch(text);

    if (createIntent) {
      if (activityError != null) {
        addAssistantMessage(
          'I cannot access your planner right now. '
          'Please check your connection and try again.',
        );
        return true;
      }

      final title = extractNewActivityTitle(message);

      if (title.isEmpty) {
        addAssistantMessage(
          'What activity would you like me to add to your planner?',
        );
        return true;
      }

      final date = parseDate(message);
      final time = parseTime(message);

      final appointmentIntent = RegExp(
        r'\b(appointment|meeting|event)\b',
      ).hasMatch(text);

      _pendingAction = {
        'action': 'create',
        'title': title,
        'type': appointmentIntent ? 'Appointment' : 'Task',
        'priority': extractPriority(message),
        'date': date,
        'time': time,
      };

      await askForMissingDetails();
      return true;
    }

    // DELETE
    final deleteIntent = RegExp(
      r'\b(delete|remove|cancel)\b',
    ).hasMatch(text);

    if (deleteIntent) {
      final activity = findActivity(message);

      if (activity == null) {
        addAssistantMessage(
          'I could not identify which activity you want to delete. '
          'Please mention its name as it appears in your planner.',
        );
        return true;
      }

      _pendingAction = {
        'action': 'delete',
        'activity': activity,
      };

      await showActionConfirmation();
      return true;
    }

    // UPDATE OR RESCHEDULE
    final updateIntent = RegExp(
      r'\b(reschedule|move|update|edit|change)\b',
    ).hasMatch(text);

    if (updateIntent) {
      final activity = findActivity(message);

      if (activity == null) {
        addAssistantMessage(
          'I could not identify which activity you want to change. '
          'Please mention its name as it appears in your planner.',
        );
        return true;
      }

      final oldDate = readActivityDate(activity);
      final newDate = parseDate(message);
      final newTime = parseTime(message);

      final date = newDate ?? oldDate;
      final time = newTime ??
          (oldDate == null
              ? null
              : {
                  'hour': oldDate.hour,
                  'minute': oldDate.minute,
                });

      _pendingAction = {
        'action': 'update',
        'activity': activity,
        'date': date,
        'time': time,
      };

      await askForMissingDetails();
      return true;
    }

    return false;
  }

  // ---------------------------------------------------------
  // CHAT
  // ---------------------------------------------------------

  Future<void> sendMessage([String? suggestedMessage]) async {
    if (_isThinking) return;

    final message = suggestedMessage ?? _messageController.text.trim();
    if (message.trim().isEmpty) return;

    if (_isListening) await _speech.stop();
    await _flutterTts.stop();

    if (!mounted) return;

    setState(() {
      _isListening = false;
      _isThinking = true;
      messages.add({
        'text': message,
        'isUser': true,
      });
      _messageController.clear();
    });

    scrollToBottom();

    try {
      // Planner actions are checked before ordinary chat.
      final handled = await handlePlannerCommand(message);
      if (handled) return;

      // Try offline intelligence first.
      if (activityError == null) {
        final offlineReply = OfflineAssistant.getReply(
          message: message,
          activities: activities,
        );

        if (offlineReply != null) {
          addAssistantMessage(offlineReply);
          return;
        }
      }

      // Use online AI for other questions.
      final userId = int.tryParse(widget.userId.toString());

      if (userId == null || userId <= 0) {
        throw Exception(
          'Your account session is invalid. Please log in again.',
        );
      }

      final history = messages
          .take(messages.length - 1)
          .map((message) {
        return {
          'role': message['isUser'] == true ? 'user' : 'assistant',
          'content': message['text'].toString(),
        };
      }).toList();

      final reply = await ApiService.sendAssistantMessage(
        userId: userId,
        message: message,
        history: history,
      );

      addAssistantMessage(reply);
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e.toString().replaceFirst('Exception: ', '');

      addAssistantMessage(
        "I'm sorry, I couldn't get a response from my AI service. 💜\n\n"
        "$errorMessage\n\n"
        "You can still ask me about your planner activities.",
      );

      debugPrint('AURA AI error: $e');
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void startNewConversation() {
    if (_isThinking) return;

    _flutterTts.stop();
    _pendingAction = null;
    _waitingFor = null;

    setState(() {
      messages.clear();
      messages.add({
        'text': 'Hello again! ✨ What would you like help with today?',
        'isUser': false,
      });
    });

    loadActivities();
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------
  // EXISTING AURA DESIGN
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              navy,
              const Color(0xFF252044),
              const Color(0xFF19172F),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              buildHeader(),
              buildAssistantInfo(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  itemCount: messages.length + (_isThinking ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return buildThinkingIndicator();
                    }
                    return buildMessage(messages[index]);
                  },
                ),
              ),
              if (messages.length == 1 && !_isThinking)
                buildSuggestions(),
              buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
      child: Row(
        children: [
          buildAuraLogo(size: 46),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AURA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Your personal assistant',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isThinking ? null : startNewConversation,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white70,
            ),
            tooltip: 'New conversation',
          ),
          IconButton(
            onPressed: toggleVoiceOutput,
            tooltip: _speakResponses ? 'Mute AURA' : 'Turn on AURA voice',
            icon: Icon(
              _speakResponses
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: _speakResponses ? teal : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAuraLogo({double size = 60}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: purple, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: purple.withOpacity(0.35),
            blurRadius: 15,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.67,
          height: size * 0.67,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: teal, width: 2),
          ),
          child: Icon(
            Icons.star_rounded,
            color: Colors.white,
            size: size * 0.34,
          ),
        ),
      ),
    );
  }

  Widget buildAssistantInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: purple.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          buildAuraLogo(size: 48),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your AURA Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _isListening
                      ? 'Listening to you...'
                      : _isSpeaking
                          ? 'AURA is speaking...'
                          : _isThinking
                              ? 'AURA is thinking...'
                              : isLoadingActivities
                                  ? 'Loading your planner activities...'
                                  : activityError != null
                                      ? 'Planner connection unavailable'
                                      : 'Here to help you plan smarter and stay organised.',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.circle,
            color: _isListening
                ? Colors.redAccent
                : _isThinking || _isSpeaking
                    ? teal
                    : isLoadingActivities
                        ? Colors.orange
                        : activityError != null
                            ? Colors.redAccent
                            : teal,
            size: 10,
          ),
        ],
      ),
    );
  }

  Widget buildMessage(Map<String, dynamic> message) {
    final bool isUser = message['isUser'] == true;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isUser ? purple : Colors.white.withOpacity(0.09),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser
              ? null
              : Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Text(
          message['text'].toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget buildThinkingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.09),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: teal,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'AURA is thinking...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSuggestions() {
    final suggestions = [
      'Help me organise my day',
      'How can I manage my time?',
      'Help me with unfinished tasks',
      'I need some motivation',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRY ASKING AURA',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((suggestion) {
              return InkWell(
                onTap: _isThinking ? null : () => sendMessage(suggestion),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: purple.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: purple.withOpacity(0.55)),
                  ),
                  child: Text(
                    suggestion,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.16),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !_isThinking,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: _isListening
                    ? 'Listening...'
                    : _isThinking
                        ? 'AURA is responding...'
                        : 'Message AURA...',
                hintStyle: const TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.09),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isThinking ? null : toggleListening,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _isListening
                    ? Colors.redAccent
                    : purple.withOpacity(0.25),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isListening ? Colors.redAccent : purple,
                ),
              ),
              child: Icon(
                _isListening
                    ? Icons.mic_rounded
                    : Icons.mic_none_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isThinking ? null : () => sendMessage(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [purple, teal]),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isThinking
                    ? Icons.hourglass_top_rounded
                    : Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
