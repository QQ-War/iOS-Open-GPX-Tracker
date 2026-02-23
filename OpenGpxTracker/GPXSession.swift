//
//  GPXSession.swift
//  OpenGpxTracker
//
//  Created by Vincent Neo on 13/6/19.
//
//  Shared file: this file is also included in the OpenGpxTracker-Watch Extension target.

import Foundation
import CoreGPX
import CoreLocation

#if os(iOS)
/// GPX creator identifier. Used on generated files identify this app created them.
let kGPXCreatorString = "Open GPX Tracker for iOS"

#elseif os(watchOS)
/// GPX creator identifier. Used on generated files identify this app created them.
let kGPXCreatorString = "Open GPX Tracker for watchOS"

/// Such that current watch app code remains compatible without needing to rename.
typealias GPXMapView = GPXSession
#endif

///
/// Handles the actual logging of waypoints and trackpoints.
///
/// Addition of waypoints, trackpoints, and the handling of adding trackpoints to tracksegments and tracks all happens here.
/// Exporting the data as a GPX string is also done here as well.
///
/// Should not be used directly on iOS, as code origins from `GPXMapView`.
///
class GPXSession {
    
    /// List of waypoints currently displayed on the map.
    var waypoints: [GPXWaypoint] = []
    
    /// List of tracks currently displayed on the map.
    var tracks: [GPXTrack] = []
    
    /// Current track segments
    var trackSegments: [GPXTrackSegment] = []
    
    /// Segment in which device locations are added.
    var currentSegment: GPXTrackSegment =  GPXTrackSegment()
    
    /// Total tracked distance in meters
    var totalTrackedDistance = 0.00
    
    /// Total elevation gain in meters
    var totalElevationGain = 0.00
    
    /// Distance in meters of current track (track in which new user positions are being added)
    var currentTrackDistance = 0.00
    
    /// Current segment distance in meters
    var currentSegmentDistance = 0.00
    
    ///
    /// Adds a waypoint to the map.
    ///
    /// - Parameters: The waypoint to add to the map.
    ///
    func addWaypoint(_ waypoint: GPXWaypoint) {
        self.waypoints.append(waypoint)
    }
    
    ///
    /// Removes a Waypoint from current session
    ///
    /// - Parameters: The waypoint to remove from the session.
    ///
    func removeWaypoint(_ waypoint: GPXWaypoint) {
        let index = waypoints.firstIndex(of: waypoint)
        if index == nil {
            print("Waypoint not found")
            return
        }
        waypoints.remove(at: index!)
    }
    
    ///
    /// Adds a new point to current segment.
    /// - Parameters:
    ///    - location: Typically a location provided by CLLocation
    ///
    func addPointToCurrentTrackSegmentAtLocation(_ location: CLLocation) {
        let pt = GPXTrackPoint(location: location)
        
        // Elevation gain
        if self.currentSegment.points.count >= 1 {
            let lastPt = self.currentSegment.points.last!
            if let lastEle = lastPt.elevation, let currEle = pt.elevation {
                let diff = currEle - lastEle
                if diff > 0 {
                    self.totalElevationGain += diff
                }
            }
        }
        
        self.currentSegment.add(trackpoint: pt)
        
        // Add the distance to previous tracked point
        if self.currentSegment.points.count >= 2 { // At elast there are two points in the segment
            let prevPt = self.currentSegment.points[self.currentSegment.points.count-2] // Get previous point
            guard let latitude = prevPt.latitude, let longitude = prevPt.longitude else { return }
            let prevPtLoc = CLLocation(latitude: latitude, longitude: longitude)
            // Now get the distance
            let distance = prevPtLoc.distance(from: location)
            self.currentTrackDistance += distance
            self.totalTrackedDistance += distance
            self.currentSegmentDistance += distance
        }
    }
    
    ///
    /// Appends currentSegment to trackSegments and initializes currentSegment to a new one.
    ///
    func startNewTrackSegment() {
        if self.currentSegment.points.count > 0 {
            self.trackSegments.append(self.currentSegment)
            self.currentSegment = GPXTrackSegment()
            self.currentSegmentDistance = 0.00
        }
    }
    
    ///
    /// Clears all data held in this object.
    ///
    func reset() {
        self.trackSegments = []
        self.tracks = []
        self.currentSegment = GPXTrackSegment()
        self.waypoints = []
        
        self.totalTrackedDistance = 0.00
        self.totalElevationGain = 0.00
        self.currentTrackDistance = 0.00
        self.currentSegmentDistance = 0.00
        
    }
    
