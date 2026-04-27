class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String category;
  final EmergencyContact? emergencyContact;
  final UserPreferences preferences;
  final Streak streak;
  final int wellnessScore;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.category = 'other',
    this.emergencyContact,
    UserPreferences? preferences,
    Streak? streak,
    this.wellnessScore = 50,
  })  : preferences = preferences ?? UserPreferences(),
        streak = streak ?? Streak();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatar: json['avatar'],
      category: json['category'] ?? 'other',
      emergencyContact: json['emergencyContact'] != null
          ? EmergencyContact.fromJson(json['emergencyContact'])
          : null,
      preferences: json['preferences'] != null
          ? UserPreferences.fromJson(json['preferences'])
          : UserPreferences(),
      streak: json['streak'] != null
          ? Streak.fromJson(json['streak'])
          : Streak(),
      wellnessScore: json['wellnessScore'] ?? 50,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'avatar': avatar,
    'category': category,
    'emergencyContact': emergencyContact?.toJson(),
    'preferences': preferences.toJson(),
    'streak': streak.toJson(),
    'wellnessScore': wellnessScore,
  };

  UserModel copyWith({
    String? name,
    String? phone,
    String? category,
    EmergencyContact? emergencyContact,
    UserPreferences? preferences,
    Streak? streak,
    int? wellnessScore,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      avatar: avatar,
      category: category ?? this.category,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      preferences: preferences ?? this.preferences,
      streak: streak ?? this.streak,
      wellnessScore: wellnessScore ?? this.wellnessScore,
    );
  }
}

class EmergencyContact {
  final String name;
  final String phone;
  final String relation;

  EmergencyContact({this.name = '', this.phone = '', this.relation = ''});

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      relation: json['relation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone, 'relation': relation};
}

class UserPreferences {
  final bool darkMode;
  final bool notifications;
  final String reminderTime;

  UserPreferences({this.darkMode = false, this.notifications = true, this.reminderTime = '09:00'});

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      darkMode: json['darkMode'] ?? false,
      notifications: json['notifications'] ?? true,
      reminderTime: json['reminderTime'] ?? '09:00',
    );
  }

  Map<String, dynamic> toJson() => {
    'darkMode': darkMode,
    'notifications': notifications,
    'reminderTime': reminderTime,
  };
}

class Streak {
  final int current;
  final int longest;
  final DateTime? lastCheckIn;

  Streak({this.current = 0, this.longest = 0, this.lastCheckIn});

  factory Streak.fromJson(Map<String, dynamic> json) {
    return Streak(
      current: json['current'] ?? 0,
      longest: json['longest'] ?? 0,
      lastCheckIn: json['lastCheckIn'] != null ? DateTime.tryParse(json['lastCheckIn']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'current': current,
    'longest': longest,
    'lastCheckIn': lastCheckIn?.toIso8601String(),
  };
}
