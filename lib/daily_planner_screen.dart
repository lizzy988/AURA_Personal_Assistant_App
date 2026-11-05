
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'reminder_screen.dart';
import 'assistant_screen.dart';

const Color plannerTeal = Color(0xFF00C4C7);
const Color plannerPurple = Color(0xFF7950F2);
const Color plannerNavy = Color(0xFF19172F);
const Color plannerBackground = Color(0xFFF7F8FC);

class PlannerActivity {
  final int id;
  String title;
  String type;
  DateTime scheduledAt;
  String priority;
  bool completed;

  PlannerActivity({
    required this.id,
    required this.title,
    required this.type,
    required this.scheduledAt,
    required this.priority,
    this.completed = false,
  });
}

class DailyPlannerScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const DailyPlannerScreen({
    super.key,
    required this.userId,
    this.userName = '',
  });

  @override
  State<DailyPlannerScreen> createState() =>
      _DailyPlannerScreenState();
}

class _DailyPlannerScreenState extends State<DailyPlannerScreen> {
  DateTime selectedDate = DateUtils.dateOnly(DateTime.now());
  String selectedFilter = 'All';

  int selectedTab = 0;

  final List<PlannerActivity> activities = [];
  bool isLoading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        loadError = null;
      });
    }

    try {
      final data =
          await ApiService.getActivities(userId: widget.userId);

      final loadedActivities = data.map((item) {
        final row = Map<String, dynamic>.from(item as Map);

        final rawDate = row['scheduled_at']?.toString() ??
            row['due_date']?.toString() ??
            row['start_time']?.toString() ??
            '';

        final parsedDate =
            DateTime.parse(rawDate.replaceFirst(' ', 'T'));

        final rawCompleted =
            row['completed'] ?? row['status'] ?? false;

        final isCompleted = rawCompleted == true ||
            rawCompleted == 1 ||
            rawCompleted.toString() == '1' ||
            rawCompleted.toString().toLowerCase() == 'true' ||
            rawCompleted.toString().toLowerCase() == 'completed';

        return PlannerActivity(
          id: int.parse(row['id'].toString()),
          title: row['title']?.toString() ?? '',
          type: row['type']?.toString() ?? 'Task',
          scheduledAt: parsedDate,
          priority: row['priority']?.toString() ?? 'Medium',
          completed: isCompleted,
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        activities
          ..clear()
          ..addAll(loadedActivities);
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        loadError =
            error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<PlannerActivity> get dailyActivities {
    return activities.where((activity) {
      return DateUtils.isSameDay(
          activity.scheduledAt, selectedDate);
    }).toList()
      ..sort((a, b) =>
          a.scheduledAt.compareTo(b.scheduledAt));
  }

  List<PlannerActivity> get filteredActivities {
    if (selectedFilter == 'Pending') {
      return dailyActivities.where((a) => !a.completed).toList();
    }

    if (selectedFilter == 'Completed') {
      return dailyActivities.where((a) => a.completed).toList();
    }

    return dailyActivities;
  }

  int get completedCount =>
      dailyActivities.where((a) => a.completed).length;

  int get totalCount => dailyActivities.length;

  double get progress =>
      totalCount == 0 ? 0 : completedCount / totalCount;

  Future<void> selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: plannerPurple,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = DateUtils.dateOnly(picked);
      });
    }
  }

  void changeDate(int days) {
    setState(() {
      selectedDate =
          selectedDate.add(Duration(days: days));
    });
  }

  Future<void> addActivity() async {
    final result = await showDialog<PlannerActivity>(
      context: context,
      builder: (context) =>
          ActivityDialog(selectedDate: selectedDate),
    );

    if (result == null) return;

    try {
      final response = await ApiService.createActivity(
        userId: widget.userId,
        title: result.title,
        type: result.type,
        scheduledAt: result.scheduledAt,
        priority: result.priority,
      );

      if (response['success'] != true) {
        throw Exception(
            response['message'] ?? 'Could not add activity.');
      }

      await _loadActivities();
      _showMessage('Activity added successfully!');
    } catch (error) {
      _showMessage(
          error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> editActivity(PlannerActivity activity) async {
    final result = await showDialog<PlannerActivity>(
      context: context,
      builder: (context) => ActivityDialog(
        selectedDate: selectedDate,
        existingActivity: activity,
      ),
    );

    if (result == null) return;

    try {
      final response = await ApiService.updateActivity(
        userId: widget.userId,
        id: activity.id,
        title: result.title,
        type: result.type,
        scheduledAt: result.scheduledAt,
        priority: result.priority,
        completed: activity.completed,
      );

      if (response['success'] != true) {
        throw Exception(
            response['message'] ?? 'Could not update activity.');
      }

      await _loadActivities();
      _showMessage('Activity updated successfully!');
    } catch (error) {
      _showMessage(
          error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> deleteActivity(PlannerActivity activity) async {
    try {
      final response = await ApiService.deleteActivity(
        userId: widget.userId,
        id: activity.id,
        type: activity.type,
      );

      if (response['success'] != true) {
        throw Exception(
            response['message'] ?? 'Could not delete activity.');
      }

      await _loadActivities();
      _showMessage('Activity deleted.');
    } catch (error) {
      _showMessage(
          error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> toggleCompletion(
    PlannerActivity activity,
    bool? value,
  ) async {
    final completed = value ?? false;

    try {
      final response = await ApiService.updateActivity(
        userId: widget.userId,
        id: activity.id,
        title: activity.title,
        type: activity.type,
        scheduledAt: activity.scheduledAt,
        priority: activity.priority,
        completed: completed,
      );

      if (response['success'] != true) {
        throw Exception(
            response['message'] ?? 'Could not update activity.');
      }

      setState(() {
        activity.completed = completed;
      });
    } catch (error) {
      _showMessage(
          error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> rescheduleUnfinished() async {
    final unfinished =
        dailyActivities.where((a) => !a.completed).toList();

    if (unfinished.isEmpty) {
      _showMessage('No unfinished activities to reschedule.');
      return;
    }

    try {
      for (final activity in unfinished) {
        final newDate =
            activity.scheduledAt.add(const Duration(days: 1));

        final response = await ApiService.updateActivity(
          userId: widget.userId,
          id: activity.id,
          title: activity.title,
          type: activity.type,
          scheduledAt: newDate,
          priority: activity.priority,
          completed: activity.completed,
        );

        if (response['success'] != true) {
          throw Exception(response['message'] ??
              'Could not reschedule activity.');
        }
      }

      await _loadActivities();

      _showMessage(
        '${unfinished.length} unfinished activities moved to tomorrow.',
      );
    } catch (error) {
      await _loadActivities();

      _showMessage(
          error.toString().replaceFirst('Exception: ', ''));
    }
  }

  String formattedDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildPlaceholder({
    required IconData icon,
    required String title,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 65, color: plannerPurple),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: plannerNavy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Coming soon!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: plannerBackground,

      appBar: selectedTab == 0
          ? AppBar(
              backgroundColor: plannerTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'AURA Planner',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: selectDate,
                  tooltip: 'Choose date',
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,

      floatingActionButton: selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: addActivity,
              backgroundColor: plannerPurple,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Activity'),
            )
          : null,

      body: selectedTab == 0
          ? _buildPlannerBody()
          : selectedTab == 1
              ? ReminderScreen(
                  userId: widget.userId,
                  userName: widget.userName,
                )
              : selectedTab == 2
    ? AssistantScreen(
        userId: widget.userId,
      )
    : _buildPlaceholder(
        icon: Icons.settings,
        title: 'Settings',
      ),
                
       bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedTab,
        onTap: (index) {
          setState(() {
            selectedTab = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: plannerPurple,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Planner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active_outlined),
            label: 'Reminders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Assistant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildPlannerBody() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 100),
        children: [
          Text(
            'Hello, ${widget.userName.isEmpty ? 'there' : widget.userName}! 👋',
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: plannerNavy,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Let\'s make today productive.',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),

          const SizedBox(height: 22),

          // DATE SELECTOR
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => changeDate(-1),
                  icon: const Icon(Icons.chevron_left),
                ),

                Expanded(
                  child: GestureDetector(
                    onTap: selectDate,
                    child: Column(
                      children: [
                        Text(
                          formattedDate(selectedDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: plannerNavy,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Tap to choose another date',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () => changeDate(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // PROGRESS CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [plannerPurple, Color(0xFF9B79FF)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your daily progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedCount of $totalCount activities completed',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                    backgroundColor: Colors.white30,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // RESCHEDULE BUTTON
          OutlinedButton.icon(
            onPressed: rescheduleUnfinished,
            icon: const Icon(Icons.event_repeat),
            label: const Text(
              'Move unfinished activities to tomorrow',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: plannerPurple,
              side: const BorderSide(color: plannerPurple),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),

          const SizedBox(height: 24),

          // FILTERS
          const Text(
            'My Activities',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: plannerNavy,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 9,
            children: ['All', 'Pending', 'Completed'].map((filter) {
              final selected = selectedFilter == filter;

              return ChoiceChip(
                label: Text(filter),
                selected: selected,
                selectedColor: plannerPurple,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : plannerNavy,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) {
                  setState(() {
                    selectedFilter = filter;
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // ACTIVITY LIST
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(
                child: CircularProgressIndicator(
                  color: plannerPurple,
                ),
              ),
            )
          else if (loadError != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_off,
                    color: Colors.red,
                    size: 38,
                  ),
                  const SizedBox(height: 10),
                  Text(loadError!, textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _loadActivities,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            )
          else if (filteredActivities.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.event_available,
                    size: 48,
                    color: plannerPurple,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Nothing here yet!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: plannerNavy,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Add an activity to start planning your day.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ...filteredActivities.map(
              (activity) => ActivityCard(
                activity: activity,
                onChanged: (value) =>
                    toggleCompletion(activity, value),
                onEdit: () => editActivity(activity),
                onDelete: () => deleteActivity(activity),
              ),
            ),
        ],
      ),
    );
  }
}

// ACTIVITY CARD

class ActivityCard extends StatelessWidget {
  final PlannerActivity activity;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAppointment = activity.type == 'Appointment';

    Color priorityColor;

    switch (activity.priority) {
      case 'High':
        priorityColor = Colors.red;
        break;
      case 'Medium':
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Checkbox(
            value: activity.completed,
            activeColor: plannerPurple,
            onChanged: onChanged,
          ),

          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: plannerPurple.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isAppointment ? Icons.event : Icons.task_alt,
              color: plannerPurple,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: plannerNavy,
                    decoration: activity.completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '${activity.scheduledAt.hour.toString().padLeft(2, '0')}:'
                  '${activity.scheduledAt.minute.toString().padLeft(2, '0')}'
                  '  •  ${activity.type}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 7),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '${activity.priority} Priority',
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    if (activity.completed) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: Text('Edit activity'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete activity'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ADD AND EDIT ACTIVITY DIALOG

class ActivityDialog extends StatefulWidget {
  final DateTime selectedDate;
  final PlannerActivity? existingActivity;

  const ActivityDialog({
    super.key,
    required this.selectedDate,
    this.existingActivity,
  });

  @override
  State<ActivityDialog> createState() =>
      _ActivityDialogState();
}

class _ActivityDialogState extends State<ActivityDialog> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController titleController;

  late String selectedType;
  late String selectedPriority;
  late DateTime selectedDay;
  late TimeOfDay selectedTime;

  bool get isEditing => widget.existingActivity != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existingActivity;

    titleController = TextEditingController(
      text: existing?.title ?? '',
    );

    selectedType = existing?.type ?? 'Task';
    selectedPriority = existing?.priority ?? 'Medium';

    final initialDate =
        existing?.scheduledAt ?? widget.selectedDate;

    selectedDay = DateUtils.dateOnly(initialDate);
    selectedTime = TimeOfDay.fromDateTime(initialDate);
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  Future<void> chooseDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDay = DateUtils.dateOnly(picked);
      });
    }
  }

  Future<void> chooseTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void saveActivity() {
    if (!formKey.currentState!.validate()) return;

    final scheduledAt = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    final existing = widget.existingActivity;

    final result = PlannerActivity(
      id: existing?.id ??
          DateTime.now().microsecondsSinceEpoch,
      title: titleController.text.trim(),
      type: selectedType,
      scheduledAt: scheduledAt,
      priority: selectedPriority,
      completed: existing?.completed ?? false,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        isEditing ? 'Edit Activity' : 'Add New Activity',
        style: const TextStyle(
          color: plannerNavy,
          fontWeight: FontWeight.bold,
        ),
      ),

      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Activity title',
                  hintText: 'Enter activity name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an activity title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(
                  labelText: 'Activity type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Task',
                    child: Text('Task'),
                  ),
                  DropdownMenuItem(
                    value: 'Appointment',
                    child: Text('Appointment'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedType = value);
                  }
                },
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'High',
                    child: Text('High'),
                  ),
                  DropdownMenuItem(
                    value: 'Medium',
                    child: Text('Medium'),
                  ),
                  DropdownMenuItem(
                    value: 'Low',
                    child: Text('Low'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedPriority = value);
                  }
                },
              ),

              const SizedBox(height: 15),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.calendar_today,
                  color: plannerPurple,
                ),
                title: const Text('Date'),
                subtitle: Text(
                  '${selectedDay.day}/${selectedDay.month}/${selectedDay.year}',
                ),
                trailing: const Icon(Icons.edit_calendar),
                onTap: chooseDay,
              ),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.access_time,
                  color: plannerPurple,
                ),
                title: const Text('Time'),
                subtitle: Text(selectedTime.format(context)),
                trailing: const Icon(Icons.edit),
                onTap: chooseTime,
              ),
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),

        ElevatedButton(
          onPressed: saveActivity,
          style: ElevatedButton.styleFrom(
            backgroundColor: plannerPurple,
            foregroundColor: Colors.white,
          ),
          child: Text(
            isEditing ? 'Save Changes' : 'Add Activity',
          ),
        ),
      ],
    );
  }
}
