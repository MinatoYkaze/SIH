class ProfileModel {
  final String id;
  final String name;
  final String role;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? location;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.id,
    required this.name,
    required this.role,
    this.phoneNumber,
    this.avatarUrl,
    this.location,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Anonymous',
      role: (json['role'] as String? ?? 'citizen').toLowerCase(),
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      location: json['location'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'location': location,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? name,
    String? role,
    String? phoneNumber,
    String? avatarUrl,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ProfileCreate {
  final String name;
  final String role;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? location;

  const ProfileCreate({
    required this.name,
    required this.role,
    this.phoneNumber,
    this.avatarUrl,
    this.location,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'role': role.toLowerCase(),
    };
    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      map['phone_number'] = phoneNumber;
    }
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      map['avatar_url'] = avatarUrl;
    }
    if (location != null && location!.isNotEmpty) {
      map['location'] = location;
    }
    return map;
  }
}
