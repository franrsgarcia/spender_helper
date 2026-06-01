import Foundation

enum TimePeriodFilter: String, CaseIterable, Identifiable {
    case all = "All Time"
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case last30Days = "Last 30 Days"
    case custom = "Custom Range"

    var id: String { rawValue }

    func dateInterval(customStart: Date, customEnd: Date, calendar: Calendar = .current) -> ClosedRange<Date>? {
        let now = Date()
        switch self {
        case .all:
            return nil
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!.addingTimeInterval(-1)
            return start...end
        case .thisWeek:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return nil }
            return interval.start...(interval.end.addingTimeInterval(-1))
        case .thisMonth:
            guard let interval = calendar.dateInterval(of: .month, for: now) else { return nil }
            return interval.start...(interval.end.addingTimeInterval(-1))
        case .last30Days:
            guard let start = calendar.date(byAdding: .day, value: -30, to: calendar.startOfDay(for: now)) else {
                return nil
            }
            return start...now
        case .custom:
            let start = calendar.startOfDay(for: customStart)
            let endDay = calendar.startOfDay(for: customEnd)
            let end = calendar.date(byAdding: .day, value: 1, to: endDay)!.addingTimeInterval(-1)
            return start...max(start, end)
        }
    }
}
