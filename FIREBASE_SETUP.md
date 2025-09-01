# Firebase Setup Guide for Local Lore

This guide will help you set up Firebase for the Local Lore project.

## 🔥 Firebase Project Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `local-lore-app` (or your preferred name)
4. Enable Google Analytics (optional but recommended)
5. Click "Create project"

### 2. Add Apps to Firebase

#### Android App
1. Click "Add app" and select Android
2. **Android package name**: `com.example.runes` (or change in `android/app/build.gradle.kts`)
3. **App nickname**: `Local Lore Android`
4. Download `google-services.json`
5. Place it in `android/app/google-services.json`

#### iOS App (if targeting iOS)
1. Click "Add app" and select iOS
2. **iOS bundle ID**: `com.example.runes` (or change in `ios/Runner.xcodeproj`)
3. **App nickname**: `Local Lore iOS`
4. Download `GoogleService-Info.plist`
5. Place it in `ios/Runner/GoogleService-Info.plist`

## 🗄️ Firestore Database Setup

### 1. Enable Firestore
1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location (choose closest to your users)

### 2. Security Rules
Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Stories are readable by all authenticated users
    match /stories/{storyId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (resource == null || request.auth.uid == resource.data.authorId);
    }
    
    // Categories are read-only for all authenticated users
    match /categories/{categoryId} {
      allow read: if request.auth != null;
      allow write: if false; // Only admins can write (via admin SDK)
    }
  }
}
```

### 3. Create Collections

#### Users Collection
```javascript
// Document structure for /users/{userId}
{
  "uid": "user_unique_id",
  "email": "user@example.com",
  "displayName": "User Name",
  "photoURL": "https://...",
  "createdAt": timestamp,
  "updatedAt": timestamp,
  "storiesCount": 0,
  "bio": "User bio..."
}
```

#### Stories Collection
```javascript
// Document structure for /stories/{storyId}
{
  "id": "story_unique_id",
  "title": "Story Title",
  "description": "Story description...",
  "category": "folklore", // folklore, historical, architecture, legend
  "location": {
    "latitude": 40.7128,
    "longitude": -74.0060,
    "address": "New York, NY"
  },
  "authorId": "user_unique_id",
  "authorName": "Author Name",
  "images": ["https://storage.url/image1.jpg"],
  "createdAt": timestamp,
  "updatedAt": timestamp,
  "isPublished": true,
  "likes": 0,
  "views": 0
}
```

#### Categories Collection
```javascript
// Document structure for /categories/{categoryId}
{
  "id": "folklore",
  "name": "Folklore",
  "description": "Local folklore and traditional stories",
  "icon": "folklore_icon",
  "color": "#FF6B6B",
  "isActive": true
}
```

## 🔐 Authentication Setup

### 1. Enable Authentication
1. Go to "Authentication" in Firebase Console
2. Click "Get started"
3. Go to "Sign-in method" tab

### 2. Enable Sign-in Methods
- **Email/Password**: Enable for basic authentication
- **Google**: Enable for social login (recommended)

### 3. Configure Google Sign-in (Optional)
1. Download the configuration files again after enabling Google sign-in
2. For Android: Ensure SHA-1 fingerprint is added
3. For iOS: Ensure URL schemes are configured

## 💾 Storage Setup

### 1. Enable Storage
1. Go to "Storage" in Firebase Console
2. Click "Get started"
3. Choose security rules (start in test mode)
4. Select storage location

### 2. Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Images can be uploaded by authenticated users
    match /story_images/{userId}/{fileName} {
      allow read: if true; // Anyone can view images
      allow write: if request.auth != null && 
        request.auth.uid == userId &&
        request.resource.size < 10 * 1024 * 1024 && // 10MB limit
        request.resource.contentType.matches('image/.*');
    }
    
    // Profile pictures
    match /profile_images/{userId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null && 
        request.auth.uid == userId &&
        request.resource.size < 5 * 1024 * 1024 && // 5MB limit
        request.resource.contentType.matches('image/.*');
    }
  }
}
```

## 🗺️ Google Maps API Setup

### 1. Enable APIs
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (or create one)
3. Enable these APIs:
   - Maps SDK for Android
   - Maps SDK for iOS (if using iOS)
   - Places API
   - Geocoding API

### 2. Create API Key
1. Go to "Credentials" in Google Cloud Console
2. Click "Create Credentials" > "API Key"
3. Copy the API key

### 3. Restrict API Key (Recommended)
1. Click on your API key
2. Under "Application restrictions":
   - For Android: Add package name and SHA-1 fingerprint
   - For iOS: Add bundle identifier
3. Under "API restrictions": Select the APIs you enabled

### 4. Add API Key to Project
Create `android/local.properties` file:
```properties
MAPS_API_KEY=your_api_key_here
```

## 📱 Final Configuration

### 1. Update App Configuration
Ensure your `firebase_options.dart` is generated and up to date:
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

### 2. Test Configuration
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

## 🔒 Security Best Practices

1. **Never commit**: 
   - `google-services.json`
   - `GoogleService-Info.plist`
   - API keys
   - `local.properties`

2. **Use environment-specific projects**:
   - Development project for testing
   - Production project for live app

3. **Implement proper security rules**:
   - Validate data on server side
   - Implement rate limiting
   - Use field-level security

4. **Monitor usage**:
   - Set up billing alerts
   - Monitor API usage
   - Implement quota limits

## 🚨 Troubleshooting

### Common Issues

**Build fails with google-services.json not found**
- Ensure file is in `android/app/` directory
- Verify file is not in `.gitignore`
- Clean and rebuild project

**Maps not loading**
- Check API key is correct
- Verify APIs are enabled
- Check billing is enabled in Google Cloud

**Authentication not working**
- Verify SHA-1 fingerprint is added
- Check package name matches
- Ensure auth methods are enabled

**Firestore permission denied**
- Check security rules
- Verify user is authenticated
- Validate document structure

## 📞 Support

If you encounter issues:
1. Check the [Firebase documentation](https://firebase.google.com/docs)
2. Review [FlutterFire documentation](https://firebase.flutter.dev/)
3. Open an issue in the project repository
4. Join our Discord community for help

---

**Happy coding! 🔥📱**
