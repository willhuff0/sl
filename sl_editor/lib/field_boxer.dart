// String propertyToFieldString<T>(T value) {
//   switch (value) {
//     case String stringValue:
//       return stringValue;
//     case num numValue:
//       return numValue.toString();
//     default:
//       return '';
//   }
// }

// dynamic propertyFromFieldString<T>(String value) {
//   switch (T) {
//     case const (String):
//       return value;
//     case const (num):
//       return num.parse(value);
//     default:
//       return null;
//   }
// }

// String propertyToFieldTypeName<T>() {
//   return T.toString();
// }

String unbox(dynamic unboxed) {
  return unboxed.toString();
}

dynamic box(Type type, String boxed) {
  switch (type) {
    case const (String):
      return boxed;
    case const (double):
      return double.tryParse(boxed);
    case const (int):
      return int.tryParse(boxed);
    default:
      return null;
  }
}
