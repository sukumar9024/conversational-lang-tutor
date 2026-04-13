# Language Practice App

A production-ready cross-platform mobile application for conversational language practice. Built with Flutter, featuring real-time speech recognition, text-to-speech, and AI powered conversation.

## ✨ Features

### Core Capabilities
- ✅ Text chat interface
- ✅ Voice input with real-time speech recognition
- ✅ Text-to-speech voice output
- ✅ Streaming AI responses
- ✅ Multiple language practice modes

### Practice Modes
1. **Immersion Mode** - Assistant speaks only in target language
2. **Guided Mode** - 3 part responses: understanding, english answer, translated answer
3. **Correction Mode** - Gentle grammar and phrasing corrections

### UX Features
- Beautiful Material 3 design
- Light / Dark mode support
- Smooth animations
- Recording states and indicators
- Auto scrolling chat
- Mute controls
- Professional chat bubbles

## 🚀 Getting Started

### 1. Prerequisites
- Flutter SDK `3.41.6` or newer
- Dart SDK `3.11.4` or newer
- Java `17`
- Android Studio with Android SDK installed
- Xcode if you want to build for iOS
- OpenRouter API key

### 2. Installation

```bash
git clone <repository-url>
cd conversation
flutter pub get
```

### 3. Verify Local Tooling

Run:

```bash
flutter doctor
```

Make sure Flutter can see:
- the Flutter SDK
- Android toolchain
- Android SDK
- Xcode if you need iOS

### 4. Files Created Locally After Cloning

These files are local-machine or generated files. They may not exist immediately after clone, and that is expected.

| File | Purpose | How it is created |
|---|---|---|
| `.env` | Runtime app configuration and API key | Create manually from `.env.example` |
| `android/key.properties` | Android release signing config | Create manually from `android/key.properties.example` if you want signed release builds |
| `android/local.properties` | Local Android SDK + Flutter paths | Usually generated automatically by Flutter/Gradle |
| `.flutter-plugins-dependencies` | Generated Flutter plugin metadata | Generated automatically by `flutter pub get` / `flutter run` |
| `.dart_tool/` | Generated Dart/Flutter build state | Generated automatically |
| `build/` | Build outputs | Generated automatically |

### 5. Create `.env`

```bash
cp .env.example .env
```

Then edit `.env` and set at least:

```env
OPENROUTER_API_KEY=your_actual_openrouter_api_key
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
OPENROUTER_PRIMARY_MODEL=anthropic/claude-sonnet-4.5
OPENROUTER_FALLBACK_MODEL_1=openai/gpt-4.1-mini
OPENROUTER_FALLBACK_MODEL_2=google/gemini-2.5-flash
APP_DEBUG=false
APP_LOG_LEVEL=info
```

The app uses 3 OpenRouter models in priority order. If the primary model is unavailable, OpenRouter can route to the fallback models.

Get your API key from [OpenRouter](https://openrouter.ai/keys).

### 6. Generate Local Build Files

Run one of these:

```bash
flutter run
```

or

```bash
flutter build apk --debug
```

That will usually generate local files like:
- `android/local.properties`
- `.flutter-plugins-dependencies`
- `.dart_tool/`

### 7. Android SDK Note

If Android builds fail because the SDK path is missing or wrong:
- install the Android SDK from Android Studio
- make sure `flutter doctor` reports the Android toolchain correctly
- regenerate `android/local.properties` by rerunning `flutter run` or `flutter build`

`android/local.properties` is machine-specific and should point to your own Android SDK location.

### 8. Run the App

```bash
flutter run

flutter run -d ios
```

## 🔐 Release Setup

### Android Release Signing

For a proper signed Android release, create `android/key.properties`:

```bash
cp android/key.properties.example android/key.properties
```

Then fill in:

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=upload
storeFile=/absolute/path/to/your-upload-keystore.jks
```

If `android/key.properties` is not present, the project falls back to debug signing for local release builds only. That is fine for local testing, but not for production distribution.

### Android Release Build

```bash
flutter build apk --release
```

### iOS Release Build

```bash
flutter build ios --release
```

## 🏗 Architecture

Clean layered architecture with separation of concerns:

```
lib/
├── main.dart                 # App entry point
├── app/                      # App level config, DI, routing
├── core/                     # Utilities, constants, errors, network
├── features/chat/            # Chat BLOC, events, states
├── models/                   # Typed data models
├── services/                 # STT, TTS, OpenRouter, Environment
├── theme/                    # Colors, Typography, ThemeData
├── widgets/                  # Reusable UI components
└── screens/                  # App screens
```

### State Management
- **BLoC (Business Logic Component)** for predictable state management
- Clean separation between UI and business logic
- Reactive state updates

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `flutter_bloc` | State management |
| `dio` | HTTP client |
| `speech_to_text` | Voice recognition |
| `flutter_tts` | Text to speech |
| `get_it` | Dependency injection |
| `flutter_dotenv` | Environment configuration |
| `shared_preferences` | Local storage |
| `equatable` | Value equality |

## 🔧 Configuration

### Environment Variables
| Variable | Description |
|---|---|
| `OPENROUTER_API_KEY` | Your OpenRouter API key |
| `OPENROUTER_BASE_URL` | API endpoint |
| `OPENROUTER_PRIMARY_MODEL` | First model to try |
| `OPENROUTER_FALLBACK_MODEL_1` | Second model to try |
| `OPENROUTER_FALLBACK_MODEL_2` | Third model to try |
| `OPENROUTER_MODEL` | Optional legacy single-model variable |
| `APP_DEBUG` | Enables debug-oriented app/network behavior |
| `APP_LOG_LEVEL` | App logging level |

## 📁 What Not To Commit

Do not commit:
- `.env`
- `android/key.properties`
- `.dart_tool/`
- `build/`
- machine-specific SDK paths

Safe to commit:
- `.env.example`
- `android/key.properties.example`
- app source code
- shared Gradle and Flutter config

## 📝 License

Open source. Free to use for personal and commercial projects.

---

Made with ❤️ for language learners
