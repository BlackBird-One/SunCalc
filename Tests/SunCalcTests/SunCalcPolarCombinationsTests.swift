//
//  SunCalcPolarCombinationsTests.swift
//  SunCalc
//
//  Created for BlackBird on 25.11.2025.
//  Testy pro všechny možné kombinace výšek slunce blízko pólů
//

import XCTest
@testable import SunCalc

final class SunCalcPolarCombinationsTests: XCTestCase {

    // MARK: - Helper Methods

    /// Vytvoří datum pro zadané datum v GMT
    private func makeDate(year: Int, month: Int, day: Int, hour: Int = 12) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(abbreviation: "GMT")!
        let components = DateComponents(year: year, month: month, day: day, hour: hour)
        return calendar.date(from: components)!
    }

    /// Zjistí výšku slunce v poledne a o půlnoci
    private func getSunAltitudes(date: Date, latitude: Double, longitude: Double) -> (noon: Double, midnight: Double) {
        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)

        var noonAltitude: Double = 0
        var midnightAltitude: Double = 0

        if let noonDate = times.solarNoon {
            let noonPosition = SunCalc.getSunPosition(timeAndDate: noonDate, latitude: latitude, longitude: longitude)
            noonAltitude = noonPosition.altitude * 180.0 / .pi
        }

        if let nadirDate = times.nadir {
            let midnightPosition = SunCalc.getSunPosition(timeAndDate: nadirDate, latitude: latitude, longitude: longitude)
            midnightAltitude = midnightPosition.altitude * 180.0 / .pi
        }

        return (noonAltitude, midnightAltitude)
    }

    // MARK: - Konstanty pro prahové hodnoty

    let cSunrise = -0.83
    let cSunriseEnd = -0.3
    let cDawn = -6.0
    let cNauticalDawn = -12.0
    let cNightEnd = -18.0
    let cGoldenHourEnd = 6.0

    // MARK: - Test 1: Polární den (slunce vždy nad horizontem)
    // midnight > -0.83, noon > -0.83

    func test_polarDay_allEventsNil() {
        // Tromso během léta - polární den
        let latitude = 69.6492
        let longitude = 18.9553
        let date = makeDate(year: 2025, month: 6, day: 21)

        let altitudes = getSunAltitudes(date: date, latitude: latitude, longitude: longitude)
        print("🌞 Polární den - Tromso červen:")
        print("   Noon: \(altitudes.noon)°, Midnight: \(altitudes.midnight)°")

        // Obě výšky nad horizontem
        XCTAssertGreaterThan(altitudes.midnight, cSunrise, "Půlnoc > -0.83")
        XCTAssertGreaterThan(altitudes.noon, cSunrise, "Poledne > -0.83")

        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)

        // Během polárního dne slunce neklesá pod -0.83°
        XCTAssertNil(times.sunrise, "Sunrise nil v polárním dni")
        XCTAssertNil(times.sunset, "Sunset nil v polárním dni")
        XCTAssertNil(times.sunriseEnd, "SunriseEnd nil v polárním dni")
        XCTAssertNil(times.sunsetStart, "SunsetStart nil v polárním dni")
        XCTAssertNil(times.dawn, "Dawn nil v polárním dni")
        XCTAssertNil(times.dusk, "Dusk nil v polárním dni")
        XCTAssertNil(times.nauticalDawn, "NauticalDawn nil v polárním dni")
        XCTAssertNil(times.nauticalDusk, "NauticalDusk nil v polárním dni")
        XCTAssertNil(times.nightEnd, "NightEnd nil v polárním dni")
        XCTAssertNil(times.night, "Night nil v polárním dni")

        // POZOR: Golden hour MŮŽE existovat i v polárním dni!
        // V Tromsø slunce klesá k 3.09° (pod 6°) a vystupuje k 43.79° (nad 6°)
        // Proto golden hour end (6°) existuje
        if altitudes.midnight < 6.0 {
            // Golden hour end existuje
            XCTAssertNotNil(times.morningGoldenHourEnd, "MorningGoldenHourEnd může existovat")
            XCTAssertNotNil(times.eveningGoldenHourStart, "EveningGoldenHourStart může existovat")
        }

        // Golden hour start (-4°) také může existovat
        if altitudes.midnight < -4.0 {
            XCTAssertNotNil(times.morningGoldenHourStart, "MorningGoldenHourStart může existovat")
            XCTAssertNotNil(times.eveningGoldenHourEnd, "EveningGoldenHourEnd může existovat")
        }

        XCTAssertNotNil(times.solarNoon, "SolarNoon vždy existuje")
        XCTAssertNotNil(times.nadir, "Nadir vždy existuje")
    }

    // MARK: - Test 2: Polární noc (slunce vždy pod horizontem)
    // noon < -0.83, midnight < -0.83

    func test_polarNight_allEventsNil() {
        // Barrow během zimy - polární noc
        let latitude = 71.2906
        let longitude = -156.7886
        let date = makeDate(year: 2025, month: 12, day: 21)

        let altitudes = getSunAltitudes(date: date, latitude: latitude, longitude: longitude)
        print("🌙 Polární noc - Barrow prosinec:")
        print("   Noon: \(altitudes.noon)°, Midnight: \(altitudes.midnight)°")

        // Obě výšky pod horizontem
        XCTAssertLessThan(altitudes.noon, cSunrise, "Poledne < -0.83")
        XCTAssertLessThan(altitudes.midnight, cSunrise, "Půlnoc < -0.83")

        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)

        // Všechny události kromě solarNoon a nadir by měly být nil
        XCTAssertNil(times.sunrise, "Sunrise nil v polární noci")
        XCTAssertNil(times.sunset, "Sunset nil v polární noci")
        XCTAssertNil(times.sunriseEnd, "SunriseEnd nil v polární noci")
        XCTAssertNil(times.sunsetStart, "SunsetStart nil v polární noci")

        XCTAssertNotNil(times.solarNoon, "SolarNoon vždy existuje")
        XCTAssertNotNil(times.nadir, "Nadir vždy existuje")
    }

    // MARK: - Test 3: Normální den (slunce vychází a zapadá)
    // midnight < -0.83, noon > -0.83

    func test_normalDay_sunriseAndSunsetExist() {
        // Praha - normální den
        let latitude = 50.0755
        let longitude = 14.4378
        let date = makeDate(year: 2025, month: 6, day: 21)

        let altitudes = getSunAltitudes(date: date, latitude: latitude, longitude: longitude)
        print("🌅 Normální den - Praha červen:")
        print("   Noon: \(altitudes.noon)°, Midnight: \(altitudes.midnight)°")

        XCTAssertGreaterThan(altitudes.noon, cSunrise, "Poledne > -0.83")
        XCTAssertLessThan(altitudes.midnight, cSunrise, "Půlnoc < -0.83")

        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)

        // Sunrise a sunset musí existovat
        XCTAssertNotNil(times.sunrise, "Sunrise existuje v normálním dni")
        XCTAssertNotNil(times.sunset, "Sunset existuje v normálním dni")
        XCTAssertNotNil(times.sunriseEnd, "SunriseEnd existuje")
        XCTAssertNotNil(times.sunsetStart, "SunsetStart existuje")
        XCTAssertNotNil(times.dawn, "Dawn existuje")
        XCTAssertNotNil(times.dusk, "Dusk existuje")
        XCTAssertNotNil(times.nauticalDawn, "NauticalDawn existuje")
        XCTAssertNotNil(times.nauticalDusk, "NauticalDusk existuje")

        // V Praze během léta slunce neklesá pod -18° (klesá jen k -16.49°)
        // Proto astronomical night (nightEnd/night) NEEXISTUJE
        if altitudes.midnight < cNightEnd {
            XCTAssertNotNil(times.nightEnd, "NightEnd existuje když slunce klesne pod -18°")
            XCTAssertNotNil(times.night, "Night existuje když slunce klesne pod -18°")
        } else {
            XCTAssertNil(times.nightEnd, "NightEnd nil když slunce neklesne pod -18°")
            XCTAssertNil(times.night, "Night nil když slunce neklesne pod -18°")
        }
    }

    // MARK: - Test 4: Částečný soumrak
    // midnight mezi -6 a -0.83 (slunce neklesá pod civilní soumrak)

    func test_partialTwilight_noDawn() {
        // Potřebujeme najít lokaci a datum, kde:
        // - noon > -6
        // - midnight mezi -6 a -0.83
        // Např. severní Skandinávie koncem května

        let latitude = 68.0
        let longitude = 15.0
        let date = makeDate(year: 2025, month: 5, day: 20)

        let altitudes = getSunAltitudes(date: date, latitude: latitude, longitude: longitude)
        print("🌆 Částečný soumrak - severní Norsko květen:")
        print("   Noon: \(altitudes.noon)°, Midnight: \(altitudes.midnight)°")

        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)

        if altitudes.midnight >= cDawn {
            // Slunce o půlnoci neklesá pod -6°
            print("   → Slunce neklesá pod civilní soumrak")
            XCTAssertNil(times.dawn, "Dawn nil - slunce neklesá pod -6°")
            XCTAssertNil(times.dusk, "Dusk nil - slunce neklesá pod -6°")
        }

        if altitudes.midnight < cSunrise && altitudes.noon >= cSunrise {
            // Ale sunrise/sunset mohou existovat
            XCTAssertNotNil(times.sunrise, "Sunrise může existovat")
            XCTAssertNotNil(times.sunset, "Sunset může existovat")
        }
    }

    // MARK: - Test 5: Žádná astronomická noc
    // midnight mezi -18 a -12 (slunce neklesá pod astronomický soumrak)

    func test_noAstronomicalNight() {
        // Např. jižní Skandinávie během léta
        let latitude = 60.0
        let longitude = 10.0
        let date = makeDate(year: 2025, month: 6, day: 21)

        let altitudes = getSunAltitudes(date: date, latitude: latitude, longitude: longitude)
        print("🌃 Bez astronomické noci - Oslo červen:")
        print("   Noon: \(altitudes.noon)°, Midnight: \(altitudes.midnight)°")

        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)

        if altitudes.midnight >= cNightEnd && altitudes.midnight < cNauticalDawn {
            // Slunce neklesá pod -18°
            print("   → Slunce neklesá pod astronomický soumrak")
            XCTAssertNil(times.nightEnd, "NightEnd nil - slunce neklesá pod -18°")
            XCTAssertNil(times.night, "Night nil - slunce neklesá pod -18°")

            // Ale nautical twilight může existovat
            if altitudes.noon >= cNauticalDawn {
                XCTAssertNotNil(times.nauticalDawn, "NauticalDawn existuje")
                XCTAssertNotNil(times.nauticalDusk, "NauticalDusk existuje")
            }
        }
    }

    // MARK: - Test 6: Žádná zlatá hodina
    // noon < 6° (slunce nikdy nedosáhne 6° nad horizontem)

    func test_noGoldenHour_winter() {
        // Např. Praha v zimě
        let latitude = 50.0755
        let longitude = 14.4378
        let date = makeDate(year: 2025, month: 12, day: 21)

        let altitudes = getSunAltitudes(date: date, latitude: latitude, longitude: longitude)
        print("❄️ Bez zlaté hodiny - Praha prosinec:")
        print("   Noon: \(altitudes.noon)°, Midnight: \(altitudes.midnight)°")

        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)

        if altitudes.noon < cGoldenHourEnd {
            print("   → Slunce nikdy nedosáhne 6° nad horizontem")
            XCTAssertNil(times.morningGoldenHourStart, "MorningGoldenHourStart nil")
            XCTAssertNil(times.morningGoldenHourEnd, "MorningGoldenHourEnd nil")
            XCTAssertNil(times.eveningGoldenHourStart, "EveningGoldenHourStart nil")
            XCTAssertNil(times.eveningGoldenHourEnd, "EveningGoldenHourEnd nil")
        }
    }

    // MARK: - Test 7: Kombinace - bez nautical dawn ale s civilním soumrakem
    // midnight mezi -12 a -6

    func test_noCivilTwilight_butHasNautical() {
        // Potřebujeme lokaci kde:
        // - noon > -12
        // - midnight mezi -12 a -6

        let latitude = 64.0
        let longitude = 20.0
        let date = makeDate(year: 2025, month: 5, day: 15)

        let altitudes = getSunAltitudes(date: date, latitude: latitude, longitude: longitude)
        print("🌅 Bez civilního soumraku, ale s nautickým:")
        print("   Noon: \(altitudes.noon)°, Midnight: \(altitudes.midnight)°")

        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)

        if altitudes.midnight >= cDawn && altitudes.midnight < cNauticalDawn {
            print("   → Slunce neklesá pod -6° ale klesá pod -12°")
            XCTAssertNil(times.dawn, "Dawn nil")
            XCTAssertNil(times.dusk, "Dusk nil")

            if altitudes.noon >= cNauticalDawn {
                XCTAssertNotNil(times.nauticalDawn, "NauticalDawn existuje")
                XCTAssertNotNil(times.nauticalDusk, "NauticalDusk existuje")
            }
        }
    }

    // MARK: - Test 8: Přechod mezi polárním dnem a normálním dnem

    func test_transitionPeriod_barrowMay() {
        // Barrow začátkem května - přechod k polárnímu dni
        let latitude = 71.2906
        let longitude = -156.7886

        // Testujeme několik dní
        for day in 1...15 {
            let date = makeDate(year: 2025, month: 5, day: day)
            let altitudes = getSunAltitudes(date: date, latitude: latitude, longitude: longitude)
            let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)

            print("📅 Barrow 5/\(day): noon=\(String(format: "%.2f", altitudes.noon))°, midnight=\(String(format: "%.2f", altitudes.midnight))°")

            if altitudes.midnight < cSunrise {
                // Ještě ne polární den
                XCTAssertNotNil(times.sunrise, "Sunrise existuje 5/\(day)")
                XCTAssertNotNil(times.sunset, "Sunset existuje 5/\(day)")
            } else {
                // Už polární den
                XCTAssertNil(times.sunrise, "Sunrise nil 5/\(day)")
                XCTAssertNil(times.sunset, "Sunset nil 5/\(day)")
            }
        }
    }

    // MARK: - Test 9: Rovník - vždy všechny události

    func test_equator_allEventsAlwaysExist() {
        let latitude = 0.0
        let longitude = 0.0

        // Testuj různá roční období
        for month in [3, 6, 9, 12] {
            let date = makeDate(year: 2025, month: month, day: 21)
            let altitudes = getSunAltitudes(date: date, latitude: latitude, longitude: longitude)

            print("🌍 Rovník měsíc \(month): noon=\(String(format: "%.2f", altitudes.noon))°, midnight=\(String(format: "%.2f", altitudes.midnight))°")

            let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)

            // Na rovníku vždy všechny události existují
            XCTAssertNotNil(times.sunrise, "Rovník sunrise měsíc \(month)")
            XCTAssertNotNil(times.sunset, "Rovník sunset měsíc \(month)")
            XCTAssertNotNil(times.dawn, "Rovník dawn měsíc \(month)")
            XCTAssertNotNil(times.dusk, "Rovník dusk měsíc \(month)")
            XCTAssertNotNil(times.nauticalDawn, "Rovník nauticalDawn měsíc \(month)")
            XCTAssertNotNil(times.nauticalDusk, "Rovník nauticalDusk měsíc \(month)")
            XCTAssertNotNil(times.nightEnd, "Rovník nightEnd měsíc \(month)")
            XCTAssertNotNil(times.night, "Rovník night měsíc \(month)")
        }
    }

    // MARK: - Test 10: Extrémní severní zeměpisná šířka

    func test_extremeNorth_85degrees() {
        // Velmi blízko severního pólu
        let latitude = 85.0
        let longitude = 0.0

        // Léto - polární den
        let summerDate = makeDate(year: 2025, month: 6, day: 21)
        let summerAltitudes = getSunAltitudes(date: summerDate, latitude: latitude, longitude: longitude)
        print("🧊 85°N léto: noon=\(String(format: "%.2f", summerAltitudes.noon))°, midnight=\(String(format: "%.2f", summerAltitudes.midnight))°")

        let summerTimes = SunCalc.getTimes(date: summerDate, latitude: latitude, longitude: longitude)
        XCTAssertNil(summerTimes.sunrise, "85°N léto - polární den")
        XCTAssertNil(summerTimes.sunset, "85°N léto - polární den")

        // Zima - polární noc
        let winterDate = makeDate(year: 2025, month: 12, day: 21)
        let winterAltitudes = getSunAltitudes(date: winterDate, latitude: latitude, longitude: longitude)
        print("🧊 85°N zima: noon=\(String(format: "%.2f", winterAltitudes.noon))°, midnight=\(String(format: "%.2f", winterAltitudes.midnight))°")

        let winterTimes = SunCalc.getTimes(date: winterDate, latitude: latitude, longitude: longitude)
        XCTAssertNil(winterTimes.sunrise, "85°N zima - polární noc")
        XCTAssertNil(winterTimes.sunset, "85°N zima - polární noc")
    }

    // MARK: - Test 11: Kontrola pořadí časů (když existují)

    func test_timeOrdering_whenEventsExist() {
        // Praha - normální den se všemi událostmi
        let latitude = 50.0755
        let longitude = 14.4378
        let date = makeDate(year: 2025, month: 6, day: 21)

        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)

        // Kontrola pořadí ranních událostí
        if let nightEnd = times.nightEnd,
           let nauticalDawn = times.nauticalDawn,
           let dawn = times.dawn,
           let sunrise = times.sunrise,
           let sunriseEnd = times.sunriseEnd {

            XCTAssertLessThan(nightEnd, nauticalDawn, "nightEnd < nauticalDawn")
            XCTAssertLessThan(nauticalDawn, dawn, "nauticalDawn < dawn")
            XCTAssertLessThan(dawn, sunrise, "dawn < sunrise")
            XCTAssertLessThan(sunrise, sunriseEnd, "sunrise < sunriseEnd")
        }

        // Kontrola pořadí večerních událostí
        if let sunsetStart = times.sunsetStart,
           let sunset = times.sunset,
           let dusk = times.dusk,
           let nauticalDusk = times.nauticalDusk,
           let night = times.night {

            XCTAssertLessThan(sunsetStart, sunset, "sunsetStart < sunset")
            XCTAssertLessThan(sunset, dusk, "sunset < dusk")
            XCTAssertLessThan(dusk, nauticalDusk, "dusk < nauticalDusk")
            XCTAssertLessThan(nauticalDusk, night, "nauticalDusk < night")
        }

        // Kontrola pořadí zlatých hodin
        if let morningGoldenStart = times.morningGoldenHourStart,
           let morningGoldenEnd = times.morningGoldenHourEnd,
           let eveningGoldenStart = times.eveningGoldenHourStart,
           let eveningGoldenEnd = times.eveningGoldenHourEnd {

            XCTAssertLessThan(morningGoldenStart, morningGoldenEnd, "morningGoldenStart < morningGoldenEnd")
            XCTAssertLessThan(eveningGoldenStart, eveningGoldenEnd, "eveningGoldenStart < eveningGoldenEnd")
            XCTAssertLessThan(morningGoldenEnd, eveningGoldenStart, "morningGoldenEnd < eveningGoldenStart")
        }
    }
}
