import 'package:meta/meta.dart';

@experimental
class SiriTool {
  const SiriTool({required this.title, required this.description});

  final String title;
  final String description;
}

@experimental
class SiriField {
  const SiriField({required this.title, required this.description});

  final String title;
  final String description;
}

@experimental
class SiriGenerableEntity {
  const SiriGenerableEntity({this.title});

  final String? title;
}

@experimental
class SiriSkill {
  const SiriSkill({
    required this.name,
    required this.description,
    required this.body,
  });

  final String name;
  final String description;
  final String body;
}
