# Grahvani Theme Quick Start Guide

## 🚀 Fast Track to Implementation

This guide gets you coding with the new theme **in 5 minutes**.

---

## Step 1: Extract & Run (30 seconds)

```bash
# Extract the project
unzip Grahvani-master-themed.zip
cd Grahvani-master/apps/mobile

# Install dependencies
flutter pub get

# Run the app
flutter run
```

Done! The theme is already applied throughout the app.

---

## Step 2: Import Colors (Automatic)

Every screen already has the import:

```dart
import '../../theme/app_colors.dart';
```

If you create a new file, just add:

```dart
import '../../theme/app_colors.dart';
```

---

## Step 3: Use Colors in Your Code

### Buttons (Already Themed)

```dart
// Just use standard Flutter buttons - they're already themed!
ElevatedButton(
  onPressed: () {},
  child: Text('Button'),  // Automatically burgundy
)

// Or customize if needed:
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.rose100,  // Rose instead of burgundy
  ),
  onPressed: () {},
  child: Text('Rose Button'),
)
```

### Text (Already Themed)

```dart
// Use theme styles (automatic colors):
Text(
  'Heading',
  style: Theme.of(context).textTheme.headlineMedium,
)

// Or use AppColors:
Text(
  'Custom Text',
  style: TextStyle(color: AppColors.textPrimaryDark),
)
```

### Cards (Already Themed)

```dart
// Standard card - already uses theme colors
Card(
  child: ListTile(
    title: Text('Title'),
    subtitle: Text('Subtitle'),
  ),
)
```

### Backgrounds

```dart
// Light mode
Scaffold(
  backgroundColor: AppColors.lightBg,  // Warm cream
)

// Dark mode
Scaffold(
  backgroundColor: AppColors.darkBg,  // Dark burgundy
)
```

### Input Fields (Already Themed)

```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Name',
    hintText: 'Enter name',
  ),
  // Already themed! Focus state is burgundy
)
```

---

## Color Cheat Sheet

### Primary & Accents
```dart
AppColors.primaryBurgundy       // #850E35 - Main color
AppColors.primaryBurgundyDark   // #650A29 - Pressed state
AppColors.rose100               // #EE6983 - Secondary accent
AppColors.gold                  // #D6A85F - Premium/Vedic
```

### Backgrounds
```dart
// Light mode
AppColors.lightBg              // #FCF5EE - Warm cream (main)
AppColors.lightBgWhite         // #FFFFFF - Pure white

// Dark mode
AppColors.darkBg               // #18070E - Deep burgundy (main)
AppColors.darkBgPrimary        // #250914 - Primary surface
AppColors.darkBgElevated       // #421126 - Elevated surface
```

### Text Colors
```dart
// Dark mode (most common)
AppColors.textPrimaryDark      // #FCF5EE - Main text (warm cream)
AppColors.textSecondaryDark    // #E4B9C2 - Secondary text
AppColors.textMutedDark        // #B98A98 - Muted text

// Light mode
AppColors.textPrimaryLight     // #3A1722 - Main text (deep burgundy)
AppColors.textSecondaryLight   // #704653 - Secondary text
```

### Special Colors
```dart
AppColors.aiSecondary          // #8B5BA8 - AI features
AppColors.success              // #3D8B5A - Success
AppColors.error                // #C43D50 - Error
AppColors.warning              // #C8892F - Warning
```

### Gradients
```dart
AppColors.gradientPrimary      // Burgundy → Rose
AppColors.gradientAI           // AI purple gradient
AppColors.gradientGold         // Gold gradient
```

---

## Real Code Examples

### Example 1: Premium Card with Gold

```dart
Card(
  child: Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border(
        left: BorderSide(color: AppColors.gold, width: 4),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.goldLighter,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text('PREMIUM', style: TextStyle(color: AppColors.goldDark)),
        ),
        SizedBox(height: 12),
        Text('Premium Feature', style: Theme.of(context).textTheme.titleLarge),
        Text('Get exclusive insights', style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  ),
)
```

### Example 2: AI Chat Bubble

```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(colors: AppColors.gradientAI),
    borderRadius: BorderRadius.circular(12),
  ),
  padding: EdgeInsets.all(12),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.auto_awesome, color: AppColors.lightBgWhite),
      SizedBox(height: 8),
      Text(
        'AI Insight: Based on your chart...',
        style: TextStyle(color: AppColors.lightBgWhite),
      ),
    ],
  ),
)
```

### Example 3: Search Field

```dart
TextField(
  decoration: InputDecoration(
    hintText: 'Search charts...',
    prefixIcon: Icon(Icons.search, color: AppColors.primaryBurgundy),
    filled: true,
    fillColor: AppColors.darkBgElevated,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.darkBgStrong),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: AppColors.primaryBurgundy,  // Burgundy when focused
        width: 2,
      ),
    ),
  ),
)
```

