import 'dart:typed_data';

import 'package:native_ai_bridge/enums/styles.dart';
import 'package:native_ai_bridge/models/native_ai_capabilities.dart';
import 'package:native_ai_bridge/models/tool.dart';
import 'package:native_ai_bridge/services/tool_handler_manager.dart';

import 'apple_foundation_flutter_platform_interface.dart';

class AppleFoundationFlutter {
  Future<String?> getPlatformVersion() {
    return AppleFoundationFlutterPlatform.instance.getPlatformVersion();
  }

  Future<String?> ask(String prompt, {String? sessionId}) {
    return AppleFoundationFlutterPlatform.instance.ask(
      prompt,
      sessionId: sessionId,
    );
  }

  Future<Map<String, dynamic>> getStructuredData(
    String prompt, {
    String? sessionId,
  }) {
    return AppleFoundationFlutterPlatform.instance.getStructuredData(
      prompt,
      sessionId: sessionId,
    );
  }

  Future<List<String>> getListOfString(String prompt, {String? sessionId}) {
    return AppleFoundationFlutterPlatform.instance.getListOfString(
      prompt,
      sessionId: sessionId,
    );
  }

  Future<String> openSession(
    String instructions, {
    Map<Tool, ToolCallHandler>? toolHandlers,
  }) {
    return AppleFoundationFlutterPlatform.instance.openSession(
      instructions,
      toolHandlers: toolHandlers,
    );
  }

  Future<void> closeSession(String sessionId) {
    return AppleFoundationFlutterPlatform.instance.closeSession(sessionId);
  }

  Future<bool> isAvailable() {
    return AppleFoundationFlutterPlatform.instance.isAvailable();
  }

  Future<Map<String, dynamic>> getAvailabilityStatus() {
    return AppleFoundationFlutterPlatform.instance.getAvailabilityStatus();
  }

  Future<String?> generateText(
    String prompt, {
    String? sessionId,
    int? maxTokens,
    double? temperature,
    double? topP,
  }) {
    return AppleFoundationFlutterPlatform.instance.generateText(
      prompt,
      sessionId: sessionId,
    );
  }

  Future<List<String>> generateAlternatives(
    String prompt, {
    String? sessionId,
    int count = 3,
  }) {
    return AppleFoundationFlutterPlatform.instance.generateAlternatives(
      prompt,
      sessionId: sessionId,
      count: count,
    );
  }

  Future<String?> summarizeText(
    String text, {
    String? sessionId,
    SummarizationStyle style = SummarizationStyle.concise,
  }) {
    return AppleFoundationFlutterPlatform.instance.summarizeText(
      text,
      sessionId: sessionId,
      style: style,
    );
  }

  Future<Map<String, dynamic>> extractInformation(
    String text, {
    String? sessionId,
    List<String>? fields,
  }) {
    return AppleFoundationFlutterPlatform.instance.extractInformation(
      text,
      sessionId: sessionId,
      fields: fields,
    );
  }

  Future<Map<String, double>> classifyText(
    String text, {
    String? sessionId,
    List<String>? categories,
  }) {
    return AppleFoundationFlutterPlatform.instance.classifyText(
      text,
      sessionId: sessionId,
      categories: categories,
    );
  }

  Future<List<String>> generateSuggestions(
    String context, {
    String? sessionId,
    int maxSuggestions = 5,
  }) {
    return AppleFoundationFlutterPlatform.instance.generateSuggestions(
      context,
      sessionId: sessionId,
      maxSuggestions: maxSuggestions,
    );
  }

  Stream<String> generateTextStream(String prompt, {String? sessionId}) {
    return AppleFoundationFlutterPlatform.instance.generateTextStream(
      prompt,
      sessionId: sessionId,
    );
  }

  Stream<String> getStructuredDataStream(String prompt, {String? sessionId}) {
    return AppleFoundationFlutterPlatform.instance.getStructuredDataStream(
      prompt,
      sessionId: sessionId,
    );
  }

  Future<NativeAiCapabilities> getCapabilities() {
    return AppleFoundationFlutterPlatform.instance.getCapabilities();
  }

  /// Generates a JSON object that is guaranteed to match [schema].
  ///
  /// [schema] is a JSON-Schema subset: `object` (with `properties` and
  /// `required`), `array` (with `items`, `minItems`, `maxItems`), `string`,
  /// `number`, `integer`, `boolean`, `enum` of strings, and `description` on
  /// any node. Properties are generated in the order they are written.
  ///
  /// [images] are encoded image bytes (JPEG, PNG, HEIC). They need iOS 27 and
  /// [NativeAiCapabilities.vision]; otherwise the call throws
  /// `VISION_UNSUPPORTED`.
  Future<Map<String, dynamic>> generateStructured({
    required String prompt,
    required Map<String, dynamic> schema,
    String? instructions,
    List<Uint8List> images = const [],
    String schemaName = 'Response',
    double? temperature,
    int? maxTokens,
    Duration? timeout,
  }) {
    return AppleFoundationFlutterPlatform.instance.generateStructured(
      prompt: prompt,
      schema: schema,
      instructions: instructions,
      images: images,
      schemaName: schemaName,
      temperature: temperature,
      maxTokens: maxTokens,
      timeout: timeout,
    );
  }
}
