import Foundation

struct DaySelection: Identifiable {
    let date: Date
    var id: Date { date }
}

enum DailyDetailMode: String, CaseIterable, Identifiable {
    case list
    case trend

    var id: String { rawValue }

    var labelKey: String {
        switch self {
        case .list: return "daily_detail_segment_list"
        case .trend: return "daily_detail_segment_trend"
        }
    }
}

struct DailyTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
