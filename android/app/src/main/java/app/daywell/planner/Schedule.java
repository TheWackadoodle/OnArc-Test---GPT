package app.daywell.planner;

import java.time.*;
import java.util.List;

/** Daily wall-clock starts. A gap has no occurrence. An overlap uses the first offset. */
final class Schedule {
    static Instant next(int minute, Instant after, ZoneId zone) {
        LocalDate date = after.atZone(zone).toLocalDate();
        while (true) {
            LocalDateTime time = date.atStartOfDay().plusMinutes(minute);
            List<ZoneOffset> offsets = zone.getRules().getValidOffsets(time);
            if (!offsets.isEmpty()) {
                Instant start = time.toInstant(offsets.get(0));
                if (start.isAfter(after)) return start;
            }
            date = date.plusDays(1);
        }
    }
}
