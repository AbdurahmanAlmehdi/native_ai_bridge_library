import 'package:flutter_test/flutter_test.dart';
import 'package:native_ai_bridge/models/tool_argument.dart';
import 'package:native_ai_bridge/enums/tool_argument_type.dart';

void main() {
  group('ToolArgument', () {
    group('BaseToolArgument', () {
      test('should create argument with required properties', () {
        final argument = BaseToolArgument(
          name: 'city',
          type: ToolArgumentType.string,
          description: 'City name',
        );

        expect(argument.name, 'city');
        expect(argument.type, ToolArgumentType.string);
        expect(argument.description, 'City name');
        expect(argument.isOptional, false);
        expect(argument.constraints, isNull);
      });

      test('should create optional argument', () {
        final argument = BaseToolArgument(
          name: 'units',
          type: ToolArgumentType.string,
          description: 'Temperature units',
          isOptional: true,
        );

        expect(argument.isOptional, true);
      });

      test('should create argument with constraints', () {
        final argument = BaseToolArgument(
          name: 'count',
          type: ToolArgumentType.integer,
          description: 'Number of results',
          constraints: {
            'min': 1,
            'max': 100,
          },
        );

        expect(argument.constraints, isNotNull);
        expect(argument.constraints!['min'], 1);
        expect(argument.constraints!['max'], 100);
      });

      test('should create argument with enum constraints', () {
        final argument = BaseToolArgument(
          name: 'units',
          type: ToolArgumentType.string,
          description: 'Temperature units',
          constraints: {
            'enum': ['metric', 'imperial'],
          },
        );

        expect(argument.constraints, isNotNull);
        expect(argument.constraints!['enum'], isA<List>());
        expect(argument.constraints!['enum'], contains('metric'));
        expect(argument.constraints!['enum'], contains('imperial'));
      });

      test('should convert to JSON correctly', () {
        final argument = BaseToolArgument(
          name: 'city',
          type: ToolArgumentType.string,
          description: 'City name',
        );

        final json = argument.toJson();

        expect(json['name'], 'city');
        expect(json['type'], 'String');
        expect(json['description'], 'City name');
        expect(json['isOptional'], false);
      });

      test('should include constraints in JSON when present', () {
        final argument = BaseToolArgument(
          name: 'count',
          type: ToolArgumentType.integer,
          description: 'Count',
          constraints: {'min': 1, 'max': 10},
        );

        final json = argument.toJson();

        expect(json['constraints'], isNotNull);
        expect(json['constraints']['min'], 1);
        expect(json['constraints']['max'], 10);
      });

      test('should not include constraints in JSON when null', () {
        final argument = BaseToolArgument(
          name: 'city',
          type: ToolArgumentType.string,
          description: 'City name',
        );

        final json = argument.toJson();

        expect(json.containsKey('constraints'), false);
      });

      test('should convert from JSON correctly', () {
        final json = {
          'name': 'city',
          'type': 'String',
          'description': 'City name',
          'isOptional': false,
        };

        final argument = BaseToolArgument.fromJson(json);

        expect(argument.name, 'city');
        expect(argument.type, ToolArgumentType.string);
        expect(argument.description, 'City name');
        expect(argument.isOptional, false);
      });

      test('should handle missing isOptional in fromJson', () {
        final json = {
          'name': 'city',
          'type': 'String',
          'description': 'City name',
        };

        final argument = BaseToolArgument.fromJson(json);

        expect(argument.isOptional, false);
      });

      test('should handle constraints in fromJson', () {
        final json = {
          'name': 'count',
          'type': 'Int',
          'description': 'Count',
          'isOptional': false,
          'constraints': {'min': 1, 'max': 10},
        };

        final argument = BaseToolArgument.fromJson(json);

        expect(argument.constraints, isNotNull);
        expect(argument.constraints!['min'], 1);
        expect(argument.constraints!['max'], 10);
      });

      test('should handle all ToolArgumentTypes', () {
        final types = [
          ToolArgumentType.string,
          ToolArgumentType.integer,
          ToolArgumentType.double_,
          ToolArgumentType.boolean,
        ];

        for (final type in types) {
          final argument = BaseToolArgument(
            name: 'test',
            type: type,
            description: 'Test',
          );

          expect(argument.type, type);
        }
      });

      test('toString should return formatted string', () {
        final argument = BaseToolArgument(
          name: 'city',
          type: ToolArgumentType.string,
          description: 'City name',
        );

        final string = argument.toString();

        expect(string, contains('city'));
        expect(string, contains('String'));
        expect(string, contains('City name'));
        expect(string, contains('false'));
      });
    });
  });
}
