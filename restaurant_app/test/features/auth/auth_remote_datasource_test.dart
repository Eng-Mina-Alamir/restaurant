import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/exceptions.dart';
import 'package:restaurant_app/features/auth/data/datasources/auth_remote_datasource.dart';

// Simple fake/mock Dio adapter for testing AuthRemoteDataSourceImpl
class FakeDio implements Dio {
  Response<dynamic>? nextResponse;
  DioException? nextError;
  String? lastPath;
  dynamic lastData;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    lastPath = path;
    lastData = data;

    if (nextError != null) {
      throw nextError!;
    }
    return nextResponse as Response<T>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeDio fakeDio;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    fakeDio = FakeDio();
    dataSource = AuthRemoteDataSourceImpl(fakeDio);
  });

  group('AuthRemoteDataSourceImpl Login', () {
    test('successful login with nested user map returns UserModel', () async {
      fakeDio.nextResponse = Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/auth/login'),
        data: <String, dynamic>{
          'user': <String, dynamic>{
            'id': 'usr-1',
            'name': 'Test User',
            'email': 'test@restaurant.com',
            'phone': '1234567890',
            'role': 'manager',
          },
        },
        statusCode: 200,
      );

      final user = await dataSource.login('test@restaurant.com', 'password123');

      expect(user.id, equals('usr-1'));
      expect(user.name, equals('Test User'));
      expect(user.role, equals(UserRole.manager));
      expect(fakeDio.lastPath, contains('/login'));
    });

    test('successful login with flat map returns UserModel', () async {
      fakeDio.nextResponse = Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/auth/login'),
        data: <String, dynamic>{
          'id': 'usr-2',
          'name': 'Customer User',
          'email': 'customer@test.com',
          'phone': '0555555555',
          'role': 'customer',
        },
        statusCode: 200,
      );

      final user = await dataSource.login('customer@test.com', 'pass');
      expect(user.id, equals('usr-2'));
      expect(user.role, equals(UserRole.customer));
    });

    test('throws NetworkException when connection timeout occurs', () async {
      fakeDio.nextError = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.connectionTimeout,
      );

      expect(
        () => dataSource.login('a@b.com', 'p'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('throws ServerException on 500 error response', () async {
      fakeDio.nextError = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 500,
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        () => dataSource.login('a@b.com', 'p'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('AuthRemoteDataSourceImpl verifyOtp & refreshToken', () {
    test('verifyOtp returns UserModel on success', () async {
      fakeDio.nextResponse = Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/auth/verify-otp'),
        data: <String, dynamic>{
          'user': <String, dynamic>{
            'id': 'usr-otp',
            'name': 'OTP User',
            'email': 'otp@test.com',
            'phone': '0500000000',
            'role': 'waiter',
          },
        },
        statusCode: 200,
      );

      final user = await dataSource.verifyOtp(otp: '1234', phone: '0500000000');
      expect(user.id, equals('usr-otp'));
      expect(user.role, equals(UserRole.waiter));
    });

    test('refreshToken returns new token string on success', () async {
      fakeDio.nextResponse = Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/auth/refresh'),
        data: <String, dynamic>{'token': 'new_jwt_access_token_123'},
        statusCode: 200,
      );

      final token = await dataSource.refreshToken('old_refresh_token');
      expect(token, equals('new_jwt_access_token_123'));
    });

    test('refreshToken throws ServerException if token missing', () async {
      fakeDio.nextResponse = Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/auth/refresh'),
        data: <String, dynamic>{},
        statusCode: 200,
      );

      expect(
        () => dataSource.refreshToken('old_refresh_token'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('AuthRemoteDataSourceImpl register & logout', () {
    test('register sends payload and returns UserModel', () async {
      fakeDio.nextResponse = Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/auth/register'),
        data: <String, dynamic>{
          'id': 'usr-reg',
          'name': 'New Driver',
          'email': 'driver@test.com',
          'phone': '0511111111',
          'role': 'driver',
        },
        statusCode: 201,
      );

      final user = await dataSource.register(
        name: 'New Driver',
        email: 'driver@test.com',
        phone: '0511111111',
        password: 'secretPassword1',
        restaurantId: 'test-restaurant-id',
        role: UserRole.driver,
      );

      expect(user.id, equals('usr-reg'));
      expect(user.role, equals(UserRole.driver));
    });

    test('logout completes successfully without errors', () async {
      fakeDio.nextResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: '/auth/logout'),
        statusCode: 200,
      );

      await expectLater(dataSource.logout('active_token'), completes);
    });
  });
}
