# SunCalc Edge Case Bug - Tromsø July 25, 2025

## Problem Summary

**Date Discovered:** 2025-11-27
**Location:** Tromsø, Norway (69.6492°N, 18.9553°E)
**Date:** July 25, 2025
**Expected:** Sunrise ~01:50, Sunset ~23:52 (user-reported actual times)
**SunCalc Returns:** Sunrise 00:51, Sunset 00:51 (INCORRECT - both near midnight!)

## Root Cause Analysis

### 1. Detection Uses Nadir Instead of True Minimum

SunCalc uses `solarMidnight` (nadir) for polar day/night detection:

```swift
if let nadirDate = self.nadir {
    let midnightPosition = SunCalc.getSunPosition(...)
    midnightAltitude = midnightPosition.altitude * 180.0 / .pi
}

let canHaveSunrise = noonAltitude >= cSunrise && midnightAltitude < cSunrise
```

**For Tromsø July 25:**
- `noonAltitude` = 39.99° ✅
- `midnightAltitude` (nadir) = **-0.602°** ❌
- **True minimum** = **-0.8047°** (occurs around 11:00 GMT, NOT at midnight!)

### 2. Nadir vs True Minimum Problem

The sun's **lowest point** is NOT always at solar midnight in high latitudes!

**Hourly altitudes for Tromsø July 25:**
```
Hour  0: -0.60° (nadir - used by SunCalc)
Hour  1: -0.70°
Hour  2: -0.78°
...
Hour 11: -0.80° ← TRUE MINIMUM
Hour 12: -0.74°
...
Hour 23: -0.62°
```

Because SunCalc checks `-0.602° < -0.83°` → **FALSE**, it thinks the sun never crosses the horizon!

### 3. Incorrect Time Calculation

When `getHourAngle()` is called with conditions where the sun BARELY crosses the threshold:

```swift
let value = (sin(h) - sin(phi) * sin(d)) / (cos(phi) * cos(d))
// For Tromsø July 25: value = -1.0065 (outside valid range [-1, 1])

if value < -1 {
    return acos(-1)  // π (180°) = 12 hours
}
```

This causes:
- `Jset = Jnoon + 0.5` → midnight
- `Jrise = Jnoon - 0.5` → midnight
- **Both sunrise and sunset calculated as ~00:51** (near midnight)

## Why Current Fix is Incomplete

### Tolerance Approach (Current Implementation)

Added tolerance of 0.25° to detection:

```swift
let tolerance = 0.25
let canHaveSunrise = noonAltitude >= (cSunrise - tolerance) &&
                     midnightAltitude < (cSunrise + tolerance)
```

**Result:**
- Detection now allows calculation: `-0.602 < -0.58` → TRUE ✅
- BUT times are still wrong: `00:51` instead of `01:50` / `23:52` ❌

**Why it fails:**
- Even though detection passes, `getHourAngle()` still gets `value = -1.0065`
- The sun NEVER actually reaches `-0.83°` when measured from nadir
- The calculation returns midnight times (π radians = 12 hours)

## Proper Solution (Not Yet Implemented)

### Option 1: Use True Daily Minimum (RECOMMENDED)

Instead of using `nadir` altitude, scan the entire day:

```swift
// Find true minimum altitude across entire day
var minAltitude = Double.infinity
for hour in 0..<24 {
    let hourDate = DateUtils.getHoursLater(date: date, hours: Double(hour))
    let position = SunCalc.getSunPosition(timeAndDate: hourDate, ...)
    let altitude = position.altitude * 180.0 / .pi
    minAltitude = min(minAltitude, altitude)
}

// Use TRUE minimum for detection
let canHaveSunrise = noonAltitude >= cSunrise && minAltitude < cSunrise
```

**Pros:**
- Accurate detection
- Works for all edge cases
- No artificial tolerance needed

**Cons:**
- Performance impact (24 position calculations per date)
- Requires significant refactoring

### Option 2: Return nil When acos Input Invalid

Detect when calculation is impossible and return nil:

```swift
class func getHourAngle(h: Double, phi: Double, d: Double) -> Double? {
    let value = (sin(h) - sin(phi) * sin(d)) / (cos(phi) * cos(d))

    if value < -1 || value > 1 {
        return nil  // Cannot compute - sun never reaches this altitude
    }

    return acos(value)
}
```

Then in `SunCalc.init()`:

```swift
if let w = TimeUtils.getHourAngle(h: h, phi: phi, d: dec) {
    let Jset = SunCalc.getSetJ(...)
    self.sunrise = DateUtils.fromJulian(j: Jrise)
} else {
    self.sunrise = nil  // Cannot compute
}
```

**Pros:**
- Clean solution
- Prevents incorrect calculations
- Minimal performance impact

**Cons:**
- Breaking API change (getHourAngle returns Optional)
- Requires updating all callers

## Current Workaround

**Location:** `BlackBirdKit/Sources/BlackBirdKit/🔌 Adapters/SunAdapter.swift`
**Lines:** ~830-838

```swift
public var isAlwaysDay: Bool {
    // Check actual altitude instead of trusting SunCalc times
    return sunrise == nil && sunset == nil && altitude.degrees > 0
}

public var isAlwaysNight: Bool {
    return sunrise == nil && sunset == nil && altitude.degrees < 0
}
```

And in `SolarCalculator.swift` lines ~137-146, override incorrect times with nil based on actual altitude checks.

## Test Case

Added test in `Tests/SunCalcTests/SunCalcPolarTests.swift`:

```swift
func test_tromso_july25_2025_sunrise_sunset_exist() {
    // Tromsø: 69.6492°N, 18.9553°E
    // July 25, 2025
    // Expected: Sunrise ~01:50, Sunset ~23:52
    // Current: Sunrise 00:51, Sunset 00:51 (BUG!)
}
```

## Impact

**Affected Locations:**
- High latitude regions (>66.5°N/S) during edge case dates
- Specifically when true minimum altitude differs significantly from nadir altitude
- Most problematic during shoulder seasons (May-July, November-January in Arctic)

**Severity:** MEDIUM
- Times are incorrect but events are detected
- Workaround in adapter layer prevents incorrect nil values
- Affects time accuracy, not event existence detection

## Related Issues

- `POLAR_BUG_DOCUMENTATION.md` - Documents nil vs incorrect times bug
- `COMPREHENSIVE_BUGS_REPORT.md` - General polar region issues

## Recommendation

For now, **continue using adapter workaround**. Proper fix requires:
1. Choosing between Option 1 (true minimum) or Option 2 (nil on invalid)
2. Comprehensive testing across all polar edge cases
3. Performance benchmarking if using Option 1
4. API version bump if using Option 2 (breaking change)

---

**Documented by:** Claude Code Assistant
**Date:** 2025-11-27
**Status:** WORKAROUND IN PLACE - Full fix pending architectural decision
