import SwiftTUI

/// The app's one hard-coded brand color and its dim companion. Everything else
/// uses SwiftTUI's semantic styles (`.foreground`, `.secondary`, `.success`,
/// `.danger`), which adapt to light and dark terminals on their own.
enum Theme {
    /// Violet accent. This is also SwiftTUI's built-in `.magenta` value, so it
    /// reproduces exactly. Used for the wordmark, the active step, selection
    /// markers, the progress-bar fill, and buttons.
    static let accent = Color(hexRGB: 0xB46EFF)

    /// A dimmer violet for box borders and the empty part of the progress bar.
    static let accentDim = Color(hexRGB: 0x544178)
}
