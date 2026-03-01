#!/usr/bin/env python3
"""Determine light/dark mode based on sunrise/sunset times.

Uses the NOAA solar position algorithm to calculate sunrise and sunset
from latitude, longitude, and timezone. Outputs "light" or "dark".

Usage: sunrise-sunset.py <latitude> <longitude> <timezone>
Example: sunrise-sunset.py 43.65 -79.38 America/Toronto
"""

import math
import sys
from datetime import datetime, timezone as tz
from zoneinfo import ZoneInfo


def calc_sunrise_sunset(lat, lon, date, utc_offset_hours):
    """Calculate sunrise/sunset using NOAA algorithm.

    Returns (sunrise_hour, sunset_hour) in local decimal hours,
    or (None, None) for polar day/night.
    """
    zenith = 90.833
    day_of_year = date.timetuple().tm_yday
    lng_hour = lon / 15.0

    def calc_time(is_sunrise):
        if is_sunrise:
            t = day_of_year + (6 - lng_hour) / 24.0
        else:
            t = day_of_year + (18 - lng_hour) / 24.0

        mean_anomaly = (0.9856 * t) - 3.289
        sun_lon = (
            mean_anomaly
            + 1.916 * math.sin(math.radians(mean_anomaly))
            + 0.020 * math.sin(math.radians(2 * mean_anomaly))
            + 282.634
        ) % 360

        right_asc = math.degrees(
            math.atan(0.91764 * math.tan(math.radians(sun_lon)))
        )
        # Adjust quadrant
        sun_quad = (sun_lon // 90) * 90
        ra_quad = (right_asc // 90) * 90
        right_asc = (right_asc + (sun_quad - ra_quad)) / 15.0

        sin_dec = 0.39782 * math.sin(math.radians(sun_lon))
        cos_dec = math.cos(math.asin(sin_dec))

        cos_h = (
            math.cos(math.radians(zenith))
            - sin_dec * math.sin(math.radians(lat))
        ) / (cos_dec * math.cos(math.radians(lat)))

        if cos_h > 1:
            return None  # Sun never rises (polar night)
        if cos_h < -1:
            return None  # Sun never sets (midnight sun)

        if is_sunrise:
            hour_angle = (360 - math.degrees(math.acos(cos_h))) / 15.0
        else:
            hour_angle = math.degrees(math.acos(cos_h)) / 15.0

        local_mean = hour_angle + right_asc - 0.06571 * t - 6.622
        utc_hour = local_mean - lng_hour
        local_hour = (utc_hour + utc_offset_hours) % 24
        return local_hour

    return calc_time(True), calc_time(False)


def main():
    if len(sys.argv) != 4:
        print("Usage: sunrise-sunset.py <latitude> <longitude> <timezone>", file=sys.stderr)
        sys.exit(2)

    lat = float(sys.argv[1])
    lon = float(sys.argv[2])
    tz_name = sys.argv[3]

    try:
        zone = ZoneInfo(tz_name)
    except KeyError:
        print(f"Unknown timezone: {tz_name}", file=sys.stderr)
        sys.exit(2)

    now = datetime.now(zone)
    utc_offset = now.utcoffset().total_seconds() / 3600.0

    sunrise, sunset = calc_sunrise_sunset(lat, lon, now, utc_offset)

    current_hour = now.hour + now.minute / 60.0

    if sunrise is None or sunset is None:
        # Polar conditions — use 7-19 fallback
        if 7 <= current_hour < 19:
            print("light")
        else:
            print("dark")
    elif sunrise <= current_hour < sunset:
        print("light")
    else:
        print("dark")


if __name__ == "__main__":
    main()
