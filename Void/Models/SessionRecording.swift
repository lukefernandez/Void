import Foundation

enum SessionRecording {
  static let minimumSavedSeconds = 10

  /// An open-ended sit has no planned end. Four hours is past every preset.
  static let maximumOpenEndedSeconds = 4 * 60 * 60

  /// The interval written when a sit ends. `nil` means the sit was too short to keep.
  ///
  /// The phone does not tick while locked, so elapsed time can include sleep.
  /// A planned sit ends when its timer was due. An open-ended sit stops at
  /// `maximumOpenEndedSeconds`.
  static func intervalToRecord(
    elapsedSeconds: Int,
    now: Date,
    plannedDurationSeconds: Int?
  ) -> PracticeLog.Interval? {
    guard elapsedSeconds > minimumSavedSeconds else { return nil }
    let elapsed = TimeInterval(elapsedSeconds)
    let cap = TimeInterval(plannedDurationSeconds ?? maximumOpenEndedSeconds)
    let recorded = min(elapsed, max(cap, 0))
    let start = now.addingTimeInterval(-elapsed)
    return PracticeLog.Interval(start: start, end: start.addingTimeInterval(recorded))
  }

  static func canEdit(sampleBundleIdentifier: String, appBundleIdentifier: String) -> Bool {
    !sampleBundleIdentifier.isEmpty && sampleBundleIdentifier == appBundleIdentifier
  }
}
