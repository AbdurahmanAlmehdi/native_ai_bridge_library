import 'package:native_ai_bridge/annotations/siri_annotations.dart';

@SiriSkill(name: 'Store--Shopping', description: 'Helps.', body: 'Body.')
abstract final class BadNameSkill {}

@SiriSkill(name: 'store', description: 'Helps.', body: 'Body.')
abstract final class FirstSkill {}

@SiriSkill(name: 'store', description: 'Helps too.', body: 'Body.')
abstract final class DuplicateSkill {}
