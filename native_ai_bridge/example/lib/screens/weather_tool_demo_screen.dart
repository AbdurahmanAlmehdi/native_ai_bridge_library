import 'dart:async';
import 'dart:math';

import 'package:native_ai_bridge/enums/tool_argument_type.dart';
import 'package:native_ai_bridge/models/tool.dart';
import 'package:native_ai_bridge/models/tool_argument.dart';
import 'package:native_ai_bridge/models/tool_call.dart';
import 'package:native_ai_bridge/session/apple_intelligence_session.dart';
import 'package:flutter/material.dart';

class WeatherToolDemoScreen extends StatefulWidget {
  const WeatherToolDemoScreen({super.key});

  @override
  State<WeatherToolDemoScreen> createState() => _WeatherToolDemoScreenState();
}

class _WeatherToolDemoScreenState extends State<WeatherToolDemoScreen> {
  AppleIntelligenceSession? _session;
  final TextEditingController _promptController = TextEditingController();
  String _response = '';
  bool _isLoading = false;
  final List<String> _toolCallLog = [];

  @override
  void initState() {
    super.initState();
    _createSessionWithWeatherTool();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _closeSession();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchWeatherData(String city) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final random = Random();
    final temperatures = {
      'Boston': 45 + random.nextInt(30),
      'Wichita': 55 + random.nextInt(35),
      'Pittsburgh': 40 + random.nextInt(30),
      'New York': 42 + random.nextInt(28),
      'San Francisco': 58 + random.nextInt(20),
      'Chicago': 35 + random.nextInt(35),
    };

    final conditions = ['Sunny', 'Cloudy', 'Rainy', 'Partly Cloudy', 'Clear'];

    return {
      'city': city,
      'temperature': temperatures[city] ?? (50 + random.nextInt(30)),
      'condition': conditions[random.nextInt(conditions.length)],
      'humidity': 40 + random.nextInt(40),
      'windSpeed': 5 + random.nextInt(15),
    };
  }

  Tool _createWeatherTool() {
    return BaseTool(
      name: 'getWeather',
      description: 'Retrieve the latest weather information for a city',
      arguments: [
        BaseToolArgument(
          name: 'city',
          type: ToolArgumentType.string,
          description: 'The city to get weather information for',
        ),
      ],
    );
  }

  Tool _createForecastTool() {
    return BaseTool(
      name: 'getWeekForecast',
      description: 'Get a 7-day weather forecast for a city',
      arguments: [
        BaseToolArgument(
          name: 'city',
          type: ToolArgumentType.string,
          description: 'The city to get forecast for',
        ),
        BaseToolArgument(
          name: 'days',
          type: ToolArgumentType.integer,
          description: 'Number of days to forecast (1-7)',
          isOptional: true,
          constraints: {'min': 1, 'max': 7},
        ),
      ],
    );
  }

  Future<String> _handleWeatherTool(ToolCall call) async {
    final city = call.arguments['city'] as String;

    setState(() {
      _toolCallLog.add('🔧 getWeather(city: "$city")');
    });

    final weather = await _fetchWeatherData(city);

    final result =
        'The weather in ${weather['city']} is ${weather['condition']}, '
        '${weather['temperature']}°F with ${weather['humidity']}% humidity '
        'and winds at ${weather['windSpeed']} mph.';

    setState(() {
      _toolCallLog.add('✅ Result: $result');
    });

    return result;
  }

  Future<Map<String, dynamic>> _handleForecastTool(ToolCall call) async {
    final city = call.arguments['city'] as String;
    final days = (call.arguments['days'] as int?) ?? 7;

    setState(() {
      _toolCallLog.add('🔧 getWeekForecast(city: "$city", days: $days)');
    });

    await Future.delayed(const Duration(milliseconds: 300));

    final random = Random();
    final forecast = List.generate(days, (index) {
      return {
        'day': index + 1,
        'high': 60 + random.nextInt(20),
        'low': 40 + random.nextInt(15),
        'condition': ['Sunny', 'Cloudy', 'Rainy'][random.nextInt(3)],
      };
    });

    final result = {'city': city, 'forecast': forecast};

    setState(() {
      _toolCallLog.add('✅ Result: ${forecast.length} day forecast');
    });

    return result;
  }

