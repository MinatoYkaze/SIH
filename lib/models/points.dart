class PointTransactionModel {
  final String userId;
  final int points;
  final String reason;
  final String? issueId;
  final DateTime? createdAt;

  PointTransactionModel({
    required this.userId,
    required this.points,
    required this.reason,
    this.issueId,
    this.createdAt,
  });

  factory PointTransactionModel.fromJson(Map<String, dynamic> json) {
    return PointTransactionModel(
      userId: json['user_id'] as String,
      points: (json['points'] as num).toInt(),
      reason: json['reason'] as String,
      issueId: json['issue_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class PointsModel {
  final int points;
  final List<PointTransactionModel> transactions;

  PointsModel({
    required this.points,
    required this.transactions,
  });

  factory PointsModel.fromJson(Map<String, dynamic> json) {
    return PointsModel(
      points: (json['points'] as num?)?.toInt() ?? 0,
      transactions: (json['transactions'] as List<dynamic>? ?? [])
          .map(
            (item) => PointTransactionModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
