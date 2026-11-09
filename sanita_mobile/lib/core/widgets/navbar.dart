import 'package:flutter/material.dart';
import '../theme/theme.dart';

class SanitaNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const SanitaNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: isDark ? SanitaColors.darkCard : Colors.white,
        border: Border(top: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border, width: 1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_outlined, Icons.home, 'Beranda'),
          _buildNavItem(1, Icons.check_box_outlined, Icons.check_box, 'Cek'),
          _buildCenterLaporItem(2),
          _buildNavItem(3, Icons.format_list_bulleted_outlined, Icons.format_list_bulleted, 'Riwayat'),
          _buildNavItem(4, Icons.person_outline, Icons.person, 'Profil'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData inactiveIcon, IconData activeIcon, String label) {
    final bool isSelected = currentIndex == index;
    final color = isSelected ? SanitaColors.primary : SanitaColors.textMuted;

    return InkWell(
      onTap: () => onTabSelected(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterLaporItem(int index) {
    final bool isSelected = currentIndex == index;
    return InkWell(
      onTap: () => onTabSelected(index),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isSelected ? SanitaColors.primary : SanitaColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add,
              color: isSelected ? Colors.white : SanitaColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Lapor',
            style: TextStyle(
              color: isSelected ? SanitaColors.primary : SanitaColors.textMuted,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}