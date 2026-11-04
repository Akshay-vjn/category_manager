import 'package:category_manager/core/errors/app_exception.dart';
import 'package:category_manager/features/profile/data/models/user_profile.dart';
import 'package:category_manager/features/profile/data/services/user_api_service.dart';

class AuthRepository {
  AuthRepository(this._api);
  final UserApiService _api;
  Future<UserProfile> login(String input) {
    final id = int.tryParse(input.trim());
    if (id == null || id <= 0) {
      throw const AppException('Enter a valid positive User ID.');
    }
    return _api.fetchUser(id);
  }
}
