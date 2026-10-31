"""
Train Trip Manager

A metro operator tracks every train trip through a `TripManager`. A trip starts at an
origin station, arrives at one or more stations, and finishes with either `end_trip`
or `cancel_trip`. The manager must enforce the operating rules below.

    start_trip
        |
        v
    [at origin]
        |  arrive_at_station
        v
    [at station] <-------------+
        |                      |
        +-- arrive_at_station -+
        |
        +-- end_trip -----> [completed]
        |
        +-- cancel_trip --> [cancelled]

Rules:

1. One active trip per driver and per train. A driver may operate, and a train may be
   used by, at most one active trip at a time. A trip is active from `start_trip`
   until `end_trip` or `cancel_trip`.
2. Dwell time. After a train arrives at a station, it must stay there for at least
   45 seconds before it can depart or the trip can end, so passengers can get on and
   off.
3. Headway. At any station, a train may not arrive within 3 minutes of the previous
   departure from that station. Exactly 3 minutes after the previous departure is allowed.
   Arrivals made by `start_trip` count.
4. Capacity. A train holds at most 200 passengers, or 250 during rush hour. Rush
   hour is Monday to Friday, 07:00 to 09:30 and 16:30 to 19:00, where each window
   includes its start and excludes its end. Capacity is decided by the arrival time.
   Passengers alight before anyone boards. If not everyone fits, as many board as fit
   and the rest stay on the platform. Nobody is forced off: a train that is over the
   current capacity (for example, it filled up during rush hour) simply accepts no new
   boarders until it is under the limit again.
5. Driver rest. A driver must rest at least 2 minutes between the end of one trip
   and the start of their next trip.
6. Trip lifecycle. A trip starts at its origin station, then arrives at one or more
   stations, and finishes as either completed (`end_trip`) or cancelled
   (`cancel_trip`). A trip can finish only while the train is stopped at a station it
   arrived at after the origin, so a trip that has not yet reached its first station
   can be neither completed nor cancelled.
"""

from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import Enum


class TripStatus(Enum):
    AT_STATION = "at_station"
    ENDED = "ended"
    CANCELLED = "cancelled"


@dataclass
class Trip:
    trip_id: str
    train_id: str
    driver_id: str
    last_arrival_time: datetime
    status: TripStatus = TripStatus.AT_STATION
    passengers: int = 0


class TripManager:
    def __init__(self) -> None:
        self.trips: dict[str, Trip] = {}

    def get_trip(self, trip_id: str) -> Trip:
        if trip_id not in self.trips:
            raise KeyError(f"unknown trip {trip_id}")
        return self.trips[trip_id]

    def start_trip(
        self,
        trip_id: str,
        train_id: str,
        driver_id: str,
        station_id: str,
        time: datetime,
        boarding: int = 0,
    ) -> int:
        if trip_id in self.trips:
            raise ValueError(f"trip {trip_id} already exists")
        if boarding < 0:
            raise ValueError("passenger counts must be non-negative")

        trip = Trip(
            trip_id=trip_id,
            train_id=train_id,
            driver_id=driver_id,
            last_arrival_time=time,
        )
        self.trips[trip_id] = trip

        trip.passengers += boarding
        return 0

    def arrive_at_station(
        self,
        trip_id: str,
        station_id: str,
        time: datetime,
        alighting: int = 0,
        boarding: int = 0,
    ) -> int:
        trip = self.get_trip(trip_id)
        trip.status = TripStatus.AT_STATION
        trip.last_arrival_time = time

        if alighting < 0 or boarding < 0:
            raise ValueError("passenger counts must be non-negative")
        if alighting > trip.passengers:
            raise ValueError("more passengers alighting than on board")

        trip.passengers -= alighting
        trip.passengers += boarding
        return 0

    def end_trip(self, trip_id: str, time: datetime) -> None:
        trip = self.get_trip(trip_id)
        if trip.status != TripStatus.AT_STATION:
            raise ValueError(f"trip {trip_id} must be at a station to end")

        trip.status = TripStatus.ENDED
        trip.passengers = 0

    def cancel_trip(self, trip_id: str, time: datetime) -> None:
        trip = self.get_trip(trip_id)
        if trip.status != TripStatus.AT_STATION:
            raise ValueError(f"trip {trip_id} can only be cancelled at a station")

        trip.status = TripStatus.CANCELLED
        trip.passengers = 0


def main() -> None:
    m = TripManager()
    t = datetime(2026, 10, 21, 8, 0, 0)  # Wednesday morning

    left = m.start_trip("T100", "train-7", "drv-ana", "NH", t, boarding=120)
    print(f"T100 started at NH, {left} left on platform")

    left = m.arrive_at_station("T100", "CT", t + timedelta(minutes=4), alighting=20, boarding=90)
    print(f"T100 at CT, on board={m.get_trip('T100').passengers}, left={left}")

    left = m.arrive_at_station("T100", "RV", t + timedelta(minutes=9), alighting=150, boarding=10)
    print(f"T100 at RV, on board={m.get_trip('T100').passengers}, left={left}")

    m.end_trip("T100", t + timedelta(minutes=10))
    print("T100 ended:", m.get_trip("T100").status)

    m.start_trip("T200", "train-9", "drv-ana", "CT", t + timedelta(minutes=13))
    print("T200 started at CT with drv-ana")
    m.cancel_trip("T200", t + timedelta(minutes=13, seconds=30))
    print("T200 cancelled:", m.get_trip("T200").status)


if __name__ == "__main__":
    main()