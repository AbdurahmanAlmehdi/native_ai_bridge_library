import 'package:flutter_test/flutter_test.dart';
import 'package:native_ai_bridge/models/tool.dart';
import 'package:native_ai_bridge/models/tool_argument.dart';
import 'package:native_ai_bridge/enums/tool_argument_type.dart';

void main() {
  group('Tool', () {
    group('BaseTool', () {
      test('should create a tool with required properties', () {
        final tool = BaseTool(
          name: 'test_tool',
          description: 'A test tool',
          arguments: [],
        );

        expect(tool.name, 'test_tool');
        expect(tool.description, 'A test tool');
        expect(tool.arguments, isEmpty);
      });

      test('should create a tool with arguments', () {
        final arguments = [
          BaseToolArgument(
            name: 'city',
            type: ToolArgumentType.string,
            description: 'City name',
          ),
          BaseToolArgument(
            name: 'units',
            type: ToolArgumentType.string,
            description: 'Temperature units',
            isOptional: true,
          ),
        ];

        final tool = BaseTool(
          name: 'get_weather',
          description: 'Get weather for a city',
          arguments: arguments,
        );

        expect(tool.name, 'get_weather');
        expect(tool.description, 'Get weather for a city');
        expect(tool.arguments.length, 2);
        expect(tool.arguments[0].name, 'city');
        expect(tool.arguments[1].name, 'units');
        expect(tool.arguments[1].isOptional, true);
      });

      test('should convert to JSON correctly', () {
        final tool = BaseTool(
          name: 'test_tool',
          description: 'A test tool',
          arguments: [
            BaseToolArgument(
              name: 'param1',
              type: ToolArgumentType.string,
              description: 'First parameter',
            ),
          ],
        );

        final json = tool.toJson();

        expect(json['name'], 'test_tool');
        expect(json['description'], 'A test tool');
        expect(json['arguments'], isA<List>());
        expect(json['arguments'].length, 1);
        expect(json['arguments'][0]['name'], 'param1');
      });

      test('should convert from JSON correctly', () {
        final json = {
          'name': 'test_tool',
          'description': 'A test tool',
          'arguments': [
            {
              'name': 'param1',
              'type': 'String',
              'description': 'First parameter',
              'isOptional': false,
            },
          ],
        };

        final tool = BaseTool.fromJson(json);

        expect(tool.name, 'test_tool');
        expect(tool.description, 'A test tool');
        expect(tool.arguments.length, 1);
        expect(tool.arguments[0].name, 'param1');
        expect(tool.arguments[0].type, ToolArgumentType.string);
      });

      test('should handle empty arguments array in fromJson', () {
        final json = {
          'name': 'test_tool',
          'description': 'A test tool',
          'arguments': null,
        };

        final tool = BaseTool.fromJson(json);

        expect(tool.arguments, isEmpty);
      });

      test('toString should return formatted string', () {
        final tool = BaseTool(
          name: 'test_tool',
          description: 'A test tool',
          arguments: [
            BaseToolArgument(
              name: 'param1',
              type: ToolArgumentType.string,
              description: 'First parameter',
            ),
            BaseToolArgument(
              name: 'param2',
              type: ToolArgumentType.integer,
              description: 'Second parameter',
            ),
          ],
        );

        final string = tool.toString();

        expect(string, contains('test_tool'));
        expect(string, contains('2'));
      });
    });
  });
}
