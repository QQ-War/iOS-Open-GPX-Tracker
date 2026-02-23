//
//  GPXTrackSegment+MapKit.swift
//  OpenGpxTracker
//
//  Created by merlos on 20/09/14.
//

import Foundation
import UIKit
import MapKit
import CoreGPX

///
/// This extension adds some methods to work with MapKit
///
#if os(iOS)
extension GPXTrackSegment {
    
    /// Returns a MapKit polyline with the points of the segment.
    /// This polyline can be directly plotted on the map as an overlay
    public var overlay: MKPolyline {
        var coords: [CLLocationCoordinate2D] = self.trackPointsToCoordinates()
        let pl = MKPolyline(coordinates: &coords, count: coords.count)
        return pl
    }
}
#endif

extension GPXTrackSegment {
  
    /// Helper method to create the polyline. Returns the array of coordinates of the points
    /// that belong to this segment
    func trackPointsToCoordinates() -> [CLLocationCoordinate2D] {
        var coords: [CLLocationCoordinate2D] = []
        for point in self.points {
            coords.append(point.coordinate)
        }
        return coords
    }
    
    /// Calculates length in meters of the segment
    func length() -> CLLocationDistance {
        var length: CLLocationDistance = 0.0
        var distanceTwoPoints: CLLocationDistance
        // We need at least two points
        if self.points.count < 2 {
            return length
        }
        var prev: CLLocation? // Previous
        for point in self.points {
            guard let latitude = point.latitude, let longitude = point.longitude else {
                continue
            }
            let pt = CLLocation(latitude: latitude, longitude: longitude)
            if prev == nil { // If first point => set it as previous and go for next
                prev = pt
                continue
            }
            distanceTwoPoints = pt.distance(from: prev!)
            length += distanceTwoPoints
            // Set current point as previous point
            prev = pt
        }
        return length
    }
    
    /// Calculates elevation gain in meters of the segment
    func elevationGain() -> Double {
        var gain: Double = 0.0
        if self.points.count < 2 {
            return gain
        }
        var prev: Double?
        for point in self.points {
            guard let current = point.elevation else { continue }
            if let previous = prev {
                let diff = current - previous
                if diff > 0 {
                    gain += diff
                }
            }
            prev = current
        }
        return gain
    }

    struct Stats {
        var totalDistance: Double = 0
        var totalElevationGain: Double = 0
        var totalElevationLoss: Double = 0
        var minElevation: Double?
        var maxElevation: Double?
        var startTime: Date?
        var endTime: Date?
        var movingTime: TimeInterval = 0
    }

    func calculateStats() -> Stats {
        var stats = Stats()
        stats.totalDistance = self.length()
        
        if self.points.count < 1 { return stats }
        
        stats.startTime = self.points.first?.time
        stats.endTime = self.points.last?.time
        
        var prevPoint: GPXTrackPoint?
        for point in self.points {
            if let ele = point.elevation {
                if let minElevation = stats.minElevation {
                    if ele < minElevation { stats.minElevation = ele }
                } else {
                    stats.minElevation = ele
                }
                if let maxElevation = stats.maxElevation {
                    if ele > maxElevation { stats.maxElevation = ele }
                } else {
                    stats.maxElevation = ele
                }
                
                if let prevEle = prevPoint?.elevation {
                    let diff = ele - prevEle
                    if diff > 0 {
                        stats.totalElevationGain += diff
                    } else {
                        stats.totalElevationLoss -= diff
                    }
                }
            }
            
            if let prev = prevPoint, let prevTime = prev.time, let currTime = point.time {
                guard
                    let prevLat = prev.latitude,
                    let prevLon = prev.longitude,
                    let currLat = point.latitude,
                    let currLon = point.longitude
                else {
                    prevPoint = point
                    continue
                }
                let timeDiff = currTime.timeIntervalSince(prevTime)
                let distDiff = CLLocation(latitude: currLat, longitude: currLon)
                    .distance(from: CLLocation(latitude: prevLat, longitude: prevLon))
                
                // If moving faster than 0.5 m/s, consider it moving time
                if timeDiff > 0 && (distDiff / timeDiff) > 0.5 {
                    stats.movingTime += timeDiff
                }
            }
            prevPoint = point
        }
        return stats
    }
}
