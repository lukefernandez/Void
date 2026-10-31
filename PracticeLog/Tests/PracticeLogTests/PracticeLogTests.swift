import XCTest
@testable import PracticeLog

final class PracticeLogTests: XCTestCase {
  private var calendar: Calendar!

  override func setUp() {
    super.setUp()
    calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
  }

  func testElevenFortyFiveSessionIsListedOnlyOnTheDayItStartedAndCountsForTheStreak() {
    let start = date(2026, 3, 14, 23, 45)
    let end = date(2026, 3, 15, 0, 5)
    let now = date(2026, 3, 15, 0, 10)
    let interval = PracticeLog.Interval(start: start, end: end)
    let startDay = calendar.startOfDay(for: start)
    let endDay = calendar.startOfDay(for: end)
    let summary = PracticeLog.summary(intervals: [interval], now: now, calendar: calendar)

    XCTAssertNotEqual(startDay, endDay)
    XCTAssertTrue(PracticeLog.includes(interval, on: startDay, calendar: calendar))
    XCTAssertFalse(
      PracticeLog.includes(interval, on: endDay, calendar: calendar),
      "The 12:05 AM morning lists the sit, and that morning is not part of the streak"
    )
    XCTAssertEqual(summary.streak, 1)
    XCTAssertEqual(summary.totalMinutesToday, 0, accuracy: 0.001)
    XCTAssertEqual(minutes(summary, startDay), 20, accuracy: 0.001)
    XCTAssertEqual(summary.recentDays.first { $0.date == startDay }?.isInCurrentStreak, true)
    XCTAssertEqual(summary.recentDays.first { $0.date == endDay }?.minutes, 0)
    XCTAssertEqual(summary.recentDays.first { $0.date == endDay }?.isInCurrentStreak, false)
  }

  func testSessionCrossingNewYearCountsOnNewYearsEve() {
    let start = date(2025, 12, 31, 23, 45)
    let end = date(2026, 1, 1, 0, 5)
    let now = date(2026, 1, 1, 0, 10)
    let interval = PracticeLog.Interval(start: start, end: end)
    let summary = PracticeLog.summary(intervals: [interval], now: now, calendar: calendar)
    let eve = calendar.startOfDay(for: start)

    XCTAssertTrue(PracticeLog.includes(interval, on: start, calendar: calendar))
    XCTAssertFalse(PracticeLog.includes(interval, on: end, calendar: calendar))
    XCTAssertEqual(summary.streak, 1)
    XCTAssertEqual(summary.totalMinutesToday, 0, accuracy: 0.001)
    XCTAssertEqual(minutes(summary, eve), 20, accuracy: 0.001)
    XCTAssertEqual(summary.recentDays.first { $0.date == eve }?.isInCurrentStreak, true)
  }

  func testASitThatSpansThreeLocalDaysCountsOnceOnTheStartDay() {
    let start = date(2026, 4, 3, 23, 0)
    let end = date(2026, 4, 5, 1, 0)
    let now = date(2026, 4, 5, 9, 0)
    let interval = PracticeLog.Interval(start: start, end: end)
    let summary = PracticeLog.summary(intervals: [interval], now: now, calendar: calendar)
    let startDay = calendar.startOfDay(for: start)
    let minutes = end.timeIntervalSince(start) / 60

    XCTAssertTrue(PracticeLog.includes(interval, on: start, calendar: calendar))
    XCTAssertFalse(PracticeLog.includes(interval, on: date(2026, 4, 4, 12, 0), calendar: calendar))
    XCTAssertFalse(PracticeLog.includes(interval, on: end, calendar: calendar))
    XCTAssertEqual(summary.streak, 0)
    XCTAssertEqual(self.minutes(summary, startDay), minutes, accuracy: 0.001)
    XCTAssertEqual(summary.recentDays.first { $0.date == startDay }?.isInCurrentStreak, false)
  }

  func testSessionEndingExactlyAtMidnightStaysOnTheDayItStarted() {
    let start = date(2026, 1, 3, 23, 30)
    let end = date(2026, 1, 4, 0, 0)
    let now = date(2026, 1, 4, 0, 10)
    let interval = PracticeLog.Interval(start: start, end: end)
    let startDay = calendar.startOfDay(for: start)
    let summary = PracticeLog.summary(intervals: [interval], now: now, calendar: calendar)

    XCTAssertTrue(PracticeLog.includes(interval, on: start, calendar: calendar))
    XCTAssertFalse(PracticeLog.includes(interval, on: end, calendar: calendar))
    XCTAssertEqual(summary.streak, 1)
    XCTAssertEqual(summary.totalMinutesToday, 0, accuracy: 0.001)
    XCTAssertEqual(minutes(summary, startDay), 30, accuracy: 0.001)
    XCTAssertEqual(summary.recentDays.first { $0.date == startDay }?.isInCurrentStreak, true)
  }

