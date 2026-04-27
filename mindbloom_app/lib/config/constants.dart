class AppConstants {
  // API Base URL - change for production
  // static const String baseUrl = 'http://10.0.2.2:5001'; // Android emulator
  // static const String baseUrl = 'http://localhost:5001'; // iOS simulator
  static const String baseUrl = 'http://10.159.168.148:5001'; // Local network (your Mac IP)
  // static const String baseUrl = 'https://your-render-url.onrender.com'; // Production

  // API Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String signupEndpoint = '/api/auth/signup';
  static const String profileEndpoint = '/api/auth/me';
  static const String updateProfileEndpoint = '/api/auth/profile';
  static const String categoryEndpoint = '/api/auth/category';
  static const String moodCheckinEndpoint = '/api/mood/checkin';
  static const String moodHistoryEndpoint = '/api/mood/history';
  static const String moodWeeklyEndpoint = '/api/mood/weekly';
  static const String moodLatestEndpoint = '/api/mood/latest';
  static const String recommendationsEndpoint = '/api/recommendations/generate';
  static const String appointmentsEndpoint = '/api/appointments';
  static const String trackerEndpoint = '/api/tracker';
  static const String trackerTodayEndpoint = '/api/tracker/today';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String onboardingKey = 'onboarding_complete';

  // Helpline Numbers
  static const List<Map<String, String>> helplines = [
    {'name': 'Vandrevala Foundation', 'number': '9999666555', 'available': '24/7'},
    {'name': 'iCall', 'number': '9152987821', 'available': 'Mon-Sat 8am-10pm'},
    {'name': 'NIMHANS', 'number': '08046110007', 'available': '24/7'},
    {'name': 'Snehi', 'number': '04424640050', 'available': '24/7'},
    {'name': 'AASRA', 'number': '9820466726', 'available': '24/7'},
  ];

  // Mood Emojis
  static const List<String> moodEmojis = ['😢', '😟', '😕', '😐', '🙂', '😊', '😄', '😁', '🤩', '🥳'];

  // Feelings
  static const List<String> feelings = [
    'happy', 'sad', 'anxious', 'calm', 'stressed',
    'energetic', 'tired', 'grateful', 'angry', 'hopeful',
    'lonely', 'loved', 'confused', 'motivated', 'overwhelmed'
  ];

  // Activities
  static const List<String> activities = [
    'exercise', 'meditation', 'reading', 'socializing',
    'work', 'sleep', 'nature', 'music', 'cooking',
    'journaling', 'therapy', 'gaming', 'studying', 'walking'
  ];

  // Categories
  static const List<Map<String, String>> categories = [
    {'key': 'student', 'label': 'Student', 'icon': '🎓', 'desc': 'School or college student'},
    {'key': 'professional', 'label': 'Professional', 'icon': '💼', 'desc': 'Working professional'},
    {'key': 'parent', 'label': 'Parent', 'icon': '👨‍👩‍👧', 'desc': 'Parent or caregiver'},
    {'key': 'senior', 'label': 'Senior', 'icon': '🧓', 'desc': 'Senior citizen'},
    {'key': 'other', 'label': 'Other', 'icon': '🌟', 'desc': 'Other / prefer not to say'},
  ];
}
