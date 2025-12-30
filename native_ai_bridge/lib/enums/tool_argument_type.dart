enum ToolArgumentType {
  string('String'),

  integer('Int'),

  double_('Double'),

  boolean('Bool');

  final String value;

  const ToolArgumentType(this.value);

  factory ToolArgumentType.fromString(String value) {
    for (final type in ToolArgumentType.values) {
      if (type.value == value) {
        return type;
      }
    }
    throw ArgumentError('Unknown ToolArgumentType: $value');
  }

  String toJson() => value;
}
