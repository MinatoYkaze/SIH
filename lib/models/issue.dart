class IssueMediaModel {
  final String id;
  final String issueId;
  final String mediaUrl;
  final String mediaType;
  final DateTime? createdAt;

  const IssueMediaModel({
    required this.id,
    required this.issueId,
    required this.mediaUrl,
    required this.mediaType,
    this.createdAt,
  });

  factory IssueMediaModel.fromJson(Map<String, dynamic> json) {
    return IssueMediaModel(
      id: json['id'] as String? ?? '',
      issueId: json['issue_id'] as String? ?? '',
      mediaUrl: json['media_url'] as String? ?? '',
      mediaType: json['media_type'] as String? ?? 'image',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issue_id': issueId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class IssueModel {
  final String id;
  final String title;
  final String description;
  final String? category;
  final String? priority;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String reporterId;
  final String? assignedStudentId;
  final double? categoryConfidence;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<IssueMediaModel> media;

  const IssueModel({
    required this.id,
    required this.title,
    required this.description,
    this.category,
    this.priority,
    this.latitude,
    this.longitude,
    this.address,
    required this.reporterId,
    this.assignedStudentId,
    this.categoryConfidence,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.media = const [],
  });

  factory IssueModel.fromJson(Map<String, dynamic> json) {
    final mediaList = (json['media'] as List<dynamic>?)
            ?.map((m) => IssueMediaModel.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [];

    return IssueModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Issue',
      description: json['description'] as String? ?? '',
      category: json['category'] as String?,
      priority: json['priority'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      address: json['address'] as String?,
      reporterId: json['reporter_id'] as String? ?? '',
      assignedStudentId: json['assigned_student_id'] as String?,
      categoryConfidence: json['category_confidence'] != null
          ? (json['category_confidence'] as num).toDouble()
          : null,
      status: json['status'] as String? ?? 'REPORTED',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      media: mediaList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'reporter_id': reporterId,
      'assigned_student_id': assignedStudentId,
      'category_confidence': categoryConfidence,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'media': media.map((m) => m.toJson()).toList(),
    };
  }

  String get displayCategory => category ?? 'General Issue';
  String get displayPriority => priority ?? 'Medium';
  String get displayStatus => status.replaceAll('_', ' ');

  String? get firstImageUrl {
    for (final m in media) {
      if (m.mediaType == 'image' && m.mediaUrl.isNotEmpty) {
        return m.mediaUrl;
      }
    }
    return null;
  }
}

class IssueCreate {
  final String title;
  final String description;
  final String? category;
  final String? priority;
  final double? latitude;
  final double? longitude;
  final String? address;
  final List<String>? mediaUrls;

  const IssueCreate({
    required this.title,
    required this.description,
    this.category,
    this.priority,
    this.latitude,
    this.longitude,
    this.address,
    this.mediaUrls,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
    };
    if (category != null && category!.isNotEmpty) {
      map['category'] = category;
    }
    if (priority != null && priority!.isNotEmpty) {
      map['priority'] = priority;
    }
    if (latitude != null) map['latitude'] = latitude;
    if (longitude != null) map['longitude'] = longitude;
    if (address != null && address!.isNotEmpty) {
      map['address'] = address;
    }
    if (mediaUrls != null && mediaUrls!.isNotEmpty) {
      map['media_urls'] = mediaUrls;
    }
    return map;
  }
}

class IssueListResponse {
  final int total;
  final int page;
  final int pageSize;
  final List<IssueModel> items;

  const IssueListResponse({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.items,
  });

  factory IssueListResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>?)
            ?.map((i) => IssueModel.fromJson(i as Map<String, dynamic>))
            .toList() ??
        [];
    return IssueListResponse(
      total: json['total'] as int? ?? list.length,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? list.length,
      items: list,
    );
  }
}
