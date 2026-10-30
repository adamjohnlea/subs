import Foundation
import Testing
@testable import SubtitleKit

@Test func srtTimestampFormatsAndTruncates() {
    #expect(srtTimestamp(0) == "00:00:00,000")
    #expect(srtTimestamp(1.0) == "00:00:01,000")
    #expect(srtTimestamp(3661.5) == "01:01:01,500")
    // Truncates toward zero, never rounds up.
    #expect(srtTimestamp(1.9999) == "00:00:01,999")
    // Negative or non-finite clamps to zero.
    #expect(srtTimestamp(-5) == "00:00:00,000")
}
