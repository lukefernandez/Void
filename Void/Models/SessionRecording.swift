import Foundation

enum SessionRecording {
  static let minimumSavedSeconds = 10

  /// An open-ended sit has no planned end. Four hours is past every preset.
  static let maximumOpenEndedSeconds = 4 * 60 * 60

  /// The interval written when a sit ends. `nil` means the sit was too short to keep.
  ///
  /// This still writes the whole elapsed span. The phone does not tick while locked,
  /// so a 20 minute sit that finishes on the next wake includes the hours in between.
  static func intervalToRecord(
    elapsedSeconds: Int,
    now: Date,
    plannedDurationSeconds: Int?
  ) -> PracticeLog.Interval? {
    guard elapsedSeconds > minimumSavedSeconds else { return nil }
    let start = now.addingTimeInterval(-Double(elapsedSeconds))
    return PracticeLog.Interval(start: start, end: now)
  }

  static func canEdit(sampleBundleIdentifier: String, appBundleIdentifier: String) -> Bool {
    !sampleBundleIdentifier.isEmpty && sampleBundleIdentifier == appBundleIdentifier
  }
}
