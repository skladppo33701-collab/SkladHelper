// [PROTOCOL-ARCH-1] Functional Error Handling
// A lightweight Result type to replace throwing Exceptions.

sealed class Result<S, F> {
  const Result();

  B fold<B>(B Function(F failure) onFailure, B Function(S success) onSuccess);
}

class Success<S, F> extends Result<S, F> {
  final S value;
  const Success(this.value);

  @override
  B fold<B>(B Function(F failure) onFailure, B Function(S success) onSuccess) {
    return onSuccess(value);
  }
}

class Failure<S, F> extends Result<S, F> {
  final F value;
  const Failure(this.value);

  @override
  B fold<B>(B Function(F failure) onFailure, B Function(S success) onSuccess) {
    return onFailure(value);
  }
}

// Standard Failure Types
abstract class AppFailure {
  final String message;
  const AppFailure(this.message);
}

class ServerFailure extends AppFailure {
  const ServerFailure(super.message);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

class ParsingFailure extends AppFailure {
  const ParsingFailure(super.message);
}
