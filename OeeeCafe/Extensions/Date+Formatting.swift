import Foundation

extension Date {
    /// Formats the date as a relative time string (e.g., "2 hours ago", "just now")
    /// Uses localized strings from Localizable.strings for internationalization
    func relativeFormatted() -> String {
        let now = Date()
        let interval = now.timeIntervalSince(self)

        // Less than 1 minute ago
        if interval < 60 {
            return "time.just_now".localized
        }
        // Less than 1 hour ago
        else if interval < 3600 {
            let minutes = Int(interval / 60)
            return minutes == 1 ? "time.minute_ago".localized : "time.minutes_ago".localized(minutes)
        }
        // Less than 1 day ago
        else if interval < 86400 {
            let hours = Int(interval / 3600)
            return hours == 1 ? "time.hour_ago".localized : "time.hours_ago".localized(hours)
        }
        // Less than 1 week ago
        else if interval < 604800 {
            let days = Int(interval / 86400)
            return days == 1 ? "time.yesterday".localized : "time.days_ago".localized(days)
        }
        // Less than 1 month ago (approximately 30 days)
        else if interval < 2592000 {
            let weeks = Int(interval / 604800)
            return weeks == 1 ? "time.week_ago".localized : "time.weeks_ago".localized(weeks)
        }
        // Less than 1 year ago (approximately 365 days)
        else if interval < 31536000 {
            let months = Int(interval / 2592000)
            return months == 1 ? "time.month_ago".localized : "time.months_ago".localized(months)
        }
        // 1 year or more ago
        else {
            let years = Int(interval / 31536000)
            return years == 1 ? "time.year_ago".localized : "time.years_ago".localized(years)
        }
    }
}
