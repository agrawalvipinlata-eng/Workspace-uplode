/// Lightweight Result type so services return typed failures instead of
/// throwing raw exceptions into the UI layer.
sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T value) ok,
    required R Function(AppFailure failure) err,
  }) {
    final Result<T> self = this;
    return switch (self) {
      Ok<T>(:final T value) => ok(value),
      Err<T>(:final AppFailure failure) => err(failure),
    };
  }

  bool get isOk => this is Ok<T>;
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final AppFailure failure;
}

/// Normalized, user-presentable failure.
class AppFailure {
  const AppFailure(this.code, this.message);

  final String code;
  final String message;

  static const AppFailure network = AppFailure(
    'network',
    'No internet connection. Please check your network and try again.',
  );
  static const AppFailure permissionDenied = AppFailure(
    'permission-denied',
    'You don\'t have permission to do that.',
  );
  static const AppFailure sessionExpired = AppFailure(
    'session-expired',
    'Your session has expired. Please sign in again.',
  );
  static const AppFailure unknown = AppFailure(
    'unknown',
    'Something went wrong. Please try again.',
  );

  @override
  String toString() => 'AppFailure($code: $message)';
}
