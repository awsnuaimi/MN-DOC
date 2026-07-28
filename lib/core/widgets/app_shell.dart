import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Container(
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.lightWash),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'الرئيسية',
                  active: currentIndex == 0,
                  onTap: () => navigationShell.goBranch(0, initialLocation: currentIndex == 0),
                ),
                _NavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'القوالب',
                  active: currentIndex == 1,
                  onTap: () => navigationShell.goBranch(1, initialLocation: currentIndex == 1),
                ),
                _FabItem(onTap: () => context.push('/scanner')),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'الإعدادات',
                  active: currentIndex == 2,
                  onTap: () => navigationShell.goBranch(2, initialLocation: currentIndex == 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 17, color: active ? Colors.white : AppColors.primary.withOpacity(0.3)),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    height: 1.0,
                    fontWeight: FontWeight.bold,
                    color: active ? AppColors.primary : AppColors.primary.withOpacity(0.4))),
            SizedBox(
              height: 6,
              child: active
                  ? Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _FabItem extends StatelessWidget {
  final VoidCallback onTap;
  const _FabItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppColors.primaryButtonShadow,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}