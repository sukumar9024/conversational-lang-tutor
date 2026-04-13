import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../core/network/dio_client.dart';
import '../services/env_service.dart';
import '../services/openrouter_service.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies({EnvService? envService}) async {
  await getIt.reset();

  final resolvedEnvService = envService ?? EnvService();
  if (envService == null) {
    await resolvedEnvService.init();
  }

  getIt.registerSingleton<EnvService>(resolvedEnvService);
  getIt.registerLazySingleton<Dio>(() => DioClient.create(resolvedEnvService));
  getIt.registerLazySingleton<OpenRouterService>(
    () => OpenRouterService(getIt<Dio>(), getIt<EnvService>()),
  );
  getIt.registerLazySingleton<SpeechToTextService>(SpeechToTextService.new);
  getIt.registerLazySingleton<TextToSpeechService>(TextToSpeechService.new);
}
