import 'package:meta/meta.dart';

/// Marks a class as a Siri AI tool.
///
/// `dart run native_ai_bridge_generator:siri` turns the class into a Swift
/// `@AppIntent(.tool)` intent and a `<ClassName>Handler` protocol that your
/// app implements in Swift. Each field is a tool parameter and needs a
/// [SiriField].
///
/// These declarations are read at build time only. Siri never calls Dart.
///
/// ```dart
/// @SiriTool(
///   title: 'Search Products',
///   description: 'Finds products in the store and returns the best matches.',
/// )
/// class SearchProducts {
///   @SiriField(title: 'Search', description: 'What the shopper wants.')
///   late final ProductSearch search;
/// }
/// ```
@experimental
class SiriTool {
  const SiriTool({required this.title, required this.description});

  /// What the action is, for example `Search Products`.
  final String title;

  /// What the action does, written for someone who does not know your app.
  final String description;
}

/// Describes a tool parameter, a generable entity property or an enum case.
///
/// Siri reads the title and description to decide how to fill the value, so
/// include formats, units and ranges in the description.
@experimental
class SiriField {
  const SiriField({required this.title, required this.description});

  /// A short name for the value, for example `Maximum Price`.
  final String title;

  /// What the value means, for example `Highest price in US dollars`.
  final String description;
}

/// Marks a class or an enum as a type Siri can generate from a request.
///
/// A class becomes a Swift `@AppEntity(.generable)` entity whose fields need a
/// [SiriField]. An enum becomes a Swift `AppEnum`; its cases may carry a
/// [SiriField] for their display title.
///
/// [title] is the type's display name and defaults to the Dart name split
/// into words.
@experimental
class SiriGenerableEntity {
  const SiriGenerableEntity({this.title});

  /// The type's display name, for example `Product Search`.
  final String? title;
}

/// Declares an app skill, written to `Skills/<name>/SKILL.md`.
///
/// Put it on any top-level declaration in the Siri input library, such as an
/// empty abstract class.
///
/// ```dart
/// @SiriSkill(
///   name: 'store-shopping',
///   description: 'Helps a shopper find products and add them to the cart.',
///   body: 'Use the search products tool first...',
/// )
/// abstract final class StoreShoppingSkill {}
/// ```
@experimental
class SiriSkill {
  const SiriSkill({
    required this.name,
    required this.description,
    required this.body,
  });

  /// 1 to 64 characters from `a-z`, `0-9` and `-`, unique in the app.
  final String name;

  /// One line of at most 1024 characters saying when Siri should use it.
  final String description;

  /// Markdown instructions Siri reads once it picks the skill.
  final String body;
}
