String fp(void Function(StringSink b) build) {
  final b = StringBuffer();
  build(b);
  return b.length <= 512
      ? b.toString()
      : b.toString().hashCode.toRadixString(36);
}
