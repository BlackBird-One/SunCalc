//
//  SunCalcBarrowTransitionTests.swift
//  SunCalc
//
//  Created for BlackBird on 25.11.2025.
//  Detailní testy přechodu do polárního dne v Utqiaġvik (Barrow), Alaska
//  9. května až 12. května 2025
//

import XCTest
@testable import SunCalc

final class SunCalcBarrowTransitionTests: XCTestCase {

    // Utqiaġvik (Barrow), Alaska
    let latitude = 71.2906
    let longitude = -156.7886

    // Konstanty pro prahy
    let cSunrise = -0.83
    let cSunriseEnd = -0.3
    let cDawn = -6.0
    let cNauticalDawn = -12.0
    let cNightEnd = -18.0
    let cGoldenHourStart = -4.0
    let cGoldenHourEnd = 6.0

    // MARK: - Helper Methods

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(abbreviation: "GMT")!
        let components = DateComponents(year: year, month: month, day: day, hour: 12)
        return calendar.date(from: components)!
    }

    private func getSunAltitudes(date: Date) -> (noon: Double, midnight: Double) {
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

    private func printEventSummary(date: Date, times: SunCalc, altitudes: (noon: Double, midnight: Double)) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "GMT")

        print("\n📅 Datum: \(date)")
        print("   ☀️ Noon altitude: \(String(format: "%.2f", altitudes.noon))°")
        print("   🌙 Midnight altitude: \(String(format: "%.2f", altitudes.midnight))°")
        print("   Sunrise: \(times.sunrise != nil ? formatter.string(from: times.sunrise!) : "nil")")
        print("   Sunset: \(times.sunset != nil ? formatter.string(from: times.sunset!) : "nil")")
        print("   Dawn: \(times.dawn != nil ? formatter.string(from: times.dawn!) : "nil")")
        print("   Dusk: \(times.dusk != nil ? formatter.string(from: times.dusk!) : "nil")")
        print("   Nautical dawn: \(times.nauticalDawn != nil ? formatter.string(from: times.nauticalDawn!) : "nil")")
        print("   Nautical dusk: \(times.nauticalDusk != nil ? formatter.string(from: times.nauticalDusk!) : "nil")")
        print("   Night end: \(times.nightEnd != nil ? formatter.string(from: times.nightEnd!) : "nil")")
        print("   Night: \(times.night != nil ? formatter.string(from: times.night!) : "nil")")
        print("   Morning golden hour start: \(times.morningGoldenHourStart != nil ? formatter.string(from: times.morningGoldenHourStart!) : "nil")")
        print("   Morning golden hour end: \(times.morningGoldenHourEnd != nil ? formatter.string(from: times.morningGoldenHourEnd!) : "nil")")
        print("   Evening golden hour start: \(times.eveningGoldenHourStart != nil ? formatter.string(from: times.eveningGoldenHourStart!) : "nil")")
        print("   Evening golden hour end: \(times.eveningGoldenHourEnd != nil ? formatter.string(from: times.eveningGoldenHourEnd!) : "nil")")
    }

    // MARK: - 9. května 2025

    func test_barrow_2025_05_09() {
        let date = makeDate(year: 2025, month: 5, day: 9)
        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)
        let altitudes = getSunAltitudes(date: date)

        printEventSummary(date: date, times: times, altitudes: altitudes)

        // Očekávané hodnoty
        XCTAssertGreaterThan(altitudes.noon, cSunrise, "V poledne by slunce mělo být nad horizontem")
        XCTAssertLessThan(altitudes.midnight, cSunrise, "O půlnoci by slunce mělo být pod horizontem")

        // Sunrise a sunset musí existovat (ještě není polární den)
        XCTAssertNotNil(times.sunrise, "9.5. - Sunrise by měl existovat")
        XCTAssertNotNil(times.sunset, "9.5. - Sunset by měl existovat")
        XCTAssertNotNil(times.sunriseEnd, "9.5. - SunriseEnd by měl existovat")
        XCTAssertNotNil(times.sunsetStart, "9.5. - SunsetStart by měl existovat")

        // Kontrola dawn/dusk podle midnight altitude
        if altitudes.midnight < cDawn {
            XCTAssertNotNil(times.dawn, "9.5. - Dawn by měl existovat když slunce klesne pod -6°")
            XCTAssertNotNil(times.dusk, "9.5. - Dusk by měl existovat když slunce klesne pod -6°")
        } else {
            XCTAssertNil(times.dawn, "9.5. - Dawn by měl být nil když slunce neklesne pod -6°")
            XCTAssertNil(times.dusk, "9.5. - Dusk by měl být nil když slunce neklesne pod -6°")
        }

        // Kontrola nautical podle midnight altitude
        if altitudes.midnight < cNauticalDawn {
            XCTAssertNotNil(times.nauticalDawn, "9.5. - NauticalDawn by měl existovat")
            XCTAssertNotNil(times.nauticalDusk, "9.5. - NauticalDusk by měl existovat")
        } else {
            XCTAssertNil(times.nauticalDawn, "9.5. - NauticalDawn by měl být nil")
            XCTAssertNil(times.nauticalDusk, "9.5. - NauticalDusk by měl být nil")
        }

        // Kontrola astronomical night
        if altitudes.midnight < cNightEnd {
            XCTAssertNotNil(times.nightEnd, "9.5. - NightEnd by měl existovat")
            XCTAssertNotNil(times.night, "9.5. - Night by měl existovat")
        } else {
            XCTAssertNil(times.nightEnd, "9.5. - NightEnd by měl být nil")
            XCTAssertNil(times.night, "9.5. - Night by měl být nil")
        }

        // Kontrola golden hour
        if altitudes.midnight < cGoldenHourEnd && altitudes.noon >= cGoldenHourEnd {
            XCTAssertNotNil(times.morningGoldenHourEnd, "9.5. - MorningGoldenHourEnd by měl existovat")
            XCTAssertNotNil(times.eveningGoldenHourStart, "9.5. - EveningGoldenHourStart by měl existovat")
        }

        if altitudes.midnight < cGoldenHourStart && altitudes.noon >= cGoldenHourStart {
            XCTAssertNotNil(times.morningGoldenHourStart, "9.5. - MorningGoldenHourStart by měl existovat")
            XCTAssertNotNil(times.eveningGoldenHourEnd, "9.5. - EveningGoldenHourEnd by měl existovat")
        }

        // Solar noon a nadir vždy existují
        XCTAssertNotNil(times.solarNoon, "9.5. - SolarNoon musí existovat")
        XCTAssertNotNil(times.nadir, "9.5. - Nadir musí existovat")
    }

    // MARK: - 10. května 2025

    func test_barrow_2025_05_10() {
        let date = makeDate(year: 2025, month: 5, day: 10)
        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)
        let altitudes = getSunAltitudes(date: date)

        printEventSummary(date: date, times: times, altitudes: altitudes)

        // Očekávané hodnoty
        XCTAssertGreaterThan(altitudes.noon, cSunrise, "V poledne by slunce mělo být nad horizontem")

        // 10.5. je kritický den - slunce klesá těsně pod horizont
        if altitudes.midnight < cSunrise {
            // Ještě normální den
            XCTAssertNotNil(times.sunrise, "10.5. - Sunrise by měl existovat")
            XCTAssertNotNil(times.sunset, "10.5. - Sunset by měl existovat")
            XCTAssertNotNil(times.sunriseEnd, "10.5. - SunriseEnd by měl existovat")
            XCTAssertNotNil(times.sunsetStart, "10.5. - SunsetStart by měl existovat")
        } else {
            // Začíná polární den
            XCTAssertNil(times.sunrise, "10.5. - Sunrise by měl být nil v polárním dni")
            XCTAssertNil(times.sunset, "10.5. - Sunset by měl být nil v polárním dni")
            XCTAssertNil(times.sunriseEnd, "10.5. - SunriseEnd by měl být nil")
            XCTAssertNil(times.sunsetStart, "10.5. - SunsetStart by měl být nil")
        }

        // Dawn/dusk kontrola
        if altitudes.midnight < cDawn {
            XCTAssertNotNil(times.dawn, "10.5. - Dawn by měl existovat")
            XCTAssertNotNil(times.dusk, "10.5. - Dusk by měl existovat")
        } else {
            XCTAssertNil(times.dawn, "10.5. - Dawn by měl být nil")
            XCTAssertNil(times.dusk, "10.5. - Dusk by měl být nil")
        }

        // Nautical kontrola
        if altitudes.midnight < cNauticalDawn {
            XCTAssertNotNil(times.nauticalDawn, "10.5. - NauticalDawn by měl existovat")
            XCTAssertNotNil(times.nauticalDusk, "10.5. - NauticalDusk by měl existovat")
        } else {
            XCTAssertNil(times.nauticalDawn, "10.5. - NauticalDawn by měl být nil")
            XCTAssertNil(times.nauticalDusk, "10.5. - NauticalDusk by měl být nil")
        }

        // Astronomical night kontrola
        if altitudes.midnight < cNightEnd {
            XCTAssertNotNil(times.nightEnd, "10.5. - NightEnd by měl existovat")
            XCTAssertNotNil(times.night, "10.5. - Night by měl existovat")
        } else {
            XCTAssertNil(times.nightEnd, "10.5. - NightEnd by měl být nil")
            XCTAssertNil(times.night, "10.5. - Night by měl být nil")
        }

        // Solar noon a nadir vždy existují
        XCTAssertNotNil(times.solarNoon, "10.5. - SolarNoon musí existovat")
        XCTAssertNotNil(times.nadir, "10.5. - Nadir musí existovat")
    }

    // MARK: - 11. května 2025

    func test_barrow_2025_05_11() {
        let date = makeDate(year: 2025, month: 5, day: 11)
        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)
        let altitudes = getSunAltitudes(date: date)

        printEventSummary(date: date, times: times, altitudes: altitudes)

        // Očekávané hodnoty
        XCTAssertGreaterThan(altitudes.noon, cSunrise, "V poledne by slunce mělo být nad horizontem")

        // 11.5. - podle výpočtu je midnight -0.82°, což je těsně nad prahem -0.83°
        // To znamená polární den! Slunce neklesá pod -0.83°
        if altitudes.midnight >= cSunrise {
            // Polární den začal
            print("   🌞 POLÁRNÍ DEN - slunce neklesá pod horizont (-0.83°)")
            XCTAssertNil(times.sunrise, "11.5. - Sunrise by měl být nil v polárním dni")
            XCTAssertNil(times.sunset, "11.5. - Sunset by měl být nil v polárním dni")
        } else {
            // Ještě normální den
            print("   🌅 Ještě normální den - slunce klesá pod -0.83°")
            XCTAssertNotNil(times.sunrise, "11.5. - Sunrise by měl existovat")
            XCTAssertNotNil(times.sunset, "11.5. - Sunset by měl existovat")
        }

        // SunriseEnd/SunsetStart mají jiný práh (-0.3°), takže mohou existovat i když sunrise/sunset je nil
        if altitudes.midnight >= cSunriseEnd {
            XCTAssertNil(times.sunriseEnd, "11.5. - SunriseEnd by měl být nil když slunce neklesá pod -0.3°")
            XCTAssertNil(times.sunsetStart, "11.5. - SunsetStart by měl být nil když slunce neklesá pod -0.3°")
        }

        // Dawn/dusk/nautical/night by měly být nil (slunce neklesá tak hluboko)
        XCTAssertNil(times.dawn, "11.5. - Dawn by měl být nil")
        XCTAssertNil(times.dusk, "11.5. - Dusk by měl být nil")
        XCTAssertNil(times.nauticalDawn, "11.5. - NauticalDawn by měl být nil")
        XCTAssertNil(times.nauticalDusk, "11.5. - NauticalDusk by měl být nil")
        XCTAssertNil(times.nightEnd, "11.5. - NightEnd by měl být nil")
        XCTAssertNil(times.night, "11.5. - Night by měl být nil")

        // Golden hour může stále existovat i v polárním dni
        if altitudes.midnight < cGoldenHourEnd && altitudes.noon >= cGoldenHourEnd {
            XCTAssertNotNil(times.morningGoldenHourEnd, "11.5. - MorningGoldenHourEnd může existovat")
            XCTAssertNotNil(times.eveningGoldenHourStart, "11.5. - EveningGoldenHourStart může existovat")
        }

        // Solar noon a nadir vždy existují
        XCTAssertNotNil(times.solarNoon, "11.5. - SolarNoon musí existovat")
        XCTAssertNotNil(times.nadir, "11.5. - Nadir musí existovat")
    }

    // MARK: - 12. května 2025

    func test_barrow_2025_05_12() {
        let date = makeDate(year: 2025, month: 5, day: 12)
        let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)
        let altitudes = getSunAltitudes(date: date)

        printEventSummary(date: date, times: times, altitudes: altitudes)

        // Očekávané hodnoty
        XCTAssertGreaterThan(altitudes.noon, cSunrise, "V poledne by slunce mělo být nad horizontem")

        // 12.5. - midnight je -0.56°, což je těsně nad prahem -0.83°
        if altitudes.midnight >= cSunrise {
            print("   🌞 POLÁRNÍ DEN - slunce neklesá pod horizont (-0.83°)")
            XCTAssertNil(times.sunrise, "12.5. - Sunrise by měl být nil v polárním dni")
            XCTAssertNil(times.sunset, "12.5. - Sunset by měl být nil v polárním dni")
        } else {
            print("   🌅 Ještě normální den - slunce klesá pod -0.83°")
            XCTAssertNotNil(times.sunrise, "12.5. - Sunrise by měl existovat")
            XCTAssertNotNil(times.sunset, "12.5. - Sunset by měl existovat")
        }

        // SunriseEnd/SunsetStart kontrola
        if altitudes.midnight >= cSunriseEnd {
            XCTAssertNil(times.sunriseEnd, "12.5. - SunriseEnd by měl být nil když slunce neklesá pod -0.3°")
            XCTAssertNil(times.sunsetStart, "12.5. - SunsetStart by měl být nil když slunce neklesá pod -0.3°")
        }

        // Dawn/dusk/nautical/night by měly být nil
        XCTAssertNil(times.dawn, "12.5. - Dawn by měl být nil")
        XCTAssertNil(times.dusk, "12.5. - Dusk by měl být nil")
        XCTAssertNil(times.nauticalDawn, "12.5. - NauticalDawn by měl být nil")
        XCTAssertNil(times.nauticalDusk, "12.5. - NauticalDusk by měl být nil")
        XCTAssertNil(times.nightEnd, "12.5. - NightEnd by měl být nil")
        XCTAssertNil(times.night, "12.5. - Night by měl být nil")

        // Golden hour může stále existovat
        if altitudes.midnight < cGoldenHourEnd {
            XCTAssertNotNil(times.morningGoldenHourEnd, "12.5. - MorningGoldenHourEnd může existovat")
            XCTAssertNotNil(times.eveningGoldenHourStart, "12.5. - EveningGoldenHourStart může existovat")
        }

        // Solar noon a nadir vždy existují
        XCTAssertNotNil(times.solarNoon, "12.5. - SolarNoon musí existovat")
        XCTAssertNotNil(times.nadir, "12.5. - Nadir musí existovat")
    }

    // MARK: - Kompletní přehled všech 4 dní

    func test_barrow_transition_complete_overview() {
        print("\n" + String(repeating: "=", count: 80))
        print("KOMPLETNÍ PŘEHLED: Přechod do polárního dne v Utqiaġvik (Barrow)")
        print("9. května až 12. května 2025")
        print(String(repeating: "=", count: 80))

        for day in 9...12 {
            let date = makeDate(year: 2025, month: 5, day: day)
            let times = SunCalc.getTimes(date: date, latitude: latitude, longitude: longitude)
            let altitudes = getSunAltitudes(date: date)

            printEventSummary(date: date, times: times, altitudes: altitudes)

            // Kontrola konzistence dat
            if let sunrise = times.sunrise, let sunset = times.sunset {
                XCTAssertLessThan(sunrise, sunset, "\(day).5. - Sunrise by měl být před sunset")
            }

            if let dawn = times.dawn, let sunrise = times.sunrise {
                XCTAssertLessThan(dawn, sunrise, "\(day).5. - Dawn by měl být před sunrise")
            }

            if let sunset = times.sunset, let dusk = times.dusk {
                XCTAssertLessThan(sunset, dusk, "\(day).5. - Sunset by měl být před dusk")
            }

            if let nauticalDawn = times.nauticalDawn, let dawn = times.dawn {
                XCTAssertLessThan(nauticalDawn, dawn, "\(day).5. - NauticalDawn by měl být před dawn")
            }

            if let dusk = times.dusk, let nauticalDusk = times.nauticalDusk {
                XCTAssertLessThan(dusk, nauticalDusk, "\(day).5. - Dusk by měl být před nauticalDusk")
            }

            if let nightEnd = times.nightEnd, let nauticalDawn = times.nauticalDawn {
                XCTAssertLessThan(nightEnd, nauticalDawn, "\(day).5. - NightEnd by měl být před nauticalDawn")
            }

            if let nauticalDusk = times.nauticalDusk, let night = times.night {
                XCTAssertLessThan(nauticalDusk, night, "\(day).5. - NauticalDusk by měl být před night")
            }

            // Golden hour pořadí
            if let morningGoldenStart = times.morningGoldenHourStart,
               let morningGoldenEnd = times.morningGoldenHourEnd {
                XCTAssertLessThan(morningGoldenStart, morningGoldenEnd,
                                "\(day).5. - MorningGoldenHourStart by měl být před MorningGoldenHourEnd")
            }

            if let eveningGoldenStart = times.eveningGoldenHourStart,
               let eveningGoldenEnd = times.eveningGoldenHourEnd {
                XCTAssertLessThan(eveningGoldenStart, eveningGoldenEnd,
                                "\(day).5. - EveningGoldenHourStart by měl být před EveningGoldenHourEnd")
            }
        }

        print(String(repeating: "=", count: 80))
    }

    // MARK: - Test postupného zvyšování midnight altitude

    func test_barrow_midnight_altitude_progression() {
        print("\n📊 Progrese midnight altitude:")

        var previousMidnight: Double?

        for day in 9...12 {
            let date = makeDate(year: 2025, month: 5, day: day)
            let altitudes = getSunAltitudes(date: date)

            print(String(format: "   %d.5.: noon=%.2f°, midnight=%.2f°",
                        day, altitudes.noon, altitudes.midnight))

            // Midnight altitude by se měla zvyšovat každý den (blížíme se k polárnímu dni)
            if let prev = previousMidnight {
                XCTAssertGreaterThan(altitudes.midnight, prev,
                                    "Midnight altitude by se měla zvyšovat: \(day).5.")
            }

            previousMidnight = altitudes.midnight
        }

        // Kontrola přechodu přes práh sunrise (-0.83°)
        let day9 = getSunAltitudes(date: makeDate(year: 2025, month: 5, day: 9))
        let day11 = getSunAltitudes(date: makeDate(year: 2025, month: 5, day: 11))
        let day12 = getSunAltitudes(date: makeDate(year: 2025, month: 5, day: 12))

        if day9.midnight < cSunrise {
            print("   ✅ 9.5.: pod horizontem (\(String(format: "%.2f", day9.midnight))°)")
        }

        if day11.midnight >= cSunrise {
            print("   ✅ 11.5.: nad horizontem (\(String(format: "%.2f", day11.midnight))°) - ZAČÍNÁ POLÁRNÍ DEN")
        }

        if day12.midnight >= cSunrise {
            print("   ✅ 12.5.: nad horizontem (\(String(format: "%.2f", day12.midnight))°) - POLÁRNÍ DEN POKRAČUJE")
        }
    }
}
