// utils/timezone_helper.dart
import 'package:timezone/timezone.dart' as tz;

class TimezoneHelper {
  // Get the current local timezone (simplified version)
  static String getLocalTimezone() {
    try {
      // Get the current timezone from timezone package
      return tz.local.name;
    } catch (e) {
      // Default to a common timezone if there's an error
      return 'America/New_York';
    }
  }

  // Initialize timezone with a default timezone
  static void configureLocalTimeZone() {
    try {
      // Set to a default timezone
      tz.setLocalLocation(tz.getLocation('America/New_York'));
    } catch (e) {
    }
  }
}