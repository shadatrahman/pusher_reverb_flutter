/// Represents a member in a presence channel.
///
/// This immutable class encapsulates information about a user who is
/// currently subscribed to a presence channel, including their unique
/// identifier and additional user information.
class PresenceMember {
  /// The unique identifier for this member.
  ///
  /// Typically this is a user ID provided by your application's backend.
  final String id;

  /// Additional information about this member.
  ///
  /// This can contain any user data provided by your application's backend,
  /// such as username, avatar URL, online status, etc.
  final Map<String, dynamic> info;

  /// Creates a new PresenceMember instance.
  ///
  /// Both [id] and [info] parameters are required and the instance is immutable.
  ///
  /// Example:
  /// ```dart
  /// final member = PresenceMember(
  ///   id: '123',
  ///   info: {
  ///     'name': 'John Doe',
  ///     'avatar': 'https://example.com/avatar.jpg',
  ///   },
  /// );
  /// ```
  const PresenceMember({required this.id, required this.info});

  /// Creates a PresenceMember from a JSON map.
  ///
  /// Expects a map with 'id' (String) and 'info' (Map) fields.
  /// If 'info' is not provided or is not a map, an empty map is used.
  ///
  /// Example:
  /// ```dart
  /// final member = PresenceMember.fromJson({
  ///   'id': '123',
  ///   'info': {'name': 'John Doe'},
  /// });
  /// ```
  factory PresenceMember.fromJson(Map<String, dynamic> json) {
    return PresenceMember(id: json['id'] as String, info: json['info'] is Map<String, dynamic> ? json['info'] as Map<String, dynamic> : {});
  }

  /// Converts this PresenceMember to a JSON map.
  ///
  /// Returns a map with 'id' and 'info' fields.
  ///
  /// Example:
  /// ```dart
  /// final json = member.toJson();
  /// // {'id': '123', 'info': {'name': 'John Doe'}}
  /// ```
  Map<String, dynamic> toJson() {
    return {'id': id, 'info': info};
  }

  @override
  String toString() {
    return 'PresenceMember(id: $id, info: $info)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PresenceMember && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
