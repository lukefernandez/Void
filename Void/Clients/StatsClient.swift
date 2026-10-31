//
//  StatsClient.swift
//  Void
//
//  Created by Kit Langton on 12/1/24.
//

import ComposableArchitecture
import Foundation

// MARK: - StatsClient

@DependencyClient
struct StatsClient: Sendable {
  var getDailyStats: @Sendable () async throws -> DailyStats
  var getWeeklyStats: @Sendable () async throws -> [Double]
}

struct DailyStats: Equatable {
  let streak: Int
  let totalMinutesToday: Double
  let recentPracticeDays: [PracticeDay]
}

struct PracticeDay: Equatable, Identifiable, Sendable {
  let date: Date
  let minutes: Double
  let isInCurrentStreak: Bool

  var id: Date { date }
  var didMeditate: Bool { minutes > 0 }
}

extension StatsClient: DependencyKey {
  static var liveValue: StatsClient {
    let live = StatsClientLive()
    return StatsClient(
      getDailyStats: { try await live.getDailyStats() },
      getWeeklyStats: { try await live.getWeeklyStats() }
    )
  }

  static var previewValue: StatsClient {
    StatsClient(
      getDailyStats: {
        sampleDailyStats(totalMinutesToday: 10)
      },
      getWeeklyStats: { [10] }
    )
  }
}

extension DependencyValues {
  var statsClient: StatsClient {
    get { self[StatsClient.self] }
    set { self[StatsClient.self] = newValue }
  }
}

// MARK: - Live Implementation

struct StatsClientLive: Sendable {
  @Dependency(\.healthKitClient) var healthKitClient

  @Sendable
  func getDailyStats() async throws -> DailyStats {
    let intervals = try await healthKitClient.getDailyMindfulSessions()
    let summary = PracticeLog.summary(intervals: intervals, now: Date(), calendar: .current)
    return DailyStats(
      streak: summary.streak,
      totalMinutesToday: summary.totalMinutesToday,
      recentPracticeDays: summary.recentDays.map { day in
        PracticeDay(
          date: day.date,
          minutes: day.minutes,
          isInCurrentStreak: day.isInCurrentStreak
        )
      }
    )
  }

  @Sendable
  func getWeeklyStats() async throws -> [Double] {
    let intervals = try await healthKitClient.getDailyMindfulSessions()
    return PracticeLog.weeklyMinutes(intervals: intervals, now: Date(), calendar: .current)
  }
}

/// Sample stats whose streak count always matches the highlighted days.
func sampleDailyStats(totalMinutesToday: Double = 12) -> DailyStats {
  let days = samplePracticeDays()
  return DailyStats(
    streak: days.count(where: \.isInCurrentStreak),
    totalMinutesToday: totalMinutesToday,
    recentPracticeDays: days
  )
}

func samplePracticeDays() -> [PracticeDay] {
  let calendar = Calendar.current
  let today = calendar.startOfDay(for: Date())

  /// A 14-day current streak, a rest day, then a looser earlier habit.
  let streakLength = 14
  let earlierPracticedOffsets: Set<Int> = [15, 16, 17, 19, 20, 22, 23, 24, 27, 29, 30, 33, 34, 38, 41]
  let sampleMinutes: [Double] = [12, 20, 10, 15, 30, 12, 25, 10, 18, 22, 15, 10, 20, 12]

  return (0 ..< 42).compactMap { offset in
    guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
      return nil
    }

    let isInStreak = offset < streakLength
    let practiced = isInStreak || earlierPracticedOffsets.contains(offset)

    return PracticeDay(
      date: date,
      minutes: practiced ? sampleMinutes[offset % sampleMinutes.count] : 0,
      isInCurrentStreak: isInStreak
    )
  }
}
