import '../config/app_config.dart';
import '../data/station_content.dart';

/// Current time in Papua New Guinea (UTC+10, no daylight saving).
DateTime pngNow() => DateTime.now().toUtc().add(AppConfig.pngUtcOffset);

bool isWeekend(DateTime png) => png.weekday == DateTime.saturday || png.weekday == DateTime.sunday;

/// Index in [weekdayPrograms] of the program on air at [png] time,
/// or -1 on weekends (the weekday schedule doesn't apply).
int currentProgramIndex(DateTime png) {
  if (isWeekend(png)) return -1;
  final int minute = png.hour * 60 + png.minute;
  if (minute < weekdayPrograms.first.startMinute) {
    return weekdayPrograms.length - 1; // overnight automation
  }
  int current = -1;
  for (int i = 0; i < weekdayPrograms.length; i++) {
    final int start = weekdayPrograms[i].startMinute;
    if (start == 0) continue; // midnight entries are covered above
    if (start <= minute) current = i;
  }
  return current;
}
