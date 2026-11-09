import 'package:native_ai_bridge/annotations/siri_annotations.dart';

@SiriGenerableEntity()
class Filter {
  @SiriField(title: 'Brand', description: 'The brand.')
  late final String brand;
}
