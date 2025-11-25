# SunCalc Edge Case Test Suite

Comprehensive test suite documenting bugs in SunCalc library when handling polar regions and edge cases.

## 📁 Test Files

### 1. SunCalcTests.swift (Original)
- Basic functionality tests
- ⚠️ Contains `test_sun_getTimes_invalid()` which **incorrectly expects** sunrise to exist at 84°N

### 2. SunCalcPolarTests.swift (New)
- **10 tests** covering basic polar day/night scenarios
- Tests Arctic summer (polar day) and Arctic winter (polar night)
- Tests Antarctic (South Pole) summer and winter
- Includes transition tests and Arctic Circle boundary cases

### 3. SunCalcEdgeCasesTests.swift (New) ⭐
- **23+ comprehensive tests** covering ALL solar events
- Tests every twilight type (civil, nautical, astronomical)
- Tests golden hours and blue hours
- Tests event ordering and consistency
- Tests transition periods between polar night and day

## 🎯 What We're Testing

### Solar Events Tested

| Event | Altitude | Should be nil when |
|-------|----------|-------------------|
| **Sunrise/Sunset** | -0.83° | Polar day/night |
| **Civil twilight** (dawn/dusk) | -6° | Sun always above/below -6° |
| **Nautical twilight** | -12° | Sun always above/below -12° |
| **Astronomical twilight** | -18° | Sun always above/below -18° |
| **Golden hour** | 6° above | Sun always above 6° OR never rises |
| **Blue hour** | -6° to -4° | Civil twilight missing |
| **Solar noon/nadir** | N/A | ✅ ALWAYS exist (works!) |

## 🌍 Test Locations

### Arctic (69°N - 90°N)
- **Tromsø, Norway** (69.65°N) - Classic polar conditions
- **Nordkapp, Norway** (71.17°N) - North Cape
- **Svalbard** (78°N) - Extreme polar conditions
- **Alert, Canada** (82.5°N) - One of northernmost settlements
- **Barrow, Alaska** (71.29°N) - USA polar location
- **Longyearbyen** (78.22°N) - Transition period testing
- **Murmansk, Russia** (68.97°N) - Russian Arctic
- **Hammerfest, Norway** (70.66°N) - Golden hour testing

### Subarctic (60°N - 69°N)
- **Reykjavik, Iceland** (64.15°N) - No astronomical twilight in summer
- **Rovaniemi, Finland** (66.5°N) - Arctic Circle boundary
- **Anchorage, Alaska** (61.22°N) - Limited twilight types
- **Oulu, Finland** (65.01°N) - Short winter days

### Antarctic
- **South Pole** (90°S) - Both summer and winter

### Control Locations (Normal Behavior)
- **Prague, Czech Republic** (50.08°N) - All events exist
- **Equator** (0°) - Rapid sunrise, short twilight

## 🐛 Confirmed Bugs

### High Priority
- ❌ **Sunrise/Sunset** return midnight time instead of nil in polar day/night
- ❌ **All twilight types** return times instead of nil when thresholds never crossed
- ❌ **Golden hours** return times when sun never in valid range
- ❌ **Blue hours** return identical start/end times or invalid times

### What Works
- ✅ **Solar noon and nadir** always calculated correctly
- ✅ **Event ordering** correct when events exist
- ✅ **Equator behavior** perfect
- ✅ **Equinox symmetry** accurate

## 🚀 Running Tests

### Quick Start
```bash
cd /path/to/SunCalc
./run_polar_tests.sh
```

### Manual Execution
```bash
swift test
```

### Run Specific Test
```bash
swift test --filter SunCalcPolarTests
swift test --filter SunCalcEdgeCasesTests
swift test --filter test_tromso_summer_solstice_polarDay
```

### View Detailed Output
```bash
swift test 2>&1 | grep -E "(🌞|🌙|🌅|🌍|✅|❌)"
```

## 📊 Test Output Explanation

Tests print detailed information about altitude and bug status:

```
🌞 Tromso letní slunovrat:
   Min altitude: 3.12°                     # Sun never sets
   ❌ BUG: sunrise = 22:47 (mělo by být nil)  # Should be nil!
```

Emoji meanings:
- 🌞 Polar day test
- 🌙 Polar night test
- 🌅 Civil twilight test
- 🌃 Astronomical twilight test
- 🌊 Nautical twilight test
- ✨ Golden hour test
- 💙 Blue hour test
- ☀️ Solar noon/nadir test
- 🔄 Transition period test
- ⏰ Event ordering test
- 🌍 Equator/control test
- ✅ Correct behavior identified
- ❌ Bug confirmed
- ⚠️ Warning/edge case

## 📖 Documentation

### For Quick Overview
- **POLAR_BUG_DOCUMENTATION.md** - Original polar day/night findings

### For Complete Analysis
- **COMPREHENSIVE_BUGS_REPORT.md** - Full bug report covering all event types
  - Executive summary
  - Detailed test results per event type
  - Impact assessment
  - Recommended fixes
  - Statistics

## 🔧 Workaround Implementation

Our workaround is implemented in:
```
BlackBirdKit/Sources/BlackBirdKit/🔌 Adapters/SunAdapter.swift
```

Strategy:
1. Check if location is circumpolar (|latitude| > 66.5°)
2. Calculate sun altitude at noon and midnight
3. Determine if polar day/night based on altitude
4. Override SunCalc's incorrect times with nil

```swift
if isCircumPolar {
    let midnightAlt = getSunPosition(midnight).altitude
    if midnightAlt > -0.83 {
        // Polar day: nullify all events
        sunrise = nil
        sunset = nil
        // ... etc
    }
}
```

## 📈 Coverage Statistics

- **Total tests**: 40+
- **Locations**: 15+
- **Event types**: 10
- **Bug cases**: 30+
- **Seasons tested**: All four
- **Latitude range**: 90°S to 90°N

## 🎯 Test Goals

These tests serve to:
1. **Document** the bugs clearly with reproducible cases
2. **Validate** our workaround implementation
3. **Provide** regression tests for future SunCalc fixes
4. **Demonstrate** expected behavior for edge cases
5. **Support** potential PR to SunCalc repository

## 🤝 Contributing

If you find additional edge cases:
1. Add test to `SunCalcEdgeCasesTests.swift`
2. Include location name, coordinates, and date
3. Document expected vs actual behavior
4. Add emoji marker for easy filtering
5. Update COMPREHENSIVE_BUGS_REPORT.md

## 📞 Contact

Tests created by: BlackBird Team
Date: 2025-11-25
Purpose: DayLight app polar region support
Related: Issue #[TBD] in SunCalc repository

---

**Run the tests, see the bugs, read the reports. The evidence is comprehensive.** 🎯
