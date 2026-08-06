abstract class EngineResult<T> {
  const EngineResult();
}

class EngineSuccess<T> extends EngineResult<T> {
  const EngineSuccess(this.data);
  final T data;
}

class EngineFailure<T> extends EngineResult<T> {
  const EngineFailure(this.error, [this.stackTrace]);
  final Object error;
  final StackTrace? stackTrace;
}
