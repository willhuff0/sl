String unbox(dynamic boxed) {
  return boxed.toString();
}

String unboxFloat32(dynamic boxed) {
  return (double.parse(boxed.toStringAsFixed(5)) + 0.0).toString();
}

dynamic box(Type type, String unboxed) {
  switch (type) {
    case const (String):
      return unboxed;
    case const (double):
      return double.tryParse(unboxed);
    case const (int):
      return int.tryParse(unboxed);
    default:
      return null;
  }
}
