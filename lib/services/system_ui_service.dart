import 'package:flutter/services.dart';

class SystemUiService {
  static Future<void> configure() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  }
}
