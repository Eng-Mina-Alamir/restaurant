import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/loyalty_entity.dart';

abstract class LoyaltyRepository {
  Future<Either<Failure, LoyaltyAccount>> getAccount(String userId);

  Future<Either<Failure, LoyaltyAccount>> earnPoints({
    required String userId,
    required double orderTotal,
    required String orderId,
  });

  Future<Either<Failure, LoyaltyAccount>> redeemReward({
    required String userId,
    required LoyaltyReward reward,
  });

  Future<Either<Failure, List<LoyaltyReward>>> getAvailableRewards();
}
