
import 'package:flutter/material.dart';
import 'api_service.dart';

class ReminderScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const ReminderScreen({
    super.key,
    required this.userId,
    this.userName = '',
  });

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  static const Color teal = Color(0xFF00C4C7);
  static const Color purple = Color(0xFF7950F2);
  static const Color navy = Color(0xFF19172F);

  List<dynamic> reminders = [];

  bool isLoading = true;
  String selectedFilter = 'All';

  final Set<int> updatingNotifications = {};

  @override
  void initState() {
    super.initState();
    loadReminders();
  }

  // LOAD REMINDERS FROM DATABASE
  Future<void> loadReminders() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
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
      });

      showMessage('Could not load reminders: $e');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  DateTime parseReminderDate(dynamic value) {
    return DateTime.parse(
      value.toString().replaceFirst(' ', 'T'),
    );
  }

  bool notificationIsEnabled(Map<String, dynamic> reminder) {
    final value = reminder['notification_enabled'];

    return value == true ||
        value.toString() == '1' ||
        value.toString().toLowerCase() == 'true';
  }

  bool isCompleted(Map<String, dynamic> reminder) {
    return reminder['status'] == 'Completed';
  }

  bool isOverdue(Map<String, dynamic> reminder) {
    if (isCompleted(reminder)) return false;

    return parseReminderDate(
      reminder['reminder_datetime'],
    ).isBefore(DateTime.now());
  }

  // FILTER REMINDERS
  List<dynamic> get filteredReminders {
    if (selectedFilter == 'Completed') {
      return reminders.where((item) {
        return isCompleted(Map<String, dynamic>.from(item));
      }).toList();
    }

    if (selectedFilter == 'Overdue') {
      return reminders.where((item) {
        return isOverdue(Map<String, dynamic>.from(item));
      }).toList();
    }

    if (selectedFilter == 'Upcoming') {
      return reminders.where((item) {
        final reminder = Map<String, dynamic>.from(item);

        return !isCompleted(reminder) &&
            !isOverdue(reminder);
      }).toList();
    }

    return reminders;
  }

  // CHANGE NOTIFICATION SETTING
  Future<void> toggleNotification(
    Map<String, dynamic> reminder,
    bool enabled,
  ) async {
    final reminderId = int.parse(
      reminder['reminder_id'].toString(),
    );

    if (updatingNotifications.contains(reminderId)) return;

    final oldValue = notificationIsEnabled(reminder);

    setState(() {
      updatingNotifications.add(reminderId);
      reminder['notification_enabled'] = enabled ? 1 : 0;
    });

    try {
      final result = await ApiService.setReminderNotification(
        userId: widget.userId,
        reminderId: reminderId,
        title: reminder['title'].toString(),
        reminderDateTime: parseReminderDate(
          reminder['reminder_datetime'],
        ),
        enabled: enabled,
        taskId: int.tryParse(
          reminder['task_id']?.toString() ?? '',
        ),
      );

      if (!mounted) return;

      if (result['success'] != true) {
        throw Exception(
          result['message'] ?? 'Could not update notification.',
        );
      }

      showMessage(
        enabled
            ? 'Notifications turned ON for this reminder.'
            : 'Notifications turned OFF for this reminder.',
      );

      await loadReminders();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        reminder['notification_enabled'] = oldValue ? 1 : 0;
      });

      showMessage('Could not update notification: $e');
    } finally {
      if (mounted) {
        setState(() {
          updatingNotifications.remove(reminderId);
        });
      }
    }
  }

  // CREATE OR EDIT REMINDER
  Future<void> showReminderDialog({
    Map<String, dynamic>? reminder,
  }) async {
    final titleController = TextEditingController(
      text: reminder?['title']?.toString() ?? '',
    );

    DateTime selectedDateTime = reminder != null
        ? parseReminderDate(reminder['reminder_datetime'])
        : DateTime.now().add(const Duration(hours: 1));

    bool notificationEnabled = reminder == null
        ? true
        : notificationIsEnabled(reminder);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                reminder == null
                    ? 'Add Reminder'
                    : 'Edit Reminder',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Reminder title',
                        hintText: 'Enter reminder details',
                        prefixIcon: Icon(
                          Icons.notifications_outlined,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_month,
                        color: purple,
                      ),
                      title: const Text('Date'),
                      subtitle: Text(
                        '${selectedDateTime.day}/'
                        '${selectedDateTime.month}/'
                        '${selectedDateTime.year}',
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedDateTime,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );

                        if (date != null) {
                          setDialogState(() {
                            selectedDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              selectedDateTime.hour,
                              selectedDateTime.minute,
                            );
                          });
                        }
                      },
                    ),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.access_time,
                        color: purple,
                      ),
                      title: const Text('Time'),
                      subtitle: Text(
                        TimeOfDay.fromDateTime(
                          selectedDateTime,
                        ).format(context),
                      ),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: dialogContext,
                          initialTime: TimeOfDay.fromDateTime(
                            selectedDateTime,
                          ),
                        );

                        if (time != null) {
                          setDialogState(() {
                            selectedDateTime = DateTime(
                              selectedDateTime.year,
                              selectedDateTime.month,
                              selectedDateTime.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      },
                    ),

                    const Divider(),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Enable notifications',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        notificationEnabled
                            ? 'AURA notifications are ON'
                            : 'AURA notifications are OFF',
                      ),
                      secondary: Icon(
                        notificationEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: purple,
                      ),
                      activeColor: purple,
                      value: notificationEnabled,
                      onChanged: (value) {
                        setDialogState(() {
                          notificationEnabled = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final title = titleController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(dialogContext)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter a reminder title.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, {
                      'title': title,
                      'dateTime': selectedDateTime,
                      'notificationEnabled': notificationEnabled,
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();

    if (result == null) return;

    try {
      if (reminder == null) {
        final response = await ApiService.createReminder(
          userId: widget.userId,
          title: result['title'],
          reminderDateTime: result['dateTime'],
          notificationEnabled: result['notificationEnabled'],
        );

        if (response['success'] != true) {
          throw Exception(response['message'] ?? 'Could not create reminder.');
        }

        if (!mounted) return;
        showMessage('Reminder created successfully!');
      } else {
        final response = await ApiService.updateReminder(
          userId: widget.userId,
          reminderId: int.parse(
            reminder['reminder_id'].toString(),
          ),
          title: result['title'],
          reminderDateTime: result['dateTime'],
          taskId: int.tryParse(
            reminder['task_id']?.toString() ?? '',
          ),
          notificationEnabled: result['notificationEnabled'],
        );

        if (response['success'] != true) {
          throw Exception(response['message'] ?? 'Could not update reminder.');
        }

        if (!mounted) return;
        showMessage('Reminder updated successfully!');
      }

      await loadReminders();
    } catch (e) {
      if (!mounted) return;
      showMessage('Could not save reminder: $e');
    }
  }

  // MARK AS COMPLETED
  Future<void> completeReminder(int reminderId) async {
    try {
      await ApiService.completeReminder(
        userId: widget.userId,
        reminderId: reminderId,
      );

      if (!mounted) return;

      showMessage('Reminder completed!');
      await loadReminders();
    } catch (e) {
      if (!mounted) return;
      showMessage('Could not complete reminder: $e');
    }
  }

  // DELETE REMINDER
  Future<void> deleteReminder(int reminderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Reminder'),
          content: const Text(
            'Are you sure you want to delete this reminder?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await ApiService.deleteReminder(
        userId: widget.userId,
        reminderId: reminderId,
      );

      if (!mounted) return;

      showMessage('Reminder deleted.');
      await loadReminders();
    } catch (e) {
      if (!mounted) return;
      showMessage('Could not delete reminder: $e');
    }
  }

  // REMINDER CARD
  Widget buildReminderCard(Map<String, dynamic> reminder) {
    final completed = isCompleted(reminder);
    final overdue = isOverdue(reminder);
    final notificationEnabled =
        notificationIsEnabled(reminder);

    final dateTime = parseReminderDate(
      reminder['reminder_datetime'],
    );

    final reminderId = int.parse(
      reminder['reminder_id'].toString(),
    );

    final dateText =
        '${dateTime.day}/${dateTime.month}/${dateTime.year}';

    final timeText = TimeOfDay.fromDateTime(
      dateTime,
    ).format(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: completed
                      ? Colors.green.shade100
                      : overdue
                          ? Colors.red.shade100
                          : teal.withOpacity(0.15),
                  child: Icon(
                    completed
                        ? Icons.check_circle
                        : overdue
                            ? Icons.warning_amber
                            : Icons.notifications_active,
                    color: completed
                        ? Colors.green
                        : overdue
                            ? Colors.red
                            : teal,
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
                          fontSize: 16,
                          decoration: completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$dateText  •  $timeText',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      showReminderDialog(
                        reminder: reminder,
                      );
                    } else if (value == 'delete') {
                      deleteReminder(reminderId);
                    }
                  },
                  itemBuilder: (context) => [
                    if (!completed)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit / Reschedule'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // NOTIFICATION ON/OFF SWITCH
            Container(
              decoration: BoxDecoration(
                color: notificationEnabled
                    ? purple.withOpacity(0.07)
                    : Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                secondary: Icon(
                  notificationEnabled
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  color: notificationEnabled
                      ? purple
                      : Colors.grey,
                ),
                title: const Text(
                  'AURA Notifications',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  notificationEnabled
                      ? 'Notifications enabled'
                      : 'Notifications disabled',
                  style: const TextStyle(fontSize: 11),
                ),
                value: notificationEnabled,
                activeColor: purple,
                onChanged: updatingNotifications.contains(reminderId)
                    ? null
                    : (value) {
                        toggleNotification(reminder, value);
                      },
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: completed
                        ? Colors.green.shade50
                        : overdue
                            ? Colors.red.shade50
                            : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    completed
                        ? 'Completed'
                        : overdue
                            ? 'Overdue'
                            : 'Upcoming',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: completed
                          ? Colors.green
                          : overdue
                              ? Colors.red
                              : Colors.blue,
                    ),
                  ),
                ),

                if (!completed)
                  TextButton.icon(
                    onPressed: () {
                      completeReminder(reminderId);
                    },
                    icon: const Icon(
                      Icons.check_circle_outline,
                      size: 17,
                    ),
                    label: const Text('Complete'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: teal,
        foregroundColor: Colors.white,
        title: const Text(
          'Intelligent Reminders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: loadReminders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showReminderDialog(),
        backgroundColor: purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Reminder'),
      ),

      body: RefreshIndicator(
        onRefresh: loadReminders,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              widget.userName.isEmpty
                  ? 'Manage your reminders'
                  : 'Hello, ${widget.userName}!',
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Remember what matters. Stay organised.',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 22),

            // REMINDER FILTERS
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'All',
                  'Upcoming',
                  'Overdue',
                  'Completed',
                ].map((filter) {
                  final selected = selectedFilter == filter;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: selected,
                      selectedColor: purple,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : navy,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) {
                        setState(() {
                          selectedFilter = filter;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: purple,
                  ),
                ),
              )
            else if (filteredReminders.isEmpty)
              Padding(
                padding: const EdgeInsets.all(35),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 65,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No reminders found',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap Add Reminder to create your first reminder.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ...filteredReminders.map((item) {
                return buildReminderCard(
                  Map<String, dynamic>.from(item),
                );
              }),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
