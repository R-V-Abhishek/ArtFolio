import 'package:flutter/foundation.dart';

/// Holds ephemeral session flags that are not persisted yet (e.g. guest mode).
class SessionState {
  SessionState._();
  static final SessionState instance = SessionState._();

  /// When true we bypass Firebase auth gated UI and show the home experience.
  final ValueNotifier<bool> guestMode = ValueNotifier<bool>(false);

  void enterGuest() => guestMode.value = true;
  void exitGuest() => guestMode.value = false;
}
