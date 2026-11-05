
class OfflineAssistant {
  /// Returns an offline answer for supported planner questions.
  /// Returns null when the question needs the online AI.
  static String? getReply({
    required String message,
    required List<dynamic> activities,
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final question = message.toLowerCase().trim();

    final allActivities = activities
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    DateTime? getActivityDate(Map<String, dynamic> activity) {
      final rawDate = activity['due_date'] ??
          activity['start_time'] ??
          activity['scheduledAt'] ??
          activity['date'];

      if (rawDate == null || rawDate.toString().isEmpty) {
        return null;
      }

      return DateTime.tryParse(rawDate.toString())?.toLocal();
    }

    bool isCompleted(Map<String, dynamic> activity) {
      final status = (activity['status'] ?? '').toString().toLowerCase();

      return status == 'completed' ||
          status == 'complete' ||
          status == 'done' ||
          activity['completed'] == true;
    }

    String titleOf(Map<String, dynamic> activity) {
      return (activity['title'] ?? 'Untitled activity').toString();
    }

    String priorityOf(Map<String, dynamic> activity) {
      return (activity['priority'] ?? 'Normal').toString();
    }

    bool isHighPriority(Map<String, dynamic> activity) {
      final priority = priorityOf(activity).toLowerCase();

      return priority.contains('high') ||
          priority.contains('urgent');
    }

    String formatDate(DateTime date) {
      const months = [
        'January', 'February', 'March', 'April',
        'May', 'June', 'July', 'August',
        'September', 'October', 'November', 'December'
      ];

      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }

    String formatList(List<Map<String, dynamic>> items) {
      if (items.isEmpty) return 'None found.';

      return items.asMap().entries.map((entry) {
        final activity = entry.value;
        final date = getActivityDate(activity);
        final priority = priorityOf(activity);

        final dateText = date == null
            ? ''
            : ' — ${formatDate(date)}';

        return '${entry.key + 1}. ${titleOf(activity)}'
            '$dateText (Priority: $priority)';
      }).join('\n');
    }

    final pending = allActivities
        .where((activity) => !isCompleted(activity))
        .toList();

    final completed = allActivities
        .where(isCompleted)
        .toList();

    final todayActivities = pending.where((activity) {
      final date = getActivityDate(activity);

      if (date == null) return false;

      return date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    }).toList();

    final overdue = pending.where((activity) {
      final date = getActivityDate(activity);

      if (date == null) return false;

      final activityDay = DateTime(date.year, date.month, date.day);

      return activityDay.isBefore(today);
    }).toList();

    final upcoming = pending.where((activity) {
      final date = getActivityDate(activity);

      if (date == null) return false;

      final activityDay = DateTime(date.year, date.month, date.day);

      return activityDay.isAfter(today);
    }).toList();

    final highPriority = pending
        .where(isHighPriority)
        .toList();

    final todayText = formatDate(today);

    // Unfinished tasks
    if (question.contains('unfinished') ||
        question.contains('pending') ||
        question.contains('not completed') ||
        question.contains('not done') ||
        question.contains('remaining tasks')) {
      return 'Here are your unfinished activities, Liz!\n\n'
          'You have ${pending.length} pending activities.\n\n'
          'OVERDUE ACTIVITIES (${overdue.length})\n'
          '${formatList(overdue)}\n\n'
          'OTHER PENDING ACTIVITIES (${pending.length - overdue.length})\n'
          '${formatList(pending.where((item) => !overdue.contains(item)).toList())}';
    }

    // Overdue activities
    if (question.contains('overdue') ||
        question.contains('past due') ||
        question.contains('late tasks')) {
      return overdue.isEmpty
          ? 'Great news! You have no overdue activities.'
          : 'You have ${overdue.length} overdue activities:\n\n'
              '${formatList(overdue)}';
    }

    // Completed activities
    if (question.contains('completed') ||
        question.contains('finished') ||
        question.contains('done tasks')) {
      return 'You have completed ${completed.length} activities.\n\n'
          '${formatList(completed)}';
    }

    // High-priority activities
    if (question.contains('priority') ||
        question.contains('urgent') ||
        question.contains('important')) {
      return highPriority.isEmpty
          ? 'You currently have no pending high-priority activities.'
          : 'Here are your high-priority activities:\n\n'
              '${formatList(highPriority)}';
    }

    // Today's activities
    if (question.contains('today') ||
        question.contains('schedule') ||
        question.contains('planned')) {
      return 'Here is your planner summary for $todayText.\n\n'
          'You have ${todayActivities.length} pending activities scheduled for today.\n\n'
          '${formatList(todayActivities)}';
    }

    // Daily planning
    if (question.contains('plan my day') ||
        question.contains('organise my day') ||
        question.contains('organize my day') ||
        question.contains('help me plan') ||
        question.contains('what should i do')) {
      final suggestions = <Map<String, dynamic>>[
        ...overdue,
        ...todayActivities.where(isHighPriority),
        ...todayActivities.where((item) => !isHighPriority(item)),
        ...upcoming.where(isHighPriority),
        ...upcoming.where((item) => !isHighPriority(item)),
      ];

      final uniqueSuggestions = <Map<String, dynamic>>[];

      for (final item in suggestions) {
        if (!uniqueSuggestions.contains(item)) {
          uniqueSuggestions.add(item);
        }
      }

      if (uniqueSuggestions.isEmpty) {
        return 'Your planner is clear for $todayText! '
            'You have no pending activities to organise. '
            'Enjoy your day!';
      }

      return 'Let us organise your day, Liz! 🌟\n\n'
          'Today is $todayText.\n\n'
          'Here is my suggested order:\n\n'
          '${formatList(uniqueSuggestions)}\n\n'
          'Start with overdue and high-priority activities, '
          'then work through the remaining activities. '
          'Remember to take breaks!';
    }

    // General planner summary
    if (question.contains('planner') ||
        question.contains('my activities') ||
        question.contains('my tasks')) {
      return 'Here is your planner summary for $todayText:\n\n'
          'Total activities: ${allActivities.length}\n'
          'Pending: ${pending.length}\n'
          'Completed: ${completed.length}\n'
          'Overdue: ${overdue.length}\n'
          'Scheduled today: ${todayActivities.length}\n'
          'High priority: ${highPriority.length}';
    }

    // Return null when this is not a supported offline question.
    return null;
  }
}
