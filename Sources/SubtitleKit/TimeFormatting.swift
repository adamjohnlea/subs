import Foundation

/// Formats a time in seconds as an SRT timestamp `"HH:MM:SS,mmm"`, truncated
/// toward zero to the millisecond (never rounded up). Non-finite or negative
/// values clamp to zero.
func srtTimestamp(_ seconds: Double) -> String {
    let safe = seconds.isFinite && seconds > 0 ? seconds : 0
    let totalMilliseconds = Int(safe * 1000)   // truncates toward zero
    let milliseconds = totalMilliseconds % 1000
    let totalSeconds = totalMilliseconds / 1000
    return String(format: "%02d:%02d:%02d,%03d",
                  totalSeconds / 3600, (totalSeconds / 60) % 60, totalSeconds % 60, milliseconds)
}
