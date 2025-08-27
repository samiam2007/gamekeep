# Flutter Installation Guide for GameKeep

## Quick Installation

### macOS

1. **Download Flutter SDK**
```bash
# Using Homebrew (recommended)
brew install flutter

# OR download directly
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable
```

2. **Add Flutter to PATH**
```bash
# Add to ~/.zshrc or ~/.bash_profile
export PATH="$PATH:~/development/flutter/bin"

# Reload shell
source ~/.zshrc
```

3. **Verify Installation**
```bash
flutter doctor
```

4. **Install Required Dependencies**
```bash
# iOS development (macOS only)
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# Android development
brew install --cask android-studio
```

### Windows

1. **Download Flutter SDK**
   - Download from: https://docs.flutter.dev/get-started/install/windows
   - Extract to `C:\src\flutter`

2. **Update PATH**
   - Add `C:\src\flutter\bin` to your PATH environment variable

3. **Run Flutter Doctor**
```cmd
flutter doctor
```

### Linux

1. **Install Flutter**
```bash
sudo snap install flutter --classic
```

2. **Verify Installation**
```bash
flutter doctor
```

## Setting Up GameKeep

Once Flutter is installed:

```bash
# Navigate to project
cd /Users/smccoy/Desktop/GameKeep/gamekeep

# Get dependencies
flutter pub get

# Run tests
flutter test test/models/

# Run the app
flutter run
```

## Troubleshooting

### Common Issues

1. **"Flutter command not found"**
   - Ensure Flutter is in your PATH
   - Restart your terminal

2. **"No devices available"**
   - iOS: Open Xcode and accept licenses
   - Android: Start Android emulator or connect device

3. **"Dart SDK not found"**
   - Flutter includes Dart, run: `flutter doctor -v`

## Verify Setup for GameKeep

Run this checklist:
```bash
flutter doctor
flutter --version
flutter pub get
flutter test test/models/game_model_test.dart
```

Expected output:
```
✓ Flutter installed
✓ Dart SDK included
✓ Tests passing
```

## IDE Setup

### VS Code
```bash
# Install Flutter extension
code --install-extension Dart-Code.flutter
```

### Android Studio
- Install Flutter plugin from Preferences → Plugins

## Next Steps

After installation:
1. Run `flutter doctor` to verify setup
2. Run `flutter pub get` in the gamekeep directory
3. Execute tests: `./run_tests.sh`
4. Start development: `flutter run`

For more details: https://docs.flutter.dev/get-started/install