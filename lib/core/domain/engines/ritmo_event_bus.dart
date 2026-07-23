import 'dart:async';

class RitmoEvent {

  RitmoEvent({
    required this.type,
    required this.timestamp,
    required this.payload,
  });
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> payload;

  @override
  String toString() => 'RitmoEvent(type: $type, timestamp: $timestamp, payload: $payload)';
}

class RitmoEventBus {
  factory RitmoEventBus() => _instance;
  RitmoEventBus._internal();
  static final RitmoEventBus _instance = RitmoEventBus._internal();

  final _controller = StreamController<RitmoEvent>.broadcast();

  Stream<RitmoEvent> get onEvents => _controller.stream;

  void fire(RitmoEvent event) {
    _controller.add(event);
  }
}
