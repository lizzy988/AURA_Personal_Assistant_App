
import 'package:flutter/material.dart';
import 'api_service.dart';

class PlannerRemindersSection extends StatefulWidget {
  final int userId;
  final DateTime selectedDate;
  final VoidCallback onViewAll;

  const PlannerRemindersSection({
    super.key,
    required this.userId,
    required this.selectedDate,
    required this.onViewAll,
  });

  @override
  State<PlannerRemindersSection> createState() =>
      _PlannerRemindersSectionState();
}

class _PlannerRemindersSectionState
    extends State<PlannerRemindersSection> {
  static const Color purple = Color(0xFF7950F2);
  static const Color navy = Color(0xFF19172F);

  List<dynamic> reminders = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadReminders();
  }

  @override
  void didUpdateWidget(covariant PlannerRemindersSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!DateUtils.isSameDay(
      oldWidget.selectedDate,
      widget.selectedDate,
    )) {
      loadReminders();
    }
  }

  Future<void> loadReminders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getReminders(
        userId: widget.userId,
      );

      if (!mounted) return;

      setState(() {
        reminders = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  DateTime? reminderDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(
      value.toString().replaceFirst(' ', 'T'),
    );
  }

  List<dynamic> get dailyReminders {
    return reminders.where((item) {
      final reminder = Map<String, dynamic>.from(item);
      final date = reminderDate(
        reminder['reminder_datetime'],
      );

      return date != null &&
          DateUtils.isSameDay(date, widget.selectedDate);
    }).toList()
      ..sort((a, b) {
        final first = reminderDate(
          a['reminder_datetime'],
        )!;
        final second = reminderDate(
          b['reminder_datetime'],
        )!;
        return first.compareTo(second);
      });
  }

  bool isCompleted(dynamic item) {
    return item['status']?.toString().toLowerCase() ==
        'completed';
  }

  @override
  Widget build(BuildContext context) {
    final daily = dailyReminders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),

        Row(
          children: [
            const Icon(
              Icons.notifications_active_outlined,
              color: purple,
              size: 23,
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Text(
                'My Reminders',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
            ),
            TextButton(
              onPressed: widget.onViewAll,
              child: const Text(
                'View all',
                style: TextStyle(
                  color: purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: purple,
              ),
            ),
          )
        else if (errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.cloud_off,
                  color: Colors.grey,
                  size: 30,
                ),
                const SizedBox(height: 8),
                const Text('Could not load reminders.'),
                TextButton(
                  onPressed: loadReminders,
                  child: const Text('Try again'),
                ),
              ],
            ),
          )
        else if (daily.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.notifications_none,
                  color: purple,
                  size: 38,
                ),
                SizedBox(height: 8),
                Text(
                  'No reminders for this day.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: navy,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Your scheduled reminders will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          ...daily.map((item) {
            final reminder =
                Map<String, dynamic>.from(item);

            final date = reminderDate(
              reminder['reminder_datetime'],
            )!;

            final completed = isCompleted(reminder);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: completed
                        ? Colors.green.shade50
                        : purple.withOpacity(0.10),
                    child: Icon(
                      completed
                          ? Icons.check_circle
                          : Icons.notifications_active,
                      color: completed
                          ? Colors.green
                          : purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder['title']?.toString() ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: navy,
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          TimeOfDay.fromDateTime(date)
                              .format(context),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (completed)
                    const Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            );
          }),

        if (!isLoading)
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: widget.onViewAll,
              icon: const Icon(Icons.notifications_outlined),
              label: const Text('Manage all reminders'),
              style: TextButton.styleFrom(
                foregroundColor: purple,
              ),
            ),
          ),
      ],
    );
  }
}
