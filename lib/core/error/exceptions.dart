// lib/core/error/exceptions.dart
class ServerException implements Exception {
  final String message;
  ServerException([this.message = "ServerException"]);
  @override
  String toString() => "ServerException: $message";
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = "NetworkException"]);
  @override
  String toString() => "NetworkException: $message";
}
