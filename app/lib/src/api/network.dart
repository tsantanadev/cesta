import 'package:dio/dio.dart';

/// Whether [e] means the server couldn't be reached (no connection, or no
/// answer in time), as opposed to the server answering with something unexpected.
bool isOffline(DioException e) => switch (e.type) {
  DioExceptionType.connectionError ||
  DioExceptionType.connectionTimeout ||
  DioExceptionType.sendTimeout ||
  DioExceptionType.receiveTimeout => true,
  _ => false,
};
