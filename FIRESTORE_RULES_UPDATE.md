# 🔥 Firestore Rules Update Required

## Issue
The app was crashing because the Firestore security rules don't include permissions for the new messaging features (conversations and messages collections).

## Solution
You need to manually update the Firestore security rules in the Firebase Console.

## Steps to Update:

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your ArtFolio project**
3. **Navigate to**: Firestore Database → Rules (tab at the top)
4. **Copy the updated rules** from `firestore.rules` file in this project
5. **Paste** into the Firebase Console rules editor
6. **Click "Publish"**

## What Was Added:

The following rules were added to `firestore.rules`:

```
// Conversations collection - for direct messaging
match /conversations/{conversationId} {
  allow read: if isAuthenticated() && 
    request.auth.uid in resource.data.participants;
  
  allow create: if isAuthenticated() && 
    request.auth.uid in request.resource.data.participants &&
    request.resource.data.participants.size() == 2;
  
  allow update: if isAuthenticated() && 
    request.auth.uid in resource.data.participants;
  
  allow delete: if false;
}

// Messages collection - for direct messaging
match /messages/{messageId} {
  allow read: if isAuthenticated() && (
    request.auth.uid == resource.data.senderId ||
    request.auth.uid == resource.data.receiverId
  );
  
  allow create: if isAuthenticated() && 
    request.auth.uid == request.resource.data.senderId;
  
  allow update: if isAuthenticated() && 
    request.auth.uid == resource.data.receiverId;
  
  allow delete: if false;
}
```

## After Updating:

1. **Hot restart** the app (press 'R' in the terminal running flutter)
2. **Test the messaging feature** - it should work without crashes

## Error Handling Added:

I've also added error handling to gracefully handle permission issues:
- Home screen messages button won't crash if permissions are missing
- Conversations screen shows a helpful error message instead of crashing

---

**Note**: Until you update the Firestore rules, the messaging feature won't work properly, but the app won't crash anymore.
