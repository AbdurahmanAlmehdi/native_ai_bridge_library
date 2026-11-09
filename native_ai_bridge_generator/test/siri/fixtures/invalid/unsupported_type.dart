import 'package:native_ai_bridge/annotations/siri_annotations.dart';

@SiriTool(title: 'Search', description: 'Finds products.')
class Search {
  @SiriField(title: 'Filters', description: 'Extra filters.')
  late final Map<String, String> filters;

  @SiriField(title: 'Range', description: 'Price range.')
  late final (double, double) range;

  @SiriField(title: 'Anything', description: 'Anything at all.')
  late final dynamic anything;

  @SiriField(title: 'Tags', description: 'Tags to match.')
  late final List<String>? tags;

  @SiriField(title: 'Store', description: 'The store to search.')
  late final Store store;
}

class Store {}

@SiriGenerableEntity()
class Filter {
  @SiriField(title: 'Brand', description: 'The brand, if any.')
  late final String? brand;
}
