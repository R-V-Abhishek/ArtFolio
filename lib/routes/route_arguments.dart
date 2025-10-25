import '../models/post.dart';
import '../models/user.dart';
import '../screens/follow_list_screen.dart';

class UserTypeSelectionArguments {

  UserTypeSelectionArguments({
    required this.uid,
    required this.email,
    required this.fullName,
    this.profilePictureUrl,
  });
  final String uid;
  final String email;
  final String fullName;
  final String? profilePictureUrl;
}

class ProfileArguments {

  ProfileArguments({this.userId});
  final String? userId;
}

class EditProfileArguments {

  EditProfileArguments({required this.user});
  final User user;
}

class PostDetailArguments {

  PostDetailArguments({this.post, this.posts, this.initialIndex});
  /// Back-compat single post argument
  final Post? post;
  /// Optional list of posts to enable vertical paging
  final List<Post>? posts;
  /// Initial index within [posts], defaults to 0
  final int? initialIndex;
}

class FollowListArguments {

  FollowListArguments({required this.userId, required this.type});
  final String userId;
  final FollowListType type;
}

class CommentsArguments {

  CommentsArguments({required this.postId, required this.allowComments});
  final String postId;
  final bool allowComments;
}
