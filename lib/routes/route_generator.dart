import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/user_type_selection_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/delete_account_screen.dart';
import '../screens/follow_list_screen.dart';
import '../screens/post_detail_screen.dart';
import '../screens/create_post_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/image_upload_test_screen.dart';
import '../widgets/auth_state_handler.dart';
import 'app_routes.dart';
import 'route_arguments.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(
            next: AuthStateHandler(),
          ),
        );

      case AppRoutes.splash:
        final args = settings.arguments as Widget?;
        return MaterialPageRoute(
          builder: (_) => SplashScreen(
            next: args ?? const AuthStateHandler(),
          ),
        );

      case AppRoutes.auth:
        return MaterialPageRoute(
          builder: (_) => const AuthScreen(),
          settings: settings,
        );

      case AppRoutes.userTypeSelection:
        final args = settings.arguments as UserTypeSelectionArguments?;
        if (args == null) {
          return _errorRoute('UserTypeSelection requires arguments');
        }
        return MaterialPageRoute(
          builder: (_) => UserTypeSelectionScreen(
            uid: args.uid,
            email: args.email,
            fullName: args.fullName,
            profilePictureUrl: args.profilePictureUrl,
          ),
          settings: settings,
        );

      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );

      case AppRoutes.profile:
        final args = settings.arguments as ProfileArguments?;
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(userId: args?.userId),
          settings: settings,
        );

      case AppRoutes.editProfile:
        final args = settings.arguments as EditProfileArguments?;
        if (args == null) {
          return _errorRoute('EditProfile requires user argument');
        }
        return MaterialPageRoute(
          builder: (_) => EditProfileScreen(user: args.user),
          settings: settings,
        );

      case AppRoutes.deleteAccount:
        return MaterialPageRoute(
          builder: (_) => const DeleteAccountScreen(),
          settings: settings,
        );

      case AppRoutes.notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationsScreen(),
          settings: settings,
        );

      case AppRoutes.followList:
        final args = settings.arguments as FollowListArguments?;
        if (args == null) {
          return _errorRoute('FollowList requires arguments');
        }
        return MaterialPageRoute(
          builder: (_) => FollowListScreen(
            userId: args.userId,
            type: args.type,
          ),
          settings: settings,
        );

      case AppRoutes.postDetail:
        final args = settings.arguments as PostDetailArguments?;
        if (args == null) {
          return _errorRoute('PostDetail requires post argument');
        }
        return MaterialPageRoute(
          builder: (_) => PostDetailScreen(post: args.post),
          settings: settings,
        );

      case AppRoutes.imageUploadTest:
        return MaterialPageRoute(
          builder: (_) => const ImageUploadTestScreen(),
          settings: settings,
        );

      case AppRoutes.createPost:
        return MaterialPageRoute<bool>(
          builder: (_) => const CreatePostScreen(),
          settings: settings,
          fullscreenDialog: true,
        );

      default:
        return _errorRoute('Route ${settings.name} not found');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Navigation Error',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(message),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.home),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}