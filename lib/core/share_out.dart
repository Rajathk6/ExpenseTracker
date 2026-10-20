/// Sending text out of the app — a split or a group shared to WhatsApp, SMS,
/// a mail app, anything that accepts text.
///
/// The app could *receive* shares from the start; it could never send one,
/// which made the share code on a split useless.
library;

import 'package:flutter/services.dart';

const _channel = MethodChannel('dev.rajath.expense_tracker/share');

/// Opens the system share sheet with [text]. Returns false when there is no
/// platform to share with (tests, desktop).
Future<bool> shareText({required String text, String? subject}) async {
  try {
    final ok = await _channel.invokeMethod<bool>('shareText', {
      'text': text,
      if (subject != null) 'subject': subject,
    });
    return ok ?? false;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
}
