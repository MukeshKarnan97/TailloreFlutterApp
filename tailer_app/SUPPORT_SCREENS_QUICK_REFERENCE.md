# Support Screens Quick Reference Guide

## 🎯 What Was Changed

All three support screens updated to match app design standards:
- **help_center_screen.dart** ✅
- **feedback_screen.dart** ✅
- **bug_report_screen.dart** ✅

---

## 📋 Changes Applied

### Header
**Before**: Basic AppBar with manual back button
**After**: CustomHeaderWithProfile (consistent with rest of app)

### Colors
**Before**: Mixed (Colors.grey, Colors.orange, Color(AppConstants.primaryTeal))
**After**: AppColors constants (primary, accent, info, error, success)

### Responsive Design
**Before**: Fixed sizes (no responsiveness)
**After**: Screen width detection + conditional sizing

### Input Fields
**Before**: Basic TextFormField styling
**After**: Enhanced with AppColors, responsive fonts, filled backgrounds

---

## 🔧 How to Use The New Pattern

### 1. Screen Setup
```dart
@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isSmallScreen = screenWidth < 360;
  
  return Scaffold(
    backgroundColor: AppColors.background,
    appBar: CustomHeaderWithProfile(
      title: locale.translate('yourTitle'),
    ),
    body: ... // Pass isSmallScreen to all methods
  );
}
```

### 2. Section Container
```dart
Container(
  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
    border: Border.all(
      color: AppColors.primary.withOpacity(0.15),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadow.withOpacity(0.08),
        blurRadius: 16,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: Column(...),
)
```

### 3. Section Header with Icon
```dart
Row(
  children: [
    Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.your_icon_rounded,
        color: Colors.white,
        size: isSmallScreen ? 18 : 20,
      ),
    ),
    SizedBox(width: isSmallScreen ? 10 : 12),
    Expanded(
      child: Text(
        'Section Title',
        style: GoogleFonts.inter(
          fontSize: isSmallScreen ? 14 : 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    ),
  ],
)
```

### 4. Enhanced Text Field
```dart
TextFormField(
  controller: _controller,
  style: GoogleFonts.inter(
    fontSize: isSmallScreen ? 13 : 14,
    color: AppColors.textPrimary,
  ),
  decoration: InputDecoration(
    labelText: 'Label',
    labelStyle: GoogleFonts.inter(
      fontSize: isSmallScreen ? 12 : 14,
      color: AppColors.textSecondary,
    ),
    prefixIcon: Icon(
      Icons.icon_rounded,
      color: AppColors.primary,
      size: isSmallScreen ? 20 : 22,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.error),
    ),
    filled: true,
    fillColor: AppColors.background,
    hintText: 'Hint text',
    hintStyle: GoogleFonts.inter(
      fontSize: isSmallScreen ? 12 : 13,
      color: AppColors.textSecondary.withOpacity(0.6),
    ),
  ),
)
```

### 5. Gradient Button
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        AppColors.primary,
        AppColors.primary.withOpacity(0.9),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: SizedBox(
    width: double.infinity,
    height: isSmallScreen ? 50 : 56,
    child: ElevatedButton(
      onPressed: _onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.send_rounded, size: isSmallScreen ? 18 : 20),
          SizedBox(width: isSmallScreen ? 8 : 10),
          Text(
            'Button Text',
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  ),
)
```

---

## 📐 Responsive Size Reference

### Screen Breakpoint
```dart
isSmallScreen = screenWidth < 360
```

### Padding Sizes
| Element | Small | Normal |
|---------|-------|--------|
| Container | 16 | 20 |
| Section Header Icon | 8 | 10 |
| Card Internal | 14-16 | 16-20 |
| Multi-line Icon | varies | varies |

### Font Sizes
| Text Type | Small | Normal |
|-----------|-------|--------|
| Body Text | 12-13 | 14 |
| Labels | 12 | 14 |
| Headers | 14 | 16 |
| Titles | 17 | 20 |

### Icon Sizes
| Icon Type | Small | Normal |
|-----------|-------|--------|
| Section Icons | 18 | 20 |
| Field Icons | 20 | 22 |
| Large Icons | 32 | 40 |
| Star Rating | 28 | 32 |

### Button Heights
| Button Type | Small | Normal |
|-------------|-------|--------|
| Primary | 50 | 56 |
| Secondary | 44 | 48 |

### Spacing
| Space Type | Small | Normal |
|------------|-------|--------|
| Between Sections | 16 | 20 |
| Between Fields | 14 | 16 |
| Icon to Text | 10 | 12 |
| Before Submit | 24 | 32 |

---

## 🎨 AppColors Reference

### Primary Colors
- `AppColors.primary` - Main teal color
- `AppColors.accent` - Orange accent
- `AppColors.background` - Light grey background

### Semantic Colors
- `AppColors.success` - Green (for positive actions)
- `AppColors.warning` - Orange/Amber (for warnings)
- `AppColors.error` - Red (for errors)
- `AppColors.info` - Teal (for information)

### Text Colors
- `AppColors.textPrimary` - Main text (dark)
- `AppColors.textSecondary` - Secondary text (grey)

### UI Colors
- `AppColors.border` - Border color
- `AppColors.shadow` - Shadow color

### Usage Examples
```dart
// Background
backgroundColor: AppColors.background

