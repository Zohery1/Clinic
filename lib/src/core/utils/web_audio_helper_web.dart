import 'dart:js_interop';

@JS('playNotificationChime')
external void _jsPlayNotificationChime();

/// Web audio implementation invoking the JS interop function on Web browsers.
void playWebNotificationChime() {
  try {
    _jsPlayNotificationChime();
  } catch (_) {}
}
