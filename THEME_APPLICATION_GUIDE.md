# Theme Application Guide — Actual Implementation in Grahvani

This guide shows exactly how the burgundy theme is applied throughout the Grahvani codebase.

---

## 1. AUTHENTICATION SCREENS

### Before: Login Screen (Old Purple Theme)

```dart
// OLD - Generic purple
Container(
  width: 96,
  height: 96,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    gradient: const RadialGradient(
      colors: [Color(0xFF7C6EFA), Color(0xFF3B2FBE)],  // PURPLE
    ),
  ),
)
```

### After: Login Screen (New Burgundy Theme)

```dart
// NEW - Premium burgundy
import '../../theme/app_colors.dart';

Container(
  width: 96,
  height: 96,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    gradient: const RadialGradient(
      colors: [
        AppColors.primaryBurgundy,      // #850E35
        AppColors.primaryBurgundyDark,  // #650A29
      ],
    ),
  ),
)
```

### Before: Login Background (Old Black)

```dart
// OLD - Generic black
Scaffold(
  backgroundColor: const Color(0xFF0A0A1A),
)
```

### After: Login Background (New Dark Burgundy)

```dart
// NEW - Premium dark burgundy
Scaffold(
  backgroundColor: AppColors.darkBg,  // #18070E
)
```

---

## 2. PROFILE SCREENS

### Before: Profile Card (Old Generic Colors)

```dart
// OLD
Card(
  child: Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF12122A),  // GENERIC DARK
      borderRadius: BorderRadius.circular(12),
    ),
  ),
)
```

### After: Profile Card (New Theme)

```dart
// NEW
Card(
  child: Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.darkBgPrimary,  // #250914 - Dark Burgundy
      borderRadius: BorderRadius.circular(12),
    ),
  ),
)
```

### Before: Profile Text (Old Purple Muted)

```dart
// OLD
Text(
  'Birth Date',
  style: TextStyle(color: Color(0xFF6B6B99)),  // PURPLE-MUTED
)
```

### After: Profile Text (New Theme)

```dart
// NEW
Text(
  'Birth Date',
  style: TextStyle(color: AppColors.textSecondaryDark),  // #E4B9C2
)
```

---

## 3. CHART SCREENS (Kundali, Synastry, etc.)

### Before: Chart Screen (Old Purple Primary)

```dart
// OLD - Purple button
FloatingActionButton(
  backgroundColor: const Color(0xFF7C6EFA),  // PURPLE
  onPressed: () {},
  child: Icon(Icons.refresh),
)
```

### After: Chart Screen (New Burgundy Primary)

```dart
// NEW - Burgundy button
FloatingActionButton(
  backgroundColor: AppColors.primaryBurgundy,  // #850E35
  onPressed: () {},
  child: Icon(Icons.refresh),
)
```

### Before: Chart Overlay (Old Black)

```dart
// OLD
Container(
  color: const Color(0xFF0A0A1A),  // GENERIC BLACK
  child: Column(...)
)
```

### After: Chart Overlay (New Dark Burgundy)

```dart
// NEW
Container(
  color: AppColors.darkBg,  // #18070E - Premium dark
  child: Column(...)
)
```

### Before: Gold Accent (Old Harsh Gold)

```dart
// OLD
const Icon(Icons.star, color: Color(0xFFFFD700), size: 16)  // BRIGHT GOLD
```

### After: Gold Accent (New Elegant Gold)

```dart
// NEW
Icon(Icons.star, color: AppColors.gold, size: 16)  // #D6A85F - ELEGANT
```

---

## 4. AI & CHAT SCREENS

### Before: AI Feature (Old Purple)

```dart
// OLD
Container(
  decoration: BoxDecoration(
    color: const Color(0xFF7C6EFA),  // SAME PURPLE AS PRIMARY
  ),
)
```

### After: AI Feature (New AI Gradient)

```dart
// NEW - Distinct AI purple gradient
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: AppColors.gradientAI,  // #A94D76 → #8B5BA8
    ),
  ),
)
```

### Before: Chat Message (Old Generic Dark)

```dart
// OLD
Container(
  color: const Color(0xFF12122A),  // GENERIC
  child: Text('AI Response'),
)
```

### After: Chat Message (New Theme)

