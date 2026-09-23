import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/gemini_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  final GeminiService _geminiService = GeminiService();
  final TtsService _ttsService = TtsService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  late List<Content> _apiHistory;

  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isThinking = false;
  bool _speakReplies = true;

  @override
  void initState() {
    super.initState();
    _apiHistory = List.from(_geminiService.chatPrimingTurns());
    _messages.add(ChatMessage(
      text: 'Namaste! I am Krishi Saathi, your farming assistant. Ask me anything about your crops, plants, or farm.',
      isUser: false,
    ));
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize();
    setState(() => _speechAvailable = available);
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) return;
    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          _textController.text = result.recognizedWords;
          setState(() => _isListening = false);
        }
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _apiHistory.add(Content('user', [TextPart(text)]));
      _isThinking = true;
    });
    _scrollToBottom();

    final answer = await _geminiService.continueChat(_apiHistory);

    setState(() {
      _messages.add(ChatMessage(text: answer, isUser: false));
      _apiHistory.add(Content('model', [TextPart(answer)]));
      _isThinking = false;
    });
    _scrollToBottom();

    if (_speakReplies) {
      await _ttsService.speak(answer, languageName: 'English');
    }
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

  @override
  void dispose() {
    _speech.stop();
    _ttsService.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text('Krishi Saathi', style: AppTextStyles.heading(size: 18))),
                    GestureDetector(
                      onTap: () => setState(() => _speakReplies = !_speakReplies),
                      child: Icon(
                        _speakReplies ? Icons.volume_up_outlined : Icons.volume_off_outlined,
                        color: _speakReplies ? AppColors.neonGreen : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Chat messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                  itemCount: _messages.length + (_isThinking ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return _buildTypingBubble();
                    }
                    return _buildBubble(_messages[index]);
                  },
                ),
              ),

              // Input row
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _isListening ? _stopListening : _startListening,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _isListening
                                ? AppColors.neonRed.withOpacity(0.15)
                                : AppColors.neonGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            color: _isListening ? AppColors.neonRed : AppColors.neonGreen,
                            size: 20,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          style: AppTextStyles.body(size: 14),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: _isListening ? 'Listening...' : 'Ask a farming question...',
                            hintStyle: AppTextStyles.body(size: 13, color: AppColors.textSecondary),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.neonGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send, color: AppColors.bgDark, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser
              ? AppColors.neonGreen.withOpacity(0.15)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: message.isUser ? AppColors.neonGreen.withOpacity(0.4) : AppColors.glassBorder,
          ),
        ),
        child: Text(message.text, style: AppTextStyles.body(size: 14)),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonGreen),
        ),
      ),
    );
  }
}