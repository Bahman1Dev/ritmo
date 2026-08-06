class Sampled<T> {
  const Sampled(this.value, this.timestamp, {this.weight = 1.0});

  final T value;
  final DateTime timestamp;
  final double weight;
}
