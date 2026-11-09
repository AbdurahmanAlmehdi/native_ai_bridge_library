import 'package:native_ai_bridge/annotations/siri_annotations.dart';

import 'entities.dart';

@SiriTool(title: 'Search', description: 'Finds products.')
class Search {
  @SiriField(title: 'Filter', description: 'How to filter.')
  late final Filter filter;
}
