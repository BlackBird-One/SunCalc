# SunCalc Polar Day/Night Bug Documentation

## Problem Summary

SunCalc returns **incorrect times** (usually near midnight) instead of `nil` for sunrise/sunset events in polar regions where the sun never rises or never sets.

## Bug Confirmation

Tests in `Tests/SunCalcTests/SunCalcPolarTests.swift` demonstrate this issue:

### Test Results

#### ❌ Tromsø, Norway (69.65°N) - Summer Solstice
```
Expected: Polar day (sun never sets)
Reality:  Min altitude = 3.12° (always above horizon)
Bug:      sunrise = 22:47 UTC (should be nil)
          sunset  = 22:47 UTC (should be nil)
```

#### ❌ Svalbard (78°N) - Summer Solstice
```
Expected: Polar day
Reality:  Min altitude = 11.44° (always above horizon)
Bug:      sunrise = 22:59 UTC (should be nil)
```

#### ❌ Tromsø - Winter Solstice
```
Expected: Polar night (sun never rises)
Reality:  Max altitude = -3.14° (always below horizon)
Bug:      sunrise/sunset returned (should be nil)
```

## Root Cause

In `SunCalc.swift` lines 209-214:

```swift
var h: Double = -0.83
var Jset: Double = SunCalc.getSetJ(h: h * Constants.RAD(), phi: phi, dec: dec, lw: lw, n: n, M: M, L: L)
var Jrise: Double = Jnoon - (Jset - Jnoon)

self.sunrise = DateUtils.fromJulian(j: Jrise)
self.sunset = DateUtils.fromJulian(j: Jset)
```

The `getSetJ()` function uses `acos()` which returns `NaN` when the argument is outside [-1, 1]. This happens in polar regions where the calculation becomes mathematically invalid (sun never crosses the horizon).

However, the code doesn't check for `NaN` and continues to calculate with invalid values, resulting in dates that correspond to the **solar nadir** (lowest point = midnight) instead of returning `nil`.

## Expected Behavior

According to astronomical principles:

- **Polar Day**: When `altitude(midnight) > -0.83°` → sunrise/sunset should be `nil`
- **Polar Night**: When `altitude(noon) < -0.83°` → sunrise/sunset should be `nil`

The `-0.83°` threshold accounts for atmospheric refraction at the horizon.

## Workaround Implementation

Since fixing SunCalc directly would require forking the library, we implemented a workaround in our adapter layer (`SunCalcAdapter.swift`):

```swift
// STEP 1: Detect polar conditions using altitude
if isCircumPolar {
    let midnightPosition = SunCalc.getSunPosition(timeAndDate: midnight, ...)
    let midnightAltitude = midnightPosition.altitude * 180.0 / .pi

    if midnightAltitude > -0.83 {
        isPolarDay = true
    }

    let noonPosition = SunCalc.getSunPosition(timeAndDate: noon, ...)
    let noonAltitude = noonPosition.altitude * 180.0 / .pi

    if noonAltitude < -0.83 {
        isPolarNight = true
    }
}

// STEP 2: Override invalid times with nil
if isPolarDay || isPolarNight {
    self._sunrise = nil
    self._sunset = nil
    // ... all other twilight times = nil
}
```

This checks the physical reality (sun position) rather than trusting SunCalc's output.

## Test Locations

Our tests cover:

### Arctic (Summer)
- ✅ **Tromsø, Norway** (69.65°N) - Classic polar day example
- ✅ **Svalbard** (78°N) - More extreme polar day
- ✅ **Rovaniemi, Finland** (66.5°N) - Edge case at Arctic Circle

### Arctic (Winter)
- ✅ **Tromsø** - Polar night
- ✅ **Barrow, Alaska** (71.29°N) - Extended polar night

### Antarctic
- ✅ **South Pole** (90°S) - Summer (December) and Winter (June)

### Normal (Sanity Checks)
- ✅ **Prague** (50°N) - Normal behavior
- ✅ **Equator** (0°) - Very short twilight

## How to Run Tests

```bash
cd /path/to/SunCalc
swift test
```

Look for output like:
```
🌞 Tromso letní slunovrat:
   Min altitude: 3.12°
   ❌ BUG: sunrise = 22:47 (mělo by být nil)
```

## Impact

This bug affects:
- Navigation apps in polar regions
- Photography apps (golden hour calculations)
- Circadian rhythm apps
- Any app showing sunrise/sunset times above 66.5° latitude

## Recommendations

1. **Short term**: Use our workaround (check altitude before trusting times)
2. **Long term**:
   - Submit PR to SunCalc with fix
   - Add `NaN` checks after `acos()` calls
   - Return `nil` when calculations are invalid

## Related Issues

- The existing `test_sun_getTimes_invalid()` test at 84°N **incorrectly expects** sunrise to NOT be nil (line 63)
- This test should be updated to reflect proper polar day/night behavior

## Credits

Bug discovered and documented by BlackBird team (2025-11-25)
Tests written to demonstrate the issue across multiple polar locations
Workaround implemented in BlackBirdKit/SunCalcAdapter.swift
