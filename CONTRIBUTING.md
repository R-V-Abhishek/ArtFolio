# Contributing to Local Lore

Thank you for your interest in contributing to Local Lore! We welcome contributions from developers of all skill levels.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.10.0+)
- Android Studio or VS Code
- Git
- Firebase account
- Google Maps API key

### Setting up the Development Environment

1. **Fork and Clone**
   ```bash
   git clone https://github.com/YOUR_USERNAME/local-lore-app.git
   cd local-lore-app
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create your own Firebase project for testing
   - Add your `google-services.json` and `GoogleService-Info.plist`
   - Set up your `local.properties` with your Maps API key

## 📋 Development Guidelines

### Code Style
- Follow [Flutter's style guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused

### Commit Messages
Use the conventional commit format:
```
type(scope): description

feat(map): add story clustering functionality
fix(auth): resolve login error handling
docs(readme): update installation instructions
```

### Branch Naming
- `feature/feature-name` for new features
- `fix/bug-description` for bug fixes
- `docs/documentation-update` for documentation
- `refactor/component-name` for refactoring

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models (Story, User, etc.)
├── screens/                  # UI screens
│   ├── map/                  # Map-related screens
│   ├── auth/                 # Authentication screens
│   └── profile/              # User profile screens
├── widgets/                  # Reusable UI components
├── services/                 # Firebase and API services
├── utils/                    # Helper functions and constants
└── providers/                # State management (if using Provider)
```

## 👥 Team Roles & Responsibilities

### Person A - UI/UX & Frontend 🎨
**Focus Areas:**
- Flutter widgets and screens
- User interface design
- User experience optimization
- Responsive design

**Key Files:**
- `lib/screens/`
- `lib/widgets/`
- Theme and styling components

### Person B - Backend & Database 🗄️
**Focus Areas:**
- Firebase Firestore database design
- User authentication
- Data models and validation
- Security rules

**Key Files:**
- `lib/models/`
- `lib/services/firebase_service.dart`
- `lib/services/auth_service.dart`
- Firebase security rules

### Person C - Features & Integration 🔧
**Focus Areas:**
- Google Maps integration
- Location services
- Image upload functionality
- Search and filtering logic

**Key Files:**
- `lib/services/maps_service.dart`
- `lib/services/location_service.dart`
- `lib/services/storage_service.dart`
- Map-related widgets

## 🧪 Testing

### Running Tests
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter drive --target=test_driver/app.dart
```

### Writing Tests
- Write unit tests for services and utilities
- Write widget tests for UI components
- Write integration tests for critical user flows
- Aim for >80% code coverage

## 📝 Pull Request Process

1. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**
   - Write clean, well-documented code
   - Add tests for new functionality
   - Update documentation if needed

3. **Test Your Changes**
   ```bash
   flutter test
   flutter analyze
   ```

4. **Commit and Push**
   ```bash
   git add .
   git commit -m "feat(component): add new feature"
   git push origin feature/your-feature-name
   ```

5. **Create Pull Request**
   - Use the PR template
   - Include screenshots for UI changes
   - Reference any related issues

## 🐛 Reporting Bugs

When reporting bugs, please include:
- Device and OS version
- Flutter version
- Steps to reproduce
- Expected vs actual behavior
- Screenshots or error logs

## 💡 Feature Requests

For new features:
- Check existing issues first
- Provide clear use cases
- Consider implementation complexity
- Discuss design implications

## 📋 Code Review Checklist

### For Reviewers
- [ ] Code follows project conventions
- [ ] Tests are included and pass
- [ ] Documentation is updated
- [ ] No hardcoded values or API keys
- [ ] Performance considerations addressed
- [ ] UI/UX is consistent with design

### For Contributors
- [ ] Self-review completed
- [ ] Tests written and passing
- [ ] Documentation updated
- [ ] Breaking changes documented
- [ ] Performance impact considered

## 🌟 Recognition

Contributors will be:
- Listed in the project README
- Mentioned in release notes
- Invited to join the core team (for significant contributions)

## 📞 Getting Help

- **Discord**: [Join our community server]
- **Email**: contribute@locallore.app
- **Issues**: Use GitHub issues for bugs and features
- **Discussions**: Use GitHub discussions for questions

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Google Maps API](https://developers.google.com/maps/documentation)
- [Material Design Guidelines](https://material.io/design)

Thank you for contributing to Local Lore! 🗺️✨
