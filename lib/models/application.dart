import 'profile.dart';

class ApplicationModel {
  final String id;
  final String issueId;
  final String studentId;
  final String proposal;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ProfileModel? student;

  const ApplicationModel({
    required this.id,
    required this.issueId,
    required this.studentId,
    required this.proposal,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.student,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id'] as String? ?? '',
      issueId: json['issue_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      proposal: json['proposal'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      student: json['student'] != null
          ? ProfileModel.fromJson(json['student'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issue_id': issueId,
      'student_id': studentId,
      'proposal': proposal,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'student': student?.toJson(),
    };
  }
}

class ApplicationCreate {
  final String proposal;

  const ApplicationCreate({required this.proposal});

  Map<String, dynamic> toJson() => {'proposal': proposal};
}
