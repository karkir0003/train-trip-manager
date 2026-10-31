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

#include <chrono>
#include <ctime>
#include <iostream>
#include <stdexcept>
#include <string>
#include <unordered_map>

using DateTime = std::chrono::system_clock::time_point;

inline DateTime make_datetime(int year, int month, int day, int hour, int minute, int second = 0) {
    std::tm tm = {};
    tm.tm_year = year - 1900;
    tm.tm_mon = month - 1;
    tm.tm_mday = day;
    tm.tm_hour = hour;
    tm.tm_min = minute;
    tm.tm_sec = second;
    tm.tm_isdst = -1;
    return std::chrono::system_clock::from_time_t(std::mktime(&tm));
}

enum class TripStatus {
    AT_STATION,
    ENDED,
    CANCELLED
};

inline std::ostream& operator<<(std::ostream& os, const TripStatus& status) {
    switch (status) {
        case TripStatus::AT_STATION:
            return os << "TripStatus.AT_STATION";
        case TripStatus::ENDED:
            return os << "TripStatus.ENDED";
        case TripStatus::CANCELLED:
            return os << "TripStatus.CANCELLED";
    }
    return os;
}

struct Trip {
    std::string trip_id;
    std::string train_id;
    std::string driver_id;
    DateTime last_arrival_time;
    TripStatus status = TripStatus::AT_STATION;
    int passengers = 0;

    Trip() = default;
    Trip(std::string trip_id, std::string train_id, std::string driver_id, DateTime last_arrival_time)
        : trip_id(std::move(trip_id)),
          train_id(std::move(train_id)),
          driver_id(std::move(driver_id)),
          last_arrival_time(last_arrival_time),
          status(TripStatus::AT_STATION),
          passengers(0) {}
};

class TripManager {
public:
    std::unordered_map<std::string, Trip> trips;

    Trip& get_trip(const std::string& trip_id) {
        auto it = trips.find(trip_id);
        if (it == trips.end()) {
            throw std::out_of_range("unknown trip " + trip_id);
        }
        return it->second;
    }

    const Trip& get_trip(const std::string& trip_id) const {
        auto it = trips.find(trip_id);
        if (it == trips.end()) {
            throw std::out_of_range("unknown trip " + trip_id);
        }
        return it->second;
    }

    int start_trip(
        const std::string& trip_id,
        const std::string& train_id,
        const std::string& driver_id,
        const std::string& station_id,
        DateTime time,
        int boarding = 0
    ) {
        (void)station_id;
        if (trips.find(trip_id) != trips.end()) {
            throw std::invalid_argument("trip " + trip_id + " already exists");
        }
        if (boarding < 0) {
            throw std::invalid_argument("passenger counts must be non-negative");
        }

        Trip trip(trip_id, train_id, driver_id, time);
        trips[trip_id] = trip;

        trips[trip_id].passengers += boarding;
        return 0;
    }

    int arrive_at_station(
        const std::string& trip_id,
        const std::string& station_id,
        DateTime time,
        int alighting = 0,
        int boarding = 0
    ) {
        (void)station_id;
        Trip& trip = get_trip(trip_id);
        trip.status = TripStatus::AT_STATION;
        trip.last_arrival_time = time;

        if (alighting < 0 || boarding < 0) {
            throw std::invalid_argument("passenger counts must be non-negative");
        }
        if (alighting > trip.passengers) {
            throw std::invalid_argument("more passengers alighting than on board");
        }

        trip.passengers -= alighting;
        trip.passengers += boarding;
        return 0;
    }

    void end_trip(const std::string& trip_id, DateTime time) {
        (void)time;
        Trip& trip = get_trip(trip_id);
        if (trip.status != TripStatus::AT_STATION) {
            throw std::invalid_argument("trip " + trip_id + " must be at a station to end");
        }

        trip.status = TripStatus::ENDED;
        trip.passengers = 0;
    }

    void cancel_trip(const std::string& trip_id, DateTime time) {
        (void)time;
        Trip& trip = get_trip(trip_id);
        if (trip.status != TripStatus::AT_STATION) {
            throw std::invalid_argument("trip " + trip_id + " can only be cancelled at a station");
        }

        trip.status = TripStatus::CANCELLED;
        trip.passengers = 0;
    }
};

int main() {
    TripManager m;
    DateTime t = make_datetime(2026, 10, 21, 8, 0, 0); // Wednesday morning

    int left = m.start_trip("T100", "train-7", "drv-ana", "NH", t, 120);
    std::cout << "T100 started at NH, " << left << " left on platform\n";

    left = m.arrive_at_station("T100", "CT", t + std::chrono::minutes(4), 20, 90);
    std::cout << "T100 at CT, on board=" << m.get_trip("T100").passengers << ", left=" << left << "\n";

    left = m.arrive_at_station("T100", "RV", t + std::chrono::minutes(9), 150, 10);
    std::cout << "T100 at RV, on board=" << m.get_trip("T100").passengers << ", left=" << left << "\n";

    m.end_trip("T100", t + std::chrono::minutes(10));
    std::cout << "T100 ended: " << m.get_trip("T100").status << "\n";

    m.start_trip("T200", "train-9", "drv-ana", "CT", t + std::chrono::minutes(13));
    std::cout << "T200 started at CT with drv-ana\n";
    m.cancel_trip("T200", t + std::chrono::minutes(13) + std::chrono::seconds(30));
    std::cout << "T200 cancelled: " << m.get_trip("T200").status << "\n";

    return 0;
}