```dart
// NEW - Using dark burgundy surface + AI colors
Container(
  color: AppColors.darkBgElevated,  // #421126 - Elevated surface
  child: Text(
    'AI Response',
    style: TextStyle(color: AppColors.textPrimaryDark),  // #FCF5EE
  ),
)
```

---

## 5. SUBSCRIPTION & PREMIUM UI

### Before: Premium Badge (No Gold)

```dart
// OLD - Plain
Container(
  padding: EdgeInsets.all(8),
  decoration: BoxDecoration(
    color: const Color(0xFF1E1B4B),
  ),
  child: Text('PRO'),
)
```

### After: Premium Badge (With Gold)

```dart
// NEW - Gold accent
Container(
  padding: EdgeInsets.all(8),
  decoration: BoxDecoration(
    color: AppColors.goldLighter,  // #F1D9A6
    borderRadius: BorderRadius.circular(4),
  ),
  child: Text(
    'PRO',
    style: TextStyle(color: AppColors.goldDark),  // #A87532
  ),
)
```

### Before: Paywall Button (Old Purple)

```dart
// OLD
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF7C6EFA),
  ),
  child: Text('Subscribe'),
)
```

### After: Paywall Button (New Burgundy with Gold)

```dart
// NEW - Burgundy button with gold text option
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryBurgundy,  // #850E35
  ),
  child: Text('Subscribe'),
)

// OR Premium style with gold:
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.goldLight,  // #E7C27A
  ),
  child: Text(
    'Premium Subscribe',
    style: TextStyle(color: AppColors.goldDark),
  ),
)
```

---

## 6. INPUT FIELDS & FORMS

### Before: Input Field (Old Dark)

```dart
// OLD
TextField(
  decoration: InputDecoration(
    filled: true,
    fillColor: const Color(0xFF12122A),  // GENERIC DARK
    border: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFF3D3266)),  // GENERIC BORDER
    ),
  ),
)
```

### After: Input Field (New Theme)

```dart
// NEW
TextField(
  decoration: InputDecoration(
    filled: true,
    fillColor: AppColors.darkBgElevated,  // #421126
    border: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.darkBgStrong),  // #631C37
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: AppColors.primaryBurgundy,  // #850E35 - BURGUNDY FOCUS
        width: 2,
      ),
    ),
  ),
)
```

### Before: Search Field (Old Colors)

```dart
// OLD
TextField(
  decoration: InputDecoration(
    hintText: 'Search...',
    prefixIcon: Icon(Icons.search, color: Color(0xFF7C6EFA)),  // PURPLE
    fillColor: const Color(0xFF12122A),  // DARK
  ),
)
```

### After: Search Field (New Theme)

```dart
// NEW
TextField(
  decoration: InputDecoration(
    hintText: 'Search...',
    prefixIcon: Icon(
      Icons.search,
      color: AppColors.primaryBurgundy,  // #850E35
    ),
    filled: true,
    fillColor: AppColors.darkBgElevated,  // #421126
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.rose300),  // Rose border
    ),
  ),
)
```

---

## 7. BUTTONS & INTERACTIVE ELEMENTS

### Before: Primary Button (Old Purple)

```dart
// OLD
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF7C6EFA),  // PURPLE
    foregroundColor: Colors.white,
  ),
  child: Text('Button'),
)
```

### After: Primary Button (New Burgundy)

```dart
// NEW - Uses theme automatically
ElevatedButton(
  onPressed: () {},
  child: Text('Button'),  // Automatically burgundy!
)

// OR explicit:
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryBurgundy,  // #850E35
    foregroundColor: AppColors.lightBgWhite,     // White text
  ),
  child: Text('Button'),
)
```

### Before: Outlined Button (Old Colors)

```dart
// OLD
OutlinedButton(
  style: OutlinedButton.styleFrom(
    side: const BorderSide(color: Color(0xFF3D3266)),
    foregroundColor: const Color(0xFF7C6EFA),
  ),
  child: Text('Secondary'),
)
```

### After: Outlined Button (New Theme)

```dart
// NEW
OutlinedButton(
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: AppColors.rose100),  // Rose border
    foregroundColor: AppColors.primaryBurgundy,  // Burgundy text
  ),
  child: Text('Secondary'),
)
```

---

