import 'package:supabase_flutter/supabase_flutter.dart' as sb;

sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

final class AuthException extends AppException {
  const AuthException(super.message);
}

final class NetworkException extends AppException {
  const NetworkException(
      [super.message = 'Network error. Check your connection.']);
}

final class ServerException extends AppException {
  const ServerException(
      [super.message = 'An unexpected server error occurred.']);
}

final class NotFoundException extends AppException {
  const NotFoundException(
      [super.message = 'The requested resource was not found.']);
}

final class ValidationException extends AppException {
  const ValidationException(super.message);
}

final class PermissionException extends AppException {
  const PermissionException(
      [super.message = 'You do not have permission to perform this action.']);
}

final class AttendanceException extends AppException {
  const AttendanceException(super.message);
}

final class DuplicateException extends AppException {
  const DuplicateException([super.message = 'This name is already taken.']);
}

/// Converts raw exceptions into typed [AppException]s.
AppException mapException(Object error) {
  if (error is AppException) return error;
  if (error is sb.PostgrestException) {
    if (error.code == '42501') return const PermissionException();
    if (error.code == 'PGRST116') return const NotFoundException();
    if (error.code == '23505') return const DuplicateException();
    return ServerException(error.message);
  }
  if (error is sb.AuthException) return AuthException(error.message);
  if (error is sb.StorageException) return ServerException(error.message);
  return const ServerException();
}
