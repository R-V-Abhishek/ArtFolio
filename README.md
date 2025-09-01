# 🗺️ Local Lore - Interactive Map of Stories

**Local Lore** is a community-driven mobile application that transforms your surroundings into an interactive atlas of folklore, hidden histories, and cultural landmarks. Built with Flutter and powered by Firebase, this app lets users explore and contribute to a rich tapestry of local stories and discoveries.

## 📱 App Overview

Local Lore bridges the gap between digital exploration and local storytelling, creating a living map where every pin represents a piece of cultural heritage, folklore, or historical significance. Whether you're a history enthusiast, a local storyteller, or simply curious about your surroundings, Local Lore invites you to discover and share the hidden narratives that make every place unique.

## ✨ Core Features

### 🗺️ **Interactive Map**
- Browse an intuitive map interface with pins representing stories and landmarks
- Seamless navigation with zoom, pan, and location-based exploration
- Real-time loading of nearby points of interest

### 📝 **Story Submission**
- Easy-to-use submission form for contributing new stories
- Support for multiple categories: Folklore, Historical Events, Architecture, Local Legends
- Photo upload capabilities to enrich story content
- GPS integration for precise location tagging

### 👤 **User Profiles**
- Personal profiles showcasing user contributions
- Track your storytelling journey and impact on the community
- View submission history and favorite stories

### 🔍 **Smart Filtering**
- Filter map content by story categories
- Search for specific types of landmarks or events
- Discover content based on your interests

### 📍 **Location-Based Discovery**
- GPS-powered "nearby stories" feature
- Explore local content wherever you are
- Distance-based story recommendations

## 🛠️ Technical Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase Firestore
- **Authentication**: Firebase Auth
- **Storage**: Firebase Storage (for images)
- **Maps**: Google Maps SDK
- **Platform**: Android & iOS

## 🏗️ Project Architecture

This project follows a modular architecture designed for a 3-person development team:

### **Person A - UI/UX & Frontend** 🎨
- **Responsibilities**: 
  - Flutter UI development with modern design principles
  - Screen implementations: Map view, Story submission, Story details, User profiles
  - User experience optimization and responsive design
- **Technologies**: Flutter, Dart, Material Design

### **Person B - Backend & Database** 🗄️
- **Responsibilities**:
  - Firebase Firestore database design and management
  - User authentication and account management
  - Data models and API structure
- **Technologies**: Firebase Firestore, Firebase Auth, Cloud Functions

### **Person C - Features & Integration** 🔧
- **Responsibilities**:
  - Google Maps SDK integration and customization
  - Location services and GPS functionality
  - Image upload and storage management
  - Data filtering and search logic
- **Technologies**: Google Maps SDK, Firebase Storage, Location Services

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.10.0 or higher)
- Android Studio / VS Code
- Firebase account
- Google Maps API key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/local-lore-app.git
   cd local-lore-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Add Android/iOS apps to your Firebase project
   - Download and place `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Enable Firestore, Authentication, and Storage in Firebase Console

4. **Google Maps Setup**
   - Get a Google Maps API key from Google Cloud Console
   - Add the API key to `android/local.properties`:
     ```
     MAPS_API_KEY=your_api_key_here
     ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 📂 Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
├── screens/                  # UI screens
├── widgets/                  # Reusable widgets
├── services/                 # Firebase services
└── utils/                    # Helper utilities
```

## 🔥 Firebase Configuration

The app uses the following Firebase services:
- **Firestore**: Story data, user profiles, categories
- **Authentication**: Email/password and Google sign-in
- **Storage**: Image uploads for stories
- **Cloud Functions**: Optional backend logic

## 🗺️ Google Maps Integration

- Custom map styling for enhanced user experience
- Custom markers for different story categories
- Location clustering for dense areas
- Offline map caching support

## 🤝 Contributing

We welcome contributions from the community! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Commit your changes** (`git commit -m 'Add amazing feature'`)
4. **Push to the branch** (`git push origin feature/amazing-feature`)
5. **Open a Pull Request**

### Development Guidelines
- Follow Flutter's official style guide
- Write meaningful commit messages
- Add tests for new features
- Update documentation as needed

## 📝 Roadmap

- [ ] **Phase 1**: Core map and story submission functionality
- [ ] **Phase 2**: Enhanced filtering and search capabilities
- [ ] **Phase 3**: Social features (comments, ratings, sharing)
- [ ] **Phase 4**: Offline mode and advanced caching
- [ ] **Phase 5**: Admin panel for content moderation

## 🐛 Known Issues

- Initial map loading may take a few seconds on slower networks
- Image uploads are limited to 10MB per story
- Location services must be enabled for full functionality

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Thanks to the Flutter and Firebase teams for excellent documentation
- Google Maps team for robust mapping capabilities
- The open-source community for inspiration and support

## 📞 Contact

- **Project Maintainer**: [Your Name]
- **Email**: your.email@example.com
- **Project Link**: https://github.com/yourusername/local-lore-app

---

**Made with ❤️ by the Local Lore Team**

*Discover the stories that make every place special*
