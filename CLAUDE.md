# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

Build for simulator:
```bash
xcodebuild -project TalkTimer.xcodeproj -scheme TalkTimer -sdk iphonesimulator build
```

Build and run on iOS Simulator:
```bash
xcodebuild -project TalkTimer.xcodeproj -scheme TalkTimer -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' build
xcrun simctl boot "iPhone 15"
xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/TalkTimer-*/Build/Products/Debug-iphonesimulator/TalkTimer.app
xcrun simctl launch booted com.talktimer.app
```

## Architecture

This is a SwiftUI iOS app using MVVM architecture. The app is locked to landscape orientation.

**Core Flow:**
- `TalkTimerApp` → `TimerView` (main screen) → `SettingsView` (modal sheet)
- `TimerViewModel` manages all timer logic and publishes state changes
- Settings are persisted via `@AppStorage` in `TimerView` and passed to the view model

**Timer Zones:**
The timer transitions through color-coded zones based on remaining time:
- Black (safe) → Yellow (warning threshold) → Red (danger threshold) → Flashing (time's up)
- Zone thresholds are configurable; transitions trigger haptic feedback via `HapticManager`

**Display Logic:**
- Always shows MM:SS format
- `ScalableTimerText` auto-scales text to fill available screen space
