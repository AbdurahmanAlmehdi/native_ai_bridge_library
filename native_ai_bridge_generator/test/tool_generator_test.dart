import 'package:build_test/build_test.dart';
import 'package:native_ai_bridge_generator/src/tool_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  group('ToolGenerator', () {
    test('should generate Tool class from annotated class', () async {
      final builder = LibraryBuilder(
        ToolGenerator(),
        generatedExtension: '.tool.g.dart',
      );

      await testBuilder(
        builder,
        {
          'native_ai_bridge|lib/annotations/tool_annotations.dart': '''
            class GenerateTool {
              final String? name;
              final String? description;
              const GenerateTool({this.name, this.description});
            }

            class GenerateToolArgument {
              final String? description;
              final bool? isOptional;
              final bool exclude;
              final Map<String, dynamic>? constraints;
              const GenerateToolArgument({
                this.description,
                this.isOptional,
                this.exclude = false,
                this.constraints,
              });
            }
          ''',
          'native_ai_bridge|lib/models/tool.dart': '''
            abstract class Tool {
              String get name;
              String get description;
              List get arguments;
            }

            class BaseTool extends Tool {
              final String name;
              final String description;
              final List arguments;
              BaseTool({
                required this.name,
                required this.description,
                required this.arguments,
              });
            }
          ''',
          'native_ai_bridge|lib/models/tool_argument.dart': '''
            class BaseToolArgument {
              final String name;
              final dynamic type;
              final String description;
              final bool isOptional;
              final Map<String, dynamic>? constraints;
              BaseToolArgument({
                required this.name,
                required this.type,
                required this.description,
                this.isOptional = false,
                this.constraints,
              });
            }
          ''',
          'native_ai_bridge|lib/enums/tool_argument_type.dart': '''
            enum ToolArgumentType {
              string,
              integer,
              double_,
              boolean,
            }
          ''',
          'a|lib/models/weather_request.dart': '''
            import 'package:native_ai_bridge/annotations/tool_annotations.dart';

            @GenerateTool(
              name: 'get_weather',
              description: 'Get weather for a city',
            )
            class WeatherRequest {
              final String city;
              final String? units;

              const WeatherRequest({
                required this.city,
                this.units,
              });
            }
          ''',
        },
        outputs: {
          'a|lib/models/weather_request.tool.g.dart': decodedMatches(
            allOf([
              contains('class WeatherRequestTool'),
              contains('extends BaseTool'),
              contains("name: 'get_weather'"),
              contains('Get weather for a city'),
              contains('BaseToolArgument'),
              contains('city'),
              contains('units'),
            ]),
          ),
        },
      );
    });

    test('should use class name for tool name when not provided', () async {
      final builder = LibraryBuilder(
        ToolGenerator(),
        generatedExtension: '.tool.g.dart',
      );

      await testBuilder(
        builder,
        {
          'native_ai_bridge|lib/annotations/tool_annotations.dart': '''
            class GenerateTool {
              final String? name;
              final String? description;
              const GenerateTool({this.name, this.description});
            }

            class GenerateToolArgument {
              final String? description;
              final bool? isOptional;
              final bool exclude;
              final Map<String, dynamic>? constraints;
              const GenerateToolArgument({
                this.description,
                this.isOptional,
                this.exclude = false,
                this.constraints,
              });
            }
          ''',
          'native_ai_bridge|lib/models/tool.dart': '''
            abstract class Tool {
              String get name;
              String get description;
              List get arguments;
            }

            class BaseTool extends Tool {
              final String name;
              final String description;
              final List arguments;
              BaseTool({
                required this.name,
                required this.description,
                required this.arguments,
              });
            }
          ''',
          'native_ai_bridge|lib/models/tool_argument.dart': '''
            class BaseToolArgument {
              final String name;
              final dynamic type;
              final String description;
              final bool isOptional;
              final Map<String, dynamic>? constraints;
              BaseToolArgument({
                required this.name,
                required this.type,
                required this.description,
                this.isOptional = false,
                this.constraints,
              });
            }
          ''',
          'native_ai_bridge|lib/enums/tool_argument_type.dart': '''
            enum ToolArgumentType {
              string,
              integer,
              double_,
              boolean,
            }
          ''',
          'a|lib/models/search_request.dart': '''
            import 'package:native_ai_bridge/annotations/tool_annotations.dart';

            @GenerateTool()
            class SearchRequest {
              final String query;

              const SearchRequest({required this.query});
            }
          ''',
        },
        outputs: {
          'a|lib/models/search_request.tool.g.dart': decodedMatches(
            allOf([
              contains("name: 'search_request'"),
              contains('Tool for SearchRequest'),
            ]),
          ),
        },
      );
    });

    test('should handle constraints correctly', () async {
      final builder = LibraryBuilder(
        ToolGenerator(),
        generatedExtension: '.tool.g.dart',
      );

      await testBuilder(
        builder,
        {
          'native_ai_bridge|lib/annotations/tool_annotations.dart': '''
            class GenerateTool {
              final String? name;
              final String? description;
              const GenerateTool({this.name, this.description});
            }

            class GenerateToolArgument {
              final String? description;
              final bool? isOptional;
              final bool exclude;
              final Map<String, dynamic>? constraints;
              const GenerateToolArgument({
                this.description,
                this.isOptional,
                this.exclude = false,
                this.constraints,
              });
            }
          ''',
          'native_ai_bridge|lib/models/tool.dart': '''
            abstract class Tool {
              String get name;
              String get description;
              List get arguments;
            }

            class BaseTool extends Tool {
              final String name;
              final String description;
              final List arguments;
              BaseTool({
                required this.name,
                required this.description,
                required this.arguments,
              });
            }
          ''',
          'native_ai_bridge|lib/models/tool_argument.dart': '''
            class BaseToolArgument {
              final String name;
              final dynamic type;
              final String description;
              final bool isOptional;
              final Map<String, dynamic>? constraints;
              BaseToolArgument({
                required this.name,
                required this.type,
                required this.description,
                this.isOptional = false,
                this.constraints,
              });
            }
          ''',
          'native_ai_bridge|lib/enums/tool_argument_type.dart': '''
            enum ToolArgumentType {
              string,
              integer,
              double_,
              boolean,
            }
          ''',
          'a|lib/models/forecast_request.dart': '''
            import 'package:native_ai_bridge/annotations/tool_annotations.dart';

            @GenerateTool(name: 'get_forecast')
            class ForecastRequest {
              final String city;

              @GenerateToolArgument(
                description: 'Number of days (1-7)',
                constraints: {'min': 1, 'max': 7},
              )
              final int? days;

              const ForecastRequest({
                required this.city,
                this.days,
              });
            }
          ''',
        },
        outputs: {
          'a|lib/models/forecast_request.tool.g.dart': decodedMatches(
            allOf([
              contains('constraints:'),
              contains("'min': 1"),
              contains("'max': 7"),
            ]),
          ),
        },
      );
    });

    test('should exclude fields marked with exclude', () async {
      final builder = LibraryBuilder(
        ToolGenerator(),
        generatedExtension: '.tool.g.dart',
      );

      await testBuilder(
        builder,
        {
          'native_ai_bridge|lib/annotations/tool_annotations.dart': '''
            class GenerateTool {
              final String? name;
              final String? description;
              const GenerateTool({this.name, this.description});
            }

            class GenerateToolArgument {
              final String? description;
              final bool? isOptional;
              final bool exclude;
              final Map<String, dynamic>? constraints;
              const GenerateToolArgument({
                this.description,
                this.isOptional,
                this.exclude = false,
                this.constraints,
              });
            }
          ''',
          'native_ai_bridge|lib/models/tool.dart': '''
            abstract class Tool {
              String get name;
              String get description;
              List get arguments;
            }

            class BaseTool extends Tool {
              final String name;
              final String description;
              final List arguments;
              BaseTool({
                required this.name,
                required this.description,
                required this.arguments,
              });
            }
          ''',
          'native_ai_bridge|lib/models/tool_argument.dart': '''
            class BaseToolArgument {
              final String name;
              final dynamic type;
              final String description;
              final bool isOptional;
              final Map<String, dynamic>? constraints;
              BaseToolArgument({
                required this.name,
                required this.type,
                required this.description,
                this.isOptional = false,
                this.constraints,
              });
            }
          ''',
          'native_ai_bridge|lib/enums/tool_argument_type.dart': '''
            enum ToolArgumentType {
              string,
              integer,
              double_,
              boolean,
            }
          ''',
          'a|lib/models/user_request.dart': '''
            import 'package:native_ai_bridge/annotations/tool_annotations.dart';

            @GenerateTool(name: 'create_user')
            class UserRequest {
              final String username;

              @GenerateToolArgument(exclude: true)
              final String? internalId;

              const UserRequest({
                required this.username,
                this.internalId,
              });
            }
          ''',
        },
        outputs: {
          'a|lib/models/user_request.tool.g.dart': decodedMatches(
            allOf([
              contains('username'),
              isNot(contains('internalId')),
            ]),
          ),
        },
      );
    });

    test('should handle different field types', () async {
      final builder = LibraryBuilder(
        ToolGenerator(),
        generatedExtension: '.tool.g.dart',
      );

      await testBuilder(
        builder,
        {
          'native_ai_bridge|lib/annotations/tool_annotations.dart': '''
            class GenerateTool {
              final String? name;
              final String? description;
              const GenerateTool({this.name, this.description});
            }

            class GenerateToolArgument {
              final String? description;
              final bool? isOptional;
              final bool exclude;
              final Map<String, dynamic>? constraints;
              const GenerateToolArgument({
                this.description,
                this.isOptional,
                this.exclude = false,
                this.constraints,
              });
            }
          ''',
          'native_ai_bridge|lib/models/tool.dart': '''
            abstract class Tool {
              String get name;
              String get description;
              List get arguments;
            }

            class BaseTool extends Tool {
              final String name;
              final String description;
              final List arguments;
              BaseTool({
                required this.name,
                required this.description,
                required this.arguments,
              });
            }
          ''',
          'native_ai_bridge|lib/models/tool_argument.dart': '''
            class BaseToolArgument {
              final String name;
              final dynamic type;
              final String description;
              final bool isOptional;
              final Map<String, dynamic>? constraints;
              BaseToolArgument({
                required this.name,
                required this.type,
                required this.description,
                this.isOptional = false,
                this.constraints,
              });
            }
          ''',
          'native_ai_bridge|lib/enums/tool_argument_type.dart': '''
            enum ToolArgumentType {
              string,
              integer,
              double_,
              boolean,
            }
          ''',
          'a|lib/models/test_request.dart': '''
            import 'package:native_ai_bridge/annotations/tool_annotations.dart';

            @GenerateTool(name: 'test')
            class TestRequest {
              final String stringField;
              final int intField;
              final double doubleField;
              final bool boolField;

              const TestRequest({
                required this.stringField,
                required this.intField,
                required this.doubleField,
                required this.boolField,
              });
            }
          ''',
        },
        outputs: {
          'a|lib/models/test_request.tool.g.dart': decodedMatches(
            allOf([
              contains('ToolArgumentType.string'),
              contains('ToolArgumentType.integer'),
              contains('ToolArgumentType.double_'),
              contains('ToolArgumentType.boolean'),
            ]),
          ),
        },
      );
    });
  });
}
