// App-level failure types.
//
// Define typed failures here to avoid throwing raw exceptions across layers.
// These will be used by repositories and services in later phases.
//
// Example:
//
// sealed class Failure {
//   const Failure(this.message);
//   final String message;
// }
//
// final class NetworkFailure extends Failure {
//   const NetworkFailure(super.message);
// }
//
// final class ServerFailure extends Failure {
//   const ServerFailure(super.message);
// }
//
// final class CacheFailure extends Failure {
//   const CacheFailure(super.message);
// }
