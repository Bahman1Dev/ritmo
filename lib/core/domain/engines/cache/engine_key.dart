import 'package:meta/meta.dart';

@immutable
class EngineKey {
  const EngineKey(this.type, this.fingerprint);

  final Type type;
  final String fingerprint;

  @override
  bool operator ==(Object other) =>
      other is EngineKey &&
      other.type == type &&
      other.fingerprint == fingerprint;

  @override
  int get hashCode => Object.hash(type, fingerprint);

  @override
  String toString() => '$type#$fingerprint';
}