### Example 4: Status Message

```dart
// Error
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: AppColors.error.withOpacity(0.1),
    border: Border.all(color: AppColors.error),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    children: [
      Icon(Icons.error, color: AppColors.error),
      SizedBox(width: 12),
      Expanded(
        child: Text('Error: Failed to load', style: TextStyle(color: AppColors.error)),
      ),
    ],
  ),
)

// Success
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: AppColors.success.withOpacity(0.1),
    border: Border.all(color: AppColors.success),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    children: [
      Icon(Icons.check_circle, color: AppColors.success),
      SizedBox(width: 12),
      Expanded(
        child: Text('Success: Profile saved', style: TextStyle(color: AppColors.success)),
      ),
    ],
  ),
)
```

---

## Common Tasks

### Change Button Color

```dart
// Default (burgundy)
ElevatedButton(onPressed: () {}, child: Text('Button'))

// Rose color
ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose100),
  onPressed: () {},
  child: Text('Rose Button'),
)

// Gold color
ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
  onPressed: () {},
  child: Text('Gold Button'),
)
```

### Add Gold Border to Card

```dart
Card(
  child: Container(
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.gold.withOpacity(0.3)),
    ),
    child: ListTile(title: Text('Premium Item')),
  ),
)
```

### Make Text Burgundy

```dart
Text(
  'Important Text',
  style: TextStyle(color: AppColors.primaryBurgundy),
)
```

### Add Gradient Background

```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: AppColors.gradientPrimary,  // Burgundy → Rose
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  child: Center(child: Text('Gradient')),
)
```

### Dark Mode Surface

```dart
Container(
  color: AppColors.darkBgPrimary,  // Dark burgundy
  child: Text('Dark Surface', style: TextStyle(color: AppColors.textPrimaryDark)),
)
```

---

## Testing the Theme

### Check Light Mode
1. Open Settings
2. Theme → Light
3. All screens should show cream backgrounds, burgundy buttons, deep burgundy text

### Check Dark Mode
1. Settings → Theme → Dark
2. All screens should show dark burgundy backgrounds (NOT pure black)
3. Text should be warm cream (NOT harsh white)

### Verify Colors
- Buttons are burgundy (#850E35)
- Dark backgrounds are #18070E (not #000000)
- Text on dark is warm cream (#FCF5EE)
- Gold accents appear on premium elements
- AI features have purple gradient

---

## Troubleshooting

### Colors look wrong?
1. Check import: `import '../../theme/app_colors.dart';`
2. Verify file path is correct (may need to adjust `../../`)
3. Hot restart Flutter: `R` in terminal

### Text not readable?
- Check you're using correct text color for mode
- Light mode: use `AppColors.textPrimaryLight`
- Dark mode: use `AppColors.textPrimaryDark`

### Theme not applying?
- Rebuild: `flutter clean && flutter pub get && flutter run`
- Check MaterialApp has theme configured
- Verify app_theme.dart is correct

### Need different color?
- Check COLOR_REFERENCE.md for all available colors
- Use `.withOpacity()` for transparency: `AppColors.gold.withOpacity(0.5)`
- All colors defined in `app_colors.dart`

---

## File Locations

```
apps/mobile/lib/
├── core/theme/
│   ├── app_colors.dart           ← All 60+ color constants
│   ├── app_theme.dart            ← Theme configuration
│   └── theme_examples.dart       ← Code examples
├── features/
│   ├── auth/presentation/        ← Authentication screens (themed)
│   ├── profile/presentation/     ← Profile screens (themed)
│   ├── chart/presentation/       ← Chart screens (themed)
│   ├── chat/presentation/        ← AI/Chat screens (themed)
│   └── ... (all other screens themed)
└── router/
    └── app_router.dart           ← Navigation (themed)
```

---

## What's Already Done

✅ All 16 screens updated with new colors  
✅ All buttons themed with burgundy  
✅ All inputs themed with burgundy focus  
✅ All cards themed with burgundy surfaces  
✅ All text themed with correct colors  
✅ Dark mode using dark burgundy (not black)  
✅ Gold accents applied  
✅ AI gradients applied  
✅ Semantic colors applied  

**You can start coding immediately!**

---

## Next Steps

1. Extract and run the project
2. Test light and dark modes
3. Open a screen and modify a color using AppColors
4. Reference the examples above
5. Check THEME_APPLICATION_GUIDE.md for more details

---

**Duration:** 5 minutes to get started  
**Files Needed:** Just the zip file  
**Knowledge Required:** Basic Flutter

Happy coding! 🎨

