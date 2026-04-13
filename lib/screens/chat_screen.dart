import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/constants/app_constants.dart';
import '../features/chat/chat_bloc.dart';
import '../services/openrouter_service.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(const ChatInitialized());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _showVoiceSettingsSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: context.read<ChatBloc>(),
          child: const _VoiceSettingsSheet(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<ChatBloc, ChatState>(
      listenWhen: (previous, current) =>
          previous.error != current.error ||
          previous.draftText != current.draftText ||
          previous.messages.length != current.messages.length ||
          previous.isLoading != current.isLoading,
      listener: (context, state) {
        if (_textController.text != state.draftText) {
          _textController.value = TextEditingValue(
            text: state.draftText,
            selection: TextSelection.collapsed(offset: state.draftText.length),
          );
        }

        if (state.error != null && state.error!.isNotEmpty) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.error!)));
        }

        _scrollToBottom();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Language Practice'),
          centerTitle: true,
          actions: [
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                return IconButton(
                  tooltip: state.isMuted
                      ? 'Unmute voice output'
                      : 'Mute voice output',
                  icon: Icon(
                    state.isMuted ? Icons.volume_off : Icons.volume_up,
                  ),
                  onPressed: () =>
                      context.read<ChatBloc>().add(const ToggleMuteRequested()),
                );
              },
            ),
            IconButton(
              tooltip: 'Clear chat',
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  context.read<ChatBloc>().add(const ClearChatRequested()),
            ),
            IconButton(
              tooltip: 'Voice settings',
              icon: const Icon(Icons.settings_voice),
              onPressed: () => _showVoiceSettingsSheet(context),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  final voiceStatus =
                      state.activeVoice?.displayLabel ?? 'Device default voice';
                  final voiceModeLabel = state.manualVoiceOverride != null
                      ? 'Manual voice'
                      : 'Automatic voice';

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            DropdownButtonFormField<LanguageMode>(
                              initialValue: state.currentMode,
                              decoration: const InputDecoration(
                                labelText: 'Mode',
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: LanguageMode.immersion,
                                  child: Text('Immersion'),
                                ),
                                DropdownMenuItem(
                                  value: LanguageMode.guided,
                                  child: Text('Guided'),
                                ),
                                DropdownMenuItem(
                                  value: LanguageMode.correction,
                                  child: Text('Correction'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  context.read<ChatBloc>().add(
                                    ModeChanged(value),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '$voiceModeLabel: $voiceStatus',
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: state.targetLanguage,
                          decoration: const InputDecoration(
                            labelText: 'Target language',
                            isDense: true,
                          ),
                          items: AppConstants.supportedLanguages.entries
                              .map(
                                (entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              context.read<ChatBloc>().add(
                                TargetLanguageChanged(value),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state.messages.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Start a conversation to practice your language skills',
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      return ChatBubble(
                        message: state.messages[index],
                        isDarkMode: isDarkMode,
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          enabled: !state.isLoading,
                          maxLength: AppConstants.maxMessageLength,
                          minLines: 1,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: state.isLoading
                                ? 'Waiting for assistant response...'
                                : 'Type a message...',
                            counterText: '',
                          ),
                          onSubmitted: state.isLoading
                              ? null
                              : (text) {
                                  final trimmed = text.trim();
                                  if (trimmed.isNotEmpty) {
                                    context.read<ChatBloc>().add(
                                      MessageSent(trimmed),
                                    );
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: state.isRecording
                            ? 'Stop recording'
                            : 'Start recording',
                        icon: Icon(
                          state.isRecording ? Icons.stop : Icons.mic,
                          color: state.isRecording
                              ? Colors.red
                              : Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: state.isLoading
                            ? null
                            : () {
                                if (state.isRecording) {
                                  context.read<ChatBloc>().add(
                                    const RecordingStopped(),
                                  );
                                } else {
                                  context.read<ChatBloc>().add(
                                    const RecordingStarted(),
                                  );
                                }
                              },
                      ),
                      IconButton(
                        tooltip: 'Send message',
                        icon: const Icon(Icons.send),
                        color: Theme.of(context).colorScheme.primary,
                        onPressed: state.isLoading
                            ? null
                            : () {
                                final text = _textController.text.trim();
                                if (text.isNotEmpty) {
                                  context.read<ChatBloc>().add(
                                    MessageSent(text),
                                  );
                                }
                              },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceSettingsSheet extends StatelessWidget {
  const _VoiceSettingsSheet();

  static const _automaticVoiceSelection = '__automatic_voice_selection__';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            final filteredVoices =
                state.availableVoices
                    .where(
                      (voice) => voice.supportsLanguage(state.targetLanguage),
                    )
                    .toList()
                  ..sort((a, b) => a.displayLabel.compareTo(b.displayLabel));

            final currentSelection =
                state.manualVoiceOverride?.id ?? _automaticVoiceSelection;
            final currentLanguageLabel =
                AppConstants.supportedLanguages[state.targetLanguage] ??
                state.targetLanguage;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assistant voice',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Target language: $currentLanguageLabel',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  state.manualVoiceOverride != null
                      ? 'Using a manual voice override for this language.'
                      : 'Using automatic voice selection with preferred/default fallback.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey(currentSelection),
                  initialValue: currentSelection,
                  decoration: const InputDecoration(
                    labelText: 'Voice',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: _automaticVoiceSelection,
                      child: Text('Automatic'),
                    ),
                    ...filteredVoices.map(
                      (voice) => DropdownMenuItem(
                        value: voice.id,
                        child: Text(voice.displayLabel),
                      ),
                    ),
                  ],
                  onChanged: state.isVoiceLoading
                      ? null
                      : (value) {
                          if (value == null ||
                              value == _automaticVoiceSelection) {
                            context.read<ChatBloc>().add(
                              const AssistantVoiceChanged(null),
                            );
                            return;
                          }

                          final selectedVoice = filteredVoices.firstWhere(
                            (voice) => voice.id == value,
                          );
                          context.read<ChatBloc>().add(
                            AssistantVoiceChanged(selectedVoice),
                          );
                        },
                ),
                const SizedBox(height: 12),
                if (state.isVoiceLoading) const LinearProgressIndicator(),
                if (!state.isVoiceLoading) ...[
                  Text(
                    state.activeVoice == null
                        ? 'Current active voice: device default'
                        : 'Current active voice: ${state.activeVoice!.displayLabel}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  if (filteredVoices.isEmpty)
                    Text(
                      'No installed voices were found for this language. The app will fall back to the device default voice.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
