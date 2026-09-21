import 'profile.dart';

class SponsorshipModel {
  final String id;
  final String issueId;
  final String industrialistId;
  final double amount;
  final String? message;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ProfileModel? industrialist;

  const SponsorshipModel({
    required this.id,
    required this.issueId,
    required this.industrialistId,
    required this.amount,
    this.message,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.industrialist,
  });

  factory SponsorshipModel.fromJson(Map<String, dynamic> json) {
    return SponsorshipModel(
      id: json['id'] as String? ?? '',
      issueId: json['issue_id'] as String? ?? '',
      industrialistId: json['industrialist_id'] as String? ?? '',
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : 0.0,
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'PLEDGED',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      industrialist: json['industrialist'] != null
          ? ProfileModel.fromJson(json['industrialist'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issue_id': issueId,
      'industrialist_id': industrialistId,
      'amount': amount,
      'message': message,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'industrialist': industrialist?.toJson(),
    };
  }
}

class SponsorshipCreate {
  final double amount;
  final String? message;

  const SponsorshipCreate({
    required this.amount,
    this.message,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'amount': amount};
    if (message != null && message!.isNotEmpty) {
      map['message'] = message;
    }
    return map;
  }
}
