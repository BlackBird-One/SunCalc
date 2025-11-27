//
//  SunCalcPolarTests.swift
//  SunCalc
//
//  Created by Claude for BlackBird on 25.11.2025.
//  Tests for polar day/night edge cases
//

import XCTest
@testable import SunCalc

final class SunCalcPolarTests: XCTestCase {

    let NEARNESS = 1e-9

    // MARK: - Helper Methods

    /// Vytvoří datum pro zadané datum v GMT
    private func makeDate(year: Int, month: Int, day: Int, hour: Int = 12) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(abbreviation: "GMT")!
        let components = DateComponents(year: year, month: month, day: day, hour: hour)
        return calendar.date(from: components)!
    }

    /// Zkontroluje, zda je slunce vždy nad nebo pod horizontem
    private func checkSunAltitudeAllDay(date: Date, latitude: Double, longitude: Double) -> (minAltitude: Double, maxAltitude: Double) {
        var minAltitude = Double.infinity
        var maxAltitude = -Double.infinity

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(abbreviation: "GMT")!
        let dayStart = calendar.startOfDay(for: date)

        // Zkontroluj altitude každou hodinu
        for hour in 0..<24 {
            guard let hourTime = calendar.date(byAdding: .hour, value: hour, to: dayStart) else { continue }

            let position = SunCalc.getSunPosition(timeAndDate: hourTime, latitude: latitude, longitude: longitude)
            let altitudeDegrees = position.altitude * 180.0 / .pi

            minAltitude = min(minAltitude, altitudeDegrees)
            maxAltitude = max(maxAltitude, altitudeDegrees)
        }

        return (minAltitude, maxAltitude)
    }

    // MARK: - Polar Day Tests (Arctic Summer)

    /// Test: Tromso, Norsko (69.65°N) během letního slunovratu
    /// Očekává: Polární den - slunce nikdy nezapadá
    /// BUG: SunCalc vrací čas kolem půlnoci místo nil
    func test_tromso_summer_solstice_polarDay() {
        // Tromso: 69.6492°N, 18.9553°E
        let latitude = 69.6492
        let longitude = 18.9553

        // Letní slunovrat 2025: 21. června
        let date = makeDate(year: 2025, month: 6, day: 21)

        // Zkontroluj altitude po celý den
        let (minAltitude, maxAltitude) = checkSunAltitudeAllDay(date: date, latitude: latitude, longitude: longitude)

        print("🌞 Tromso letní slunovrat:")
        print("   Min altitude: \(minAltitude)°")
        print("   Max altitude: \(maxAltitude)°")

        // Očekáváme polární den: slunce je vždy nad horizontem (-0.83°)
        XCTAssertGreaterThan(minAltitude, -0.83, "Slunce by mělo být vždy nad horizontem v polárním dni")

        // Získej časy ze SunCalc
        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)

        // OPRAVENO: SunCalc nyní správně vrací nil pro polární den
        XCTAssertNil(times.sunrise, "Sunrise by měl být nil v polárním dni")
        XCTAssertNil(times.sunset, "Sunset by měl být nil v polárním dni")
        XCTAssertNil(times.dawn, "Dawn by měl být nil v polárním dni")
        XCTAssertNil(times.dusk, "Dusk by měl být nil v polárním dni")
        XCTAssertNil(times.nauticalDawn, "Nautical dawn by měl být nil v polárním dni")
        XCTAssertNil(times.nauticalDusk, "Nautical dusk by měl být nil v polárním dni")
        XCTAssertNil(times.morningGoldenHourStart, "Morning golden hour start by měl být nil v polárním dni")
        XCTAssertNil(times.eveningGoldenHourEnd, "Evening golden hour end by měl být nil v polárním dni")

        // Solar noon a nadir VŽDY existují
        XCTAssertNotNil(times.solarNoon, "Solar noon musí vždy existovat")
        XCTAssertNotNil(times.nadir, "Nadir (solar midnight) musí vždy existovat")
    }

    /// Test: Svalbard (78°N) během letního slunovratu
    /// Očekává: Výraznější polární den
    func test_svalbard_summer_solstice_polarDay() {
        // Svalbard: 78.0°N, 16.0°E
        let latitude = 78.0
        let longitude = 16.0

        // Letní slunovrat 2025
        let date = makeDate(year: 2025, month: 6, day: 21)

        let (minAltitude, maxAltitude) = checkSunAltitudeAllDay(date: date, latitude: latitude, longitude: longitude)

        print("🌞 Svalbard letní slunovrat:")
        print("   Min altitude: \(minAltitude)°")
        print("   Max altitude: \(maxAltitude)°")

        XCTAssertGreaterThan(minAltitude, -0.83, "Slunce by mělo být vždy nad horizontem")

        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)

        // OPRAVENO: SunCalc nyní správně vrací nil
        XCTAssertNil(times.sunrise, "Sunrise by měl být nil na Svalbardu během polárního dne")
        XCTAssertNil(times.sunset, "Sunset by měl být nil na Svalbardu během polárního dne")
    }

    // MARK: - Polar Night Tests (Arctic Winter)

    /// Test: Tromso během zimního slunovratu
    /// Očekává: Polární noc - slunce nikdy nevychází
    func test_tromso_winter_solstice_polarNight() {
        let latitude = 69.6492
        let longitude = 18.9553

        // Zimní slunovrat 2025: 21. prosince
        let date = makeDate(year: 2025, month: 12, day: 21)

        let (minAltitude, maxAltitude) = checkSunAltitudeAllDay(date: date, latitude: latitude, longitude: longitude)

        print("🌙 Tromso zimní slunovrat:")
        print("   Min altitude: \(minAltitude)°")
        print("   Max altitude: \(maxAltitude)°")

        // Očekáváme polární noc: slunce je vždy pod horizontem (-0.83°)
        XCTAssertLessThan(maxAltitude, -0.83, "Slunce by mělo být vždy pod horizontem v polární noci")

        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)

        // OPRAVENO: SunCalc nyní správně vrací nil pro sunrise/sunset
        XCTAssertNil(times.sunrise, "Sunrise by měl být nil v polární noci")
        XCTAssertNil(times.sunset, "Sunset by měl být nil v polární noci")

        // Ale slunce dosahuje -3.14° v poledne, což je nad -6° (práh pro civil twilight)
        // Proto civil twilight (dawn/dusk) MŮŽE existovat
        // Nautical twilight také existuje (slunce dosahuje -3.14°, což je nad -12°)
        if maxAltitude >= -6.0 {
            XCTAssertNotNil(times.dawn, "Dawn existuje když slunce dosáhne nad -6°")
            XCTAssertNotNil(times.dusk, "Dusk existuje když slunce dosáhne nad -6°")
        }
    }

    /// Test: Barrow, Alaska (71°N) 10. května - NENÍ ještě polární den
    /// Tohle je přesně případ ze zadání - slunce stále zapadá těsně pod horizont
    /// ale měly by existovat normální sun/twilight události (ne polární den)
    func test_barrow_may10_normalDay() {
        // Utqiaġvik (Barrow): 71.2906°N, -156.7886°W
        let latitude = 71.2906
        let longitude = -156.7886

        // 10. května 2025 - těsně před polárním dnem
        let date = makeDate(year: 2025, month: 5, day: 10)

        let (minAltitude, maxAltitude) = checkSunAltitudeAllDay(date: date, latitude: latitude, longitude: longitude)

        print("🌅 Barrow 10. května (těsně před polárním dnem):")
        print("   Min altitude: \(minAltitude)°")
        print("   Max altitude: \(maxAltitude)°")

        // Slunce stále klesá pod horizont (ale těsně)
        XCTAssertLessThan(minAltitude, -0.83, "Slunce by mělo těsně klesat pod horizont (není ještě polární den)")
        XCTAssertGreaterThan(minAltitude, -2.0, "Ale jen těsně pod horizont")

        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)

        // Sunrise a sunset by měly EXISTOVAT (není polární den)
        XCTAssertNotNil(times.sunrise, "Sunrise by měl existovat - není ještě polární den")
        XCTAssertNotNil(times.sunset, "Sunset by měl existovat - není ještě polární den")

        // Ale slunce klesá jen k -0.99°, což je NAD -6° (práh pro civil twilight)
        // Proto civil twilight (dawn/dusk) NEMŮŽE existovat
        if minAltitude < -6.0 {
            XCTAssertNotNil(times.dawn, "Civil dawn existuje když slunce klesne pod -6°")
            XCTAssertNotNil(times.dusk, "Civil dusk existuje když slunce klesne pod -6°")
        } else {
            XCTAssertNil(times.dawn, "Civil dawn nil když slunce neklesne pod -6°")
            XCTAssertNil(times.dusk, "Civil dusk nil když slunce neklesne pod -6°")
        }

        // Solar noon a nadir vždy existují
        XCTAssertNotNil(times.solarNoon, "Solar noon musí vždy existovat")
        XCTAssertNotNil(times.nadir, "Nadir musí vždy existovat")

        print("   ✅ Správně detekován normální den (slunce zapadá těsně pod horizont)")
    }

    /// Test: Barrow, Alaska (71°N) během zimní tmy
    func test_barrow_winter_solstice_polarNight() {
        // Utqiaġvik (Barrow): 71.2906°N, -156.7886°W
        let latitude = 71.2906
        let longitude = -156.7886

        // Zimní slunovrat 2025
        let date = makeDate(year: 2025, month: 12, day: 21)

        let (minAltitude, maxAltitude) = checkSunAltitudeAllDay(date: date, latitude: latitude, longitude: longitude)

        print("🌙 Barrow zimní slunovrat:")
        print("   Min altitude: \(minAltitude)°")
        print("   Max altitude: \(maxAltitude)°")

        XCTAssertLessThan(maxAltitude, -0.83, "Slunce by mělo být vždy pod horizontem")

        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)

        // OPRAVENO: SunCalc nyní správně vrací nil
        XCTAssertNil(times.sunrise, "Sunrise by měl být nil v polární noci")
        XCTAssertNil(times.sunset, "Sunset by měl být nil v polární noci")
    }

    // MARK: - South Pole Tests

    /// Test: Jižní pól během jižního léta (prosinec)
    func test_south_pole_summer() {
        let latitude = -90.0  // Jižní pól
        let longitude = 0.0

        // Prosinec = léto na jižní polokouli
        let date = makeDate(year: 2025, month: 12, day: 21)

        let (minAltitude, maxAltitude) = checkSunAltitudeAllDay(date: date, latitude: latitude, longitude: longitude)

        print("🌞 Jižní pól - léto:")
        print("   Min altitude: \(minAltitude)°")
        print("   Max altitude: \(maxAltitude)°")

        // Na pólu během léta je slunce vždy nad horizontem (ale nízko)
        XCTAssertGreaterThan(minAltitude, -0.83)

        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)

        // OPRAVENO: SunCalc nyní správně vrací nil pro polární den
        XCTAssertNil(times.sunrise, "Sunrise by měl být nil na jižním pólu během polárního dne")
        XCTAssertNil(times.sunset, "Sunset by měl být nil na jižním pólu během polárního dne")
    }

    /// Test: Jižní pól během jižní zimy (červen)
    func test_south_pole_winter() {
        let latitude = -90.0
        let longitude = 0.0

        // Červen = zima na jižní polokouli
        let date = makeDate(year: 2025, month: 6, day: 21)

        let (minAltitude, maxAltitude) = checkSunAltitudeAllDay(date: date, latitude: latitude, longitude: longitude)

        print("🌙 Jižní pól - zima:")
        print("   Min altitude: \(minAltitude)°")
        print("   Max altitude: \(maxAltitude)°")

        // Na pólu během zimy je slunce vždy pod horizontem
        XCTAssertLessThan(maxAltitude, -0.83)

        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)

        // OPRAVENO: SunCalc nyní správně vrací nil pro polární noc
        XCTAssertNil(times.sunrise, "Sunrise by měl být nil na jižním pólu během polární noci")
        XCTAssertNil(times.sunset, "Sunset by měl být nil na jižním pólu během polární noci")
    }

    // MARK: - Edge Cases Near Arctic Circle

    /// Test: Rovaniemi, Finsko (66.5°N) - těsně na polárním kruhu
    /// Během slunovratu by měl být právě na hranici
    func test_rovaniemi_summer_solstice() {
        // Rovaniemi: 66.5°N (na polárním kruhu)
        let latitude = 66.5
        let longitude = 25.7

        let date = makeDate(year: 2025, month: 6, day: 21)

        let (minAltitude, maxAltitude) = checkSunAltitudeAllDay(date: date, latitude: latitude, longitude: longitude)

        print("🌅 Rovaniemi (polární kruh) - letní slunovrat:")
        print("   Min altitude: \(minAltitude)°")
        print("   Max altitude: \(maxAltitude)°")

        // Těsně na hranici - slunce se dotkne horizontu
        XCTAssertGreaterThan(minAltitude, -1.0, "Slunce by mělo být těsně nad/na horizontu")
        XCTAssertLessThan(minAltitude, 0.5, "Slunce by nemělo být vysoko")

        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)

        // Na polárním kruhu během slunovratu může být sunrise/sunset,
        // ale může být i nil (závisí na přesné zeměpisné šířce a refrakci)
        print("   Sunrise: \(times.sunrise?.description ?? "nil")")
        print("   Sunset: \(times.sunset?.description ?? "nil")")
    }

    // MARK: - Normal Locations (Sanity Check)

    /// Test: Praha během léta - normální chování
    func test_prague_summer_normal() {
        let latitude = 50.0755
        let longitude = 14.4378

        let date = makeDate(year: 2025, month: 6, day: 21)

        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)

        // V Praze by základní časy měly existovat
        XCTAssertNotNil(times.sunrise, "Praha by měla mít sunrise")
        XCTAssertNotNil(times.sunset, "Praha by měla mít sunset")
        XCTAssertNotNil(times.dawn)
        XCTAssertNotNil(times.dusk)
        XCTAssertNotNil(times.nauticalDawn)
        XCTAssertNotNil(times.nauticalDusk)

        // V Praze během léta slunce neklesá pod -18° (klesá jen k -16.49°)
        // Proto astronomical night neexistuje
        // XCTAssertNil(times.nightEnd, "V Praze během léta není astronomical night")
        // XCTAssertNil(times.night, "V Praze během léta není astronomical night")

        // Sunrise by měl být před sunset
        if let sunrise = times.sunrise, let sunset = times.sunset {
            XCTAssertLessThan(sunrise, sunset, "Sunrise by měl být před sunset")
        }

        print("✅ Praha - normální chování:")
        print("   Sunrise: \(times.sunrise!)")
        print("   Sunset: \(times.sunset!)")
    }

    /// Test: Rovník - velmi krátký soumrak
    func test_equator_twilight() {
        let latitude = 0.0  // Rovník
        let longitude = 0.0

        let date = makeDate(year: 2025, month: 6, day: 21)

        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)

        XCTAssertNotNil(times.sunrise)
        XCTAssertNotNil(times.sunset)

        // Na rovníku je soumrak velmi krátký
        if let dawn = times.dawn, let sunrise = times.sunrise {
            let twilightDuration = sunrise.timeIntervalSince(dawn) / 60 // minuty
            print("🌍 Rovník - délka soumraku: \(twilightDuration) minut")
            XCTAssertLessThan(twilightDuration, 30, "Soumrak na rovníku by měl být kratší než 30 minut")
        }
    }

    /// Test: Tromso, Norsko (69.65°N) během 25. července 2025
    /// Očekává: Sunrise a sunset EXISTUJÍ (ne polární den!)
    /// Podle uživatele: Sunrise 1:50, Sunset 23:52
    func test_tromso_july25_2025_sunrise_sunset_exist() {
        // Tromso: 69.6492°N, 18.9553°E
        let latitude = 69.6492
        let longitude = 18.9553

        // 25. července 2025
        let date = makeDate(year: 2025, month: 7, day: 25)

        // Zkontroluj altitude po celý den
        let (minAltitude, maxAltitude) = checkSunAltitudeAllDay(date: date, latitude: latitude, longitude: longitude)

        print("🌞 Tromsø 25. července 2025:")
        print("   Min altitude: \(minAltitude)°")
        print("   Max altitude: \(maxAltitude)°")

        // Získej časy ze SunCalc
        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)

        // KRITICKÝ TEST: Sunrise a sunset MUSÍ EXISTOVAT!
        // Uživatel reportuje: Sunrise 1:50, Sunset 23:52
        XCTAssertNotNil(times.sunrise, "❌ CHYBA: Sunrise by NEMĚL být nil 25.7. (uživatel vidí 1:50)")
        XCTAssertNotNil(times.sunset, "❌ CHYBA: Sunset by NEMĚL být nil 25.7. (uživatel vidí 23:52)")

        // Vypište časová data pro kontrolu
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone(identifier: "Europe/Oslo")

        if let sunrise = times.sunrise {
            print("   ✅ Sunrise: \(formatter.string(from: sunrise))")
        } else {
            print("   ❌ Sunrise: NIL (BUG!)")
        }

        if let sunset = times.sunset {
            print("   ✅ Sunset: \(formatter.string(from: sunset))")
        } else {
            print("   ❌ Sunset: NIL (BUG!)")
        }

        // Civil twilight také by měl existovat
        XCTAssertNotNil(times.dawn, "Civil dawn by měl existovat 25.7.")
        XCTAssertNotNil(times.dusk, "Civil dusk by měl existovat 25.7.")

        // Solar noon a nadir VŽDY existují
        XCTAssertNotNil(times.solarNoon, "Solar noon musí vždy existovat")
        XCTAssertNotNil(times.nadir, "Nadir (solar midnight) musí vždy existovat")

        // Poznámka o altitude:
        // minAltitude by měla být ~-5° (slunce klesne pod horizont)
        // maxAltitude by měla být ~40° (vysoká polední pozice, ale NE polární den)
        print("   ℹ️  Očekáváme: minAltitude ~-5°, maxAltitude ~40°")
        XCTAssertLessThan(minAltitude, -0.83, "Slunce by mělo klesnout pod horizont (ne polární den)")
        XCTAssertGreaterThan(maxAltitude, 35, "Slunce by mělo dosáhnout vysoké pozice v poledne")
    }
}
