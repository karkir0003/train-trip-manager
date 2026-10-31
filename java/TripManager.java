/**
 * Train Trip Manager
 *
 * A metro operator tracks every train trip through a `TripManager`. A trip starts at an
 * origin station, arrives at one or more stations, and finishes with either `end_trip`
 * or `cancel_trip`. The manager must enforce the operating rules below.
 *
 *     start_trip
 *         |
 *         v
 *     [at origin]
 *         |  arrive_at_station
 *         v
 *     [at station] <-------------+
 *         |                      |
 *         +-- arrive_at_station -+
 *         |
 *         +-- end_trip -----> [completed]
 *         |
 *         +-- cancel_trip --> [cancelled]
 *
 * Rules:
 *
 * 1. One active trip per driver and per train. A driver may operate, and a train may be
 *    used by, at most one active trip at a time. A trip is active from `start_trip`
 *    until `end_trip` or `cancel_trip`.
 * 2. Dwell time. After a train arrives at a station, it must stay there for at least
 *    45 seconds before it can depart or the trip can end, so passengers can get on and
 *    off.
 * 3. Headway. At any station, a train may not arrive within 3 minutes of the previous
 *    departure from that station. Exactly 3 minutes after the previous departure is allowed.
 *    Arrivals made by `start_trip` count.
 * 4. Capacity. A train holds at most 200 passengers, or 250 during rush hour. Rush
 *    hour is Monday to Friday, 07:00 to 09:30 and 16:30 to 19:00, where each window
 *    includes its start and excludes its end. Capacity is decided by the arrival time.
 *    Passengers alight before anyone boards. If not everyone fits, as many board as fit
 *    and the rest stay on the platform. Nobody is forced off: a train that is over the
 *    current capacity (for example, it filled up during rush hour) simply accepts no new
 *    boarders until it is under the limit again.
 * 5. Driver rest. A driver must rest at least 2 minutes between the end of one trip
 *    and the start of their next trip.
 * 6. Trip lifecycle. A trip starts at its origin station, then arrives at one or more
 *    stations, and finishes as either completed (`end_trip`) or cancelled
 *    (`cancel_trip`). A trip can finish only while the train is stopped at a station it
 *    arrived at after the origin, so a trip that has not yet reached its first station
 *    can be neither completed nor cancelled.
 */

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.NoSuchElementException;

public class TripManager {
    public Map<String, Trip> trips = new HashMap<>();

    public Trip get_trip(String trip_id) {
        if (!trips.containsKey(trip_id)) {
            throw new NoSuchElementException("unknown trip " + trip_id);
        }
        return trips.get(trip_id);
    }

    public int start_trip(
        String trip_id,
        String train_id,
        String driver_id,
        String station_id,
        LocalDateTime time
    ) {
        return start_trip(trip_id, train_id, driver_id, station_id, time, 0);
    }

    public int start_trip(
        String trip_id,
        String train_id,
        String driver_id,
        String station_id,
        LocalDateTime time,
        int boarding
    ) {
        if (trips.containsKey(trip_id)) {
            throw new IllegalArgumentException("trip " + trip_id + " already exists");
        }
        if (boarding < 0) {
            throw new IllegalArgumentException("passenger counts must be non-negative");
        }

        Trip trip = new Trip(trip_id, train_id, driver_id, time);
        trips.put(trip_id, trip);

        trip.passengers += boarding;
        return 0;
    }

    public int arrive_at_station(
        String trip_id,
        String station_id,
        LocalDateTime time
    ) {
        return arrive_at_station(trip_id, station_id, time, 0, 0);
    }

    public int arrive_at_station(
        String trip_id,
        String station_id,
        LocalDateTime time,
        int alighting,
        int boarding
    ) {
        Trip trip = get_trip(trip_id);
        trip.status = TripStatus.AT_STATION;
        trip.last_arrival_time = time;

        if (alighting < 0 || boarding < 0) {
            throw new IllegalArgumentException("passenger counts must be non-negative");
        }
        if (alighting > trip.passengers) {
            throw new IllegalArgumentException("more passengers alighting than on board");
        }

        trip.passengers -= alighting;
        trip.passengers += boarding;
        return 0;
    }

    public void end_trip(String trip_id, LocalDateTime time) {
        Trip trip = get_trip(trip_id);
        if (trip.status != TripStatus.AT_STATION) {
            throw new IllegalArgumentException("trip " + trip_id + " must be at a station to end");
        }

        trip.status = TripStatus.ENDED;
        trip.passengers = 0;
    }

    public void cancel_trip(String trip_id, LocalDateTime time) {
        Trip trip = get_trip(trip_id);
        if (trip.status != TripStatus.AT_STATION) {
            throw new IllegalArgumentException("trip " + trip_id + " can only be cancelled at a station");
        }

        trip.status = TripStatus.CANCELLED;
        trip.passengers = 0;
    }

    public static void main(String[] args) {
        TripManager m = new TripManager();
        LocalDateTime t = LocalDateTime.of(2026, 10, 21, 8, 0, 0); // Wednesday morning

        int left = m.start_trip("T100", "train-7", "drv-ana", "NH", t, 120);
        System.out.println("T100 started at NH, " + left + " left on platform");

        left = m.arrive_at_station("T100", "CT", t.plusMinutes(4), 20, 90);
        System.out.println("T100 at CT, on board=" + m.get_trip("T100").passengers + ", left=" + left);

        left = m.arrive_at_station("T100", "RV", t.plusMinutes(9), 150, 10);
        System.out.println("T100 at RV, on board=" + m.get_trip("T100").passengers + ", left=" + left);

        m.end_trip("T100", t.plusMinutes(10));
        System.out.println("T100 ended: " + m.get_trip("T100").status);

        m.start_trip("T200", "train-9", "drv-ana", "CT", t.plusMinutes(13));
        System.out.println("T200 started at CT with drv-ana");
        m.cancel_trip("T200", t.plusMinutes(13).plusSeconds(30));
        System.out.println("T200 cancelled: " + m.get_trip("T200").status);
    }
}

enum TripStatus {
    AT_STATION("at_station"),
    ENDED("ended"),
    CANCELLED("cancelled");

    private final String value;

    TripStatus(String value) {
        this.value = value;
    }

    public String getValue() {
        return value;
    }

    @Override
    public String toString() {
        return "TripStatus." + name();
    }
}

class Trip {
    public String trip_id;
    public String train_id;
    public String driver_id;
    public LocalDateTime last_arrival_time;
    public TripStatus status = TripStatus.AT_STATION;
    public int passengers = 0;

    public Trip(String trip_id, String train_id, String driver_id, LocalDateTime last_arrival_time) {
        this.trip_id = trip_id;
        this.train_id = train_id;
        this.driver_id = driver_id;
        this.last_arrival_time = last_arrival_time;
        this.status = TripStatus.AT_STATION;
        this.passengers = 0;
    }
}
