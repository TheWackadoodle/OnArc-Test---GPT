package app.daywell.planner;
import java.time.*;
class ScheduleCheck {
    static void check(int minute,String from,String zone,String expected) {
        Instant actual=Schedule.next(minute,Instant.parse(from),ZoneId.of(zone));
        if(!actual.equals(Instant.parse(expected)))throw new AssertionError(actual);
    }
    public static void main(String[] args){
        check(150,"2026-03-08T05:00:00Z","America/New_York","2026-03-09T06:30:00Z");
        check(90,"2026-11-01T04:00:00Z","America/New_York","2026-11-01T05:30:00Z");
        check(90,"2026-11-01T05:30:00Z","America/New_York","2026-11-02T06:30:00Z");
        check(0,"2026-11-24T23:59:59Z","UTC","2026-11-25T00:00:00Z");
        check(540,"2026-11-25T08:00:00Z","America/Los_Angeles","2026-11-25T17:00:00Z");
        System.out.println("5 scheduling checks passed");
    }
}
