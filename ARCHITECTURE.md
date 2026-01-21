# School Parent App - Architecture Documentation

## Overview
This document describes the architecture and structure of the School Parent App, a production-grade Flutter application.

## Architecture Pattern
The app follows **Clean Architecture** principles with clear separation of concerns across layers:

1. **Presentation Layer** - UI, widgets, screens, state management
2. **Domain Layer** - Business logic, entities, use cases
3. **Data Layer** - Models, repositories, data sources
4. **Infrastructure Layer** - Network, storage, external services
5. **Core Layer** - Constants, utilities, configuration, routing

## Project Structure

```
lib/
├── core/                           # Core functionality
│   ├── constants/                  # App-wide constants
│   │   ├── app_constants.dart
│   │   └── api_endpoints.dart
│   ├── config/                     # Configuration
│   │   └── app_config.dart
│   ├── errors/                     # Error handling
│   │   └── failures.dart
│   ├── routes/                     # Routing
│   │   └── app_routes.dart
│   └── utils/                      # Utilities
│       ├── validators.dart
│       ├── date_formatter.dart
│       └── result.dart
│
├── data/                           # Data layer
│   ├── models/                     # Data models
│   │   ├── user_model.dart
│   │   ├── homework_model.dart
│   │   └── notification_model.dart
│   └── repositories/               # Repository implementations
│       └── auth_repository.dart
│
├── domain/                         # Domain layer (Business logic)
│   ├── entities/                   # Business entities
│   └── usecases/                   # Use cases
│
├── infrastructure/                 # Infrastructure layer
│   ├── network/                    # Network configuration
│   │   └── dio_client.dart
│   └── storage/                    # Storage services
│       └── storage_service.dart
│
├── presentation/                   # Presentation layer
│   ├── core/                       # Core presentation components
│   │   ├── theme/                  # Theme configuration
│   │   │   └── app_theme.dart
│   │   └── widgets/                # Reusable widgets
│   │       ├── custom_app_bar.dart
│   │       ├── loading_indicator.dart
│   │       ├── error_widget.dart
│   │       ├── empty_state_widget.dart
│   │       └── custom_text_field.dart
│   │
│   └── features/                   # Feature-based modules
│       ├── auth/                   # Authentication feature
│       │   ├── screens/
│       │   ├── widgets/
│       │   └── providers/          # State management (if using providers)
│       ├── home/                   # Home feature
│       ├── homework/               # Homework feature
│       ├── notifications/          # Notifications feature
│       ├── attendance/             # Attendance feature
│       ├── fees/                   # Fees feature
│       ├── leave/                  # Leave feature
│       └── ...                     # Other features
│
├── services/                       # External services (legacy, to be refactored)
│   ├── auth_service.dart
│   ├── mock_backend.dart
│   └── ...
│
├── l10n/                           # Localization
│   └── ...
│
└── main.dart                       # Application entry point
```

## Key Principles

### 1. Separation of Concerns
- Each layer has a specific responsibility
- Layers communicate through well-defined interfaces
- Changes in one layer don't affect others unnecessarily

### 2. Dependency Rule
- Inner layers don't know about outer layers
- Dependencies point inward
- Domain layer is independent

### 3. Single Responsibility
- Each class/function has one reason to change
- Features are organized into modules
- Widgets are small and focused

### 4. Feature-Based Organization
- Related code is grouped together
- Easy to find and maintain
- Scales well with team growth

## Data Flow

```
UI (Screen/Widget)
    ↓
Use Case / Provider
    ↓
Repository Interface
    ↓
Repository Implementation
    ↓
Data Source (API/Local Storage)
```

## State Management
- Currently uses setState and local state
- Can be extended with Provider, Bloc, or Riverpod
- State management lives in feature folders

## Network Layer
- Uses Dio for HTTP requests
- Mock backend interceptor for development/testing
- Centralized error handling
- Token management

## Storage Layer
- Uses Hive for local storage
- StorageService for abstraction
- Supports multiple storage boxes

## Error Handling
- Custom Failure classes
- Result type for success/failure states
- Centralized error handling in Dio interceptor

## Testing Strategy
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for features
- Test files mirror source structure

## Future Improvements
1. Add dependency injection (GetIt, Injectable)
2. Implement proper state management (Provider/Bloc)
3. Add comprehensive test coverage
4. Implement analytics
5. Add crash reporting
6. Performance monitoring
7. Code generation for models
8. API documentation

## Naming Conventions
- Files: snake_case.dart
- Classes: PascalCase
- Variables: camelCase
- Constants: UPPER_SNAKE_CASE
- Private members: _leadingUnderscore

## Code Style
- Follow Flutter style guide
- Use meaningful names
- Keep functions small (< 50 lines)
- Comment complex logic
- Use const constructors where possible

