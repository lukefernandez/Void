import XCTest
@testable import PracticeLog

final class SessionRecordingTests: XCTestCase {
  func testTwentyMinuteSitClosedTwoDaysLaterRecordsThePlannedEnd() {
    let calendar = losAngeles()
    let start = calendar.date(from: DateComponents(
      year: 2026, month: 10, day: 29, hour: 23, minute: 45
    ))!
    let elapsed = 2_890 * 60
    let now = start.addingTimeInterval(TimeInterval(elapsed))
    let interval = SessionRecording.intervalToRecord(
      elapsedSeconds: elapsed,
      now: now,
      plannedDurationSeconds: 20 * 60
    )

    XCTAssertEqual(interval?.start, start)
    XCTAssertEqual(interval?.end, start.addingTimeInterval(20 * 60))
    XCTAssertEqual(
      interval.map { $0.end.timeIntervalSince($0.start) },
      20 * 60
    )
    XCTAssertEqual(calendar.component(.hour, from: interval?.end ?? now), 0)
    XCTAssertEqual(calendar.component(.minute, from: interval?.end ?? now), 5)
    XCTAssertEqual(calendar.component(.day, from: interval?.end ?? now), 30)

    let recorded = interval ?? PracticeLog.Interval(start: start, end: now)
    XCTAssertTrue(PracticeLog.includes(recorded, on: start, calendar: calendar))
    XCTAssertFalse(PracticeLog.includes(recorded, on: now, calendar: calendar))
  }

  func testStoppingATimedSitEarlyKeepsTheTimeActuallySat() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let elapsed = 15 * 60
    let interval = SessionRecording.intervalToRecord(
      elapsedSeconds: elapsed,
      now: now,
      plannedDurationSeconds: 20 * 60
    )

    XCTAssertEqual(interval?.end, now)
    XCTAssertEqual(interval.map { $0.end.timeIntervalSince($0.start) }, TimeInterval(elapsed))
  }

  func testOpenEndedSitLeftForTwoDaysIsCutAtFourHours() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let elapsed = 2_890 * 60
    let interval = SessionRecording.intervalToRecord(
      elapsedSeconds: elapsed,
      now: now,
      plannedDurationSeconds: nil
    )

    XCTAssertEqual(
      interval.map { $0.end.timeIntervalSince($0.start) },
      TimeInterval(4 * 60 * 60)
    )
    XCTAssertEqual(interval?.start, now.addingTimeInterval(-TimeInterval(elapsed)))
  }

  func testOpenEndedSitUnderTheCapIsKeptWhole() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let elapsed = 30 * 60
    let interval = SessionRecording.intervalToRecord(
      elapsedSeconds: elapsed,
      now: now,
      plannedDurationSeconds: nil
    )

    XCTAssertEqual(interval?.end, now)
    XCTAssertEqual(interval.map { $0.end.timeIntervalSince($0.start) }, TimeInterval(elapsed))
  }

  func testTenSecondsOrLessIsNotSaved() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    XCTAssertNil(SessionRecording.intervalToRecord(
      elapsedSeconds: 10,
      now: now,
      plannedDurationSeconds: 20 * 60
    ))
    XCTAssertNotNil(SessionRecording.intervalToRecord(
      elapsedSeconds: 11,
      now: now,
      plannedDurationSeconds: 20 * 60
    ))
  }

  func testOnlyTheAppsOwnSamplesCanBeEdited() {
    XCTAssertTrue(SessionRecording.canEdit(
      sampleBundleIdentifier: "com.kitlangton.Void",
      appBundleIdentifier: "com.kitlangton.Void"
    ))
    XCTAssertFalse(SessionRecording.canEdit(
      sampleBundleIdentifier: "com.apple.Health",
      appBundleIdentifier: "com.kitlangton.Void"
    ))
    XCTAssertFalse(SessionRecording.canEdit(
      sampleBundleIdentifier: "",
      appBundleIdentifier: "com.kitlangton.Void"
    ))
  }

  private func losAngeles() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
    return calendar
  }
}
