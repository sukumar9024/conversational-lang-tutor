import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app/injection.dart';
import 'theme/theme.dart';
import 'screens/chat_screen.dart';
import 'features/chat/chat_bloc.dart';
import 'services/openrouter_service.dart';
import 'services/stt_service.dart';
import 'services/tts_service.dart';
import 'services/env_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment
  final envService = EnvService();
  await envService.init();

  // Setup dependency injection
  configureDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Language Practice',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: BlocProvider(
        create: (context) => ChatBloc(
          getIt<OpenRouterService>(),
          getIt<SpeechToTextService>(),
          getIt<TextToSpeechService>(),
          getIt<EnvService>(),
        ),
        child: const ChatScreen(),
      ),
    );
  }
}