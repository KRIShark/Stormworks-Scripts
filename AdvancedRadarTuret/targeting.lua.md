# targeting.lua — Functionality Overview

This script reads the predicted intercept points `(x,y,z)` for up to eight targets (from channels 1–24) as produced by `radar.lua`, along with the current turret yaw and pitch angles (from channels 25 and 26). Each tick it selects the **closest valid** intercept, computes the required yaw and pitch angular differences, scales them into velocity pivot inputs (fast for large turns, slow for fine adjustments), and writes the yaw and pitch pivot speeds to output channels 1 and 2.

---

## Inputs

| Input Type | Channel(s)   | Name               | Description                                                                    |
|------------|--------------|--------------------|--------------------------------------------------------------------------------|
| Number     | 1            | `aimX[0]`          | X-coordinate of intercept point for Target 0 (meters)                           |
| Number     | 2            | `aimY[0]`          | Y-coordinate of intercept point for Target 0                                    |
| Number     | 3            | `aimZ[0]`          | Z-coordinate of intercept point for Target 0                                    |
| Number     | 4–6          | `aimX[1]`…`aimZ[1]`| Intercept point for Target 1 (same pattern)                                     |
| Number     | 7–9          | `aimX[2]`…`aimZ[2]`| Intercept point for Target 2                                                    |
| Number     | 10–12        | `aimX[3]`…`aimZ[3]`| Intercept point for Target 3                                                    |
| Number     | 13–15        | `aimX[4]`…`aimZ[4]`| Intercept point for Target 4                                                    |
| Number     | 16–18        | `aimX[5]`…`aimZ[5]`| Intercept point for Target 5                                                    |
| Number     | 19–21        | `aimX[6]`…`aimZ[6]`| Intercept point for Target 6                                                    |
| Number     | 22–24        | `aimX[7]`…`aimZ[7]`| Intercept point for Target 7                                                    |
| Number     | 25           | `currentYawDeg`    | Current turret yaw angle, in degrees, from big velocity pivot’s angle output   |
| Number     | 26           | `currentPitchDeg`  | Current turret pitch angle, in degrees, from big velocity pivot’s angle output |

---

## Outputs

| Channel | Name             | Description                                                         |
|---------|------------------|---------------------------------------------------------------------|
| 1       | `yawPivotSpeed`  | Yaw velocity pivot input: positive = turn left, negative = turn right |
| 2       | `pitchPivotSpeed`| Pitch velocity pivot input: positive = pitch up, negative = pitch down |

---

## Behavior Summary

1. **Read Inputs**  
   - Intercept points `(x,y,z)` for Targets 0–7  
   - Current turret angles `currentYawDeg`, `currentPitchDeg`

2. **Select Closest Target**  
   - Compute squared distance `x² + y² + z²`  
   - Ignore entries where `x=y=z=0` (no valid intercept)  
   - Choose the target with the **smallest** non-zero distance²

3. **Compute Desired Angles**  
   - `desiredYaw  = atan2(y, x)` in degrees  
   - `desiredPitch = atan2(z, sqrt(x²+y²))` in degrees

4. **Calculate Angle Deltas**  
   - `deltaYaw   = normalize(desiredYaw   - currentYawDeg)`  
   - `deltaPitch = normalize(desiredPitch - currentPitchDeg)`  
   - Normalization ensures shortest rotation in ±180°

5. **Scale to Pivot Speeds**  
   - Small `|delta|` → speeds near `MIN_PIVOT_SPEED` for precision  
   - Large `|delta|` → speeds up to `MAX_PIVOT_SPEED` for responsiveness  
   - Below `ANGLE_THRESHOLD` → speed = 0 (on target)

6. **Write Outputs**  
   - `output.setNumber(1, yawPivotSpeed)`  
   - `output.setNumber(2, pitchPivotSpeed)`
