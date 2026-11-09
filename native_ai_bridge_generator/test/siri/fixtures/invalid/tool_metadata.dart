import 'package:native_ai_bridge/annotations/siri_annotations.dart';

@SiriTool(title: 'Search', description: ' ')
class Search {
  late final String query;

  @SiriField(title: 'Limit', description: '')
  late final int limit;
}
