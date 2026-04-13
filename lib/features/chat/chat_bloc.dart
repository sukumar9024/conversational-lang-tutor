import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../models/message.dart';
import '../../../services/openrouter_service.dart';
import '../../../services/stt_service.dart';
import '../../../services/tts_service.dart';
import '../../../services/env_service.dart';

part 'chat_event.dart';
part 'chat_state.dart';

const _uuid = Uuid();

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final OpenRouterService _openRouterService;
  final SpeechToTextService _sttService;
  final TextToSpeechService _ttsService;
  final EnvService _envService;

  StreamSubscription? _responseSubscription;
  LanguageMode _currentMode = LanguageMode.immersion;
  String _targetLanguage = 'es';

  ChatBloc(
    this._openRouterService,
    this._sttService,
    this._ttsService,
    this._envService,
  ) : super(const ChatState()) {
    on<ChatInitialized>(_onInitialized);
    on<MessageSent>(_onMessageSent);
    on<RecordingStarted>(_onRecordingStarted);
    on<RecordingStopped>(_onRecordingStopped);
    on<TextRecognized>(_onTextRecognized);
    on<MessageUpdated>(_onMessageUpdated);
    on<ResponseReceived>(_onResponseReceived);
    on<ClearChatRequested>(_onClearChat);
    on<ModeChanged>(_onModeChanged);
    on<ToggleMuteRequested>(_onToggleMute);
  }

  Future<void> _onInitialized(ChatInitialized event, Emitter<ChatState> emit) async {
    await _sttService.init();
    await _ttsService.init();
    emit(state.copyWith(isMuted: _ttsService.isMuted));
  }

  Future<void> _onMessageSent(MessageSent event, Emitter<ChatState> emit) async {
    final userMessage = Message(
      id: _uuid.v4(),
      content: event.text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      messages: List.of(state.messages)..add(userMessage),
      isLoading: true,
    ));

    final assistantMessageId = _uuid.v4();
    emit(state.copyWith(
      messages: List.of(state.messages)..add(Message(
        id: assistantMessageId,
        content: '',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        status: MessageStatus.thinking,
      )),
    ));

    final messages = state.messages
        .where((m) => m.content.isNotEmpty)
        .map((m) => {
          'role': m.role == MessageRole.user ? 'user' : 'assistant',
          'content': m.content,
        })
        .toList();

    try {
      _responseSubscription = _openRouterService.streamResponse(messages, _currentMode, _targetLanguage).listen(
        (content) => add(MessageUpdated(messageId: assistantMessageId, content: content)),
        onDone: () => add(ResponseReceived(messageId: assistantMessageId)),
        onError: (error) {
          emit(state.copyWith(
            messages: List.of(state.messages)..removeLast(),
            isLoading: false,
            error: error.toString(),
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        messages: List.of(state.messages)..removeLast(),
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  void _onMessageUpdated(MessageUpdated event, Emitter<ChatState> emit) {
    final index = state.messages.indexWhere((m) => m.id == event.messageId);
    if (index != -1) {
      final updatedMessages = List.of(state.messages);
      updatedMessages[index] = updatedMessages[index].copyWith(content: event.content);
      emit(state.copyWith(messages: updatedMessages));
    }
  }

  void _onResponseReceived(ResponseReceived event, Emitter<ChatState> emit) {
    final index = state.messages.indexWhere((m) => m.id == event.messageId);
    if (index != -1) {
      final updatedMessages = List.of(state.messages);
      final message = updatedMessages[index];
      updatedMessages[index] = message.copyWith(status: MessageStatus.sent);
      emit(state.copyWith(messages: updatedMessages, isLoading: false));
      _ttsService.speak(message.content);
    }
  }

  void _onRecordingStarted(RecordingStarted event, Emitter<ChatState> emit) {
    _sttService.startListening(
      onResult: (text) => add(TextRecognized(text: text)),
      onListeningStarted: () => emit(state.copyWith(isRecording: true)),
      onListeningStopped: () => emit(state.copyWith(isRecording: false)),
    );
  }

  void _onRecordingStopped(RecordingStopped event, Emitter<ChatState> emit) async {
    await _sttService.stopListening();
    emit(state.copyWith(isRecording: false));
  }

  void _onTextRecognized(TextRecognized event, Emitter<ChatState> emit) {
    emit(state.copyWith(draftText: event.text));
  }

  void _onClearChat(ClearChatRequested event, Emitter<ChatState> emit) {
    _responseSubscription?.cancel();
    _ttsService.stop();
    emit(const ChatState());
  }

  void _onModeChanged(ModeChanged event, Emitter<ChatState> emit) {
    _currentMode = event.mode;
    emit(state.copyWith(currentMode: event.mode));
  }

  void _onToggleMute(ToggleMuteRequested event, Emitter<ChatState> emit) {
    _ttsService.toggleMute();
    emit(state.copyWith(isMuted: _ttsService.isMuted));
  }

  @override
  Future<void> close() {
    _responseSubscription?.cancel();
    _sttService.dispose();
    _ttsService.dispose();
    return super.close();
  }
}