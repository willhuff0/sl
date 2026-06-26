/// A pure, stateless description of a tracked property: its wire key, default value,
/// JSON codec, and an optional value-only validator.
///
/// Shared by the server's `ValidatedProperty` and the client's `TrackedProperty` so the
/// key, codec, default, and value validation live in exactly one place. Side-specific
/// concerns stay on the wrappers: the server adds validation/setters, the client adds
/// effects and change streams.
class PropertySchema<T> {
  /// The JSON/delta key for this property.
  final String key;

  /// Produces a fresh default value. A factory (rather than a stored value) so that mutable
  /// defaults such as `Vector3` are not shared between objects.
  final T Function() createDefault;

  final dynamic Function(T value)? toJson;
  final T Function(dynamic json)? fromJson;

  /// Optional pure value check. Receiver-dependent validation (e.g. checking the tracker for a
  /// parent node) stays on the server-side wrapper.
  final bool Function(dynamic value)? validateValue;

  /// When true, the property must be present in a delta for that delta to be valid.
  final bool required;

  PropertySchema({
    required this.key,
    required this.createDefault,
    this.toJson,
    this.fromJson,
    this.validateValue,
    this.required = false,
  });

  dynamic encode(T value) => toJson == null ? value : toJson!(value);
  T decode(dynamic json) => fromJson == null ? json as T : fromJson!(json);
}

/// Shared schema for the `doesExist` property present on every state-tracked object.
/// Receiver-dependent validation (you cannot resurrect a deleted object) lives on the server.
final PropertySchema<bool> doesExistSchema = PropertySchema<bool>(
  key: 'doesExist',
  createDefault: () => true,
);
