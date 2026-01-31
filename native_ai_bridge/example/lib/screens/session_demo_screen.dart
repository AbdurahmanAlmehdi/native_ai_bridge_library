import 'dart:async';

import 'package:native_ai_bridge/session/apple_intelligence_session.dart';
import 'package:flutter/material.dart';

/// Demo screen showcasing basic text generation without tools.
///
/// This screen demonstrates simple AI conversation capabilities
/// using Apple Intelligence with streaming responses.
class SessionDemoScreen extends StatefulWidget {
  const SessionDemoScreen({super.key});

  @override
  State<SessionDemoScreen> createState() => _SessionDemoScreenState();
}

class _SessionDemoScreenState extends State<SessionDemoScreen> {
  AppleIntelligenceSession? _session;
  final StreamController<String> _responseController =
      StreamController<String>();
  String _response = '';
  bool _isLoading = false;
  late final TextEditingController _promptController;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController();
    _responseController.stream.listen((chunk) {
      setState(() {
        _response += chunk;
      });
    });
  }

  @override
  void dispose() {
    _responseController.close();
    _promptController.dispose();
    _closeSession();
    super.dispose();
  }

  Future<void> _closeSession() async {
    await _session?.close();
    _session = null;
  }

  Future<void> _createSession() async {
    await _closeSession();

    setState(() {
      _isLoading = true;
      _response = 'Creating session...';
    });

    try {
      _session = await AppleIntelligenceSession.create(
        'You are a helpful AI assistant that provides concise, accurate responses.',
      );
      setState(() {
        _response =
            '✅ Session created successfully!\n\n'
            'You can now ask questions and get AI-powered responses.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _response = '❌ Error creating session: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _askQuestion() async {
    if (_session == null) {
      setState(() {
        _response = '⚠️ Please create a session first';
      });
      return;
    }

    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      setState(() {
        _response = '⚠️ Please enter a question';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _response = 'Thinking...\n\n';
    });

    try {
      final responseStream = _session!.generateTextStream(prompt);
      _response = 'Question: $prompt\n\nAnswer: ';
      await for (final chunk in responseStream) {
        setState(() {
          _response += chunk;
        });
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _response = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  void _clearResponse() {
    setState(() {
      _response = '';
      _promptController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Session Demo'),
        actions: [
          if (_session != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _createSession,
              tooltip: 'Recreate Session',
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Session status card
              _buildStatusCard(theme, isDark),
              const SizedBox(height: 24),

              // Prompt input section
              _buildPromptSection(theme),
              const SizedBox(height: 20),

              // Action buttons
              _buildActionButtons(theme),
              const SizedBox(height: 24),

              // Response section
              _buildResponseSection(theme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, bool isDark) {
    final isActive = _session != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark
                  ? Colors.green.shade900.withValues(alpha: 0.3)
                  : Colors.green.shade50)
            : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? Colors.green
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade400),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? Icons.check_circle : Icons.circle_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'Session Active' : 'No Session',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isActive
                        ? (isDark
                              ? Colors.green.shade300
                              : Colors.green.shade900)
                        : (isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive
                      ? 'Ready to answer questions'
                      : 'Create a session to start',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_note, size: 20, color: theme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Your Question',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _promptController,
          enabled: _session != null && !_isLoading,
          decoration: InputDecoration(
            hintText: 'Ask me anything...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: _session != null && !_isLoading
                ? null
                : (theme.brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade100),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          maxLines: 4,
          style: const TextStyle(fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _session == null && !_isLoading ? _createSession : null,
            icon: _isLoading && _session == null
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_circle_outline),
            label: Text(_session == null ? 'Create Session' : 'Session Active'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _session != null && !_isLoading ? _askQuestion : null,
            icon: _isLoading && _session != null
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: const Text('Ask'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponseSection(ThemeData theme, bool isDark) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.smart_toy, size: 20, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Response',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
              if (_response.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearResponse,
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              child: _response.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No response yet',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: SelectableText(
                        _response,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: isDark
                              ? Colors.grey.shade100
                              : Colors.grey.shade900,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
