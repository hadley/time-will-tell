import SwiftUI

enum TimerZone: Equatable {
    case black
    case yellow
    case red
    case flashing

    var backgroundColor: Color {
        switch self {
        case .black:
            return .black
        case .yellow:
            return .yellow
        case .red:
            return .red
        case .flashing:
            return .red
        }
    }

    var textColor: Color {
        switch self {
        case .black:
            return .white
        case .yellow:
            return .black
        case .red:
            return .white
        case .flashing:
            return .white
        }
    }
}

enum TimerStatus {
    case idle
    case running
    case paused
    case finished
}
