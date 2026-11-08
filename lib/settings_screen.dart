
import 'package:flutter/material.dart';
import 'api_service.dart';

const Color settingsTeal = Color(0xFF00C4C7);
const Color settingsPurple = Color(0xFF7950F2);
const Color settingsNavy = Color(0xFF19172F);

class SettingsScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final VoidCallback onLogout;

  final void Function({
    required String themeMode,
    required String accentColor,
  }) onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.onLogout,
    required this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isLoading = true;
  bool isSaving = false;
  String? loadError;

  Map<String, dynamic> settings = {
    'notifications_enabled': true,
    'reminder_notifications': true,
    'assistant_notifications': true,
    'theme_mode': 'system',
    'accent_color': '#7950F2',
    'voice_responses': true,
    'speech_input': true,
    'assistant_style': 'friendly',
    'speech_rate': 0.50,
    'analytics_enabled': true,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  bool _toBool(dynamic value) {
    return value == true ||
        value == 1 ||
        value.toString() == '1' ||
        value.toString().toLowerCase() == 'true';
  }

  Future<void> _loadSettings() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final result = await ApiService.getSettings(
        userId: widget.userId,
      );

      if (!mounted) return;

      setState(() {
        settings = {
          'notifications_enabled': _toBool(
              result['notifications_enabled']),
          'reminder_notifications': _toBool(
              result['reminder_notifications']),
          'assistant_notifications': _toBool(
              result['assistant_notifications']),
          'theme_mode':
              result['theme_mode']?.toString() ?? 'system',
          'accent_color':
              result['accent_color']?.toString() ?? '#7950F2',
          'voice_responses':
              _toBool(result['voice_responses']),
          'speech_input': _toBool(result['speech_input']),
          'assistant_style':
              result['assistant_style']?.toString() ?? 'friendly',
          'speech_rate':
              double.tryParse(
                    result['speech_rate'].toString(),
                  ) ??
                  0.50,
          'analytics_enabled':
              _toBool(result['analytics_enabled']),
        };

        isLoading = false;
      });

      widget.onThemeChanged(
        themeMode: settings['theme_mode'],
        accentColor: settings['accent_color'],
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        loadError =
            error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _saveSettings(
    Map<String, dynamic> newSettings,
  ) async {
    final previousSettings =
        Map<String, dynamic>.from(settings);

    setState(() {
      settings = Map<String, dynamic>.from(newSettings);
      isSaving = true;
    });

    try {
      await ApiService.saveSettings(
        userId: widget.userId,
        settings: newSettings,
      );

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        settings = previousSettings;
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );

      rethrow;
    }
  }

  Future<void> _changeSetting(
    String key,
    dynamic value,
  ) async {
    final updated = Map<String, dynamic>.from(settings);
    updated[key] = value;

    await _saveSettings(updated);

    if (key == 'theme_mode' || key == 'accent_color') {
      widget.onThemeChanged(
        themeMode: updated['theme_mode'],
        accentColor: updated['accent_color'],
      );
    }
  }

  Future<void> _openAccount() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountSettingsPage(
          userId: widget.userId,
          fallbackName: widget.userName,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openAppearance() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppearanceSettingsPage(
          settings: Map<String, dynamic>.from(settings),
          onSave: _saveSettings,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );

    if (mounted) {
      _loadSettings();
    }
  }

  Future<void> _openAssistantPreferences() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssistantPreferencesPage(
          settings: Map<String, dynamic>.from(settings),
          onSave: _saveSettings,
        ),
      ),
    );

    if (mounted) {
      _loadSettings();
    }
  }

  Future<void> _openPrivacy() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrivacySettingsPage(
          settings: Map<String, dynamic>.from(settings),
          onSave: _saveSettings,
          onOpenAccount: _openAccount,
        ),
      ),
    );

    if (mounted) {
      _loadSettings();
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Log out?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: settingsPurple,
              ),
            )
          : loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          color: Colors.red,
                          size: 45,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Could not load your settings.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loadError!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton.icon(
                          onPressed: _loadSettings,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    ListView(
                      padding: const EdgeInsets.all(18),
                      children: [
                        _buildProfileCard(),
                        const SizedBox(height: 24),

                        _sectionTitle('Notifications'),

                        _switchTile(
                          icon: Icons.notifications_active_outlined,
                          title: 'Enable notifications',
                          subtitle:
                              'Enable or disable AURA notification preferences',
                          value: settings['notifications_enabled'],
                          onChanged: (value) async {
                            final updated =
                                Map<String, dynamic>.from(settings);

                            updated['notifications_enabled'] = value;

                            await _saveSettings(updated);
                          },
                        ),

                        _switchTile(
                          icon: Icons.alarm_outlined,
                          title: 'Reminder alerts',
                          subtitle:
                              'Receive alerts about your reminders',
                          value: settings['reminder_notifications'],
                          onChanged:
                              settings['notifications_enabled']
                                  ? (value) => _changeSetting(
                                        'reminder_notifications',
                                        value,
                                      )
                                  : null,
                        ),

                        _switchTile(
                          icon: Icons.smart_toy_outlined,
                          title: 'Assistant notifications',
                          subtitle:
                              'Receive updates from your assistant',
                          value: settings['assistant_notifications'],
                          onChanged:
                              settings['notifications_enabled']
                                  ? (value) => _changeSetting(
                                        'assistant_notifications',
                                        value,
                                      )
                                  : null,
                        ),

                        const SizedBox(height: 22),

                        _sectionTitle('Personalisation'),

                        _navigationTile(
                          icon: Icons.palette_outlined,
                          title: 'Appearance',
                          subtitle:
                              'Choose your theme and accent colour',
                          onTap: _openAppearance,
                        ),

                        _navigationTile(
                          icon: Icons.tune,
                          title: 'Assistant preferences',
                          subtitle:
                              'Manage voice and response preferences',
                          onTap: _openAssistantPreferences,
                        ),

                        const SizedBox(height: 22),

                        _sectionTitle('Account & Privacy'),

                        _navigationTile(
                          icon: Icons.person_outline,
                          title: 'Account details',
                          subtitle:
                              'Edit your name and email address',
                          onTap: _openAccount,
                        ),

                        _navigationTile(
                          icon: Icons.lock_outline,
                          title: 'Privacy and security',
                          subtitle:
                              'Manage privacy and account security',
                          onTap: _openPrivacy,
                        ),

                        _navigationTile(
                          icon: Icons.info_outline,
                          title: 'About AURA',
                          subtitle:
                              'Learn more about your personal assistant',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AboutAuraPage(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 25),

                        SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _confirmLogout,
                            icon: const Icon(
                              Icons.logout,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Log out',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Colors.red,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        const Center(
                          child: Text(
                            'AURA v1.0.0',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),
                      ],
                    ),

                    if (isSaving)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          color: settingsPurple,
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: settingsNavy,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 27,
            backgroundColor: settingsPurple,
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Account',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.userName.isEmpty
                      ? 'AURA User'
                      : widget.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage your personal settings',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified_user_outlined,
            color: settingsTeal,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: settingsNavy,
        ),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: const Icon(
          Icons.notifications_outlined,
          color: settingsPurple,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        value: value,
        activeThumbColor: settingsTeal,
        onChanged: onChanged,
      ),
    );
  }

  Widget _navigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: settingsPurple),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}