    ///
    /// Erases points near the specified coordinate.
    /// If points are removed from the middle of a segment, the segment is split.
    ///
    func erasePoints(at coordinate: CLLocationCoordinate2D, radiusInMeters: Double) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // Helper to process a list of segments
        func processSegments(_ segments: [GPXTrackSegment]) -> [GPXTrackSegment] {
            var newSegments: [GPXTrackSegment] = []
            for segment in segments {
                var currentNewSegment = GPXTrackSegment()
                for point in segment.points {
                    guard let latitude = point.latitude, let longitude = point.longitude else {
                        continue
                    }
                    let ptLoc = CLLocation(latitude: latitude, longitude: longitude)
                    if ptLoc.distance(from: location) > radiusInMeters {
                        currentNewSegment.add(trackpoint: point)
                    } else {
                        // Point erased. If currentNewSegment has points, save it and start a new one.
                        if currentNewSegment.points.count > 0 {
                            newSegments.append(currentNewSegment)
                            currentNewSegment = GPXTrackSegment()
                        }
                    }
                }
                if currentNewSegment.points.count > 0 {
                    newSegments.append(currentNewSegment)
                }
            }
            return newSegments
        }
        
        // Erase in currentSegment
        let processedCurrent = processSegments([currentSegment])
        if processedCurrent.count > 0 {
            currentSegment = processedCurrent[0]
            if processedCurrent.count > 1 {
                // It was split. Move the first parts to trackSegments
                for i in 0..<processedCurrent.count-1 {
                    trackSegments.append(processedCurrent[i])
                }
                currentSegment = processedCurrent.last!
            }
        } else {
            currentSegment = GPXTrackSegment()
        }
        
        // Erase in trackSegments
        trackSegments = processSegments(trackSegments)
        
        // Erase in tracks
        for track in tracks {
            track.segments = processSegments(track.segments)
        }
        
        // Re-calculate distance and elevation gain
        recalculateStats()
    }
    
    func recalculateStats() {
        totalTrackedDistance = 0.0
        totalElevationGain = 0.0
        currentTrackDistance = 0.0
        currentSegmentDistance = 0.0
        
        for track in tracks {
            for segment in track.segments {
                totalTrackedDistance += segment.length()
                totalElevationGain += segment.elevationGain()
            }
        }
        for segment in trackSegments {
            totalTrackedDistance += segment.length()
            totalElevationGain += segment.elevationGain()
            currentTrackDistance += segment.length()
        }
        currentSegmentDistance = currentSegment.length()
        currentTrackDistance += currentSegmentDistance
        totalTrackedDistance += currentSegmentDistance
        totalElevationGain += currentSegment.elevationGain()
    }
    
    func getGlobalStats() -> GPXTrackSegment.Stats {
        var globalStats = GPXTrackSegment.Stats()
        
        func addStats(_ stats: GPXTrackSegment.Stats) {
            globalStats.totalDistance += stats.totalDistance
            globalStats.totalElevationGain += stats.totalElevationGain
            globalStats.totalElevationLoss += stats.totalElevationLoss
            globalStats.movingTime += stats.movingTime
            
            if let start = stats.startTime {
                if let globalStart = globalStats.startTime {
                    if start < globalStart { globalStats.startTime = start }
                } else {
                    globalStats.startTime = start
                }
            }
            if let end = stats.endTime {
                if let globalEnd = globalStats.endTime {
                    if end > globalEnd { globalStats.endTime = end }
                } else {
                    globalStats.endTime = end
                }
            }
            if let min = stats.minElevation {
                if let globalMin = globalStats.minElevation {
                    if min < globalMin { globalStats.minElevation = min }
                } else {
                    globalStats.minElevation = min
                }
            }
            if let max = stats.maxElevation {
                if let globalMax = globalStats.maxElevation {
                    if max > globalMax { globalStats.maxElevation = max }
                } else {
                    globalStats.maxElevation = max
                }
            }
        }
        
        for track in tracks {
            for segment in track.segments {
                addStats(segment.calculateStats())
            }
        }
        for segment in trackSegments {
            addStats(segment.calculateStats())
        }
        addStats(currentSegment.calculateStats())
        
        return globalStats
    }
    
    ///
    ///
    /// Converts current sessionn into a GPX String
    ///
    ///
    func exportToGPXString() -> String {
        print("Exporting session data into GPX String")
        // Create the gpx structure
        let gpx = GPXRoot(creator: kGPXCreatorString)
        gpx.add(waypoints: self.waypoints)
        let track = GPXTrack()
        track.add(trackSegments: self.trackSegments)
        // Add current segment if not empty
        if self.currentSegment.points.count > 0 {
            track.add(trackSegment: self.currentSegment)
        }
        // Add existing tracks
        gpx.add(tracks: self.tracks)
        // Add current track
        gpx.add(track: track)
        return gpx.gpx()
    }
    
    func continueFromGPXRoot(_ gpx: GPXRoot) {
        
        let lastTrack = gpx.tracks.last ?? GPXTrack()
        for segment in lastTrack.segments {
            totalTrackedDistance += segment.length()
        }
        for track in gpx.tracks {
            for segment in track.segments {
                totalElevationGain += segment.elevationGain()
            }
        }
        
        // Add track segments
        self.tracks = gpx.tracks
        self.trackSegments = lastTrack.segments
        
        // Remove last track as that track is packaged by Core Data, but should its tracksegments should be seperated, into self.tracksegments.
        if self.tracks.count > 0 {
            self.tracks.removeLast()
        }
        
    }
    
}