  func testSessionStartingExactlyAtMidnightBelongsToThatDay() {
    let start = date(2026, 1, 4, 0, 0)
    let end = start.addingTimeInterval(10 * 60)
    let now = date(2026, 1, 4, 0, 20)
    let interval = PracticeLog.Interval(start: start, end: end)
    let summary = PracticeLog.summary(intervals: [interval], now: now, calendar: calendar)

    XCTAssertTrue(PracticeLog.includes(interval, on: start, calendar: calendar))
    XCTAssertFalse(PracticeLog.includes(interval, on: date(2026, 1, 3, 12, 0), calendar: calendar))
    XCTAssertEqual(summary.streak, 1)
    XCTAssertEqual(summary.totalMinutesToday, 10, accuracy: 0.001)
  }

  func testStreakStaysAliveOnADayYouHaveNotMeditatedYet() {
    let now = date(2026, 5, 10, 8, 0)
    let intervals = [date(2026, 5, 9, 21, 0), date(2026, 5, 8, 21, 0)].map { start in
      PracticeLog.Interval(start: start, end: start.addingTimeInterval(20 * 60))
    }
    let summary = PracticeLog.summary(intervals: intervals, now: now, calendar: calendar)
    let today = calendar.startOfDay(for: now)
    let yesterday = calendar.startOfDay(for: date(2026, 5, 9, 21, 0))

    XCTAssertEqual(summary.streak, 2)
    XCTAssertEqual(summary.totalMinutesToday, 0, accuracy: 0.001)
    XCTAssertEqual(summary.recentDays.first?.date, today)
    XCTAssertEqual(summary.recentDays.first { $0.date == today }?.isInCurrentStreak, false)
    XCTAssertEqual(summary.recentDays.first { $0.date == yesterday }?.isInCurrentStreak, true)
  }

  func testAMissedDayEndsTheStreakAndKeepsEarlierPracticeVisible() {
    let now = date(2026, 5, 10, 12, 0)
    let intervals = [date(2026, 5, 10, 8, 0), date(2026, 5, 8, 8, 0)].map { start in
      PracticeLog.Interval(start: start, end: start.addingTimeInterval(12 * 60))
    }
    let summary = PracticeLog.summary(intervals: intervals, now: now, calendar: calendar)
    let earlier = calendar.startOfDay(for: date(2026, 5, 8, 8, 0))

    XCTAssertEqual(summary.streak, 1)
    XCTAssertEqual(minutes(summary, earlier), 12, accuracy: 0.001)
    XCTAssertEqual(summary.recentDays.first { $0.date == earlier }?.isInCurrentStreak, false)
  }

  func testSeveralSitsOnTheSameDayAddMinutesAndCountOnce() {
    let morning = date(2026, 5, 10, 7, 0)
    let evening = date(2026, 5, 10, 20, 0)
    let intervals = [
      PracticeLog.Interval(start: morning, end: morning.addingTimeInterval(10 * 60)),
      PracticeLog.Interval(start: evening, end: evening.addingTimeInterval(15 * 60)),
    ]
    let summary = PracticeLog.summary(
      intervals: intervals,
      now: date(2026, 5, 10, 21, 0),
      calendar: calendar
    )

    XCTAssertEqual(summary.streak, 1)
    XCTAssertEqual(summary.totalMinutesToday, 25, accuracy: 0.001)
  }

  func testZeroLengthSessionDoesNotCountAsPractice() {
    let start = date(2026, 4, 2, 11, 0)
    let interval = PracticeLog.Interval(start: start, end: start)
    let summary = PracticeLog.summary(
      intervals: [interval],
      now: date(2026, 4, 2, 18, 0),
      calendar: calendar
    )

    XCTAssertEqual(summary.streak, 0)
    XCTAssertEqual(summary.totalMinutesToday, 0, accuracy: 0.001)
    XCTAssertFalse(PracticeLog.includes(interval, on: start, calendar: calendar))
    XCTAssertFalse(summary.recentDays.contains { $0.isInCurrentStreak || $0.minutes > 0 })
  }

  func testCurrentStreakCountsDaysBeyondTheVisibleGrid() {
    let now = date(2026, 8, 1, 12, 0)
    let today = calendar.startOfDay(for: now)
    let intervals = (0 ..< 50).map { offset -> PracticeLog.Interval in
      let day = calendar.date(byAdding: .day, value: -offset, to: today)!
      let start = calendar.date(from: components(day, hour: 9, minute: 0))!
      return PracticeLog.Interval(start: start, end: start.addingTimeInterval(10 * 60))
    }
    let summary = PracticeLog.summary(intervals: intervals, now: now, calendar: calendar)

    XCTAssertEqual(summary.streak, 50)
    XCTAssertEqual(summary.recentDays.count, 42)
    XCTAssertTrue(summary.recentDays.allSatisfy(\.isInCurrentStreak))
  }

