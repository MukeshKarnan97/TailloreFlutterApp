// Example implementation showing how to fix bottom navigation issues
// Use this pattern in ALL screens that have bottom navigation

import 'package:flutter/material.dart';
import 'package:tailer_app/core/mixins/bottom_navigation_mixin.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';

// ✅ CORRECT Implementation - Use this pattern
class FixedDashboardScreen extends StatefulWidget {
  const FixedDashboardScreen({Key? key}) : super(key: key);

  @override
  State<FixedDashboardScreen> createState() => _FixedDashboardScreenState();
}

class _FixedDashboardScreenState extends State<FixedDashboardScreen> 
    with BottomNavigationMixin {
  
  // Required by BottomNavigationMixin
  int _currentNavIndex = 0;
  final SimpleLocaleProvider _localeProvider = SimpleLocaleProvider();

  @override
  int get currentNavIndex => _currentNavIndex;

  @override
  void setNavIndex(int index) {
    if (mounted) {
      setState(() {
        _currentNavIndex = index;
      });
    }
  }

  @override
  void dispose() {
    // Don't dispose singleton _localeProvider
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeProvider,
      builder: (context, child) {
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        
        return Scaffold(
          appBar: AppBar(title: Text(locale.t('dashboard'))),
          body: const Center(
            child: Text('Dashboard Content'),
          ),
          // ✅ Use the standardized bottom navigation
          bottomNavigationBar: buildBottomNavigation(locale),
        );
      },
    );
  }
}

// ❌ INCORRECT Implementation - This causes the popup-only issue
class BrokenDashboardScreen extends StatefulWidget {
  @override
  State<BrokenDashboardScreen> createState() => _BrokenDashboardScreenState();
}

class _BrokenDashboardScreenState extends State<BrokenDashboardScreen> {
  int _currentNavIndex = 0;

  // ❌ This method has issues
  void _onNavTap(int index) {
    // Problem 1: Updates state but navigation might fail
    setState(() {
      _currentNavIndex = index;
    });
    
    // Problem 2: No error handling
    // Problem 3: No mounted check
    // Problem 4: Inconsistent navigation logic
    switch (index) {
      case 0:
        // Navigation might fail silently
        break;
      case 1:
        // Sometimes works, sometimes doesn't
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: AnimatedBottomNavigation(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap, // ❌ Uses broken navigation
        items: TailorAppBottomNavItems.defaultItems,
      ),
    );
  }
}

// 🔧 Quick Fix for Existing Screens
/*
To fix any existing screen with navigation issues:

1. Add the mixin:
   class MyScreenState extends State<MyScreen> with BottomNavigationMixin {

2. Implement required methods:
   int _currentNavIndex = 0; // Your current index variable
   
   @override
   int get currentNavIndex => _currentNavIndex;
   
   @override
   void setNavIndex(int index) {
     setState(() {
       _currentNavIndex = index;
     });
   }

3. Replace your bottom navigation:
   bottomNavigationBar: buildBottomNavigation(locale),

4. Remove your old _onNavTap method completely

That's it! Navigation will work consistently.
*/