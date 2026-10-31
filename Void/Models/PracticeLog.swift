import Foundation

/// Day attribution, streaks, and daily totals for meditation sessions.
///
/// A session belongs to the local day it started. A sit from 11:45 PM to
/// 12:05 AM stays on that evening, both in the day list and in the streak.
enum PracticeLog {
  struct Interval: Equatable, Sendable {
    var start: Date
    var end: Date

    var duration: TimeInterval {
      end.timeIntervalSince(start)
    }
  }

  struct Day: Equatable, Sendable {
    var date: Date
    var minutes: Double
    var isInCurrentStreak: Bool
  }

  struct Summary: Equatable, Sendable {
    var streak: Int
    var totalMinutesToday: Double
    var recentDays: [Day]
  }

  static func attributedDay(start: Date, calendar: Calendar) -> Date {
    calendar.startOfDay(for: start)
  }

  static func includes(_ interval: Interval, on day: Date, calendar: Calendar) -> Bool {
    guard counts(interval) else { return false }
    return attributedDay(start: interval.start, calendar: calendar)
      == calendar.startOfDay(for: day)
  }

  static func summary(
    intervals: [Interval],
    now: Date,
    calendar: Calendar,
    dayCount: Int = 42
  ) -> Summary {
    let today = calendar.startOfDay(for: now)
    let durationByDay = durationsByDay(intervals, calendar: calendar)
    let streakDates = currentStreakDates(
      sessionDates: Set(durationByDay.keys),
      today: today,
      calendar: calendar
    )

    let recentDays = (0 ..< dayCount).compactMap { offset -> Day? in
      guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
        return nil
      }
      let day = calendar.startOfDay(for: date)
      return Day(
        date: day,
        minutes: (durationByDay[day] ?? 0) / 60,
        isInCurrentStreak: streakDates.contains(day)
      )
    }

    return Summary(
      streak: streakDates.count,
      totalMinutesToday: (durationByDay[today] ?? 0) / 60,
      recentDays: recentDays
    )
  }

  static func weeklyMinutes(
    intervals: [Interval],
    now: Date,
    calendar: Calendar,
    weekCount: Int = 52
  ) -> [Double] {
    let today = calendar.startOfDay(for: now)
    let durationByDay = durationsByDay(intervals, calendar: calendar)
    var stats = Array(repeating: 0.0, count: weekCount)

    for weekOffset in 0 ..< weekCount {
      guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today),
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)
      else { continue }

      stats[weekOffset] = durationByDay.reduce(0) { partial, entry in
        guard entry.key >= weekStart, entry.key < weekEnd else { return partial }
        return partial + entry.value / 60
      }
    }

    return stats.reversed()
  }

  /// Local midnight `days` before today, so the oldest day is not cut off mid-morning.
  static func queryStart(now: Date, calendar: Calendar, days: Int = 365) -> Date? {
    let today = calendar.startOfDay(for: now)
    return calendar.date(byAdding: .day, value: -days, to: today)
  }

  private static func counts(_ interval: Interval) -> Bool {
    interval.duration > 0
  }

  private static func durationsByDay(
    _ intervals: [Interval],
    calendar: Calendar
  ) -> [Date: TimeInterval] {
    var durationByDay: [Date: TimeInterval] = [:]
    for interval in intervals where counts(interval) {
      let day = attributedDay(start: interval.start, calendar: calendar)
      durationByDay[day, default: 0] += interval.duration
    }
    return durationByDay
  }

  /// Consecutive practiced days ending today, or yesterday if today has no session yet.
  private static func currentStreakDates(
    sessionDates: Set<Date>,
    today: Date,
    calendar: Calendar
  ) -> Set<Date> {
    guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
      return sessionDates.contains(today) ? [today] : []
    }

    guard sessionDates.contains(today) || sessionDates.contains(yesterday) else {
      return []
    }

    var currentDate = sessionDates.contains(today) ? today : yesterday
    var streakDates: Set<Date> = [currentDate]

    while let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) {
      guard sessionDates.contains(previousDay) else { break }
      streakDates.insert(previousDay)
      currentDate = previousDay
    }

    return streakDates
  }
}
