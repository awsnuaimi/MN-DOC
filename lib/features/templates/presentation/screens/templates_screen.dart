import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('القوالب')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration:
                    BoxDecoration(color: AppColors.lightWash, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.grid_view_rounded, size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text('القوالب الجاهزة قريباً', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'هذه المساحة محجوزة لقوالب مستندات جاهزة (عقود، طلبات، نماذج...)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}