  func testStreakCrossesTheSpringForward() {
    let newYork = newYorkCalendar()
    let saturday = newYork.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 20))!
    let sunday = newYork.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 12))!
    let now = newYork.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 18))!
    let monday = newYork.date(from: DateComponents(year: 2026, month: 3, day: 9, hour: 0))!
    let summary = PracticeLog.summary(
      intervals: [saturday, sunday].map { sit($0, minutes: 15) },
      now: now,
      calendar: newYork
    )

    XCTAssertEqual(
      newYork.startOfDay(for: monday).timeIntervalSince(newYork.startOfDay(for: sunday)),
      23 * 60 * 60
    )
    XCTAssertEqual(summary.streak, 2)
  }

  func testDurationUsesAbsoluteTimeAcrossSpringForward() {
    let newYork = newYorkCalendar()
    let start = newYork.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 1, minute: 30))!
    let end = newYork.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 3, minute: 30))!
    let now = newYork.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 12))!
    let summary = PracticeLog.summary(
      intervals: [.init(start: start, end: end)],
      now: now,
      calendar: newYork
    )

    XCTAssertEqual(end.timeIntervalSince(start), 60 * 60)
    XCTAssertEqual(summary.totalMinutesToday, 60, accuracy: 0.001)
    XCTAssertEqual(summary.streak, 1)
    XCTAssertTrue(PracticeLog.includes(.init(start: start, end: end), on: start, calendar: newYork))
  }

  func testStreakCrossesTheFallBack() {
    let newYork = newYorkCalendar()
    let sunday = newYork.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 12))!
    let monday = newYork.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 12))!
    let now = newYork.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 18))!
    let summary = PracticeLog.summary(
      intervals: [sunday, monday].map { sit($0, minutes: 15) },
      now: now,
      calendar: newYork
    )

    XCTAssertEqual(
      newYork.startOfDay(for: monday).timeIntervalSince(newYork.startOfDay(for: sunday)),
      25 * 60 * 60
    )
    XCTAssertEqual(summary.streak, 2)
  }

  func testTheSameInstantBelongsToTheLocalDayWhereItStarted() {
    var losAngeles = Calendar(identifier: .gregorian)
    losAngeles.timeZone = TimeZone(identifier: "America/Los_Angeles")!
    var tokyo = Calendar(identifier: .gregorian)
    tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!

    let start = losAngeles.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 23, minute: 45))!
    let end = losAngeles.date(from: DateComponents(year: 2026, month: 1, day: 2, hour: 0, minute: 5))!
    let now = losAngeles.date(from: DateComponents(year: 2026, month: 1, day: 2, hour: 0, minute: 10))!
    let interval = PracticeLog.Interval(start: start, end: end)
    let losAngelesDay = PracticeLog.attributedDay(start: start, calendar: losAngeles)
    let tokyoDay = PracticeLog.attributedDay(start: start, calendar: tokyo)

    XCTAssertNotEqual(losAngelesDay, tokyoDay)
    XCTAssertTrue(PracticeLog.includes(interval, on: losAngelesDay, calendar: losAngeles))
    XCTAssertFalse(PracticeLog.includes(interval, on: end, calendar: losAngeles))
    XCTAssertTrue(PracticeLog.includes(interval, on: tokyoDay, calendar: tokyo))
    XCTAssertFalse(
      PracticeLog.includes(
        interval,
        on: tokyo.date(byAdding: .day, value: 1, to: tokyoDay)!,
        calendar: tokyo
      )
    )

    let summary = PracticeLog.summary(intervals: [interval], now: now, calendar: losAngeles)
    XCTAssertEqual(summary.streak, 1)
    XCTAssertEqual(summary.recentDays.first { $0.date == losAngelesDay }?.isInCurrentStreak, true)
    XCTAssertEqual(summary.totalMinutesToday, 0, accuracy: 0.001)
  }

  func testLookbackStartsAtLocalMidnightSoTheBoundaryMorningIsIncluded() {
    let now = date(2026, 6, 15, 15, 30)
    let start = PracticeLog.queryStart(now: now, calendar: calendar)
    let boundaryDay = calendar.date(byAdding: .day, value: -365, to: calendar.startOfDay(for: now))
    let morning = date(2025, 6, 15, 9, 0)

    XCTAssertEqual(start, boundaryDay)
    XCTAssertLessThanOrEqual(start ?? .distantFuture, morning)
  }

  private func minutes(_ summary: PracticeLog.Summary, _ day: Date) -> Double {
    summary.recentDays.first { $0.date == day }?.minutes ?? -1
  }

  private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
  }

  private func components(_ day: Date, hour: Int, minute: Int) -> DateComponents {
    var parts = calendar.dateComponents([.year, .month, .day], from: day)
    parts.hour = hour
    parts.minute = minute
    return parts
  }

  private func sit(_ start: Date, minutes: Double) -> PracticeLog.Interval {
    PracticeLog.Interval(start: start, end: start.addingTimeInterval(minutes * 60))
  }

  private func newYorkCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/New_York")!
    return calendar
  }
}
