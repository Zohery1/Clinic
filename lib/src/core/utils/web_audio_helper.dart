import 'web_audio_helper_stub.dart'
    if (dart.library.js_interop) 'web_audio_helper_web.dart'
    as audio_impl;

/// Platform-agnostic helper to play web notification chime sound safely.
void playWebNotificationChime() {
  audio_impl.playWebNotificationChime();
}
