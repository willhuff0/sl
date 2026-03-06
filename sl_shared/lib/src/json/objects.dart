import 'package:uuid/uuid.dart';

export 'objects/state_tracking.dart';
export 'objects/client_state.dart';
export 'objects/view_position.dart';
export 'objects/fraction.dart';
export 'objects/parent_and_order.dart';

typedef ClientId = int;
typedef UUID = String;

UUID generateUuid() {
  return Uuid().v4();
}
