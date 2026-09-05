import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/chat/chat_list_screen.dart';
import '../screens/provider/provider_book_service_screen.dart';
import '../screens/provider/provider_dashboard_screen.dart';
import '../screens/provider/provider_profile_screen.dart';
import '../screens/provider/provider_schedule_screen.dart';

class ProviderBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const ProviderBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget targetScreen;

    switch (index) {
      case 0:
        targetScreen = const ProviderDashboardScreen();
        break;
      case 1:
        targetScreen = const ProviderBookServiceScreen();
        break;
      case 2:
        targetScreen = const ProviderScheduleScreen();
        break;
      case 3:
        targetScreen = const ChatListScreen();
        break;
      case 4:
        targetScreen = const ProviderProfileScreen();
        break;
      default:
        targetScreen = const ProviderDashboardScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF020408),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context: context,
            index: 0,
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
            label: 'Home',
          ),
          _buildNavItem(
            context: context,
            index: 1,
            icon: Icons.storefront_outlined,
            activeIcon: Icons.storefront_rounded,
            label: 'Book',
          ),
          _buildNavItem(
            context: context,
            index: 2,
            icon: Icons.calendar_today_outlined,
            activeIcon: Icons.calendar_today_rounded,
            label: 'Schedule',
          ),
          _buildNavItem(
            context: context,
            index: 3,
            icon: Icons.message_outlined,
            activeIcon: Icons.message_rounded,
            label: 'Messages',
          ),
          _buildNavItem(
            context: context,
            index: 4,
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(context, index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF0284C7).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive
                  ? const Color(0xFF38BDF8)
                  : Colors.white.withValues(alpha: 0.4),
              size: 20,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF38BDF8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}