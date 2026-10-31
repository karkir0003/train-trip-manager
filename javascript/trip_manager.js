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

const TripStatus = Object.freeze({
  AT_STATION: "TripStatus.AT_STATION",
  ENDED: "TripStatus.ENDED",
  CANCELLED: "TripStatus.CANCELLED",
});

class Trip {
  constructor(trip_id, train_id, driver_id, last_arrival_time, status = TripStatus.AT_STATION, passengers = 0) {
    this.trip_id = trip_id;
    this.train_id = train_id;
    this.driver_id = driver_id;
    this.last_arrival_time = last_arrival_time;
    this.status = status;
    this.passengers = passengers;
  }
}

class TripManager {
  constructor() {
    this.trips = {};
  }

  get_trip(trip_id) {
    if (!(trip_id in this.trips)) {
      throw new Error(`unknown trip ${trip_id}`);
    }
    return this.trips[trip_id];
  }

  start_trip(trip_id, train_id, driver_id, station_id, time, boarding = 0) {
    if (trip_id in this.trips) {
      throw new Error(`trip ${trip_id} already exists`);
    }
    if (boarding < 0) {
      throw new Error("passenger counts must be non-negative");
    }

    const trip = new Trip(trip_id, train_id, driver_id, time);
    this.trips[trip_id] = trip;

    trip.passengers += boarding;
    return 0;
  }

  arrive_at_station(trip_id, station_id, time, alighting = 0, boarding = 0) {
    const trip = this.get_trip(trip_id);
    trip.status = TripStatus.AT_STATION;
    trip.last_arrival_time = time;

    if (alighting < 0 || boarding < 0) {
      throw new Error("passenger counts must be non-negative");
    }
    if (alighting > trip.passengers) {
      throw new Error("more passengers alighting than on board");
    }

    trip.passengers -= alighting;
    trip.passengers += boarding;
    return 0;
  }

  end_trip(trip_id, time) {
    const trip = this.get_trip(trip_id);
    if (trip.status !== TripStatus.AT_STATION) {
      throw new Error(`trip ${trip_id} must be at a station to end`);
    }

    trip.status = TripStatus.ENDED;
    trip.passengers = 0;
  }

  cancel_trip(trip_id, time) {
    const trip = this.get_trip(trip_id);
    if (trip.status !== TripStatus.AT_STATION) {
      throw new Error(`trip ${trip_id} can only be cancelled at a station`);
    }

    trip.status = TripStatus.CANCELLED;
    trip.passengers = 0;
  }
}

function main() {
  const m = new TripManager();
  const t = new Date(2026, 9, 21, 8, 0, 0); // Wednesday morning

  let left = m.start_trip("T100", "train-7", "drv-ana", "NH", t, 120);
  console.log(`T100 started at NH, ${left} left on platform`);

  left = m.arrive_at_station("T100", "CT", new Date(t.getTime() + 4 * 60 * 1000), 20, 90);
  console.log(`T100 at CT, on board=${m.get_trip("T100").passengers}, left=${left}`);

  left = m.arrive_at_station("T100", "RV", new Date(t.getTime() + 9 * 60 * 1000), 150, 10);
  console.log(`T100 at RV, on board=${m.get_trip("T100").passengers}, left=${left}`);

  m.end_trip("T100", new Date(t.getTime() + 10 * 60 * 1000));
  console.log("T100 ended:", m.get_trip("T100").status);

  m.start_trip("T200", "train-9", "drv-ana", "CT", new Date(t.getTime() + 13 * 60 * 1000));
  console.log("T200 started at CT with drv-ana");
  m.cancel_trip("T200", new Date(t.getTime() + 13 * 60 * 1000 + 30 * 1000));
  console.log("T200 cancelled:", m.get_trip("T200").status);
}

if (typeof require !== "undefined" && typeof module !== "undefined" && require.main === module) {
  main();
}

if (typeof module !== "undefined") {
  module.exports = {
    TripStatus,
    Trip,
    TripManager,
    main,
  };
}
