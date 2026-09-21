class SolutionReviewModel {
  final String id;
  final String solutionId;
  final String reviewerId;
  final int? rating;
  final String feedback;
  final DateTime? createdAt;

  const SolutionReviewModel({
    required this.id,
    required this.solutionId,
    required this.reviewerId,
    this.rating,
    required this.feedback,
    this.createdAt,
  });

  factory SolutionReviewModel.fromJson(Map<String, dynamic> json) {
    return SolutionReviewModel(
      id: json['id'] as String? ?? '',
      solutionId: json['solution_id'] as String? ?? '',
      reviewerId: json['reviewer_id'] as String? ?? '',
      rating: json['rating'] as int?,
      feedback: json['feedback'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'solution_id': solutionId,
      'reviewer_id': reviewerId,
      'rating': rating,
      'feedback': feedback,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class SolutionModel {
  final String id;
  final String issueId;
  final String studentId;
  final String title;
  final String description;
  final String? pdfUrl;
  final String? prototypeUrl;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<SolutionReviewModel> reviews;

  const SolutionModel({
    required this.id,
    required this.issueId,
    required this.studentId,
    required this.title,
    required this.description,
    this.pdfUrl,
    this.prototypeUrl,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.reviews = const [],
  });

  factory SolutionModel.fromJson(Map<String, dynamic> json) {
    final reviewsList = (json['reviews'] as List<dynamic>?)
            ?.map((r) => SolutionReviewModel.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    return SolutionModel(
      id: json['id'] as String? ?? '',
      issueId: json['issue_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      pdfUrl: json['pdf_url'] as String?,
      prototypeUrl: json['prototype_url'] as String?,
      status: json['status'] as String? ?? 'DRAFT',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      reviews: reviewsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issue_id': issueId,
      'student_id': studentId,
      'title': title,
      'description': description,
      'pdf_url': pdfUrl,
      'prototype_url': prototypeUrl,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'reviews': reviews.map((r) => r.toJson()).toList(),
    };
  }
}

class SolutionCreate {
  final String title;
  final String description;
  final String? pdfUrl;
  final String? prototypeUrl;

  const SolutionCreate({
    required this.title,
    required this.description,
    this.pdfUrl,
    this.prototypeUrl,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
    };
    if (pdfUrl != null) map['pdf_url'] = pdfUrl;
    if (prototypeUrl != null) map['prototype_url'] = prototypeUrl;
    return map;
  }
}

class SolutionReviewCreate {
  final int? rating;
  final String feedback;

  const SolutionReviewCreate({this.rating, required this.feedback});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'feedback': feedback};
    if (rating != null) map['rating'] = rating;
    return map;
  }
}