// Text
color: AppColors.textPrimary

// Borders
borderSide: BorderSide(color: AppColors.border)

// Focus
borderSide: BorderSide(color: AppColors.primary, width: 2)

// Shadows
BoxShadow(color: AppColors.shadow.withOpacity(0.08))

// Gradients
LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.9)])
```

---

## 🔍 Screen-Specific Features

### Help Center
- Search bar with responsive sizing
- 4 quick action cards (Contact, Live Chat, Email, Phone)
- Expandable FAQ items
- AppColors.info theme

### Feedback
- 5-star rating system with AppColors.warning
- Contact form with enhanced fields
- Category and subject dropdown
- Submit button with send icon
- AppColors.accent theme for header

### Bug Report
- Priority selector with colored indicators:
  - Low: AppColors.success (green)
  - Medium: AppColors.warning (orange)
  - High: AppColors.error (red)
  - Critical: AppColors.info (teal)
- Multi-line description fields
- System information card
- Step-by-step reproduction field
- Expected vs Actual behavior fields
- AppColors.error theme for header

---

## ✅ Checklist for New Screens

When creating a new screen following this pattern:

- [ ] Import `AppColors` and `CustomHeader`
- [ ] Add screen width detection in build method
- [ ] Use `CustomHeaderWithProfile` for AppBar
- [ ] Set `backgroundColor: AppColors.background`
- [ ] Pass `isSmallScreen` to all widget methods
- [ ] Use conditional sizing for all padding
- [ ] Use conditional sizing for all fonts
- [ ] Use conditional sizing for all icons
- [ ] Replace all `Colors.grey`, `Colors.orange`, etc. with `AppColors`
- [ ] Add borders to containers with `AppColors.primary.withOpacity(0.15)`
- [ ] Add box shadows with `AppColors.shadow.withOpacity(0.08)`
- [ ] Use rounded icon variants (`_rounded` suffix)
- [ ] Add gradient to buttons with `LinearGradient`
- [ ] Use `GoogleFonts.inter` for all text
- [ ] Make buttons full width with responsive height
- [ ] Add loading states to submit buttons
- [ ] Use `AppColors` in dialogs and snackbars
- [ ] Test on small screens (< 360px)
- [ ] Remove unused imports

---

## 🐛 Common Issues & Solutions

### Issue: Text Overflow on Small Screens
**Solution**: Use `Expanded` or `Flexible` widgets and responsive font sizes

### Issue: Icons Too Large
**Solution**: Use conditional sizing: `size: isSmallScreen ? 18 : 20`

### Issue: Padding Too Tight
**Solution**: Use conditional padding: `EdgeInsets.all(isSmallScreen ? 16 : 20)`

### Issue: Colors Don't Match
**Solution**: Use `AppColors` constants instead of hardcoded colors

### Issue: Buttons Don't Fit
**Solution**: Use responsive height: `height: isSmallScreen ? 50 : 56`

### Issue: Multi-line Field Icon Alignment
**Solution**: Use `Padding(padding: EdgeInsets.only(bottom: isSmallScreen ? 70 : 80))`

---

## 📝 Testing Guide

### Quick Test
1. Open each screen
2. Check header displays CustomHeaderWithProfile
3. Verify all colors use AppColors
4. Test form validation
5. Submit and check success dialog

### Responsive Test
1. Use device with < 360px width
2. Scroll through all sections
3. Check for text overflow
4. Verify buttons are accessible
5. Test all interactive elements

### Visual Test
1. Check consistent spacing
2. Verify gradient buttons look smooth
3. Check shadow effects
4. Verify icon colors match theme
5. Check text readability

---

## 📚 Related Documentation

- `SUPPORT_SCREENS_UPDATE_SUMMARY.md` - Full detailed summary
- `SETTINGS_SCREENS_COMPLETE_GUIDE.md` - Settings implementation guide
- `SETTINGS_IMPLEMENTATION_SUMMARY.md` - Settings summary

---

*Quick Reference - Support Screens*
*Version: 1.0*
*Last Updated: ${DateTime.now().toString().split('.')[0]}*
