# 🌸 MindBloom — Mental Wellness App

A beautifully designed Flutter application for mental wellness tracking, mood check-ins, meditation, breathing exercises, and connecting with professional help.

## ✨ Features

- **Mood Check-ins** — Log your daily mood with a rich emoji-based selector, track feelings and activities
- **Dashboard** — View your wellness score, streak, 7-day mood trends with interactive charts
- **Meditation & Breathing** — Guided meditation sessions and breathing exercises for calm
- **Wellness Tracker** — Track sleep, water intake, exercise, and screen time
- **SOS Support** — Quick access to helpline numbers and emergency contacts
- **Nearby Professionals** — Find therapists and mental health professionals near you
- **Appointments** — Schedule and manage therapy appointments
- **Personalized Recommendations** — AI-powered wellness recommendations based on your mood patterns
- **Dark Mode** — Full dark theme support for comfortable nighttime use
- **Onboarding** — Smooth onboarding flow with category selection

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.11+ |
| State Management | Riverpod |
| Routing | GoRouter |
| HTTP Client | Dio |
| Charts | fl_chart |
| Maps | flutter_map + Geolocator |
| Audio | just_audio + audio_service |
| Animations | flutter_animate + Lottie |
| Storage | flutter_secure_storage + SharedPreferences |
| Typography | Google Fonts (Inter) |

## 📁 Project Structure

```
lib/
├── config/
│   ├── constants.dart      # API endpoints, helplines, moods
│   ├── routes.dart         # GoRouter configuration
│   └── theme.dart          # Light & dark theme definitions
├── models/
│   ├── appointment_model.dart
│   ├── mood_model.dart
│   ├── recommendation_model.dart
│   ├── tracker_model.dart
│   └── user_model.dart
├── providers/
│   ├── auth_provider.dart
│   ├── mood_provider.dart
│   ├── recommendation_provider.dart
│   └── theme_provider.dart
├── screens/
│   ├── appointments/       # Appointment scheduling
│   ├── auth/               # Login & signup
│   ├── breathing/          # Breathing exercises
│   ├── category/           # User category selection
│   ├── checkin/            # Mood check-in flow
│   ├── dashboard/          # Main dashboard
│   ├── meditation/         # Meditation sessions
│   ├── mood_history/       # Mood history & analytics
│   ├── nearby/             # Nearby professionals map
│   ├── onboarding/         # Onboarding screens
│   ├── profile/            # User profile
│   ├── recommendations/    # AI recommendations
│   ├── sos/                # Emergency SOS
│   └── tracker/            # Wellness tracker
├── services/
│   └── api_service.dart    # Dio-based API client
├── widgets/
│   ├── app_shell.dart      # Bottom navigation shell
│   ├── custom_button.dart  # Reusable button component
│   ├── custom_card.dart    # Reusable card component
│   ├── mood_selector.dart  # Emoji mood picker
│   └── sos_overlay.dart    # SOS bottom sheet
└── main.dart               # App entry point
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.11.0`
- Dart SDK `^3.11.0`
- Android Studio / Xcode (for mobile builds)

### Setup

```bash
# Clone the repository
git clone https://github.com/Pushpendra-7-ux/MindBloom.git
cd MindBloom/mindbloom_app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## 📱 Screenshots

*Coming soon*

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

---

Built with 💜 by [Pushpendra](https://github.com/Pushpendra-7-ux)
