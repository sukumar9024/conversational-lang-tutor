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
- Flutter SDK >= 3.10.0
- Android Studio / Xcode
- OpenRouter API Key

### 2. Installation

```bash
# Clone the repository
git clone <repository-url>
cd language_practice

# Install dependencies
flutter pub get
```

### 3. Configure Secrets
```bash
# Copy example environment file
cp .env.example .env

# Edit .env and add your OpenRouter API key
OPENROUTER_API_KEY=your_actual_api_key_here
```

Get your API key from [OpenRouter](https://openrouter.ai/keys)

### 4. Run the App
```bash
# For Android
flutter run

# For iOS
flutter run -d ios
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
| `OPENROUTER_MODEL` | LLM model to use |
| `OPENROUTER_BASE_URL` | API endpoint |

## 🛠 Build for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 📝 License

Open source. Free to use for personal and commercial projects.

---

Made with ❤️ for language learners