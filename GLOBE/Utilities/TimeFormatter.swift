//======================================================================
// MARK: - TimeFormatter.swift
// Purpose: Format timestamps into relative time strings
// Path: GLOBE/Utilities/TimeFormatter.swift
//======================================================================
import Foundation

struct TimeFormatter {
    /// Format a date into a relative time string (e.g., "5 minutes", "2 hours")
    static func timeAgoString(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)

        // Negative interval means future date
        if timeInterval < 0 {
            return "now"
        }

        let seconds = Int(timeInterval)
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24

        // Less than 1 minute
        if minutes < 1 {
            return "now"
        }

        // 1-59 minutes
        if minutes < 60 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }

        // 1-23 hours
        if hours < 24 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }

        // 1-6 days
        if days < 7 {
            return "\(days) day\(days == 1 ? "" : "s")"
        }

        // 1-4 weeks
        let weeks = days / 7
        if weeks < 4 {
            return "\(weeks) week\(weeks == 1 ? "" : "s")"
        }

        // More than 4 weeks - show actual date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Short version: "5m", "2h", "3d"
    static func shortTimeAgoString(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)

        if timeInterval < 0 {
            return "now"
        }

        let seconds = Int(timeInterval)
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24

        if minutes < 1 {
            return "now"
        }

        if minutes < 60 {
            return "\(minutes)m"
        }

        if hours < 24 {
            return "\(hours)h"
        }

        if days < 7 {
            return "\(days)d"
        }

        let weeks = days / 7
        if weeks < 4 {
            return "\(weeks)w"
        }

        // More than 4 weeks - show date
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
