import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../models/message.dart';
import '../../models/voice_option.dart';
import '../../services/openrouter_service.dart';
import '../../services/stt_service.dart';
import '../../services/tts_service.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final OpenRouterService _openRouterService;
  final SpeechToTextService _sttService;
  final TextToSpeechService _ttsService;

  StreamSubscription? _responseSubscription;
  int _messageCounter = 0;

  ChatBloc(this._openRouterService, this._sttService, this._ttsService)
    : super(const ChatState()) {
    on<ChatInitialized>(_onInitialized);
    on<MessageSent>(_onMessageSent);
    on<RecordingStarted>(_onRecordingStarted);
    on<RecordingStopped>(_onRecordingStopped);
    on<RecordingStatusChanged>(_onRecordingStatusChanged);
    on<TextRecognized>(_onTextRecognized);
    on<MessageUpdated>(_onMessageUpdated);
    on<ResponseReceived>(_onResponseReceived);
    on<ResponseFailed>(_onResponseFailed);
    on<ClearChatRequested>(_onClearChat);
    on<ModeChanged>(_onModeChanged);
    on<TargetLanguageChanged>(_onTargetLanguageChanged);
    on<AssistantVoiceChanged>(_onAssistantVoiceChanged);
    on<ToggleMuteRequested>(_onToggleMute);
  }

  Future<void> _onInitialized(
    ChatInitialized event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _sttService.init();
      await _ttsService.init();
      await _refreshVoiceConfiguration(
        emit,
        targetLanguage: state.targetLanguage,
        clearError: true,
      );
    } catch (error) {
      emit(state.copyWith(error: _formatError(error)));
    }
  }

  Future<void> _onMessageSent(
    MessageSent event,
    Emitter<ChatState> emit,
  ) async {
    final trimmedText = event.text.trim();
    if (trimmedText.isEmpty) {
      return;
    }

    await _responseSubscription?.cancel();

    final userMessage = Message(
      id: _nextMessageId(),
      content: trimmedText,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
    final assistantMessageId = _nextMessageId();
    final updatedMessages = List<Message>.of(state.messages)
      ..add(userMessage)
      ..add(
        Message(
          id: assistantMessageId,
          content: '',
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
          status: MessageStatus.thinking,
        ),
      );

    final trimmedHistory = _trimConversation(updatedMessages);

    emit(
      state.copyWith(
        messages: trimmedHistory,
        isLoading: true,
        draftText: '',
        clearError: true,
      ),
    );

    final requestMessages = trimmedHistory
        .where((m) => m.content.isNotEmpty)
        .map(
          (m) => {
            'role': m.role == MessageRole.user ? 'user' : 'assistant',
            'content': m.content,
          },
        )
        .toList();

    _responseSubscription = _openRouterService
        .streamResponse(
          requestMessages,
          state.currentMode,
          state.targetLanguage,
        )
        .listen(
          (content) => add(
            MessageUpdated(messageId: assistantMessageId, content: content),
          ),
          onDone: () => add(ResponseReceived(messageId: assistantMessageId)),
          onError: (error) {
            add(
              ResponseFailed(
                messageId: assistantMessageId,
                error: _formatError(error),
              ),
            );
          },
        );
  }

  void _onMessageUpdated(MessageUpdated event, Emitter<ChatState> emit) {
    final index = state.messages.indexWhere((m) => m.id == event.messageId);
    if (index != -1) {
      final updatedMessages = List.of(state.messages);
      updatedMessages[index] = updatedMessages[index].copyWith(
        content: event.content,
        status: MessageStatus.thinking,
      );
      emit(state.copyWith(messages: updatedMessages));
    }
  }

  void _onResponseReceived(ResponseReceived event, Emitter<ChatState> emit) {
    final index = state.messages.indexWhere((m) => m.id == event.messageId);
    if (index != -1) {
      final updatedMessages = List.of(state.messages);
      final message = updatedMessages[index].copyWith(
        status: MessageStatus.sent,
      );
      updatedMessages[index] = message;
      emit(
        state.copyWith(
          messages: updatedMessages,
          isLoading: false,
          clearError: true,
        ),
      );
      unawaited(_ttsService.speak(message.content));
    }
  }

  Future<void> _onRecordingStarted(
    RecordingStarted event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _sttService.startListening(
        onResult: (text) => add(TextRecognized(text: text)),
        onListeningStarted: () =>
            add(const RecordingStatusChanged(isRecording: true)),
        onListeningStopped: () =>
            add(const RecordingStatusChanged(isRecording: false)),
      );
    } catch (error) {
      emit(state.copyWith(error: _formatError(error)));
    }
  }

  void _onRecordingStopped(
    RecordingStopped event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _sttService.stopListening();
      emit(state.copyWith(isRecording: false));
    } catch (error) {
      emit(state.copyWith(error: _formatError(error)));
    }
  }

  void _onRecordingStatusChanged(
    RecordingStatusChanged event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(isRecording: event.isRecording));
  }

  void _onTextRecognized(TextRecognized event, Emitter<ChatState> emit) {
    emit(state.copyWith(draftText: event.text));
  }

  Future<void> _onResponseFailed(
    ResponseFailed event,
    Emitter<ChatState> emit,
  ) async {
    await _responseSubscription?.cancel();
    _responseSubscription = null;

    final updatedMessages = List.of(state.messages);
    final index = updatedMessages.indexWhere((m) => m.id == event.messageId);
    if (index != -1) {
      updatedMessages.removeAt(index);
    }

    emit(
      state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        error: event.error,
      ),
    );
  }

  Future<void> _onClearChat(
    ClearChatRequested event,
    Emitter<ChatState> emit,
  ) async {
    await _responseSubscription?.cancel();
    _responseSubscription = null;
    await _ttsService.stop();
    emit(
      state.copyWith(
        messages: const [],
        isLoading: false,
        isRecording: false,
        draftText: '',
        clearError: true,
      ),
    );
  }

  void _onModeChanged(ModeChanged event, Emitter<ChatState> emit) {
    emit(state.copyWith(currentMode: event.mode));
  }

  void _onTargetLanguageChanged(
    TargetLanguageChanged event,
    Emitter<ChatState> emit,
  ) async {
    emit(
      state.copyWith(
        targetLanguage: event.languageCode,
        isVoiceLoading: true,
        clearError: true,
      ),
    );

    try {
      await _refreshVoiceConfiguration(
        emit,
        targetLanguage: event.languageCode,
        clearError: true,
      );
    } catch (error) {
      emit(state.copyWith(isVoiceLoading: false, error: _formatError(error)));
    }
  }

  Future<void> _onAssistantVoiceChanged(
    AssistantVoiceChanged event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isVoiceLoading: true, clearError: true));

    try {
      final configuration = event.voice == null
          ? await _ttsService.clearManualVoiceOverride(
              targetLanguage: state.targetLanguage,
            )
          : await _ttsService.setManualVoiceOverride(
              targetLanguage: state.targetLanguage,
              voice: event.voice!,
            );

      _emitVoiceConfiguration(
        emit,
        configuration: configuration,
        targetLanguage: state.targetLanguage,
        clearError: true,
      );
    } catch (error) {
      emit(state.copyWith(isVoiceLoading: false, error: _formatError(error)));
    }
  }

  void _onToggleMute(ToggleMuteRequested event, Emitter<ChatState> emit) {
    _ttsService.toggleMute();
    emit(state.copyWith(isMuted: _ttsService.isMuted));
  }

  @override
  Future<void> close() async {
    await _responseSubscription?.cancel();
    _sttService.dispose();
    _ttsService.dispose();
    await super.close();
  }

  List<Message> _trimConversation(List<Message> messages) {
    if (messages.length <= AppConstants.maxConversationHistory) {
      return messages;
    }

    return messages.sublist(
      messages.length - AppConstants.maxConversationHistory,
    );
  }

  String _nextMessageId() {
    _messageCounter += 1;
    return '${DateTime.now().microsecondsSinceEpoch}-$_messageCounter';
  }

  String _formatError(Object error) {
    if (error is Failure) {
      return error.message;
    }

    return error.toString();
  }

  Future<void> _refreshVoiceConfiguration(
    Emitter<ChatState> emit, {
    required String targetLanguage,
    bool clearError = false,
  }) async {
    emit(
      state.copyWith(
        isMuted: _ttsService.isMuted,
        isVoiceLoading: true,
        targetLanguage: targetLanguage,
        clearError: clearError,
      ),
    );

    final configuration = await _ttsService.configureVoiceForLanguage(
      targetLanguage,
    );

    _emitVoiceConfiguration(
      emit,
      configuration: configuration,
      targetLanguage: targetLanguage,
      clearError: clearError,
    );
  }

  void _emitVoiceConfiguration(
    Emitter<ChatState> emit, {
    required TtsVoiceConfiguration configuration,
    required String targetLanguage,
    bool clearError = false,
  }) {
    emit(
      state.copyWith(
        targetLanguage: targetLanguage,
        availableVoices: configuration.availableVoices,
        activeVoice: configuration.activeVoice,
        manualVoiceOverride: configuration.manualVoiceOverride,
        isMuted: _ttsService.isMuted,
        isVoiceLoading: false,
        clearError: clearError,
      ),
    );
  }
}
