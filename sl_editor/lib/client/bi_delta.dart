import 'package:sl_shared/sl_shared.dart';

class BiDelta {
  final Delta delta;
  final Delta inverseDelta;

  BiDelta({
    required this.delta,
    required this.inverseDelta,
  });
}

class BiDeltaBuilder {
  final Delta _inverseDelta = {};
  final Delta _delta = {};

  void setProperty(String path, dynamic oldValue, dynamic newValue) {
    _inverseDelta[path] = oldValue;
    _delta[path] = newValue;
  }

  BiDelta getBiDelta() {
    return BiDelta(
      delta: _delta,
      inverseDelta: _inverseDelta,
    );
  }
}

class BiStateChange {
  final ObjectClass? objectClass;
  final UUID objectId;
  final BiDelta biDelta;

  BiStateChange({
    this.objectClass,
    required this.objectId,
    required this.biDelta,
  });

  StateChange getForwardStateChange(UUID? scope) => StateChange(
    scope: scope,
    objectClass: objectClass,
    objectId: objectId,
    delta: biDelta.delta,
  );

  StateChange getInverseStateChange(UUID? scope) => StateChange(
    scope: scope,
    objectClass: objectClass,
    objectId: objectId,
    delta: biDelta.inverseDelta,
  );
}
