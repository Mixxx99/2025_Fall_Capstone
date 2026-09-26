import SwiftUI
import UIKit   // ← needed for UIColor

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return nil }

        self = Color(
            red:   Double((v & 0xFF0000) >> 16) / 255.0,
            green: Double((v & 0x00FF00) >> 8)  / 255.0,
            blue:  Double( v & 0x0000FF)        / 255.0
        )
    }

    var hex6: String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)   // ← labeled args
        return String(format: "%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
    }
}

struct TagChip: View {
    let title: String
    let color: Color
    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(color.opacity(0.18))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
