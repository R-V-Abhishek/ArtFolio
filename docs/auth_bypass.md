# Guest / Auth Bypass (Temporary)

During early UI development we allow a temporary "guest mode" so designers and
stakeholders can preview post-auth screens without configuring real Firebase
credentials.

How it works:
1. `SessionState` holds a `guestMode` ValueNotifier.
2. The `AuthScreen` has a "Skip for now (Guest)" button which sets guest mode.
3. `main.dart` checks guest mode before listening to the Firebase auth stream.
4. `HomeScreen` shows a contextual action: if guest => a login icon to exit
   guest mode; if authenticated => a logout icon.

To disable the bypass for production remove:
- The import of `session_state.dart` & the `ValueListenableBuilder` wrapping.
- The guest branch in the `home:` selection logic.
- The "Skip for now" button in `AuthScreen`.

Or simply call `SessionState.instance.exitGuest()` on app start.

Once real Firebase config is supplied, guest mode should be removed or gated
behind a debug flag.