// --------------------------------------------------
// ACCOUNT SETTINGS
// --------------------------------------------------

class AccountSettingsPage extends StatefulWidget {
  final int userId;
  final String fallbackName;

  const AccountSettingsPage({
    super.key,
    required this.userId,
    required this.fallbackName,
  });

  @override
  State<AccountSettingsPage> createState() =>
      _AccountSettingsPageState();
}

class _AccountSettingsPageState
    extends State<AccountSettingsPage> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _loadAccount() async {
    try {
      final result = await ApiService.getAccount(
        userId: widget.userId,
      );

      if (!mounted) return;

      nameController.text =
          result['full_name']?.toString() ?? widget.fallbackName;
      emailController.text =
          result['email']?.toString() ?? '';

      setState(() {
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isSaving = true;
    });

    try {
      await ApiService.updateProfile(
        userId: widget.userId,
        fullName: nameController.text.trim(),
        email: emailController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Details'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              isLoading = true;
                              errorMessage = null;
                            });
                            _loadAccount();
                          },
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const CircleAvatar(
                      radius: 38,
                      backgroundColor: settingsPurple,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Personal information',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Please enter your name.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  !RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  ).hasMatch(value.trim())) {
                                return 'Enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  isSaving ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: settingsPurple,
                                foregroundColor: Colors.white,
                              ),
                              child: isSaving
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.lock_outline,
                          color: settingsPurple,
                        ),
                        title: const Text('Change password'),
                        subtitle: const Text(
                          'Update your account password',
                        ),
                        trailing:
                            const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangePasswordPage(
                                userId: widget.userId,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

// --------------------------------------------------
// CHANGE PASSWORD
// --------------------------------------------------

class ChangePasswordPage extends StatefulWidget {
  final int userId;

  const ChangePasswordPage({
    super.key,
    required this.userId,
  });

  @override
  State<ChangePasswordPage> createState() =>
      _ChangePasswordPageState();
}

class _ChangePasswordPageState
    extends State<ChangePasswordPage> {
  final formKey = GlobalKey<FormState>();

  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();

  bool isSaving = false;
  bool hideCurrent = true;
  bool hideNew = true;
  bool hideConfirm = true;

  @override
  void dispose() {
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isSaving = true;
    });

    try {
      await ApiService.changePassword(
        userId: widget.userId,
        currentPassword: currentController.text,
        newPassword: newController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully.'),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lock_reset,
                size: 55,
                color: settingsPurple,
              ),
              const SizedBox(height: 15),
              const Text(
                'Update your password',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your current password, then choose a new password.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 25),

              TextFormField(
                controller: currentController,
                obscureText: hideCurrent,
                decoration: InputDecoration(
                  labelText: 'Current password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hideCurrent
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        hideCurrent = !hideCurrent;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your current password.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: newController,
                obscureText: hideNew,
                decoration: InputDecoration(
                  labelText: 'New password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hideNew
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        hideNew = !hideNew;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'Password must be at least 8 characters.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: confirmController,
                obscureText: hideConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm new password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hideConfirm
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        hideConfirm = !hideConfirm;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value != newController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      isSaving ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: settingsPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: isSaving
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text('Update Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// APPEARANCE SETTINGS
// --------------------------------------------------

class AppearanceSettingsPage extends StatefulWidget {
  final Map<String, dynamic> settings;
  final Future<void> Function(Map<String, dynamic>) onSave;

  final void Function({
    required String themeMode,
    required String accentColor,
  }) onThemeChanged;

  const AppearanceSettingsPage({
    super.key,
    required this.settings,
    required this.onSave,
    required this.onThemeChanged,
  });

  @override
  State<AppearanceSettingsPage> createState() =>
      _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState
    extends State<AppearanceSettingsPage> {
  late String themeMode;
  late String accentColor;

  bool isSaving = false;

  final List<String> colors = [
    '#7950F2',
    '#00C4C7',
    '#2196F3',
    '#E91E63',
    '#FF9800',
    '#4CAF50',
    '#F44336',
  ];

  @override
  void initState() {
    super.initState();

    themeMode =
        widget.settings['theme_mode']?.toString() ?? 'system';
    accentColor =
        widget.settings['accent_color']?.toString() ?? '#7950F2';
  }

  Color _parseColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(
      int.parse('FF$cleaned', radix: 16),
    );
  }

  Future<void> _saveAppearance() async {
    setState(() {
      isSaving = true;
    });

    final updated =
        Map<String, dynamic>.from(widget.settings);

    updated['theme_mode'] = themeMode;
    updated['accent_color'] = accentColor;

    try {
      await widget.onSave(updated);

      widget.onThemeChanged(
        themeMode: themeMode,
        accentColor: accentColor,
      );

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Choose your theme',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select how AURA should look on your device.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 15),

          _themeOption(
            value: 'light',
            title: 'Light',
            subtitle: 'Always use light appearance',
            icon: Icons.light_mode_outlined,
          ),

          _themeOption(
            value: 'dark',
            title: 'Dark',
            subtitle: 'Always use dark appearance',
            icon: Icons.dark_mode_outlined,
          ),

          _themeOption(
            value: 'system',
            title: 'System default',
            subtitle: 'Follow your device appearance',
            icon: Icons.settings_brightness_outlined,
          ),

          const SizedBox(height: 28),

          const Text(
            'Accent colour',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Choose a colour for AURA highlights and controls.',
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 18),

          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: colors.map((color) {
              final selected = accentColor == color;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    accentColor = color;
                  });
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _parseColor(color),
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(
                            color: Colors.black,
                            width: 3,
                          )
                        : null,
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 35),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed:
                  isSaving ? null : _saveAppearance,
              style: ElevatedButton.styleFrom(
                backgroundColor: _parseColor(accentColor),
                foregroundColor: Colors.white,
              ),
              child: isSaving
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Text('Save Appearance'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: RadioListTile<String>(
        value: value,
        groupValue: themeMode,
        activeColor: settingsPurple,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        secondary: Icon(icon, color: settingsPurple),
        onChanged: (newValue) {
          if (newValue != null) {
            setState(() {
              themeMode = newValue;
            });
          }
        },
      ),
    );
  }
}

// --------------------------------------------------
// ASSISTANT PREFERENCES
// --------------------------------------------------

class AssistantPreferencesPage extends StatefulWidget {
  final Map<String, dynamic> settings;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const AssistantPreferencesPage({
    super.key,
    required this.settings,
    required this.onSave,
  });

  @override
  State<AssistantPreferencesPage> createState() =>
      _AssistantPreferencesPageState();
}

class _AssistantPreferencesPageState
    extends State<AssistantPreferencesPage> {
  late bool voiceResponses;
  late bool speechInput;
  late String assistantStyle;
  late double speechRate;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    voiceResponses =
        widget.settings['voice_responses'] == true;
    speechInput =
        widget.settings['speech_input'] == true;

    assistantStyle =
        widget.settings['assistant_style'] ?? 'friendly';

    speechRate =
        (widget.settings['speech_rate'] as num?)?.toDouble() ??
            0.50;
  }

  Future<void> _savePreferences() async {
    setState(() {
      isSaving = true;
    });

    final updated =
        Map<String, dynamic>.from(widget.settings);

    updated['voice_responses'] = voiceResponses;
    updated['speech_input'] = speechInput;
    updated['assistant_style'] = assistantStyle;
    updated['speech_rate'] = speechRate;

    try {
      await widget.onSave(updated);

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Preferences'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Voice settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(
              Icons.volume_up_outlined,
              color: settingsPurple,
            ),
            title: const Text('Voice responses'),
            subtitle: const Text(
              'Allow AURA to respond using speech',
            ),
            value: voiceResponses,
            activeThumbColor: settingsTeal,
            onChanged: (value) {
              setState(() {
                voiceResponses = value;
              });
            },
          ),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(
              Icons.mic_none,
              color: settingsPurple,
            ),
            title: const Text('Speech input'),
            subtitle: const Text(
              'Allow you to speak to your assistant',
            ),
            value: speechInput,
            activeThumbColor: settingsTeal,
            onChanged: (value) {
              setState(() {
                speechInput = value;
              });
            },
          ),

          const SizedBox(height: 25),

          const Text(
            'Response style',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            value: assistantStyle,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'How should AURA respond?',
            ),
            items: const [
              DropdownMenuItem(
                value: 'friendly',
                child: Text('Friendly'),
              ),
              DropdownMenuItem(
                value: 'concise',
                child: Text('Concise'),
              ),
              DropdownMenuItem(
                value: 'detailed',
                child: Text('Detailed'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  assistantStyle = value;
                });
              }
            },
          ),

          const SizedBox(height: 25),

          const Text(
            'Speech rate',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Speech speed: ${speechRate.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.grey),
          ),

          Slider(
            value: speechRate,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            activeColor: settingsPurple,
            label: speechRate.toStringAsFixed(2),
            onChanged: voiceResponses
                ? (value) {
                    setState(() {
                      speechRate = value;
                    });
                  }
                : null,
          ),

          const SizedBox(height: 30),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed:
                  isSaving ? null : _savePreferences,
              style: ElevatedButton.styleFrom(
                backgroundColor: settingsPurple,
                foregroundColor: Colors.white,
              ),
              child: isSaving
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Text('Save Preferences'),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// PRIVACY AND SECURITY
// --------------------------------------------------

class PrivacySettingsPage extends StatefulWidget {
  final Map<String, dynamic> settings;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final VoidCallback onOpenAccount;

  const PrivacySettingsPage({
    super.key,
    required this.settings,
    required this.onSave,
    required this.onOpenAccount,
  });

  @override
  State<PrivacySettingsPage> createState() =>
      _PrivacySettingsPageState();
}

class _PrivacySettingsPageState
    extends State<PrivacySettingsPage> {
  late bool analyticsEnabled;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    analyticsEnabled =
        widget.settings['analytics_enabled'] == true;
  }

  Future<void> _savePrivacy(bool value) async {
    setState(() {
      analyticsEnabled = value;
      isSaving = true;
    });

    final updated =
        Map<String, dynamic>.from(widget.settings);

    updated['analytics_enabled'] = value;

    try {
      await widget.onSave(updated);

      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          analyticsEnabled = !value;
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 55,
            color: settingsPurple,
          ),

          const SizedBox(height: 15),

          const Text(
            'Your privacy matters',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Manage the privacy preferences associated with your AURA account.',
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 25),

          Card(
            elevation: 0,
            child: SwitchListTile(
              secondary: const Icon(
                Icons.analytics_outlined,
                color: settingsPurple,
              ),
              title: const Text(
                'Analytics preference',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Allow analytics preferences to be saved for your account.',
              ),
              value: analyticsEnabled,
              activeThumbColor: settingsTeal,
              onChanged: isSaving ? null : _savePrivacy,
            ),
          ),

          const SizedBox(height: 15),

          Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(
                Icons.password_outlined,
                color: settingsPurple,
              ),
              title: const Text(
                'Change password',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Update your account password securely',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: widget.onOpenAccount,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Security information',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Always keep your password private. Choose a strong password and do not share your login details with anyone.',
            style: TextStyle(
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// ABOUT AURA
// --------------------------------------------------

class AboutAuraPage extends StatelessWidget {
  const AboutAuraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About AURA'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      settingsTeal,
                      settingsPurple,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 55,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'AURA',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: settingsNavy,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Your day, thoughtfully organised.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 25),

              const Card(
                elevation: 0,
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Text(
                        'About the application',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'AURA is a personal assistant designed to help users organise daily activities, manage reminders and interact with an intelligent assistant.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              const ListTile(
                leading: Icon(
                  Icons.apps,
                  color: settingsPurple,
                ),
                title: Text('Application'),
                subtitle: Text('AURA Personal Assistant'),
              ),

              const ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: settingsPurple,
                ),
                title: Text('Version'),
                subtitle: Text('1.0.0'),
              ),

              const SizedBox(height: 20),

              const Text(
                'Made to help you plan, focus and stay organised.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
