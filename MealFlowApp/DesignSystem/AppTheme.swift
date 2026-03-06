import SwiftUI
import UIKit

enum AppTheme {
    static let background = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.14, green: 0.12, blue: 0.10, alpha: 1)
                : UIColor(red: 0.97, green: 0.94, blue: 0.88, alpha: 1)
        }
    )

    static let panel = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.21, green: 0.18, blue: 0.15, alpha: 1)
                : UIColor(red: 0.99, green: 0.98, blue: 0.95, alpha: 1)
        }
    )

    static let card = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.24, green: 0.20, blue: 0.17, alpha: 1)
                : UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1)
        }
    )

    static let soil = Color(
        uiColor: UIColor(red: 0.42, green: 0.28, blue: 0.20, alpha: 1)
    )

    static let terracotta = Color(
        uiColor: UIColor(red: 0.76, green: 0.42, blue: 0.29, alpha: 1)
    )

    static let butter = Color(
        uiColor: UIColor(red: 0.94, green: 0.81, blue: 0.50, alpha: 1)
    )

    static let sage = Color(
        uiColor: UIColor(red: 0.48, green: 0.62, blue: 0.50, alpha: 1)
    )

    static let berry = Color(
        uiColor: UIColor(red: 0.63, green: 0.36, blue: 0.40, alpha: 1)
    )

    static let mist = Color.white.opacity(0.44)
    static let stroke = Color.primary.opacity(0.09)
    static let softShadow = Color.black.opacity(0.10)
    static let warmShadow = Color(red: 0.42, green: 0.28, blue: 0.20).opacity(0.12)
}
