import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/auth/data/datasources/demo_auth_datasource.dart';
import 'package:restaurant_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:restaurant_app/features/auth/domain/usecases/register_usecase.dart';
import 'package:restaurant_app/core/storage/in_memory_secure_storage_service.dart';

void main() {
  group('Register Flow Unit Tests', () {
    late AuthRepositoryImpl repository;
    late RegisterUseCase registerUseCase;

    setUp(() {
      final remote = DemoAuthRemoteDataSource();
      final storage = InMemorySecureStorageService();
      repository = AuthRepositoryImpl(
        remoteDataSource: remote,
        secureStorage: storage,
      );
      registerUseCase = RegisterUseCase(repository);
    });

    test('validates empty name properly', () async {
      final result = await registerUseCase(
        name: '',
        email: 'test@example.com',
        phone: '0501234567',
        password: 'password123',
        restaurantId: 'test-restaurant-id',
      );
      expect(result.isLeft, isTrue);
    });

    test('validates invalid email properly', () async {
      final result = await registerUseCase(
        name: 'أحمد',
        email: 'invalid-email',
        phone: '0501234567',
        password: 'password123',
        restaurantId: 'test-restaurant-id',
      );
      expect(result.isLeft, isTrue);
    });

    test('validates short password properly', () async {
      final result = await registerUseCase(
        name: 'أحمد',
        email: 'test@example.com',
        phone: '0501234567',
        password: '123',
        restaurantId: 'test-restaurant-id',
      );
      expect(result.isLeft, isTrue);
    });

    test('registers successfully with valid customer data', () async {
      final result = await registerUseCase(
        name: 'خالد المنصور',
        email: 'khaled@example.com',
        phone: '0501234567',
        password: 'password123',
        restaurantId: 'test-restaurant-id',
        role: UserRole.customer,
      );
      expect(result.isRight, isTrue);
      final user = result.when(onLeft: (_) => null, onRight: (u) => u);
      expect(user, isNotNull);
      expect(user!.name, 'خالد المنصور');
      expect(user.role, UserRole.customer);
    });
  });
}
