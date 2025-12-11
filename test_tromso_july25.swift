#!/usr/bin/env swift

import Foundation

// Načti SunCalc (musíme být v build directoru)
// Tento script se spustí přes: swift build && swift run

print("🔍 TEST: Tromsø 25. července 2025")
print("📍 Lokace: 69.6492°N, 18.9553°E")
print("")

let latitude = 69.6492
let longitude = 18.9553

// Vytvoř datum: 25. července 2025, 12:00 UTC+2 (Oslo timezone)
var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(identifier: "Europe/Oslo")!

var components = DateComponents()
components.year = 2025
components.month = 7
components.day = 25
components.hour = 12
components.minute = 0

guard let testDate = calendar.date(from: components) else {
    print("❌ Nelze vytvořit datum")
    exit(1)
}

print("📅 Datum: \(testDate)")
print("")

// NOTE: Toto je placeholder - skutečný test musí běžet jako součást Swift package
print("⚠️  Pro skutečný test spusť: cd /Users/MIKU/Projects/BlackBird/SunCalc && swift test")
print("")
print("Nebo přidej test do Tests/SunCalcTests/")
