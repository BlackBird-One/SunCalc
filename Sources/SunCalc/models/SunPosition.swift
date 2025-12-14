//
//  SunPosition.swift
//  suncalc-example
//
//  Created by Shaun Meredith on 10/2/14.
//

import Foundation

public class SunPosition {
	public var azimuth: Double
	public var altitude: Double

	init(azimuth: Double, altitude: Double) {
		self.azimuth = azimuth
		self.altitude = altitude
	}

    public var altitudeDegrees: Double {
        altitude * 180.0 / .pi
    }

    public var azimuthDegrees: Double {
        180.0 + azimuth * 180.0 / .pi
    }

    /// Normalizuje azimut na rozsah 0-360°
    public var azimuthDegreesNormalized: Double {
        var normalized = 180.0 + azimuth * 180.0 / .pi
        normalized = normalized.truncatingRemainder(dividingBy: 360.0)
        if normalized < 0 {
            normalized += 360.0
        }
        return normalized
    }
}
