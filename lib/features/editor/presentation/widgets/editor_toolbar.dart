import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// وصف إجراء واحد بشريط أدوات المحرر (بدون أي منطق داخلي).
class ToolbarAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  const ToolbarAction({required this.icon, required this.label, required this.onTap, this.active = false});
}

/// شريط أدوات المحرر العائم — ودجت عرض بحت، لا يعرف شيئاً عن منطق كل أداة.
/// قابل لإعادة الاستخدام بأي شاشة تانية تحتاج نفس النمط.
class EditorToolbar extends StatelessWidget {
  final List<ToolbarAction> actions;
  const EditorToolbar({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightWash),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: actions.map((a) => _ToolbarButton(action: a)).toList(),
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final ToolbarAction action;
  const _ToolbarButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: action.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: action.active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: action.active ? null : Border.all(color: AppColors.lightWash),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(action.icon, size: 18, color: action.active ? Colors.white : AppColors.primary),
          const SizedBox(height: 2),
          Text(action.label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: action.active ? Colors.white : AppColors.primary)),
        ]),
      ),
    );
  }
}