## 8. CARDS & SURFACES

### Before: Basic Card (Old Colors)

```dart
// OLD
Card(
  color: const Color(0xFF2A2A4A),  // GENERIC DARK
  child: ListTile(
    title: Text('Item'),
    subtitle: Text('Subtitle', style: TextStyle(color: Color(0xFF6B6B99))),
  ),
)
```

### After: Basic Card (New Theme)

```dart
// NEW - Uses theme automatically
Card(
  child: ListTile(
    title: Text('Item'),  // Automatic colors!
    subtitle: Text('Subtitle'),
  ),
)

// OR explicit with theme:
Card(
  color: AppColors.darkBgPrimary,  // #250914
  child: ListTile(
    title: Text(
      'Item',
      style: TextStyle(color: AppColors.textPrimaryDark),
    ),
    subtitle: Text(
      'Subtitle',
      style: TextStyle(color: AppColors.textSecondaryDark),
    ),
  ),
)
```

### Before: Elevated Card (Old Dark)

```dart
// OLD
Card(
  color: const Color(0xFF1E1B4B),  // DARK
  elevation: 8,
  child: Container(...)
)
```

### After: Elevated Card (New Dark Burgundy)

```dart
// NEW
Card(
  color: AppColors.darkBgElevated,  // #421126 - Elevated burgundy
  elevation: 0,  // Subtle, no harsh shadow
  child: Container(...)
)
```

---

## 9. TEXT & TYPOGRAPHY

### Before: Text Colors (Old Colors)

```dart
// OLD
Text(
  'Heading',
  style: TextStyle(
    color: Colors.white,  // PLAIN WHITE
    fontSize: 20,
  ),
)

Text(
  'Secondary',
  style: TextStyle(
    color: Color(0xFF9B93CC),  // PURPLE MUTED
  ),
)
```

### After: Text Colors (New Theme)

```dart
// NEW - Using theme automatically
Text(
  'Heading',
  style: Theme.of(context).textTheme.headlineMedium,  // AUTOMATIC!
)

// OR explicit:
Text(
  'Heading',
  style: TextStyle(color: AppColors.textPrimaryDark),  // #FCF5EE
)

Text(
  'Secondary',
  style: TextStyle(color: AppColors.textSecondaryDark),  // #E4B9C2
)

Text(
  'Muted',
  style: TextStyle(color: AppColors.textMutedDark),  // #B98A98
)
```

### Before: Colored Text (Old Purple)

```dart
// OLD
RichText(
  text: TextSpan(
    children: [
      TextSpan(
        text: 'Premium',
        style: TextStyle(color: Color(0xFF7C6EFA)),  // PURPLE
      ),
    ],
  ),
)
```

### After: Colored Text (New Theme)

```dart
// NEW
RichText(
  text: TextSpan(
    children: [
      TextSpan(
        text: 'Premium',
        style: TextStyle(color: AppColors.gold),  // #D6A85F - ELEGANT!
      ),
    ],
  ),
)
```

---

## 10. GRADIENTS & VISUAL EFFECTS

### Before: Button Gradient (Old Purple)

```dart
// OLD
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Color(0xFF7C6EFA),  // PURPLE
        Color(0xFF3B2FBE),  // DARK PURPLE
      ],
    ),
  ),
)
```

### After: Button Gradient (New Brand)

```dart
// NEW - Premium gradients
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: AppColors.gradientPrimary,  // #850E35 → #EE6983
    ),
  ),
)

// OR AI gradient:
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: AppColors.gradientAI,  // #A94D76 → #8B5BA8
    ),
  ),
)

// OR gold gradient:
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: AppColors.gradientGold,  // #A87532 → #E7C27A
    ),
  ),
)
```

---

## 11. STATUS & SEMANTIC COLORS

### Before: Error Message (Old Red)

```dart
// OLD - Just red
Container(
  color: Colors.red.withOpacity(0.12),
  child: Text('Error', style: TextStyle(color: Colors.redAccent)),
)
```

### After: Error Message (Semantic)

```dart
// NEW - Proper semantic color
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: AppColors.error.withOpacity(0.1),  // #C43D50
    border: Border.all(color: AppColors.error.withOpacity(0.3)),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    children: [
      Icon(Icons.error, color: AppColors.error),
      SizedBox(width: 12),
      Expanded(
        child: Text(
          'Error message',
          style: TextStyle(color: AppColors.error),
        ),
      ),
    ],
  ),
)
```

