import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/settings_provider.dart';
import '../../data/models/profile.dart';
import '../../../../core/providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final profileProvider = context.read<SettingsProvider>();
    profileProvider.loadProfile().then((_) {
      if (profileProvider.profile != null) {
        _nameController.text = profileProvider.profile!.name;
        _emailController.text = profileProvider.profile!.email;
        _phoneController.text = profileProvider.profile!.phone;
      }
    });
  }

  void _save() {
    final provider = context.read<SettingsProvider>();
    final profile = Profile(
      id: provider.profile?.id,
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
    );
    provider.saveProfile(profile);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ البيانات')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final profileProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: profileProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'الاسم'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration:
                      const InputDecoration(labelText: 'البريد الإلكتروني'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ'),
                ),
                const Divider(height: 40),
                SwitchListTile(
                  title: const Text('الوضع الليلي'),
                  subtitle: Text(
                    themeProvider.themeMode == ThemeMode.dark
                        ? 'داكن'
                        : themeProvider.themeMode == ThemeMode.light
                            ? 'فاتح'
                            : 'النظام',
                  ),
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeProvider.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}