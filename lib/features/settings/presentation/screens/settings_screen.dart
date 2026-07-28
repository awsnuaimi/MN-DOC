import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/settings_provider.dart';
import '../../data/models/profile.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/constants/app_colors.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ البيانات')));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSectionCard(
                  title: 'المعلومات الشخصية',
                  icon: Icons.person_rounded,
                  children: [
                    _buildTextField('الاسم', Icons.badge_rounded, _nameController),
                    const SizedBox(height: 12),
                    _buildTextField('البريد الإلكتروني', Icons.email_rounded, _emailController),
                    const SizedBox(height: 12),
                    _buildTextField('رقم الهاتف', Icons.phone_rounded, _phoneController),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('حفظ التغييرات'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'المظهر',
                  icon: Icons.palette_rounded,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
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
                        themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                      },
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
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