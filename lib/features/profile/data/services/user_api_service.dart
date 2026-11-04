import 'package:dio/dio.dart';
import 'package:category_manager/core/errors/app_exception.dart';
import 'package:category_manager/features/profile/data/models/user_profile.dart';

class UserApiService {
  UserApiService(this._dio);
  final Dio _dio;

  Future<UserProfile> fetchUser(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/users/$id');
      final body = response.data;
      if (body == null || body.isEmpty) {
        throw const AppException('No user found for this ID.');
      }
      final user = UserProfile.fromJson(body);
      if (user.id != id) throw const FormatException('User ID mismatch');
      return user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const AppException('No user found for this ID.');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const AppException('The request timed out. Please try again.');
      }
      throw const AppException(
        'Unable to load your profile. Check your connection and try again.',
      );
    } on TypeError {
      throw const AppException(
        'The server returned an invalid profile. Please try again.',
      );
    } on FormatException {
      throw const AppException(
        'The server returned an invalid profile. Please try again.',
      );
    }
  }
}
