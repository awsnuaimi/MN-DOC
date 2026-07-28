import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../theme/app_theme.dart';

enum CommonButtonVariant { primary, secondary, outlined, soft }

class CommonButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final CommonButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  const CommonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CommonButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  @override
  State<CommonButton> createState() => _CommonButtonState();
}

class _CommonButtonState extends State<CommonButton> {
  bool _pressed = false;

  ({Color bg, Color fg, Color? border, List<BoxShadow>? shadow}) _styleFor(
      CommonButtonVariant v) {
    switch (v) {
      case CommonButtonVariant.primary:
        return (
          bg: AppColors.primary,
          fg: Colors.white,
          border: null,
          shadow: AppColors.primaryButtonShadow
        );
      case CommonButtonVariant.secondary:
        return (bg: AppColors.secondary, fg: Colors.white, border: null, shadow: null);
      case CommonButtonVariant.outlined:
        return (bg: Colors.white, fg: AppColors.primary, border: AppColors.border, shadow: null);
      case CommonButtonVariant.soft:
        return (bg: AppColors.lightWash, fg: AppColors.primary, border: null, shadow: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(widget.variant);
    final disabled = widget.onPressed == null || widget.isLoading;

    final child = AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: AppTheme.buttonHeight,
        width: widget.expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          color: disabled ? style.bg.withOpacity(0.5) : style.bg,
          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
          border: style.border != null ? Border.all(color: style.border!) : null,
          boxShadow: disabled ? null : style.shadow,
        ),
        alignment: Alignment.center,
        child: widget.isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: style.fg),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18, color: style.fg),
                    const SizedBox(width: 8),
                  ],
                  Text(widget.label,
                      style: GoogleFonts.tajawal(
                          fontSize: 14, fontWeight: FontWeight.w700, color: style.fg)),
                ],
              ),
      ),
    );

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTap: disabled ? null : widget.onPressed,
      child: child,
    );
  }
}