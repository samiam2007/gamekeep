# 🎨 GameKeep Client-Facing Design Guide

## Where the Visual Design Lives

### 1. **Theme Configuration** 
📁 `lib/utils/theme.dart`
- Color schemes (Purple primary, Teal secondary)
- Typography settings
- Component styling (buttons, cards, inputs)
- Light/Dark mode configurations

### 2. **Screen Designs**
📁 `lib/screens/`

#### Key Visual Screens:
- **splash_screen.dart** - Animated logo, loading animation
- **auth/login_screen.dart** - Clean auth UI with social buttons
- **library_screen.dart** - Game grid/list views with cards
- **camera_screen.dart** - Camera overlay with guide frame
- **discover_screen.dart** - Featured game hero, trending carousel
- **profile_screen.dart** - User stats, settings menu

### 3. **Component Designs**
📁 `lib/widgets/`
- **game_card.dart** - Game card with image, title, metadata
- **native_ad_widget.dart** - Ad integration components

## Current Visual Design Features

### 🎨 Design System
```dart
// Color Palette (from theme.dart)
Primary: #6200EA (Purple)
Secondary: #03DAC6 (Teal)
Success: #4CAF50 (Green)
Warning: #FFC107 (Amber)
Error: #B00020 (Red)
```

### 📱 Material Design 3
- Rounded corners (12px radius)
- Elevated cards with shadows
- Smooth animations
- Floating Action Button
- Bottom Navigation Bar

### 🖼️ Visual Elements
1. **Game Cards**: Image thumbnails, player count, play time, BGG rank badges
2. **Hero Sections**: Gradient backgrounds, large typography
3. **Icons**: Material icons throughout
4. **Loading States**: Circular progress indicators
5. **Empty States**: Illustrated placeholders

## How to View/Edit the Design

### Option 1: Run in Browser (Quickest)
```bash
flutter run -d chrome
```
Then navigate through:
- Login screen → Sign up/Sign in
- Home → Browse all 4 tabs
- Tap + button → See camera screen
- Profile → See user interface

### Option 2: Run on Desktop
```bash
flutter run -d macos
```

### Option 3: Hot Reload for Design Changes
While app is running, edit any screen file and press `r` in terminal for hot reload

## Design Files to Edit

### To change colors/theme:
```dart
// Edit lib/utils/theme.dart
static const Color primaryColor = Color(0xFF6200EA); // Change this
```

### To modify screen layouts:
```dart
// Edit any screen in lib/screens/
// Example: lib/screens/library_screen.dart for the main game grid
```

### To update component styles:
```dart
// Edit lib/widgets/game_card.dart for game card appearance
```

## Visual Design Highlights

### 1. **Splash Screen**
- Animated logo with scale/fade effects
- Purple gradient background
- White loading indicator

### 2. **Login Screen**
- Clean, centered layout
- Social auth buttons with brand colors
- Form validation feedback

### 3. **Library Screen**
- Staggered grid layout
- Search bar with filter chips
- Sort dropdown
- Grid/List view toggle
- Native ads between games

### 4. **Camera Screen**
- Live camera preview
- White guide frame overlay
- Tips banner at top
- Large capture button

### 5. **Game Detail Screen**
- Hero image header
- Quick stats cards
- Action buttons (Log Play, Loan)
- Chip tags for mechanics/categories

### 6. **Discover Screen**
- Featured game hero with gradient
- Horizontal scrolling trending games
- Category grid with icons

### 7. **Profile Screen**
- Avatar circle
- Stats dashboard
- Grouped menu items
- Sign out button

## Next Steps for Design Enhancement

### Quick Improvements:
1. Add custom fonts (Poppins, Inter)
2. Implement shimmer loading effects
3. Add hero animations between screens
4. Custom illustrations for empty states
5. Gradient backgrounds for cards

### Advanced Enhancements:
1. Parallax scrolling effects
2. Custom page transitions
3. Animated bottom nav
4. Glass morphism effects
5. Dynamic themes based on game colors

## Testing the Design

The app should now be running at:
**http://localhost:8080**

Navigate through all screens to see the complete visual design!