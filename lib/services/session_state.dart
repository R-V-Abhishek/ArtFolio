import 'package:flutter/foundation.dart';

/// Holds ephemeral session flags that are not persisted yet (e.g. guest mode).
class SessionState {
  SessionState._();
  static final SessionState instance = SessionState._();

  /// When true we bypass Firebase auth gated UI and show the home experience.
  final ValueNotifier<bool> guestMode = ValueNotifier<bool>(false);

  /// When toggled, consumers like ProfileScreen can reload their content.
  final ValueNotifier<int> profileRefreshTick = ValueNotifier<int>(0);

  void enterGuest() => guestMode.value = true;
  void exitGuest() => guestMode.value = false;

  /// Call after creating/deleting/updating a post that affects the profile feed.
  void notifyProfileShouldRefresh() => profileRefreshTick.value++;
}