  Future<void> _createSessionWithWeatherTool() async {
    await _closeSession();

    setState(() {
      _isLoading = true;
      _response = 'Creating session with weather tools...';
      _toolCallLog.clear();
    });

    try {
      final weatherTool = _createWeatherTool();
      final forecastTool = _createForecastTool();

      _session = await AppleIntelligenceSession.create(
        'You are a helpful weather assistant. Use the available tools to '
        'provide accurate weather information. When comparing temperatures, '
        'always call the tool for each city mentioned.',
        toolHandlers: {
          weatherTool: _handleWeatherTool,
          forecastTool: _handleForecastTool,
        },
      );

      setState(() {
        _response =
            '✅ Session created with 2 weather tools!\n\n'
            '📊 Available Tools:\n'
            '  • getWeather - Get current weather for a city\n'
            '  • getWeekForecast - Get 7-day forecast\n\n'
            '💡 Try asking:\n'
            '  • "Is it hotter in Boston or Wichita?"\n'
            '  • "What\'s the forecast for New York?"\n'
            '  • "Compare the temperature in Chicago and Pittsburgh"';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _response = '❌ Error creating session: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _closeSession() async {
    await _session?.close();
    _session = null;
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
      _response = 'Question: $prompt\n\nAnswer: ';
    });

    try {
      final response = await _session!.ask(prompt);

      setState(() {
        _response =
            'Question: $prompt\n\nAnswer: ${response ?? 'No response received'}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _response = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  void _clearLogs() {
    setState(() {
      _toolCallLog.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Tool Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _createSessionWithWeatherTool,
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

              // Tools info card
              _buildToolsInfoCard(theme, isDark),
              const SizedBox(height: 24),

              // Prompt input section
              _buildPromptSection(theme),
              const SizedBox(height: 20),

              // Ask button
              _buildAskButton(theme),
              const SizedBox(height: 24),

              // Response section
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Response area
                    Expanded(
                      flex: 2,
                      child: _buildResponseSection(theme, isDark),
                    ),
                    const SizedBox(width: 16),

                    // Tool call log
                    Expanded(flex: 1, child: _buildToolCallLog(theme, isDark)),
                  ],
                ),
              ),
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
                  ? Colors.green.shade900.withOpacity(0.3)
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
                  isActive ? 'Weather tools ready' : 'Creating session...',
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

  Widget _buildToolsInfoCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.blue.shade900.withOpacity(0.3)
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.blue.shade700 : Colors.blue.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.build_circle, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Available Tools',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.blue.shade300 : Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildToolInfoItem(
            'getWeather',
            'Get current weather',
            Icons.wb_sunny,
          ),
          const SizedBox(height: 8),
          _buildToolInfoItem(
            'getWeekForecast',
            'Get 7-day forecast',
            Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildToolInfoItem(String name, String description, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromptSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_note, size: 20, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            Text(
              'Weather Question',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _promptController,
          enabled: _session != null && !_isLoading,
          decoration: InputDecoration(
            hintText: 'e.g., Is it hotter in Boston or Wichita?',
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
            prefixIcon: const Icon(Icons.cloud),
          ),
          maxLines: 2,
          style: const TextStyle(fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildAskButton(ThemeData theme) {
    return ElevatedButton.icon(
      onPressed: _session != null && !_isLoading ? _askQuestion : null,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.send),
      label: const Text('Ask Question'),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildResponseSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }

  Widget _buildToolCallLog(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.code, size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Text(
                  'Tool Calls',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            if (_toolCallLog.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: _clearLogs,
                tooltip: 'Clear Log',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.blue.shade900.withOpacity(0.2)
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.blue.shade700 : Colors.blue.shade200,
              ),
            ),
            child: _toolCallLog.isEmpty
                ? Center(
                    child: Text(
                      'No tool calls yet',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _toolCallLog.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final isCall = _toolCallLog[index].startsWith('🔧');
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCall
                              ? (isDark
                                    ? Colors.blue.shade800.withOpacity(0.3)
                                    : Colors.blue.shade100)
                              : (isDark
                                    ? Colors.green.shade800.withOpacity(0.3)
                                    : Colors.green.shade50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _toolCallLog[index],
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: isDark
                                ? Colors.grey.shade200
                                : Colors.grey.shade800,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
