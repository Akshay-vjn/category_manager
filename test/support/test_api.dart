import 'package:dio/dio.dart';

Map<String, dynamic> profileJson({int id = 7}) => {
  'id': id,
  'name': 'API Test Person',
  'username': 'api_person',
  'email': 'person@example.test',
  'phone': '12345678',
  'website': 'example.test',
  'company': {'name': 'API Company'},
};

Dio testDio({int status = 200, Object? body, Duration delay = Duration.zero}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (delay != Duration.zero) await Future<void>.delayed(delay);
        if (status != 200) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response<dynamic>(
                requestOptions: options,
                statusCode: status,
              ),
            ),
          );
        } else {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: status,
              data: body ?? profileJson(),
            ),
          );
        }
      },
    ),
  );
  return dio;
}
