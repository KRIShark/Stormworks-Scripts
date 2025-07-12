Here is a brief Markdown overview of radar.lua and its role in your targeting system, followed by the documented input/output tables.

Overview of radar.lua
radar.lua continuously reads up to eight radar contacts (distance, azimuth, elevation, and a “detected” flag) each tick, reconstructs their 3D positions relative to the gun, maintains a five‐sample history per contact to estimate velocity, and then solves the first‐order intercept problem to find where the cannon must aim so that a 1 000 m/s projectile will collide with the moving target. The script outputs a predicted (x, y, z) aim point for each target on channels 1–24 (three values per target), or zeros if no valid intercept exists.

## Inputs

| Input Type | Channel(s) | Variable Name             | Description                                                         |
|------------|------------|---------------------------|---------------------------------------------------------------------|
| Boolean    | 1          | `detected[0]`             | True if a valid contact appears in numeric channels 1–4             |
| Boolean    | 2          | `detected[1]`             | True if a valid contact appears in numeric channels 5–8             |
| Boolean    | 3          | `detected[2]`             | True if a valid contact appears in numeric channels 9–12            |
| Boolean    | 4          | `detected[3]`             | True if a valid contact appears in numeric channels 13–16           |
| Boolean    | 5          | `detected[4]`             | True if a valid contact appears in numeric channels 17–20           |
| Boolean    | 6          | `detected[5]`             | True if a valid contact appears in numeric channels 21–24           |
| Boolean    | 7          | `detected[6]`             | True if a valid contact appears in numeric channels 25–28           |
| Boolean    | 8          | `detected[7]`             | True if a valid contact appears in numeric channels 29–32           |
| Number     | 1–4        | `distance[0]`, `azimuth[0]`, `elevation[0]`, `ageTicks[0]`   | **Target 0**: 1=distance (m), 2=azimuth (turns), 3=elevation (turns), 4=ticks since detect |
| Number     | 5–8        | `distance[1]`, `azimuth[1]`, `elevation[1]`, `ageTicks[1]`   | **Target 1** (same pattern)                                         |
| Number     | 9–12       | `distance[2]`, `azimuth[2]`, `elevation[2]`, `ageTicks[2]`   | **Target 2**                                                       |
| Number     | 13–16      | `distance[3]`, `azimuth[3]`, `elevation[3]`, `ageTicks[3]`   | **Target 3**                                                       |
| Number     | 17–20      | `distance[4]`, `azimuth[4]`, `elevation[4]`, `ageTicks[4]`   | **Target 4**                                                       |
| Number     | 21–24      | `distance[5]`, `azimuth[5]`, `elevation[5]`, `ageTicks[5]`   | **Target 5**                                                       |
| Number     | 25–28      | `distance[6]`, `azimuth[6]`, `elevation[6]`, `ageTicks[6]`   | **Target 6**                                                       |
| Number     | 29–32      | `distance[7]`, `azimuth[7]`, `elevation[7]`, `ageTicks[7]`   | **Target 7**                                                       |

## Outputs

| Channel Range | Variable Name             | Description                                                       |
|---------------|---------------------------|-------------------------------------------------------------------|
| 1–3           | `aimX[0]`, `aimY[0]`, `aimZ[0]` | Predicted intercept point (x,y,z) in meters for **Target 0**       |
| 4–6           | `aimX[1]`, `aimY[1]`, `aimZ[1]` | Predicted intercept point for **Target 1**                        |
| 7–9           | `aimX[2]`, `aimY[2]`, `aimZ[2]` | Predicted intercept point for **Target 2**                        |
| 10–12         | `aimX[3]`, `aimY[3]`, `aimZ[3]` | Predicted intercept point for **Target 3**                        |
| 13–15         | `aimX[4]`, `aimY[4]`, `aimZ[4]` | Predicted intercept point for **Target 4**                        |
| 16–18         | `aimX[5]`, `aimY[5]`, `aimZ[5]` | Predicted intercept point for **Target 5**                        |
| 19–21         | `aimX[6]`, `aimY[6]`, `aimZ[6]` | Predicted intercept point for **Target 6**                        |
| 22–24         | `aimX[7]`, `aimY[7]`, `aimZ[7]` | Predicted intercept point for **Target 7**                        |

Written by output.setNumber(channel, value).

If no valid intercept exists or no contact, the script writes 0 to each of the three channels for that target. Channels 25–32 remain unused and available for any additional flags or status data.