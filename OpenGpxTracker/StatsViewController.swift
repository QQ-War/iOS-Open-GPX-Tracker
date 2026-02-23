//
//  StatsViewController.swift
//  OpenGpxTracker
//
//  Created by Gemini on 23/02/26.
//

import UIKit
import CoreLocation

class StatsViewController: UITableViewController {
    
    var stats: GPXTrackSegment.Stats
    var useImperial: Bool
    
    init(stats: GPXTrackSegment.Stats, useImperial: Bool) {
        self.stats = stats
        self.useImperial = useImperial
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = localized("STATISTICS", fallback: "Statistics")
        
        let doneButton = UIBarButtonItem(
            title: localized("DONE", fallback: "Done"),
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )
        self.navigationItem.rightBarButtonItem = doneButton
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "StatCell")
    }
    
    @objc func doneTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 4 // Distance & Time
        case 1: return 4 // Elevation
        case 2: return 2 // Time details
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return localized("STATS_SECTION_DISTANCE_TIME", fallback: "Distance & Time")
        case 1: return localized("STATS_SECTION_ELEVATION", fallback: "Elevation")
        case 2: return localized("STATS_SECTION_TIME_DETAILS", fallback: "Time Details")
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "StatCell")
        
        switch indexPath.section {
        case 0: // Distance & Time
            if indexPath.row == 0 {
                cell.textLabel?.text = localized("STATS_TOTAL_DISTANCE", fallback: "Total Distance")
                cell.detailTextLabel?.text = stats.totalDistance.toDistance(useImperial: useImperial)
            } else if indexPath.row == 1 {
                cell.textLabel?.text = localized("STATS_MOVING_TIME", fallback: "Moving Time")
                cell.detailTextLabel?.text = formatDuration(stats.movingTime)
            } else if indexPath.row == 2 {
                cell.textLabel?.text = localized("STATS_AVG_SPEED", fallback: "Average Speed")
                let avgSpeed = stats.movingTime > 0 ? stats.totalDistance / stats.movingTime : 0
                cell.detailTextLabel?.text = avgSpeed.toSpeed(useImperial: useImperial)
            } else if indexPath.row == 3 {
                cell.textLabel?.text = localized("STATS_AVG_PACE", fallback: "Average Pace")
                let avgSpeed = stats.movingTime > 0 ? stats.totalDistance / stats.movingTime : 0
                cell.detailTextLabel?.text = avgSpeed.toPace(useImperial: useImperial)
            }
        case 1: // Elevation
            if indexPath.row == 0 {
                cell.textLabel?.text = localized("STATS_ELEVATION_GAIN", fallback: "Elevation Gain")
                cell.detailTextLabel?.text = stats.totalElevationGain.toAltitude(useImperial: useImperial)
            } else if indexPath.row == 1 {
                cell.textLabel?.text = localized("STATS_ELEVATION_LOSS", fallback: "Elevation Loss")
                cell.detailTextLabel?.text = stats.totalElevationLoss.toAltitude(useImperial: useImperial)
            } else if indexPath.row == 2 {
                cell.textLabel?.text = localized("STATS_MAX_ELEVATION", fallback: "Max Elevation")
                cell.detailTextLabel?.text = (stats.maxElevation ?? 0).toAltitude(useImperial: useImperial)
            } else if indexPath.row == 3 {
                cell.textLabel?.text = localized("STATS_MIN_ELEVATION", fallback: "Min Elevation")
                cell.detailTextLabel?.text = (stats.minElevation ?? 0).toAltitude(useImperial: useImperial)
            }
        case 2: // Time details
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium
            if indexPath.row == 0 {
                cell.textLabel?.text = localized("STATS_START_TIME", fallback: "Start Time")
                if let start = stats.startTime {
                    cell.detailTextLabel?.text = dateFormatter.string(from: start)
                } else {
                    cell.detailTextLabel?.text = "-"
                }
            } else {
                cell.textLabel?.text = localized("STATS_END_TIME", fallback: "End Time")
                if let end = stats.endTime {
                    cell.detailTextLabel?.text = dateFormatter.string(from: end)
                } else {
                    cell.detailTextLabel?.text = "-"
                }
            }
        default: break
        }
        
        return cell
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%dh %02dm %02ds", hours, minutes, seconds)
        } else {
            return String(format: "%dm %02ds", minutes, seconds)
        }
    }

    private func localized(_ key: String, fallback: String) -> String {
        return NSLocalizedString(key, tableName: nil, bundle: .main, value: fallback, comment: "")
    }
}
