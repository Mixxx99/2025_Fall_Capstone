import Foundation

enum TimeUtils {
    static func msToHMS(_ ms: Int64) -> String {
        let totalSeconds = Int(ms / 1000)
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    static var nowMs: Int64 { Int64(Date().timeIntervalSince1970 * 1000) }
}
