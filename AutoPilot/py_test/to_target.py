import math


TARGET_DISTANCE = 10.0
STEERING_GAIN = 5.0


def clamp(value, minimum, maximum):
    return max(minimum, min(maximum, value))


def autopilot(
    x_pos,
    y_pos,
    x_target,
    y_target,
    compass
):
    # ---------------------------------------------------------
    # Difference to target
    # ---------------------------------------------------------

    dx = x_target - x_pos
    dy = y_target - y_pos


    # ---------------------------------------------------------
    # Bearing
    # ---------------------------------------------------------

    bearing_rad = math.atan2(dx, dy)

    bearing_deg = math.degrees(bearing_rad)

    bearing_deg = (bearing_deg + 360.0) % 360.0


    # ---------------------------------------------------------
    # Convert bearing to Stormworks compass units
    # ---------------------------------------------------------

    target_heading = bearing_deg / 360.0


    # ---------------------------------------------------------
    # Heading error
    # ---------------------------------------------------------

    heading_error = target_heading - compass

    # Wrap into -0.5 .. +0.5
    heading_error = (heading_error + 0.5) % 1.0 - 0.5


    # ---------------------------------------------------------
    # Steering
    # ---------------------------------------------------------

    steering = heading_error * STEERING_GAIN
    steering = clamp(steering, -1.0, 1.0)


    # ---------------------------------------------------------
    # Target reached
    # ---------------------------------------------------------

    x_reached = (
        x_target - TARGET_DISTANCE
        < x_pos
        < x_target + TARGET_DISTANCE
    )

    y_reached = (
        y_target - TARGET_DISTANCE
        < y_pos
        < y_target + TARGET_DISTANCE
    )

    target_reached = x_reached and y_reached


    return {
        "dx": dx,
        "dy": dy,
        "bearing": bearing_deg,
        "target_heading": target_heading,
        "heading_error": heading_error,
        "steering": steering,
        "target_reached": target_reached,
    }


# =============================================================
# TEST
# =============================================================

result = autopilot(
    x_pos=100,
    y_pos=100,
    x_target=500,
    y_target=800,
    compass=0.05
)

for name, value in result.items():
    print(f"{name:16}: {value}")