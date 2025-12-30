import 'dart:async';
import 'dart:math';

import 'package:native_ai_bridge/native_ai_bridge.dart';
import 'package:flutter/material.dart';
import '../models/weather_request.tool.g.dart';
import '../models/forecast_request.tool.g.dart';

/// Demo screen showcasing code-generated tools.
///
/// This demonstrates how to use the native_ai_bridge_generator to automatically
/// create Tool classes from annotated model classes.
class GeneratedToolsDemoScreen extends StatefulWidget {
  const GeneratedToolsDemoScreen({super.key});

  @override
  State<GeneratedToolsDemoScreen> createState() =>
      _GeneratedToolsDemoScreenState();
}

class _GeneratedToolsDemoScreenState extends State<GeneratedToolsDemoScreen> {
  AppleIntelligenceSession? _session;
  final TextEditingController _promptController = TextEditingController();
  String _response = '';
  bool _isLoading = false;
  final List<String> _toolCallLog = [];

  @override
  void initState() {
    super.initState();
    _createSessionWithGeneratedTools();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _closeSession();
    super.dispose();
  }

  Future<void> _closeSession() async {
    await _session?.close();
    _session = null;
  }

  Future<void> _createSessionWithGeneratedTools() async {
    await _closeSession();

    setState(() {
      _isLoading = true;
      _response = 'Creating session with generated tools...';
      _toolCallLog.clear();
    });

    try {
      // Create instances of the generated Tool classes
      final weatherTool = WeatherRequestTool();
      final forecastTool = ForecastRequestTool();

      // Setup tool handlers
      final toolHandlers = {
        weatherTool: (ToolCall call) async {
          _logToolCall('get_weather', call.arguments);
          return await _handleWeatherTool(call);
        },
        forecastTool: (ToolCall call) async {
          _logToolCall('get_forecast', call.arguments);
          return await _handleForecastTool(call);
        },
      };

      _session = await AppleIntelligenceSession.create(
        'You are a helpful weather assistant. You can provide current weather information and forecasts for cities worldwide.',
        toolHandlers: toolHandlers,
      );

      setState(() {
        _response = '''Session created with generated tools!

Available Tools:
" get_weather: Get current weather
" get_forecast: Get weather forecast

Try asking: "What is the weather in San Francisco?"''';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _response = 'Error creating session: $e';
        _isLoading = false;
      });
    }
  }

  void _logToolCall(String toolName, Map<String, dynamic> arguments) {
    setState(() {
      _toolCallLog.add('Tool call: $toolName with: ${arguments.toString()}');
    });
  }

  Future<String> _handleWeatherTool(ToolCall call) async {
    final city = call.arguments['city'] as String;
    await Future.delayed(const Duration(milliseconds: 500));
    final random = Random();
    final temp = 15 + random.nextInt(20);
    return 'Current weather for $city: $temp degrees Celsius, Sunny';
  }

  Future<String> _handleForecastTool(ToolCall call) async {
    final city = call.arguments['city'] as String;
    final days = call.arguments['days'] as int? ?? 3;
    await Future.delayed(const Duration(milliseconds: 700));
    return '$days-day forecast for $city: temperatures range from 15-25C';
  }

  Future<void> _askQuestion() async {
    if (_session == null) {
      setState(() => _response = 'Please create a session first');
      return;
    }

    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      setState(() => _response = 'Please enter a question');
      return;
    }

    setState(() {
      _isLoading = true;
      _response = 'Processing...';
    });

    try {
      final responseStream = _session!.generateTextStream(prompt);
      _response = 'Q: $prompt\n\nA: ';

      await for (final chunk in responseStream) {
        setState(() => _response += chunk);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _clearResponse() {
    setState(() {
      _response = '';
      _promptController.clear();
      _toolCallLog.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generated Tools Demo'),
        actions: [
          if (_session != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _createSessionWithGeneratedTools,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _promptController,
              enabled: _session != null && !_isLoading,
              decoration: const InputDecoration(
                hintText: 'Ask about weather...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _session != null && !_isLoading ? _askQuestion : null,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Ask'),
                  ),
                ),
                const SizedBox(width: 12),
                if (_response.isNotEmpty)
                  ElevatedButton(
                    onPressed: _clearResponse,
                    child: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_toolCallLog.isNotEmpty) ...[
              const Text('Tool Calls:', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(maxHeight: 80),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _toolCallLog.map((log) => Text(log, style: const TextStyle(fontSize: 12))).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _response.isEmpty
                    ? const Center(child: Text('No response yet'))
                    : SingleChildScrollView(
                        child: SelectableText(_response),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
