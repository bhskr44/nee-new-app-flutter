/// A single passbook entry — an earn or redeem event affecting the user's points balance.
class PointTransactionModel {
  final int id;
  final String type; // earn | redeem | adjust
  final int points;
  final int balanceAfter;
  final String? description;
  final String createdAt;

  const PointTransactionModel({
    required this.id,
    required this.type,
    required this.points,
    required this.balanceAfter,
    this.description,
    required this.createdAt,
  });

  bool get isEarn => type == 'earn';

  factory PointTransactionModel.fromJson(Map<String, dynamic> j) => PointTransactionModel(
        id: j['id'],
        type: j['type'] ?? 'earn',
        points: j['points'] ?? 0,
        balanceAfter: j['balance_after'] ?? 0,
        description: j['description'],
        createdAt: j['created_at'] ?? '',
      );
}

/// A gift the admin has made redeemable for points.
class RewardModel {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int pointsRequired;
  final int? stock;

  const RewardModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.pointsRequired,
    this.stock,
  });

  bool get isAvailable => stock == null || stock! > 0;

  factory RewardModel.fromJson(Map<String, dynamic> j) => RewardModel(
        id: j['id'],
        name: j['name'] ?? '',
        description: j['description'],
        imageUrl: j['image_url'],
        pointsRequired: j['points_required'] ?? 0,
        stock: j['stock'],
      );
}

/// A user's request to redeem points for a reward, tracked through admin fulfillment.
class RewardRedemptionModel {
  final int id;
  final String rewardName;
  final String? rewardImageUrl;
  final int pointsSpent;
  final String status; // pending | approved | rejected | fulfilled
  final String createdAt;

  const RewardRedemptionModel({
    required this.id,
    required this.rewardName,
    this.rewardImageUrl,
    required this.pointsSpent,
    required this.status,
    required this.createdAt,
  });

  factory RewardRedemptionModel.fromJson(Map<String, dynamic> j) {
    final reward = j['reward'] as Map<String, dynamic>?;
    return RewardRedemptionModel(
      id: j['id'],
      rewardName: reward?['name'] ?? '',
      rewardImageUrl: reward?['image_url'],
      pointsSpent: j['points_spent'] ?? 0,
      status: j['status'] ?? 'pending',
      createdAt: j['created_at'] ?? '',
    );
  }
}
