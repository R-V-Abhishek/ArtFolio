import '../models/user.dart';
import '../models/post.dart';
import '../screens/follow_list_screen.dart';

class UserTypeSelectionArguments {
  final String uid;
  final String email;
  final String fullName;
  final String? profilePictureUrl;

  UserTypeSelectionArguments({
    required this.uid,
    required this.email,
    required this.fullName,
    this.profilePictureUrl,
  });
}

class ProfileArguments {
  final String? userId;

  ProfileArguments({this.userId});
}

class EditProfileArguments {
  final User user;

  EditProfileArguments({required this.user});
}

class PostDetailArguments {
  final Post post;

  PostDetailArguments({required this.post});
}

class FollowListArguments {
  final String userId;
  final FollowListType type;

  FollowListArguments({required this.userId, required this.type});
}

class CommentsArguments {
  final String postId;
  final bool allowComments;

  CommentsArguments({required this.postId, required this.allowComments});
}
