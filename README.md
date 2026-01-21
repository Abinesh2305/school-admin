# School Parent App

A production-grade Flutter application for school-parent communication and student management.

## 🏗️ Architecture

This project follows **Clean Architecture** principles with clear separation of concerns:

- **Core Layer**: Constants, configuration, utilities, error handling
- **Data Layer**: Models, repositories, data sources
- **Domain Layer**: Business logic, entities, use cases (to be implemented)
- **Presentation Layer**: UI, widgets, screens organized by features
- **Infrastructure Layer**: Network, storage, external services

See [ARCHITECTURE.md](./ARCHITECTURE.md) for detailed architecture documentation.

## 📁 Project Structure

```
lib/
├── core/                    # Core functionality
│   ├── constants/          # App-wide constants
│   ├── config/             # Configuration
│   ├── errors/             # Error handling
│   ├── routes/             # Routing
│   └── utils/              # Utilities
│
├── data/                   # Data layer
│   ├── models/            # Data models
│   └── repositories/      # Repository implementations
│
├── domain/                 # Domain layer (Business logic)
│   ├── entities/
│   └── usecases/
│
├── infrastructure/         # Infrastructure layer
│   ├── network/           # Network configuration
│   └── storage/           # Storage services
│
├── presentation/           # Presentation layer
│   ├── core/              # Core presentation components
│   │   ├── theme/        # Theme configuration
│   │   └── widgets/      # Reusable widgets
│   └── features/          # Feature-based modules
│
└── services/              # External services (legacy)
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- Firebase account (for push notifications)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd school_parent_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup Firebase**
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Configure Firebase in your project

4. **Configure environment** (Optional)
   - Create `.env` file in the root directory
   - Add your configuration:
     ```
     BASE_URL=https://your-api-url.com
     SCHOOL_ID=1
     APP_NAME=School Parent App
     ```
   - Note: The app works with mock backend if `.env` is not provided

5. **Run the app**
   ```bash
   flutter run
   ```

## 🧪 Development

### Mock Backend

The app includes a comprehensive mock backend for development and testing. All API calls return realistic dummy data without requiring a real backend server.

### Code Style

- Follow Flutter style guide
- Use meaningful names
- Keep functions small and focused
- Add comments for complex logic
- Use `const` constructors where possible

### Naming Conventions

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables: `camelCase`
- Constants: `UPPER_SNAKE_CASE`
- Private members: `_leadingUnderscore`

## 📱 Features

- 🔐 Authentication (Login, OTP, Password Reset)
- 🏠 Home Dashboard
- 📚 Homework Management
- 🔔 Notifications & Communications
- 📊 Attendance Tracking
- 💰 Fee Management
- 🎓 Leave Management
- 📝 Exams & Results
- 📁 Document Management
- 📷 Gallery
- 👥 Contacts
- 🌐 Multi-language Support (English/Tamil)
- 🌓 Light/Dark Theme

## 🛠️ Technologies Used

- **Flutter** - UI Framework
- **Dart** - Programming Language
- **Firebase** - Push Notifications
- **Hive** - Local Storage
- **Dio** - HTTP Client
- **Provider/Bloc** - State Management (to be implemented)

## 📦 Dependencies

Key dependencies:
- `firebase_core` - Firebase integration
- `firebase_messaging` - Push notifications
- `hive` - Local database
- `dio` - HTTP client
- `google_fonts` - Typography
- `flutter_localizations` - Internationalization

See `pubspec.yaml` for complete list.

## 🧩 Project Status

- ✅ Core architecture setup
- ✅ Mock backend implementation
- ✅ Basic feature modules
- ✅ Theme and styling
- ⏳ State management implementation
- ⏳ Dependency injection
- ⏳ Comprehensive testing
- ⏳ Performance optimization

## 📄 License

[Add your license information here]

## 👥 Contributors

[Add contributor information here]

## 📞 Support

For support, email [your-email] or create an issue in the repository.

---

**Note**: This is a production-ready structure designed for scalability and maintainability.
