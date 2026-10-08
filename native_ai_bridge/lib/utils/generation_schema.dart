/// Adds a `propertyOrder` list to every object node of a JSON-Schema-style
/// map, taken from the insertion order of its `properties`.
///
/// Platform channels deliver maps without key order, and the model fills
/// properties in schema order, so the order the caller wrote is preserved
/// explicitly. An existing `propertyOrder` is kept.
Map<String, dynamic> withPropertyOrder(Map<String, dynamic> schema) {
  final result = Map<String, dynamic>.from(schema);

  final properties = schema['properties'];
  if (properties is Map) {
    result['properties'] = {
      for (final entry in properties.entries)
        entry.key as String: entry.value is Map
            ? withPropertyOrder(Map<String, dynamic>.from(entry.value as Map))
            : entry.value,
    };
    result['propertyOrder'] ??= [
      for (final key in properties.keys) key as String,
    ];
  }

  final items = schema['items'];
  if (items is Map) {
    result['items'] = withPropertyOrder(Map<String, dynamic>.from(items));
  }

  return result;
}
