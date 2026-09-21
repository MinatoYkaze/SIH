class EvidenceModel {
  final String id;
  final String issueId;
  final String studentId;
  final String mediaUrl;
  final String? description;
  final String evidenceType;
  final DateTime? createdAt;

  const EvidenceModel({
    required this.id,
    required this.issueId,
    required this.studentId,
    required this.mediaUrl,
    this.description,
    required this.evidenceType,
    this.createdAt,
  });

  factory EvidenceModel.fromJson(Map<String, dynamic> json) {
    return EvidenceModel(
      id: json['id'] as String? ?? '',
      issueId: json['issue_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      mediaUrl: json['media_url'] as String? ?? '',
      description: json['description'] as String?,
      evidenceType: json['evidence_type'] as String? ?? 'PROGRESS',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issue_id': issueId,
      'student_id': studentId,
      'media_url': mediaUrl,
      'description': description,
      'evidence_type': evidenceType,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class EvidenceCreate {
  final String mediaUrl;
  final String? description;
  final String evidenceType;

  const EvidenceCreate({
    required this.mediaUrl,
    this.description,
    this.evidenceType = 'PROGRESS',
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'media_url': mediaUrl,
      'evidence_type': evidenceType,
    };
    if (description != null && description!.isNotEmpty) {
      map['description'] = description;
    }
    return map;
  }
}