### Before: Success Message (Old Green)

```dart
// OLD
Text('Success!', style: TextStyle(color: Colors.green))
```

### After: Success Message (Semantic)

```dart
// NEW
Text(
  'Success!',
  style: TextStyle(color: AppColors.success),  // #3D8B5A
)
```

---

## 12. THEME SWITCHING

### How the Theme is Applied (Automatic)

The theme is automatically applied to all Material widgets:

```dart
// In main.dart or MaterialApp:
MaterialApp(
  theme: appTheme.lightTheme,      // Light mode theme
  darkTheme: appTheme.darkTheme,    // Dark mode theme
  themeMode: appTheme.themeMode,    // Current mode
)

// ALL of these automatically use theme colors:
ElevatedButton(onPressed: () {}, child: Text('Button'))
TextField(decoration: InputDecoration())
Card(child: Text('Card'))
Text('Text', style: Theme.of(context).textTheme.bodyLarge)
```

### Manual Theme Access (When Needed)

```dart
// Access theme colors anywhere
final primaryColor = Theme.of(context).primaryColor;  // #850E35
final textColor = Theme.of(context).textTheme.bodyLarge?.color;

// Access app colors directly
Color bg = AppColors.darkBg;
Color text = AppColors.textPrimaryDark;
```

---

## 13. SUMMARY: OLD vs NEW COLORS IN CODE

| Element | Old Color | New Color | Usage |
|---------|-----------|-----------|-------|
| Primary Button | `0xFF7C6EFA` | `AppColors.primaryBurgundy` | CTAs, navigation |
| Dark Background | `0xFF0A0A1A` | `AppColors.darkBg` | App background |
| Dark Surface | `0xFF12122A` | `AppColors.darkBgElevated` | Cards, inputs |
| Text (Dark Mode) | `0xFFFFFFFF` | `AppColors.textPrimaryDark` | Readable text |
| Secondary Text | `0xFF9B93CC` | `AppColors.textSecondaryDark` | Hints, captions |
| Border | `0xFF3D3266` | `AppColors.darkBgStrong` | Subtle dividers |
| Gold/Premium | None | `AppColors.gold` | Vedic elements |
| AI Features | `0xFF7C6EFA` (same) | `AppColors.gradientAI` | Differentiated |
| Success | `Colors.green` | `AppColors.success` | Semantic |
| Error | `Colors.red` | `AppColors.error` | Semantic |

---

## 14. BEST PRACTICES IN GRAHVANI CODE

### ✅ DO USE

```dart
// Import colors
import '../../theme/app_colors.dart';

// Use theme system
ElevatedButton(onPressed: () {}, child: Text('Button'))

// Use AppColors for custom styling
Container(color: AppColors.primaryBurgundy, child: ...)

// Use theme text styles
Text('Text', style: Theme.of(context).textTheme.titleLarge)

// Use color opacity
AppColors.primaryBurgundy.withOpacity(0.5)
```

### ❌ DON'T USE

```dart
// Hardcoded colors
const Color(0xFF850E35)  // Use AppColors.primaryBurgundy instead

// Generic black/white
Colors.black, Colors.white  // Use AppColors colors instead

// Duplicate colors
Color(0xFF850E35)  // Already defined in AppColors

// Inconsistent theme access
Color.fromARGB(...)  // Use AppColors constants
```

---

## 15. IMPLEMENTATION CHECKLIST

- [x] All hardcoded colors replaced with AppColors references
- [x] Dark mode uses burgundy tones, not generic black
- [x] Text colors updated to warm cream on dark
- [x] Gold accents for Vedic/premium elements
- [x] AI features use AI color gradients
- [x] Buttons styled with burgundy primary
- [x] Input fields have burgundy focus state
- [x] Cards use appropriate surface colors
- [x] Icons colored per context
- [x] Gradients applied to premium elements
- [x] Semantic colors (success, error, warning, info) in place
- [x] All screens tested
- [x] No functionality broken
- [x] Ready for production

---

**Version:** 1.0  
**Date:** August 13, 2026  
**Status:** Production Ready
