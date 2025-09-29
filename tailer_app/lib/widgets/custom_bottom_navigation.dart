import 'package:flutter/material.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double? elevation;

  const CustomBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: elevation ?? 8.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: backgroundColor ?? Colors.white,
        selectedItemColor: selectedItemColor ?? Theme.of(context).primaryColor,
        unselectedItemColor: unselectedItemColor ?? Colors.grey,
        elevation: 0, // We handle elevation with Container shadow
        items: items.map((item) => BottomNavigationBarItem(
          icon: Icon(item.icon),
          activeIcon: Icon(item.activeIcon ?? item.icon),
          label: item.label,
        )).toList(),
      ),
    );
  }
}

class AnimatedBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double? elevation;
  final Duration animationDuration;

  const AnimatedBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation,
    this.animationDuration = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: elevation ?? 15.0,
            offset: const Offset(0, -5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == currentIndex;

            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.circular(16),
                  splashColor: (selectedItemColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
                  highlightColor: (selectedItemColor ?? Theme.of(context).primaryColor).withOpacity(0.05),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: animationDuration,
                          curve: Curves.easeInOut,
                          padding: EdgeInsets.all(isSelected ? 8 : 6),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? (selectedItemColor ?? Theme.of(context).primaryColor).withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                            color: isSelected 
                                ? (selectedItemColor ?? Theme.of(context).primaryColor)
                                : (unselectedItemColor ?? Colors.grey.shade600),
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedDefaultTextStyle(
                          duration: animationDuration,
                          curve: Curves.easeInOut,
                          style: TextStyle(
                            color: isSelected 
                                ? (selectedItemColor ?? Theme.of(context).primaryColor)
                                : (unselectedItemColor ?? Colors.grey.shade600),
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            height: 1.0,
                          ),
                          child: Text(
                            item.label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class FloatingBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double? margin;

  const FloatingBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.margin = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(margin!),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == currentIndex;

          return GestureDetector(
            onTap: () => onTap(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (selectedItemColor ?? Theme.of(context).primaryColor)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                    color: isSelected 
                        ? Colors.white
                        : (unselectedItemColor ?? Colors.grey),
                    size: 24,
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const BottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

// Common bottom navigation items for the tailor app
class TailorAppBottomNavItems {
  static List<BottomNavItem> get defaultItems => [
    const BottomNavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    const BottomNavItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Customers',
    ),
    const BottomNavItem(
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag,
      label: 'Orders',
    ),
    const BottomNavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
    ),
  ];
}