import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/settings_provider.dart';
import '../../data/models/profile.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_button.dart';

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
      if (profileProvider.profile != null && mounted) {
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

  void _editProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('الملف الشخصي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'الاسم')),
              const SizedBox(height: 12),
              TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
              const SizedBox(height: 12),
              TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف')),
              const SizedBox(height: 20),
              CommonButton(
                label: 'حفظ',
                icon: Icons.check_rounded,
                onPressed: () {
                  _save();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final profileProvider = context.watch<SettingsProvider>();
    final profile = profileProvider.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: profileProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SettingsGroup(title: 'الحساب', children: [
                  _SettingsRow(
                    label: profile?.name.isNotEmpty == true ? profile!.name : 'الملف الشخصي',
                    subtitle: profile?.email,
                    onTap: _editProfileSheet,
                  ),
                  _SettingsRow(label: 'الاشتراك المميز', onTap: () {}),
                ]),
                const SizedBox(height: 12),
                _SettingsGroup(title: 'التفضيلات', children: [
                  _SettingsRow(label: 'اللغة', trailingText: 'العربية'),
                  _SettingsToggleRow(
                    label: 'المظهر الداكن',
                    value: themeProvider.themeMode == ThemeMode.dark,
                    onChanged: (value) =>
                        themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light),
                  ),
                  _SettingsRow(label: 'الإشعارات', onTap: () {}),
                ]),
                const SizedBox(height: 12),
                _SettingsGroup(title: 'الدعم', children: [
                  _SettingsRow(label: 'المساعدة', onTap: () {}),
                  _SettingsRow(label: 'سياسة الخصوصية', onTap: () {}),
                ]),
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

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightWash),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(title.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.primary.withOpacity(0.4))),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightWash),
            ),
            child: Column(children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                children[i],
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final String? trailingText;
  final VoidCallback? onTap;
  const _SettingsRow({required this.label, this.subtitle, this.trailingText, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: subtitle != null ? 56 : 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: TextStyle(fontSize: 11, color: AppColors.primary.withOpacity(0.4))),
                ],
              ),
            ),
            if (trailingText != null)
              Text(trailingText!, style: TextStyle(fontSize: 12, color: AppColors.primary.withOpacity(0.4))),
            if (onTap != null) Icon(Icons.chevron_left_rounded, color: AppColors.primary.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingsToggleRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}